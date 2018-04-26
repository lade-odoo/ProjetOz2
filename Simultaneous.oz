functor
import
   Input
   OS System
export
   simultaneous:Simultaneous
   winner:Winner
define
   PlayerAtPosition ItemAtPosition
   PlayerWithID
   UpdatePlayers UpdateItems
   SendAll
   
   SpawnGhost SpawnPacman
   MoveGhost MovePacman
   KilledByGhost KillGhost
   CollectPoint CollectBonus
   SpawnPoint SpawnBonus
   
   Simultaneous
   TreatStream
   PacmanPlayer GhostPlayer
   Winner
in
   proc{PacmanPlayer MapPort PlayerPort IsAlive LivesLeft}
      if LivesLeft==0 then skip
      else ID P HasSurvived in
	 if IsAlive then
	    {Send PlayerPort move(ID P)} {Wait ID} {Wait P}
	    if {Or ID==null P==null} then {PacmanPlayer MapPort PlayerPort false LivesLeft-1} % Killed
	    else
	       {Delay Input.thinkMin+({OS.rand} mod (Input.thinkMax-Input.thinkMin))}
	       {Send MapPort movePacman(ID P HasSurvived)} {Wait HasSurvived} % Alive
	    end
	 else
	    {Delay Input.respawnTimePacman}
	    {Send PlayerPort spawn(ID P)} {Wait ID} {Wait P}
	    if {Or ID==null P==null} then {PacmanPlayer MapPort PlayerPort false LivesLeft-1} % Killed
	    else {Send MapPort spawnPacman(ID P HasSurvived)} {Wait HasSurvived} % Spawned
	    end
	 end

	 if HasSurvived==null then {PacmanPlayer MapPort PlayerPort false LivesLeft-1}
	 elseif HasSurvived then {PacmanPlayer MapPort PlayerPort true LivesLeft}
	 else {PacmanPlayer MapPort PlayerPort false LivesLeft-1}
	 end
      end
   end
   proc{GhostPlayer MapPort PlayerPort IsAlive KillThread}
      fun{IsThreadKilled Timeout}
	 X in
	 thread {Delay Timeout} X=unit end
	 if {Record.waitOr KillThread#X}==1 then true
	 else false
	 end
      end
      proc{Local IsAlive}
	 if {IsThreadKilled 10} then skip % Stop this ghost
	 else ID P HasSurvived in
	    if IsAlive then
	       {Send PlayerPort move(ID P)} {Wait ID} {Wait P}
	       if {Or ID==null P==null} then {Local false} % Killed
	       else {Delay Input.thinkMin+({OS.rand} mod (Input.thinkMax-Input.thinkMin))} {Send MapPort moveGhost(ID P HasSurvived)} {Wait HasSurvived} % Alive
	       end
	    else
	       {Delay Input.respawnTimeGhost}
	       {Send PlayerPort spawn(ID P)} {Wait ID} {Wait P}
	       if {Or ID==null P==null} then {Local false} % Failed to spawn
	       else {Send MapPort spawnGhost(ID P HasSurvived)} {Wait HasSurvived} % Spawned
	       end
	    end

	    if HasSurvived==null then {Local false}
	    else {Local HasSurvived}
	    end
	 end
      end
   in
      {Local IsAlive}
   end
     
   proc{TreatStream Stream MapPort WindowPort Pacmans Ghosts Mode Points Bonus}
      {System.show 'MapServer: '#Stream.1}
      case Stream
      of nil then skip
      [] spawnPacman(ID P HasSurvived)|T then
	 RT={SpawnPacman ID P WindowPort Pacmans Ghosts Mode} in
	 case RT
	 of pacmans(NewPacmans)#ghosts(NewGhosts)#HasSurvivedRT then
	    HasSurvived=HasSurvivedRT
	    {TreatStream T MapPort WindowPort NewPacmans NewGhosts Mode Points Bonus}
	 end
      [] spawnGhost(ID P HasSurvived)|T then
	 RT={SpawnGhost ID P WindowPort Pacmans Ghosts Mode} in
	 case RT
	 of pacmans(NewPacmans)#ghosts(NewGhosts)#HasSurvivedRT then
	    HasSurvived=HasSurvivedRT
	    {TreatStream T MapPort WindowPort NewPacmans NewGhosts Mode Points Bonus}
	 end
      [] movePacman(ID P HasSurvived)|T then
	 if {PlayerWithID ID Pacmans}.3==null then % Invalid move need to respawn if actual pos==null
	    {System.show invalidPacmanMoveCatched(ID)}
	    HasSurvived=null
	    {TreatStream T MapPort WindowPort Pacmans Ghosts Mode Points Bonus}
	 else
	    RT={MovePacman ID P MapPort WindowPort Pacmans Ghosts Mode Points Bonus} in
	    case RT
	    of pacmans(NewPacmans)#ghosts(NewGhosts)#mode(NewMode)#points(NewPoints)#bonus(NewBonus)#HasSurvivedRT then
	       HasSurvived=HasSurvivedRT
	       {TreatStream T MapPort WindowPort NewPacmans NewGhosts NewMode NewPoints NewBonus}
	    end
	 end
      [] moveGhost(ID P HasSurvived)|T then
	 if {PlayerWithID ID Ghosts}.3==null then % Invalid move need to respawn if actual pos==null
	    {System.show invalidGhostMoveCatched(ID)}
	    HasSurvived=null
	    {TreatStream T MapPort WindowPort Pacmans Ghosts Mode Points Bonus}
	 else
	    RT={MoveGhost ID P MapPort WindowPort Pacmans Ghosts Mode Points Bonus} in
	    case RT
	    of pacmans(NewPacmans)#ghosts(NewGhosts)#mode(NewMode)#points(NewPoints)#bonus(NewBonus)#HasSurvivedRT then
	       HasSurvived=HasSurvivedRT
	       {TreatStream T MapPort WindowPort NewPacmans NewGhosts NewMode NewPoints NewBonus}
	    end
	 end
      [] spawnBonus(P)|T then
	 RT={SpawnBonus P MapPort WindowPort Pacmans Ghosts Mode Bonus} in
	 case RT
	 of mode(NewMode)#bonus(NewBonus) then
	    {TreatStream T MapPort WindowPort Pacmans Ghosts NewMode Points NewBonus}
	 end
      [] spawnPoint(P)|T then
	 RT={SpawnPoint P MapPort WindowPort Pacmans Ghosts Points} in
	 case RT
	 of points(NewPoints) then
	    {TreatStream T MapPort WindowPort Pacmans Ghosts Mode NewPoints Bonus}
	 end
      [] setMode(M)|T then
	 {Send WindowPort setMode(M)}
	 {SendAll Pacmans setMode(M)}
	 {SendAll Ghosts setMode(M)}
	 {TreatStream T MapPort WindowPort Pacmans Ghosts M Points Bonus}
      else
	 {System.show 'MapServer: Incompatible message: '#Stream.1}
      end
   end
   fun{SpawnPacman ID Position WindowPort Pacmans Ghosts Mode}
      Ghost={PlayerAtPosition Position Ghosts}
      Pacman={PlayerWithID ID Pacmans}
   in
      if Mode==classic andthen Ghost\=null then % Killed by ghost
	 {KilledByGhost WindowPort Pacman Ghost Ghosts}
	 pacmans({UpdatePlayers Pacmans ID null})#ghosts(Ghosts)#false
      elseif Mode==hunt andthen Ghost\=null then % Kill a ghost
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans({UpdatePlayers Pacmans ID Position})#ghosts({UpdatePlayers Ghosts Ghost.1 null})#true
      else % Spawn
	 {Send WindowPort spawnPacman(ID Position)}
	 {SendAll Ghosts ghostPos(ID Position)}
	 pacmans({UpdatePlayers Pacmans ID Position})#ghosts(Ghosts)#true
      end
   end
   fun{SpawnGhost ID Position WindowPort Pacmans Ghosts Mode}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerWithID ID Ghosts}
   in
      if Mode==classic andthen Pacman\=null then % Kill a pacman
	 {KilledByGhost WindowPort Pacman Ghost Ghosts}
	 pacmans({UpdatePlayers Pacmans Pacman.1 null})#ghosts({UpdatePlayers Ghosts ID Position})#true
      elseif Mode==hunt andthen Pacman\=null then % Killed by a pacman
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans(Pacmans)#ghosts({UpdatePlayers Ghosts ID null})#false
      else % Spawn
	 {Send WindowPort spawnGhost(ID Position)}
	 {SendAll Pacmans ghostPos(ID Position)}
	 pacmans(Pacmans)#ghosts({UpdatePlayers Ghosts ID Position})#true
      end
   end
   fun{MovePacman ID Position MapPort WindowPort Pacmans Ghosts Mode Points Bonus}
      Ghost={PlayerAtPosition Position Ghosts}
      Pacman={PlayerWithID ID Pacmans}
      ItemPoints={ItemAtPosition Position Points}
      ItemBonus={ItemAtPosition Position Bonus}
   in
      {Send WindowPort movePacman(ID Position)}
      {SendAll Ghosts pacmanPos(ID Position)}
      
      if Mode==classic andthen Ghost\=null then % Kill by a ghost
	 {KilledByGhost WindowPort Pacman Ghost Ghosts}
	 pacmans({UpdatePlayers Pacmans ID null})#ghosts(Ghosts)#mode(Mode)#points(Points)#bonus(Bonus)#false
      elseif Mode==hunt andthen Ghost\=null then % Kill a ghost
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans({UpdatePlayers Pacmans ID Position})#ghosts({UpdatePlayers Ghosts Ghost.1 null})#mode(Mode)#points(Points)#bonus(Bonus)#true
      elseif ItemPoints\=null then % Collect a point
	 {CollectPoint MapPort WindowPort Position Pacman Pacmans}
	 pacmans({UpdatePlayers Pacmans ID Position})#ghosts(Ghosts)#mode(Mode)#points({UpdateItems Points Position disable})#bonus(Bonus)#true
      elseif ItemBonus\=null then % Collect a bonus
	 {CollectBonus MapPort WindowPort Position Pacmans Ghosts}
	 pacmans({UpdatePlayers Pacmans ID Position})#ghosts(Ghosts)#mode(hunt)#points(Points)#bonus({UpdateItems Bonus Position disable})#true
      else % Nothing to do
	 pacmans({UpdatePlayers Pacmans ID Position})#ghosts(Ghosts)#mode(Mode)#points(Points)#bonus(Bonus)#true
      end
   end
   fun{MoveGhost ID Position MapPort WindowPort Pacmans Ghosts Mode Points Bonus}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerWithID ID Ghosts}
   in
      {Send WindowPort moveGhost(ID Position)}
      {SendAll Pacmans ghostPos(ID Position)}
      
      if Mode==classic andthen Pacman\=null then % Kill a pacman
	 {KilledByGhost WindowPort Pacman Ghost Ghosts}
	 pacmans({UpdatePlayers Pacmans Pacman.1 null})#ghosts({UpdatePlayers Ghosts ID Position})#mode(Mode)#points(Points)#bonus(Bonus)#true
      elseif Mode==hunt andthen Pacman\=null then % Killed by a pacman
	 {KillGhost WindowPort Pacman Ghost Pacmans}
	 pacmans(Pacmans)#ghosts({UpdatePlayers Ghosts ID null})#mode(Mode)#points(Points)#bonus(Bonus)#false
      else % Nothing to do
	 pacmans(Pacmans)#ghosts({UpdatePlayers Ghosts ID Position})#mode(Mode)#points(Points)#bonus(Bonus)#true
      end
   end
   fun{SpawnBonus Position MapPort WindowPort Pacmans Ghosts Mode Bonus}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerAtPosition Position Ghosts} % Display ghost on same position on top of bonus
   in
      if Pacman\=null then % Collect a bonus
	 {CollectBonus MapPort WindowPort Position Pacmans Ghosts}
	 mode(hunt)#bonus(Bonus)
      else % Spawn a bonus
	 {Send WindowPort spawnBonus(Position)}
	 {SendAll Pacmans bonusSpawn(Position)}
	 if Ghost\=null then {Send WindowPort moveGhost(Ghost.1 Ghost.3)} end
	 mode(Mode)#bonus({UpdateItems Bonus Position enable})
      end
   end
   fun{SpawnPoint Position MapPort WindowPort Pacmans Ghosts Points}
      Pacman={PlayerAtPosition Position Pacmans}
      Ghost={PlayerAtPosition Position Ghosts}
   in
      if Pacman\=null then % Collect a Point
	 {CollectPoint MapPort WindowPort Position Pacman Pacmans}
	 points(Points)
      else % Spawn a Point
	 {Send WindowPort spawnPoint(Position)}
	 {SendAll Pacmans pointSpawn(Position)}
	 if Ghost\=null then {Send WindowPort moveGhost(Ghost.1 Ghost.3)} end % Reprint Ghost above the new point
	 points({UpdateItems Points Position enable})
      end    
   end

   proc{KilledByGhost WindowPort Pacman Ghost Ghosts}
      NewLife NewScore in
      {Send Pacman.2 gotKilled(_ NewLife NewScore)} {Wait NewLife} {Wait NewScore}
      {Send Ghost.2 killPacman(Pacman.1)}
      {Send WindowPort hidePacman(Pacman.1)}
      {Send WindowPort lifeUpdate(Pacman.1 NewLife)}
      {Send WindowPort scoreUpdate(Pacman.1 NewScore)}
      {SendAll Ghosts deathPacman(Pacman.1)}
   end
   proc{KillGhost WindowPort Pacman Ghost Pacmans}
      NewScore in
      {Send Ghost.2 gotKilled()}
      {Send Pacman.2 killGhost(Ghost.1 _ NewScore)} {Wait NewScore}
      {Send WindowPort hideGhost(Ghost.1)}
      {Send WindowPort scoreUpdate(Pacman.1 NewScore)}
      {SendAll Pacmans deathGhost(Ghost.1)}
   end
   proc{CollectPoint MapPort WindowPort Position Pacman Pacmans}
      NewScore in
      {Send Pacman.2 addPoint(Input.rewardPoint _ NewScore)} {Wait NewScore}
      {Send WindowPort scoreUpdate(Pacman.1 NewScore)}
      {Send WindowPort hidePoint(Position)}
      {SendAll Pacmans pointRemoved(Position)}
      thread {Delay Input.respawnTimePoint} {Send MapPort spawnPoint(Position)} end
   end
   proc{CollectBonus MapPort WindowPort Position Pacmans Ghosts}
      {Send WindowPort hideBonus(Position)}
      {Send WindowPort setMode(hunt)}
      {SendAll Pacmans bonusRemoved(Position)}
      {SendAll Pacmans setMode(hunt)}
      {SendAll Ghosts setMode(hunt)}
      thread {Delay Input.huntTime} {Send MapPort setMode(classic)} end
      thread {Delay Input.respawnTimeBonus} {Send MapPort spawnBonus(Position)} end
   end

   fun{PlayerAtPosition Position Players}
      case Players
      of nil then null
      [] H|_ andthen H.3==Position then H
      else {PlayerAtPosition Position Players.2}
      end
   end
   fun{ItemAtPosition Position Items}
      case Items
      of nil then null
      [] H|_ andthen H.1==Position andthen H.2==enable then H
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
   fun{UpdatePlayers Players ID Position}
      case Players
      of nil then nil
      [] H|T andthen H.1==ID then ID#H.2#Position|T
      else Players.1|{UpdatePlayers Players.2 ID Position}
      end
   end
   fun{UpdateItems Items Position State}
      case Items
      of nil then nil
      [] H|T andthen H.1==Position then Position#State|T
      else Items.1|{UpdateItems Items.2 Position State}
      end
   end
   proc{SendAll Players Msg}
      case Players
      of nil then skip
      [] H|T then {Send H.2 Msg} {SendAll T Msg}
      end
   end

   
   proc{Simultaneous WindowPort Pacmans Ghosts Points Bonus}
      fun{CreateMapPort}
	 local Stream MapPort={NewPort Stream} in
	    thread {TreatStream Stream MapPort WindowPort Pacmans Ghosts classic Points Bonus} end
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
      MapPort={CreateMapPort}
      StatesAgents={Record.make statesAgents {List.number 1 Input.nbPacman 1}}
      KillThread
   in
      for I in 1..Input.nbPacman do
	 thread {PacmanPlayer MapPort {Nth Pacmans I}.2 true Input.nbLives} StatesAgents.I=unit end
      end
      for I in 1..Input.nbGhost do
	 thread {GhostPlayer MapPort {Nth Ghosts I}.2 true KillThread} end
      end

      % Wait end of all pacmans then kill ghosts agents
      for I in 1..Input.nbPacman do
	 {Wait StatesAgents.I}
      end
      KillThread=unit

      Winner={BestPacman Pacmans null}
   end
end