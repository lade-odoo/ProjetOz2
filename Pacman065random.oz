functor
import
   Input
   OS
   System
export
  portPlayer:StartPlayer
define   
   StartPlayer
   TreatStream

   GetNewPosition
   WallAtPosition
   AvailableDirections
   Move
   
   FindGhostList
   RemoveList
   
in
   % ID is a <pacman> ID
   fun{StartPlayer ID}
      Stream Port Spawn Position
   in
      {NewPort Stream Port}
      thread
	 {System.show ID}
	 {TreatStream Stream ID Spawn Position false Input.nbLives 0 nil nil nil classic}
      end
      Port 
   end

%%%%%%%%%%%%% functions used in the treatStream function %%%%%%%%%%%%%%%%

 fun{Move Position}
      Directions={AvailableDirections Position Input.map [north sud east west]}
   in
      if Directions==nil then null
      else {GetNewPosition Position {Nth Directions ({OS.rand} mod {Length Directions})+1}}
      end
   end
   fun{AvailableDirections Position Grid Directions}
      case Directions
      of nil then nil
      [] H|T then NewPosition={GetNewPosition Position H} in
	 if {WallAtPosition NewPosition.x NewPosition.y Grid} then {AvailableDirections Position Grid T}
	 else H|{AvailableDirections Position Grid T}
	 end
      end
   end
   fun{WallAtPosition ColumnPos RowPos Grid}
      {System.show wallAtPosition(ColumnPos RowPos)}
      {Nth {Nth Grid RowPos} ColumnPos}==1
   end
   fun{GetNewPosition Position Direction}
      case Direction
      of north andthen Position.y==1 then pt(x:Position.x y:Input.nRow)
      [] north then pt(x:Position.x y:Position.y-1)
      [] sud then pt(x:Position.x y:((Position.y+1) mod (Input.nRow+1))+(Position.y div Input.nRow))
      [] east then pt(x:((Position.x+1) mod (Input.nColumn+1))+(Position.x div Input.nColumn) y:Position.y) 
      [] west andthen Position.x==1 then pt(x:Input.nColumn y:Position.y)
      [] west then pt(x:Position.x-1 y:Position.y)
      end
   end
   fun{FindGhostList List ID}
      case List
      of nil then nil
      []H|T then
	 if ID==H.id then H
	 else {FindGhostList T ID} end
      end
   end
   fun{RemoveList List P}
      case List
      of nil then nil
      []H|T then
	 if H==P then {RemoveList T P}
	 else H|{RemoveList T P} end
      end
   end

%%%%%%%%%%%%% TreatStream function %%%%%%%%%%%%%%%%
   proc{TreatStream Stream Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
      {System.show 'PacmanPlayerTeam65: '#Stream.1}
      case Stream
      of nil then skip
      []getId(ID)|T then ID = Pacman
	 {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
      []assignSpawn(P)|T then
	 {TreatStream T Pacman P Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
      []spawn(ID P)|T then ID = Pacman P = Spawn
	 {TreatStream T Pacman Spawn Spawn true Lives Score BonusSpawn PointSpawn ListGhost Mode}
      []move(ID P)|T then
	 if Lives>=1 then NewP = {Move Position} in
	    if NewP==null then
	       ID = Pacman P = Position
	       {TreatStream T Pacman Spawn NewP OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
	    else
	       ID = Pacman P = NewP
	       {TreatStream T Pacman Spawn NewP OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
	    end
	 else
	    ID = null P = null
	    {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
	 end
      []bonusSpawn(P)|T then L = P|BonusSpawn in
	 {TreatStream T Pacman Spawn Position OnBoard Lives Score L PointSpawn ListGhost Mode}
      []pointSpawn(P)|T then L = P|PointSpawn in
	 {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn L ListGhost Mode}
      []bonusRemoved(P)|T then NewList = {RemoveList BonusSpawn P} in
	 {TreatStream T Pacman Spawn Position OnBoard Lives Score NewList PointSpawn ListGhost Mode}
      []pointRemoved(P)|T then NewList = {RemoveList PointSpawn P} in
	 {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn NewList ListGhost Mode}
      []addPoint(Add ?ID ?NewScore)|T then
	 ID = Pacman NewScore = Score + Add
	 {TreatStream T Pacman Spawn Position OnBoard Lives NewScore BonusSpawn PointSpawn ListGhost Mode}
      []gotKilled(?ID ?NewLife ?NewScore)|T then
	 ID = Pacman NewLife = Lives-1 NewScore = Score-Input.penalityKill
	 {TreatStream T Pacman Spawn Position false NewLife Score-5 BonusSpawn PointSpawn ListGhost Mode}
      []ghostPos(ID P)|T then G in
	 G = ghost(id:ID position:P kill:_ death:_)
	 {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn G|ListGhost Mode}
      []killGhost(IDg ?IDp ?NewScore)|T then Ghost = {FindGhostList ListGhost IDg} in
	 if Ghost == nil then
	    {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
	 else
	    IDp = Pacman Ghost.kill = true NewScore = Score+Input.rewardKill
	    {TreatStream T Pacman Spawn Position OnBoard Lives NewScore BonusSpawn PointSpawn ListGhost Mode}
	 end
      []deathGhost(ID)|T then Ghost = {FindGhostList ListGhost ID} in
	 if Ghost == nil then
	    {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
	 else
 	    Ghost.death = true
	    {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
	 end
      []setMode(M)|T then
	 {TreatStream T Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost M}
      else
	 {System.show 'PacmanPlayerTeam65: Incompatible message'#Stream.1}
	 {TreatStream Stream.2 Pacman Spawn Position OnBoard Lives Score BonusSpawn PointSpawn ListGhost Mode}
      end
   end

end
