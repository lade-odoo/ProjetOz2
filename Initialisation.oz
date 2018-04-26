functor
import
   GUI
   Input
   PlayerManager
   OS
export
   initialisation:Initialisation
   windowPort:WindowPort
   pacmansMapping:PacmansMapping
   ghostsMapping:GhostsMapping
   pointsSpawns:PointsSpawns
   bonusSpawns:BonusSpawns
define
   CreatePortsList % Create ALL ports for pacmans/ghosts
   InitPlayers % Init ALL players by sending msg to window port (pacman + ghost)
   InitItems % Init ALL items by sending msg to window port (bonus + point)
   ListPositionWithValue % List ALL position with a value in Map
   AssignSpawnPlayers % Assign ALL spawn by sending msg to pacmans/ghosts ports
   SpawnPlayers % Spawn ALL pacmans/ghosts by sending msg to their ports and to WindowPort
   SpawnItems % Spawn ALL bonus/points by sending msg to window port
   SendItemsPosList % Send a list of item to the given port with the given msg
   
   Initialisation
   
   PacmansSpawns GhostsSpawns
   PointsSpawns BonusSpawns
   
   WindowPort
   PacmansPorts GhostsPorts
   PacmansMapping GhostsMapping % List with: ID#data(port:<Port> pt:<position> turnToRespawn:null'|'0'|'...'|'Infinite
in
   % Send a list of item to the given port with the given msg
   proc{SendItemsPosList Port ItemsList Msg}
      case ItemsList
      of nil then skip
      [] Item|T then {Send Port Msg(Item)} {SendItemsPosList Port T Msg}
      end
   end
   
   % Create ports for pacmans/ghosts
   fun{CreatePortsList StartID Kinds Colors Type}
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
      fun{Count L P I}
	 case L
	 of nil then I
	 [] _#_#Position|T then
	    if Position==P then {Count T P I+1}
	    else {Count T P I}
	    end
	 end
      end
      fun{Local PlayersPorts Assigned}
	 case PlayersPorts
	 of nil then Assigned
	 [] PlayerPort|T then Spawn={Nth Spawns ({OS.rand} mod NbSpawns)+1} ID in
	    if {Count Assigned Spawn 0}>=(NbPorts div NbSpawns) then {Local PlayersPorts Assigned}
	    else
	       {Send PlayerPort getId(ID)} {Wait ID}
	       {Send PlayerPort assignSpawn(Spawn)}
	       {Local T ID#PlayerPort#Spawn|Assigned}
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Initialize the game
   proc{Initialisation}
      PointsSpawns={ListPositionWithValue Input.map 0}
      PacmansSpawns={ListPositionWithValue Input.map 2}
      GhostsSpawns={ListPositionWithValue Input.map 3}
      BonusSpawns={ListPositionWithValue Input.map 4}
      
      % Create port for Window + Pacmans + Ghosts
      WindowPort={GUI.portWindow}
      PacmansPorts={CreatePortsList 1 Input.pacman Input.colorPacman pacman}
      GhostsPorts={CreatePortsList 1+Input.nbPacman Input.ghost Input.colorGhost ghost}
      
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
	 for J in 1..Input.nbGhost do ID#_#Pos={Nth GhostsMapping J} in
	    {Send PacmanPort ghostPos(ID Pos)}
	 end
      end
      % Inform Ghosts about Pacmans positions
      for I in 1..Input.nbGhost do GhostPort={Nth GhostsPorts I} in
	 for J in 1..Input.nbPacman do ID#_#Pos={Nth PacmansMapping J} in
	    {Send GhostPort pacmanPos(ID Pos)}
	 end
      end
   end
end