functor
import
   GUI
   Input
   PlayerManager
   OS
   System
define
   CreatePortsList % Create ALL ports for pacmans/ghosts
   InitPlayers % Init ALL players by sending msg to window port (pacman + ghost)
   InitItems % Init ALL items by sending msg to window port (bonus + point)
   ListPositionWithValue % List ALL position with a value in Map
   AssignSpawnPlayers % Assign ALL spawn by sending msg to pacmans/ghosts ports
   SpawnPlayers % Spawn ALL pacmans/ghosts by sending msg to their ports and to WindowPort
   SpawnItems % Spawn ALL bonus/points by sending msg to window port
   SendItemsPosList % Send a list of item to the given port with the given msg
   
   RandomMerge % Merge and order at random the two given list
   MovePlayer
   PlayerAtPos
   ListContains
   DeleteFromList

   AddPoint
   SendAll

   Initialisation
   TurnByTurn
   
   PacmansSpawns GhostsSpawns
   PointsSpawns BonusSpawns
   
   WindowPort
   PacmansPorts GhostsPorts
   PacmansMapping GhostsMapping % List with: port#<position>
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
      fun{Count L P I}
	 case L
	 of nil then I
	 [] (_#data(port:_ pt:Pos))|T then
	    if Pos==P then {Count T P I+1}
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
	       {Local T (ID#data(port:PlayerPort pt:Spawn))|Assigned}
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


   % Order at random the two given list
   fun{RandomMerge L1 L2}
      case L1#L2
      of nil#nil then nil
      [] nil#(H|T) then H|{RandomMerge nil T}
      [] (H|T)#nil then H|{RandomMerge T nil}
      [] (H1|T1)#(H2|T2) then
	 if ({OS.rand} mod 2)==0 then H1|{RandomMerge T1 L2}
	 else H2|{RandomMerge L1 T2}
	 end
      end
   end

   % Move ONE player ONCE and return move made
   fun{MovePlayer WindowPort PlayerPort}
      ID P
   in
      {Send PlayerPort move(ID P)} {Wait ID} {Wait P}
      case {Record.label ID}
      of pacman then {Send WindowPort movePacman(ID P)}
      [] ghost then {Send WindowPort moveGhost(ID P)}
      end
      move(ID P)
   end

   % Check if there is a player at <position> P and return the <ghost>/<pacman> ID or null
   fun{PlayerAtPos P PlayersMapping PlayerType}
      case PlayersMapping
      of nil then null
      [] (ID#data(port:_ pt:Pos))|T then
	 if {And {Record.label ID}==PlayerType Pos==P} then ID
	 else {PlayerAtPos P T PlayerType}
	 end
      end
   end
   % Check if there is the given value in the given list
   fun{ListContains V L}
      case L
      of nil then false
      [] H|T then
	 if H==V then true
	 else {ListContains V T}
	 end
      end
   end
   % Delete an element from the given list
   fun{DeleteFromList L V}
      case L
      of nil then nil
      [] H|T then
	 if H==V then T
	 else H|{DeleteFromList T V}
	 end
      end
   end

   % Add point to the given Port for <position> P
   proc{AddPoint WindowPort PlayerPort P}
      % pacman:pointSpawn(P) to ALL
      ID NewScore
   in
      {Send PlayerPort addPoint(Input.rewardPoint ID NewScore)}
      {Send WindowPort hidePoint(P)}
      {Send WindowPort scoreUpdate(ID NewScore)}
   end

   proc{SendAll PlayersMapping Type Msg}
      case PlayersMapping
      of nil then skip
      [] (ID#data(port:PlayerPort pt:_))|T then
	 if {Record.label ID}==Type then {Send PlayerPort Msg} {SendAll T Type Msg}
	 else {SendAll T Type Msg}
	 end
      end
   end
      
   proc{TurnByTurn WindowPort PlayersMapping BonusPos PointPos Round}
      fun{PlayOneTurn Mapping BonusPos PointPos MappingAcc}
	 case Mapping
	 of nil then oneTurn(mapping:{Reverse MappingAcc} bonusPos:BonusPos pointPos:PointPos)
	 [] (pacman(id:_ color:_ name:_)#data(port:Port pt:_))|T then
	    move(ID P)={MovePlayer WindowPort Port} NewMapElem=(ID#data(port:Port pt:P))
	    IDFound={PlayerAtPos P PlayersMapping ghost}
	 in
	    if IDFound\=null then
	       {PlayOneTurn T BonusPos PointPos NewMapElem|MappingAcc}
	    elseif {ListContains P BonusPos} then
	       {PlayOneTurn T {DeleteFromList BonusPos P} PointPos NewMapElem|MappingAcc}
	    elseif {ListContains P PointPos} then
	       {AddPoint WindowPort Port P}
	       {SendAll PlayersMapping pacman pointSpawn(P)}
	       {PlayOneTurn T BonusPos {DeleteFromList PointPos P} NewMapElem|MappingAcc}
	    else {PlayOneTurn T BonusPos PointPos NewMapElem|MappingAcc}
	    end
	 [] (ghost(id:_ color:_ name:_)#data(port:Port pt:_))|T then
	    move(ID P)={MovePlayer WindowPort Port} NewMapElem=(ID#data(port:Port pt:P))
	    IDFound={PlayerAtPos P PlayersMapping pacman}
	 in
	    if IDFound==null then {PlayOneTurn T BonusPos PointPos NewMapElem|MappingAcc}
	    else {PlayOneTurn T BonusPos PointPos NewMapElem|MappingAcc}
	    end
	 end
      end
   in
      if Round==30 then skip
      else oneTurn(mapping:NewPlayersMapping bonusPos:NewBonusPos pointPos:NewPointPos)={PlayOneTurn PlayersMapping BonusPos PointPos nil} in
	 {Delay 1000}
	 {TurnByTurn WindowPort NewPlayersMapping NewBonusPos NewPointPos Round+1}
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
	 for J in 1..Input.nbGhost do (ID#data(port:_ pt:Pos))={Nth GhostsMapping J} in
	    {Send PacmanPort ghostPos(ID Pos)}
	 end
      end
      % Inform Ghosts about Pacmans positions
      for I in 1..Input.nbGhost do GhostPort={Nth GhostsPorts I} in
	 for J in 1..Input.nbPacman do (ID#data(port:_ pt:Pos))={Nth PacmansMapping J} in
	    {Send GhostPort pacmanPos(ID Pos)}
	 end
      end
   end

   
   thread
      {Initialisation}
      {TurnByTurn WindowPort {RandomMerge PacmansMapping GhostsMapping} BonusSpawns PointsSpawns 1}
   end
end