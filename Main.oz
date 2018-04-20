functor
import
   GUI
   Input
   PlayerManager
   OS
define
   CreatePortsList % Create ALL ports for pacmans/ghosts
   InitPlayers % Init ALL players by sending msg to window port (pacman + ghost)
   InitItems % Init ALL items by sending msg to window port (bonus + point)
   ListPositionWithValue % List ALL position with a value in Map
   AssignSpawnPlayers % Assign ALL spawn by sending msg to pacmans/ghosts ports
   SpawnPlayers % Spawn ALL pacmans/ghosts by sending msg to their ports and to WindowPort
   SpawnItems % Spawn ALL bonus/points by sending msg to window port
   SendItemsPosList % Send a list of item to the given port with the given msg

   MovePlayer % Move ONE player by sending msg to player port then to window port

   Initialisation
   
   PacmansSpawns
   GhostsSpawns
   PointsSpawns
   BonusSpawns
   
   WindowPort
   PacmansPorts GhostsPorts
   PacmansMapping GhostsMapping % List with: port#<spawn>
in
   % Send a list of item to the given port with the given msg
   proc{SendItemsPosList Port ItemsList Msg}
      case ItemsList
      of nil then skip
      [] Item|T then {Send Port Msg(Item)} {SendItemsPosList Port T Msg}
      end
   end
   
   % Create ports for pacmans/ghosts
   fun{CreatePortsList StartID Nb Kinds Colors Type}
      fun{Local I Kinds Colors}
	 case Kinds#Colors
	 of nil#nil then nil
	 [] (Kind|T1)#(Color|T2) then {PlayerManager.playerGenerator Kind Type(id:StartID+I-1 color:Color name:Kind)}|{Local I+1 T1 T2}
	 end
      end
   in
      {Local 1 Kinds Colors}
   end

   % Init pacmans/ghosts by sending msg to the window port
   proc{InitPlayers WindowPort PlayersPorts Msg}
      case PlayersPorts
      of nil then skip
      [] PlayerPort|T then ID in
	 {Send PlayerPort getId(ID)} {Wait ID}
	 {Send WindowPort Msg(ID)}
	 {InitPlayers WindowPort T Msg}
      end
   end

   % Init bonus/points by sending a msg to the WindowPort
   proc{InitItems WindowPort Spawns Msg}
      case Spawns
      of nil then skip
      [] Spawn|T then {Send WindowPort Msg(Spawn)} {InitItems WindowPort T Msg}
      end
   end

   % List positions with given value in Map
   fun{ListPositionWithValue Map Value}
      fun{ReadRow Row RowIndex ColumnIndex L}
	 case Row
	 of nil then L
	 [] H|T then
	    if H==Value then {ReadRow T RowIndex ColumnIndex+1 pt(x:ColumnIndex y:RowIndex)|L}
	    else {ReadRow T RowIndex ColumnIndex+1 L}
	    end
	 end
      end
      fun{Local Map RowIndex L}
	 case Map
	 of nil then L
	 [] Row|T then {Local T RowIndex+1 {ReadRow Row RowIndex 1 L}}
	 end
      end
   in
      {Local Map 1 nil}
   end

   % Assign spawns to pacmans/ghosts at random
   fun{AssignSpawnPlayers WindowPort PlayersPorts NbPorts Spawns NbSpawns}
      fun{Count L V I}
	 case L
	 of nil then I
	 [] (_#H)|T then
	    if H==V then {Count T V I+1}
	    else {Count T V I}
	    end
	 end
      end
      fun{Local PlayersPorts Assigned}
	 case PlayersPorts
	 of nil then Assigned
	 [] PlayerPort|T then Elem={Nth Spawns ({OS.rand} mod NbSpawns)+1} in
	    if {Count Assigned Elem 0}>=(NbPorts div NbSpawns) then {Local PlayersPorts Assigned}
	    else
	       {Send PlayerPort assignSpawn(Elem)}
	       {Local T (PlayerPort#Elem)|Assigned}
	    end
	 end
      end
   in
      {Local PlayersPorts nil}
   end

   % Spawn pacmans/ghost by sending msg to their port and to the window port
   proc{SpawnPlayers WindowPort PlayersPorts Msg}
      case PlayersPorts
      of nil then skip
      [] PlayerPort|T then ID P in
	 {Send PlayerPort spawn(ID P)} {Wait ID} {Wait P}
	 {Send WindowPort Msg(ID P)}
	 {SpawnPlayers WindowPort T Msg}
      end
   end
   
   % Spawn points/bonus by sending msg to window port
   proc{SpawnItems WindowPort Spawns Msg}
      case Spawns
      of nil then skip
      [] Spawn|T then
	 {Send WindowPort Msg(Spawn)}
	 {SpawnItems WindowPort T Msg}
      end
   end

   % Move the player by sending msg to player port then to window port
   proc{MovePlayer WindowPort PlayerPort Msg}
      local ID P in
	 {Send PlayerPort move(ID P)} {Wait ID} {Wait P}
	 {Send WindowPort Msg(ID P)}
      end
   end
   
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   
   % Initialize the game
   proc{Initialisation}
      PointsSpawns={ListPositionWithValue Input.map 0}
      PacmansSpawns={ListPositionWithValue Input.map 2}
      GhostsSpawns={ListPositionWithValue Input.map 3}
      BonusSpawns={ListPositionWithValue Input.map 4}
      
      % Create port for Window + Pacmans + Ghosts
      WindowPort={GUI.portWindow}
      PacmansPorts={CreatePortsList 1 Input.nbPacman Input.pacman Input.colorPacman pacman}
      GhostsPorts={CreatePortsList 1+Input.nbPacman Input.nbGhost Input.ghost Input.colorGhost ghost}
      
      % Init Window + Pacmans + Ghosts + Bonus + Point
      {Send WindowPort buildWindow}
      {InitPlayers WindowPort PacmansPorts initPacman}
      {InitPlayers WindowPort GhostsPorts initGhost}
      {InitItems WindowPort BonusSpawns initBonus}
      {InitItems WindowPort PointsSpawns initPoint}
      
      % Assign spawns to Pacmans + Ghosts
      PacmansMapping={AssignSpawnPlayers WindowPort PacmansPorts Input.nbPacman PacmansSpawns {Length PacmansSpawns}}
      GhostsMapping={AssignSpawnPlayers WindowPort GhostsPorts Input.nbGhost GhostsSpawns {Length GhostsSpawns}}

      % Spawn Pacmans + Ghosts
      {SpawnPlayers WindowPort PacmansPorts spawnPacman}
      {SpawnPlayers WindowPort GhostsPorts spawnGhost}
      {SpawnItems WindowPort BonusSpawns spawnBonus}
      {SpawnItems WindowPort PointsSpawns spawnPoint}

      % Inform Pacmans about items positions
      for I in 1..Input.nbPacman do Port={Nth PacmansPorts I} in
	 {SendItemsPosList Port BonusSpawns bonusSpawn}
	 {SendItemsPosList Port PointsSpawns pointSpawn}
      end
      % Infrom Pacmans about Ghosts position
      for I in 1..Input.nbPacman do PacmanPort={Nth PacmansPorts I} in
	 for J in 1..Input.nbGhost do ID Elem={Nth GhostsMapping J} in
	    {Send Elem.1 getId(ID)} {Wait ID}
	    {Send PacmanPort ghostPos(ID Elem.2)}
	 end
      end
      % Inform Ghosts about Pacmans positions
      for I in 1..Input.nbGhost do GhostPort={Nth GhostsPorts I} in
	 for J in 1..Input.nbPacman do ID Elem={Nth PacmansMapping J} in
	    {Send Elem.1 getId(ID)} {Wait ID}
	    {Send GhostPort pacmanPos(ID Elem.2)}
	 end
      end
   end
   
   thread
      {Initialisation}
   end
end