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
   BuildMappingItems
   AddPoint
   SendAll
   ContainsPos
   DisableFromItemsList
   MovePlayer
   PlayerAtPos
   RespawnItem
   ChangeMode

   Initialisation
   TurnByTurn
   
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
	 [] (_#data(port:_ pt:Pos turnToRespawn:_))|T then
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
	       {Local T (ID#data(port:PlayerPort pt:Spawn turnToRespawn:null))|Assigned}
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

   fun{MovePlayer WindowPort PlayerPort}
      ID P
   in
      {Send PlayerPort move(ID P)} {Wait ID} {Wait P}
      if {Record.label ID}==pacman then {Send WindowPort movePacman(ID P)}
      else {Send WindowPort moveGhost(ID P)}
      end
      move(ID P)
   end
   proc{AddPoint WindowPort PlayerPort Pos}
      ID NewScore
   in
      {Send PlayerPort addPoint(Input.rewardPoint ID NewScore)}
      {Send WindowPort hidePoint(Pos)}
      {Send WindowPort scoreUpdate(ID NewScore)}
   end
   proc{ChangeMode WindowPort PlayersMapping Mode}
      {Send WindowPort setMode(Mode)}
      if PlayersMapping\=null then 
	 {SendAll PlayersMapping pacman setMode(Mode)}
	 {SendAll PlayersMapping ghost setMode(Mode)}
      else skip
      end
   end

   fun{PlayerAtPos Mapping Pos Type}
      case Mapping
      of nil then null#null
      [] (ID#Data)|T then
	 if {And {Record.label ID}==Type Data.pt==Pos} then ID#Data
	 else {PlayerAtPos T Pos Type}
	 end
      end
   end
   
   fun{ContainsPos Pos L}
      case L
      of nil then false
	 [] (P#TurnToRespawn)|T then
	 if {And P==Pos TurnToRespawn==null} then true
	 else {ContainsPos Pos T}
	 end
      end
   end

   fun{DisableFromItemsList ItemsMapping Pos RespawnTurn}
      case ItemsMapping
      of nil then nil
      [] H|T then
	 if Pos==H.1 then (H.1#RespawnTurn)|T
	 else H|{DisableFromItemsList T Pos RespawnTurn}
	 end
      end
   end

   proc{SendAll Mapping Type Msg}
      case Mapping
      of nil then skip
      [] (ID#data(port:Port pt:_ turnToRespawn:_))|T then
	 if {Record.label ID}==Type then {Send Port Msg} {SendAll T Type Msg}
	 else {SendAll T Type Msg}
	 end
      end
   end

   fun{RespawnItem Pos Type WindowPort PlayersMapping}
      (PacmanID#PacmanData)={PlayerAtPos PlayersMapping Pos pacman}
   in
      if PacmanID\=null then
	 if Type==point then {AddPoint WindowPort PacmanData.port Pos} false
	 else {ChangeMode WindowPort null hunt} false
	 end
      elseif Type==point then
	 {Send WindowPort spawnPoint(Pos)}
	 {SendAll PlayersMapping pacman pointSpawn(Pos)}
	 true
      else
	 {Send WindowPort spawnBonus(Pos)}
	 {SendAll PlayersMapping pacman bonusSpawn(Pos)}
	 true
      end
   end
   
   % (ID#data(port:_ pt:<position> turnToRespawn:_)) = PlayersMapping
   % <position>#TurnToRespawn = BonusPos'|'PointPos
   % <mode>#TurnLeft = Mode
   proc{TurnByTurn WindowPort PlayersMapping BonusPos PointPos}
      fun{PlayOneTurn Mapping BonusPos PointPos Mode MappingAcc}
	 case Mapping
	 of nil then rt(mapping:{Reverse MappingAcc} bonusPos:BonusPos pointPos:PointPos mode:Mode)
	 [] (pacman(id:_ color:_ name:_)#data(port:Port pt:_ turnToRespawn:TurnToRespawn))|T then
	    move(ID P)={MovePlayer WindowPort Port}
	    (GhostID#_)={PlayerAtPos PlayersMapping P ghost}
	    NewMappingElem=(ID#data(port:Port pt:P turnToRespawn:TurnToRespawn))
	 in
	    if GhostID\=null then
	       {PlayOneTurn T BonusPos PointPos Mode NewMappingElem|MappingAcc}
	    elseif {ContainsPos P BonusPos} then
	       {Send WindowPort hideBonus(P)}
	       {ChangeMode WindowPort PlayersMapping hunt}
	       {PlayOneTurn T {DisableFromItemsList BonusPos P Input.respawnTimeBonus} PointPos hunt#Input.huntTime NewMappingElem|MappingAcc}
	    elseif {ContainsPos P PointPos} then
	       {AddPoint WindowPort Port P}
	       {SendAll PlayersMapping pacman pointSpawn(P)}
	       {PlayOneTurn T BonusPos {DisableFromItemsList PointPos P Input.respawnTimePoint} Mode NewMappingElem|MappingAcc}
	    else {PlayOneTurn T BonusPos PointPos Mode NewMappingElem|MappingAcc}
	    end
	 [] (ghost(id:_ color:_ name:_)#data(port:Port pt:_ turnToRespawn:TurnToRespawn))|T then
	    move(ID P)={MovePlayer WindowPort Port}
	    (PacmanID#_)={PlayerAtPos PlayersMapping P pacman}
	    NewMappingElem=(ID#data(port:Port pt:P turnToRespawn:TurnToRespawn))
	 in
	    if PacmanID\=null then
	       {PlayOneTurn T BonusPos PointPos Mode NewMappingElem|MappingAcc}
	    else {PlayOneTurn T BonusPos PointPos Mode NewMappingElem|MappingAcc}
	    end
	 end
      end
      fun{CountPlayerInMapping Mapping Type C}
	 case Mapping
	 of nil then C
	 [] (ID#_)|T then
	    if {Record.label ID}==Type then {CountPlayerInMapping T Type C+1}
	    else {CountPlayerInMapping T Type C}
	    end
	 end
      end
      fun{UpdateItemsMapping ItemsMapping Type PlayersMapping}
	 case ItemsMapping
	 of nil then nil
	 [] (Pos#TurnToRespawn)|T then
	    if TurnToRespawn==null then (Pos#TurnToRespawn)|{UpdateItemsMapping T Type PlayersMapping}
	    elseif TurnToRespawn==0 then
	       if {RespawnItem Pos Type WindowPort PlayersMapping} then (Pos#null)|{UpdateItemsMapping T Type PlayersMapping}
	       elseif Type==point then (Pos#Input.respawnTimePoint)|{UpdateItemsMapping T Type PlayersMapping}
	       else (Pos#Input.respawnTimeBonus)|{UpdateItemsMapping T Type PlayersMapping}
	       end
	    else (Pos#TurnToRespawn-1)|{UpdateItemsMapping T Type PlayersMapping}
	    end
	 end
      end
      proc{Local Mapping BonusPos PointPos Mode Round}
	 %if {CountPlayerInMapping Mapping pacman 0}==0 then skip
	 if Round==300 then skip
	 else
	    rt(mapping:NewMapping bonusPos:RTBonusPos pointPos:RTPointPos mode:NewMode)={PlayOneTurn Mapping BonusPos PointPos Mode nil}
	    NewBonusPos={UpdateItemsMapping RTBonusPos bonus NewMapping}
	    NewPointPos={UpdateItemsMapping RTPointPos point NewMapping}
	 in
	    {Delay 1000}
	    if {And NewMode.1==hunt NewMode.2==0} then
	       {ChangeMode WindowPort NewMapping classic}
	       {Local NewMapping NewBonusPos NewPointPos classic#null Round+1}
	    elseif NewMode.1==hunt then {Local NewMapping NewBonusPos NewPointPos hunt#NewMode.2-1 Round+1}
	    else {Local NewMapping NewBonusPos NewPointPos classic#null Round+1}
	    end
	 end
      end
   in
      {Local PlayersMapping BonusPos PointPos classic#null 1}
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
	 for J in 1..Input.nbGhost do (ID#data(port:_ pt:Pos turnToRespawn:_))={Nth GhostsMapping J} in
	    {Send PacmanPort ghostPos(ID Pos)}
	 end
      end
      % Inform Ghosts about Pacmans positions
      for I in 1..Input.nbGhost do GhostPort={Nth GhostsPorts I} in
	 for J in 1..Input.nbPacman do (ID#data(port:_ pt:Pos turnToRespawn:_))={Nth PacmansMapping J} in
	    {Send GhostPort pacmanPos(ID Pos)}
	 end
      end
   end

   
   fun{BuildMappingItems Positions}
      case Positions
      of nil then nil
      [] H|T then (H#null)|{BuildMappingItems T}
      end
   end
      
   thread
      {Initialisation}
      local PointsMapping={BuildMappingItems PointsSpawns} BonusMapping={BuildMappingItems BonusSpawns} in
	 {TurnByTurn WindowPort {RandomMerge PacmansMapping GhostsMapping} BonusMapping PointsMapping}
      end
   end
end