functor
import
   Input
   OS System
export
   turnByTurn:TurnByTurn
   winner:Winner
define
   PlayerAtPosition ItemAtPosition
   PlayerWithID
   UpdatePlayersRespawn UpdatePlayersPosition UpdateItems
   SendAll
   GetType
   
   SpawnGhost SpawnPacman
   MoveGhost MovePacman
   KilledByGhost KillGhost
   CollectPoint CollectBonus
   SpawnPoint SpawnBonus
   
   RandomMerge
   TurnByTurn
   TreatStream
   PlayOneTurn
   OneTurnElapsedPlayers OneTurnElapsedItems OneTurnElapsedMode
   PacmanPlayer GhostPlayer
   CreatePlayersState
   Winner
in
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
   
   fun{PacmanPlayer MapPort PlayerPort IsAlive LivesLeft}
      if LivesLeft==0 then false#0
      else ID P HasSurvived in
	 if IsAlive then
	    {Send PlayerPort move(ID P)} {Wait ID} {Wait P}
	    if {Or ID==null P==null} then HasSurvived=false % Killed
	    else {Send MapPort movePacman(ID P HasSurvived)} {Wait HasSurvived} % Alive
	    end
	 else
	    {Send PlayerPort spawn(ID P)} {Wait ID} {Wait P}
	    if {Or ID==null P==null} then HasSurvived=false % Killed
	    else {Send MapPort spawnPacman(ID P HasSurvived)} {Wait HasSurvived} % Spawned
	    end
	 end
	 
	 if HasSurvived==null then false#LivesLeft-1
	 elseif HasSurvived then true#LivesLeft
	 else false#LivesLeft-1
	 end
      end
   end
   fun{GhostPlayer MapPort PlayerPort IsAlive}
      local ID P HasSurvived in
	 if IsAlive then
	    {Send PlayerPort move(ID P)} {Wait ID} {Wait P}
	    if {Or ID==null P==null} then HasSurvived=false % Killed
	    else {Send MapPort moveGhost(ID P HasSurvived)} {Wait HasSurvived} % Alive
	    end
	 else
	    {Send PlayerPort spawn(ID P)} {Wait ID} {Wait P}
	    if {Or ID==null P==null} then HasSurvived=false % Failed to spawn
	    else {Send MapPort spawnGhost(ID P HasSurvived)} {Wait HasSurvived} % Spawned
	    end
	 end
	 if HasSurvived==null then false
	 else HasSurvived
	 end
      end
   end
     
   proc{TreatStream Stream WindowPort Pacmans Ghosts Mode Points Bonus}
      {System.show 'MapServer: '#Stream.1}
      case Stream
      of nil then skip
      [] spawnPacman(ID P HasSurvived)|T then
	 RT={SpawnPacman ID P WindowPort Pacmans Ghosts Mode} in
	 case RT
	 of pacmans(NewPacmans)#ghosts(NewGhosts)#HasSurvivedRT then
	    HasSurvived=HasSurvivedRT
	    {TreatStream T WindowPort NewPacmans NewGhosts Mode Points Bonus}
	 end
      [] spawnGhost(ID P HasSurvived)|T then
	 RT={SpawnGhost ID P WindowPort Pacmans Ghosts Mode} in
	 case RT
	 of pacmans(NewPacmans)#ghosts(NewGhosts)#HasSurvivedRT then
	    HasSurvived=HasSurvivedRT
	    {TreatStream T WindowPort NewPacmans NewGhosts Mode Points Bonus}
	 end
      [] movePacman(ID P HasSurvived)|T then
	 if {PlayerWithID ID Pacmans}.3==null then % Invalid move need to respawn if actual pos==null
	    {System.show invalidPacmanMoveCatched(ID)}
	    HasSurvived=null
	    {TreatStream T WindowPort Pacmans Ghosts Mode Points Bonus}
	 else
	    RT={MovePacman ID P WindowPort Pacmans Ghosts Mode Points Bonus} in
	    case RT
	    of pacmans(NewPacmans)#ghosts(NewGhosts)#mode(NewMode)#points(NewPoints)#bonus(NewBonus)#HasSurvivedRT then
	       HasSurvived=HasSurvivedRT
	       {TreatStream T WindowPort NewPacmans NewGhosts NewMode NewPoints NewBonus}
	    end
	 end
      [] moveGhost(ID P HasSurvived)|T then
	 if {PlayerWithID ID Ghosts}.3==null then % Invalid move need to respawn if actual pos==null
	    {System.show invalidGhostMoveCatched(ID)}
	    HasSurvived=null
	    {TreatStream T WindowPort Pacmans Ghosts Mode Points Bonus}
	 else
	    RT={MoveGhost ID P WindowPort Pacmans Ghosts Mode Points Bonus} in
	    case RT
	    of pacmans(NewPacmans)#ghosts(NewGhosts)#mode(NewMode)#points(NewPoints)#bonus(NewBonus)#HasSurvivedRT then
	       HasSurvived=HasSurvivedRT
	       {TreatStream T WindowPort NewPacmans NewGhosts NewMode NewPoints NewBonus}
	    end
	 end
      [] roundFinished(Finished)|T then
	 ModeV1={OneTurnElapsedMode WindowPort Mode Pacmans Ghosts} 
	 pacmans(PacmansV2)#ghosts(GhostsV2)={OneTurnElapsedPlayers WindowPort Pacmans Pacmans Ghosts ModeV1 pacman}
	 pacmans(NewPacmans)#ghosts(NewGhosts)={OneTurnElapsedPlayers WindowPort GhostsV2 PacmansV2 GhostsV2 ModeV1 ghost}
	 mode(ModeV2)#bonus(BonusV2)#points(PointsV2)={OneTurnElapsedItems WindowPort Bonus NewPacmans NewGhosts ModeV1 Points Bonus bonus}
	 mode(NewMode)#bonus(NewBonus)#points(NewPoints)={OneTurnElapsedItems WindowPort PointsV2 NewPacmans NewGhosts ModeV2 PointsV2 BonusV2 point}
      in
	 Finished=unit
	 {TreatStream T WindowPort NewPacmans NewGhosts NewMode NewPoints NewBonus} 
      else
	 {System.show 'MapServer: Incompatible message: '#Stream.1}
      end
   end
   fun{SpawnPacman ID Position WindowPort Pacmans Ghosts Mode}
      Ghost={PlayerAtPosition Position Ghosts}
      Pacman={PlayerWithID ID Pacmans}
   in
      if Mode.1==classic andthen Ghost\=null then % Killed by ghost
	 if {KilledByGhost WindowPort Pacman Ghost Ghosts}==0 then pacmans({UpdatePlayersRespawn Pacmans ID dead})#ghosts(Ghosts)#false
	 else pacmans({UpdatePlayersRespawn Pacmans ID Input.respawnTimePacman})#ghosts(Ghosts)#false
	 end
      elseif Mode.1==hunt andthen Ghost\=null then % Kill a ghost
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans({UpdatePlayersPosition Pacmans ID Position})#ghosts({UpdatePlayersRespawn Ghosts Ghost.1 Input.respawnTimeGhost})#true
      else % Spawn
	 {Send WindowPort spawnPacman(ID Position)}
	 {SendAll Ghosts pacmanPos(ID Position)}
	 pacmans({UpdatePlayersPosition Pacmans ID Position})#ghosts(Ghosts)#true
      end
   end
   fun{SpawnGhost ID Position WindowPort Pacmans Ghosts Mode}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerWithID ID Ghosts}
   in
      if Mode.1==classic andthen Pacman\=null then % Kill a pacman
	 if {KilledByGhost WindowPort Pacman Ghost Ghosts}==0 then
	    pacmans({UpdatePlayersRespawn Pacmans Pacman.1 dead})#ghosts({UpdatePlayersPosition Ghosts ID Position})#true
	 else
	    pacmans({UpdatePlayersRespawn Pacmans Pacman.1 Input.respawnTimePacman})#ghosts({UpdatePlayersPosition Ghosts ID Position})#true
	 end
      elseif Mode.1==hunt andthen Pacman\=null then % Killed by a pacman
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans(Pacmans)#ghosts({UpdatePlayersRespawn Ghosts ID Input.respawnTimeGhost})#false
      else % Spawn
	 {Send WindowPort spawnGhost(ID Position)}
	 {SendAll Pacmans ghostPos(ID Position)}
	 pacmans(Pacmans)#ghosts({UpdatePlayersPosition Ghosts ID Position})#true
      end
   end
   fun{MovePacman ID Position WindowPort Pacmans Ghosts Mode Points Bonus}
      Ghost={PlayerAtPosition Position Ghosts}
      Pacman={PlayerWithID ID Pacmans}
      ItemPoints={ItemAtPosition Position Points}
      ItemBonus={ItemAtPosition Position Bonus}
   in
      {Send WindowPort movePacman(ID Position)}
      {SendAll Ghosts pacmanPos(ID Position)}
      
      if Mode.1==classic andthen Ghost\=null then % Kill by a ghost
	 if {KilledByGhost WindowPort Pacman Ghost Ghosts}==0 then
	    pacmans({UpdatePlayersRespawn Pacmans ID dead})#ghosts(Ghosts)#mode(Mode)#points(Points)#bonus(Bonus)#false
	 else
	    pacmans({UpdatePlayersRespawn Pacmans ID Input.respawnTimePacman})#ghosts(Ghosts)#mode(Mode)#points(Points)#bonus(Bonus)#false
	 end
      elseif Mode.1==hunt andthen Ghost\=null then % Kill a ghost
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans({UpdatePlayersPosition Pacmans ID Position})#ghosts({UpdatePlayersRespawn Ghosts Ghost.1 Input.respawnTimeGhost})#mode(Mode)#points(Points)#bonus(Bonus)#true
      elseif ItemPoints\=null then % Collect a point
	 {CollectPoint WindowPort Position Pacman Pacmans}
	 pacmans({UpdatePlayersPosition Pacmans ID Position})#ghosts(Ghosts)#mode(Mode)#points({UpdateItems Points Position Input.respawnTimePoint})#bonus(Bonus)#true
      elseif ItemBonus\=null then % Collect a bonus
	 {CollectBonus WindowPort Position Pacmans Ghosts}
	 pacmans({UpdatePlayersPosition Pacmans ID Position})#ghosts(Ghosts)#mode(hunt#Input.huntTime)#points(Points)#bonus({UpdateItems Bonus Position Input.respawnTimeBonus})#true
      else % Nothing to do
	 pacmans({UpdatePlayersPosition Pacmans ID Position})#ghosts(Ghosts)#mode(Mode)#points(Points)#bonus(Bonus)#true
      end
   end
   fun{MoveGhost ID Position WindowPort Pacmans Ghosts Mode Points Bonus}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerWithID ID Ghosts}
   in
      {Send WindowPort moveGhost(ID Position)}
      {SendAll Pacmans ghostPos(ID Position)}
      
      if Mode.1==classic andthen Pacman\=null then % Kill a pacman
	 if {KilledByGhost WindowPort Pacman Ghost Ghosts}==0 then 
	    pacmans({UpdatePlayersRespawn Pacmans Pacman.1 dead})#ghosts({UpdatePlayersPosition Ghosts ID Position})#mode(Mode)#points(Points)#bonus(Bonus)#true
	 else
	    pacmans({UpdatePlayersRespawn Pacmans Pacman.1 Input.respawnTimePacman})#ghosts({UpdatePlayersPosition Ghosts ID Position})#mode(Mode)#points(Points)#bonus(Bonus)#true
	 end
      elseif Mode.1==hunt andthen Pacman\=null then % Killed by a pacman
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans(Pacmans)#ghosts({UpdatePlayersRespawn Ghosts ID Input.respawnTimeGhost})#mode(Mode)#points(Points)#bonus(Bonus)#false
      else % Nothing to do
	 pacmans(Pacmans)#ghosts({UpdatePlayersPosition Ghosts ID Position})#mode(Mode)#points(Points)#bonus(Bonus)#true
      end
   end
   fun{SpawnBonus Position WindowPort Pacmans Ghosts Mode Bonus}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerAtPosition Position Ghosts} % Display ghost on same position on top of bonus
   in
      if Pacman\=null then % Collect a bonus
	 {CollectBonus WindowPort Position Pacmans Ghosts}
	 mode(hunt#Input.huntTime)#bonus(Bonus)
      else % Spawn a bonus
	 {Send WindowPort spawnBonus(Position)}
	 {SendAll Pacmans bonusSpawn(Position)}
	 if Ghost\=null then {Send WindowPort moveGhost(Ghost.1 Ghost.3)} end
	 mode(Mode)#bonus({UpdateItems Bonus Position alive})
      end
   end
   fun{SpawnPoint Position WindowPort Pacmans Ghosts Points}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerAtPosition Position Ghosts}
   in
      if Pacman\=null then % Collect a Point
	 {CollectPoint WindowPort Position Pacman Pacmans}
	 points(Points)
      else % Spawn a Point
	 {Send WindowPort spawnPoint(Position)}
	 {SendAll Pacmans pointSpawn(Position)}
	 if Ghost\=null then {Send WindowPort moveGhost(Ghost.1 Ghost.3)} end % Reprint Ghost above the new point
	 points({UpdateItems Points Position alive})
      end    
   end

   fun{KilledByGhost WindowPort Pacman Ghost Ghosts}
      NewLife NewScore in
      {Send Pacman.2 gotKilled(_ NewLife NewScore)} {Wait NewLife} {Wait NewScore}
      {Send Ghost.2 killPacman(Pacman.1)}
      {Send WindowPort hidePacman(Pacman.1)}
      {Send WindowPort lifeUpdate(Pacman.1 NewLife)}
      {Send WindowPort scoreUpdate(Pacman.1 NewScore)}
      {SendAll Ghosts deathPacman(Pacman.1)}
      NewLife
   end
   proc{KillGhost WindowPort Pacman Ghost Pacmans}
      NewScore in
      {Send Ghost.2 gotKilled()}
      {Send Pacman.2 killGhost(Ghost.1 _ NewScore)} {Wait NewScore}
      {Send WindowPort hideGhost(Ghost.1)}
      {Send WindowPort scoreUpdate(Pacman.1 NewScore)}
      {SendAll Pacmans deathGhost(Ghost.1)}
   end
   proc{CollectPoint WindowPort Position Pacman Pacmans}
      NewScore in
      {Send Pacman.2 addPoint(Input.rewardPoint _ NewScore)} {Wait NewScore}
      {Send WindowPort scoreUpdate(Pacman.1 NewScore)}
      {Send WindowPort hidePoint(Position)}
      {SendAll Pacmans pointRemoved(Position)}
   end
   proc{CollectBonus WindowPort Position Pacmans Ghosts}
      {Send WindowPort hideBonus(Position)}
      {Send WindowPort setMode(hunt)}
      {SendAll Pacmans bonusRemoved(Position)}
      {SendAll Pacmans setMode(hunt)}
      {SendAll Ghosts setMode(hunt)}
   end

   fun{OneTurnElapsedPlayers WindowPort Players Pacmans Ghosts Mode Type}
      case Players
      of nil then pacmans(Pacmans)#ghosts(Ghosts)
      [] H|T andthen {Or H.4==alive H.4==dead} then {OneTurnElapsedPlayers WindowPort T Pacmans Ghosts Mode Type}
      [] H|T andthen H.4\=0 andthen Type==pacman then {OneTurnElapsedPlayers WindowPort T {UpdatePlayersRespawn Pacmans H.1 H.4-1} Ghosts Mode Type}
      [] H|T andthen H.4\=0 andthen Type==ghost then {OneTurnElapsedPlayers WindowPort T Pacmans {UpdatePlayersRespawn Ghosts H.1 H.4-1} Mode Type}
      [] H|T andthen Type==pacman then
	 pacmans(NewPacmans)#ghosts(NewGhosts)#_={SpawnPacman H.1 H.3 WindowPort Pacmans Ghosts Mode}
      in
	 {OneTurnElapsedPlayers WindowPort T NewPacmans NewGhosts Mode Type}
      [] H|T andthen Type==ghost then
	 pacmans(NewPacmans)#ghosts(NewGhosts)#_={SpawnGhost H.1 H.3 WindowPort Pacmans Ghosts Mode}
      in
	 {OneTurnElapsedPlayers WindowPort T NewPacmans NewGhosts Mode Type}
      end
   end
   fun{OneTurnElapsedItems WindowPort Items Pacmans Ghosts Mode Points Bonus Type}
      case Items
      of nil then mode(Mode)#bonus(Bonus)#points(Points)
      [] H|T andthen {Or H.2==alive H.2==enable} then {OneTurnElapsedItems WindowPort T Pacmans Ghosts Mode Points Bonus Type}
      [] H|T andthen H.2\=0 andthen Type==bonus then {OneTurnElapsedItems WindowPort T Pacmans Ghosts Mode Points {UpdateItems Bonus H.1  H.2-1} Type}
      [] H|T andthen H.2\=0 andthen Type==point then {OneTurnElapsedItems WindowPort T Pacmans Ghosts Mode {UpdateItems Points H.1 H.2-1} Bonus Type}
      [] H|T andthen Type==point then
	 points(NewPoints)={SpawnPoint H.1 WindowPort Pacmans Ghosts Points}
      in
	 {OneTurnElapsedItems WindowPort T Pacmans Ghosts Mode NewPoints Bonus Type}
      [] H|T andthen Type==bonus then
	 mode(NewMode)#bonus(NewBonus)={SpawnBonus H.1 WindowPort Pacmans Ghosts Mode Items}
      in
	 {OneTurnElapsedItems WindowPort T Pacmans Ghosts NewMode Points NewBonus Type}
      end
   end
   fun{OneTurnElapsedMode WindowPort Mode Pacmans Ghosts}
      if Mode.2==alive then Mode
      elseif Mode.2\=0 then Mode.1#Mode.2-1
      else
	 {Send WindowPort setMode(classic)}
	 {SendAll Pacmans setMode(classic)}
	 {SendAll Ghosts setMode(classic)}
	 classic#alive
      end
   end

   fun{PlayerAtPosition Position Players}
      case Players
      of nil then null
      [] H|_ andthen H.3==Position andthen H.4==alive then H
      else {PlayerAtPosition Position Players.2}
      end
   end
   fun{ItemAtPosition Position Items}
      case Items
      of nil then null
      [] H|_ andthen H.1==Position andthen {Or H.2==alive H.2==enable} then H
      else {ItemAtPosition Position Items.2}
      end
   end
   fun{PlayerWithID ID Players}
      case Players
      of nil then null
      [] H|_ andthen H.1==ID then H
      else {PlayerWithID ID Players.2}
      end
   end
   fun{UpdatePlayersPosition Players ID Position}
      case Players
      of nil then nil
      [] H|T andthen H.1==ID then ID#H.2#Position#alive|T
      else Players.1|{UpdatePlayersPosition Players.2 ID Position}
      end
   end
   fun{UpdatePlayersRespawn Players ID TurnToRespawn}
      case Players
      of nil then nil
      [] H|T andthen H.1==ID then ID#H.2#H.3#TurnToRespawn|T
      else Players.1|{UpdatePlayersRespawn Players.2 ID TurnToRespawn}
      end
   end
   fun{UpdateItems Items Position TurnToRespawn}
      case Items
      of nil then nil
      [] H|T andthen H.1==Position then Position#TurnToRespawn|T
      else Items.1|{UpdateItems Items.2 Position TurnToRespawn}
      end
   end
   proc{SendAll Players Msg}
      case Players
      of nil then skip
      [] H|T then {Send H.2 Msg} {SendAll T Msg}
      end
   end

   
   fun{GetType Port}
      ID in
      {Send Port getId(ID)} {Wait ID}
      {Record.label ID}
   end
   fun{CreatePlayersState PlayersOrder}
      case PlayersOrder
      of nil then nil
      [] H|T andthen {GetType H.2}==pacman then true#Input.nbLives|{CreatePlayersState T}
      else true|{CreatePlayersState PlayersOrder.2}
      end
   end
   fun{PlayOneTurn MapPort PlayersOrder PlayersState}
      case PlayersOrder#PlayersState
      of nil#nil then Finished in {Send MapPort roundFinished(Finished)} {Wait Finished} nil
      [] (H1|T1)#((IsAlive#LivesLeft)|T2) then
	 {PacmanPlayer MapPort H1.2 IsAlive LivesLeft}|{PlayOneTurn MapPort T1 T2} 
      [] (H|T1)#(IsAlive|T2) then
	 {GhostPlayer MapPort H.2 IsAlive}|{PlayOneTurn MapPort T1 T2}  
      end
   end
   
   proc{TurnByTurn WindowPort Pacmans Ghosts Points Bonus}
      fun{CreateMapPort}
	 local Stream MapPort={NewPort Stream} in
	    thread {TreatStream Stream WindowPort Pacmans Ghosts classic#alive Points Bonus} end
	    MapPort
	 end
      end
      fun{BestPacman Pacmans Best}
	 case Pacmans
	 of nil then Best
	 [] H|T andthen Best==null then {BestPacman T H}
	 [] H|T andthen {GetScore H}>{GetScore Best} then {BestPacman T H}
	 else {BestPacman Pacmans.2 Best}
	 end
      end
      fun{GetScore Pacman}
	 NewScore in
	 {Send Pacman.2 addPoint(0 _ NewScore)} {Wait NewScore}
	 NewScore
      end
      fun{CountPacmanDead PlayersState Count}
	 case PlayersState
	 of nil then Count
	 [] (_#LivesLeft)|T andthen LivesLeft==0 then {CountPacmanDead T Count+1}
	 else {CountPacmanDead PlayersState.2 Count}
	 end
      end
      proc{Local PlayersState}
	 if {CountPacmanDead PlayersState 0}==Input.nbPacman then skip
	 else
	    {Delay Input.thinkMin} % Slow down the process
	    {Local {PlayOneTurn MapPort PlayersOrder PlayersState}}
	 end
      end
      MapPort={CreateMapPort}
      PlayersOrder={RandomMerge Pacmans Ghosts}
   in
      {Local {CreatePlayersState PlayersOrder}}
      
      Winner={BestPacman Pacmans null}
   end
end