functor
import
   Input
   OS System
export
   portPlayer:StartPlayer
define
   MemberWithID
   UpdateWithID
   RemoveWithID

   GetNewPosition
   WallAtPosition
   AvailableDirections
   
   StartPlayer
   TreatStream
   Move
in
   fun{StartPlayer ID}
      Stream Port={NewPort Stream}
   in
      thread {TreatStream Stream ID null null false nil classic} end
      Port
   end


   fun{MemberWithID SearchedID Pacmans}
      case Pacmans
      of nil then false
      [] (ID#_)|_ andthen ID==SearchedID then true
      else {MemberWithID SearchedID Pacmans.2}
      end
   end
   fun{UpdateWithID SearchedID Pacmans NewPosition}
      case Pacmans
      of nil then nil
      [] (ID#_)|T andthen ID==SearchedID then ID#NewPosition|T
      else Pacmans.1|{UpdateWithID SearchedID Pacmans.2 NewPosition}
      end
   end
   fun{RemoveWithID SearchedID Pacmans}
      case Pacmans
      of nil then nil
      [] (ID#_)|T andthen ID==SearchedID then T
      else Pacmans.1|{RemoveWithID SearchedID Pacmans.2}
      end
   end

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
   
   
   proc{TreatStream Stream MyID MySpawn MyPosition IsAlive Pacmans Mode}
      {System.show 'GhostPlayerTeam65: '#Stream.1}
      case Stream
      of nil then skip
      [] getId(ID)|T then ID=MyID
	 {TreatStream T MyID MySpawn MyPosition IsAlive Pacmans Mode}
      [] assignSpawn(SpawnPosition)|T then
	 {TreatStream T MyID SpawnPosition MyPosition IsAlive Pacmans Mode}
      [] spawn(ID P)|T then ID=MyID P=MySpawn
	 {TreatStream T MyID MySpawn MySpawn true Pacmans Mode}
      [] move(ID P)|T then
	 if IsAlive then NewPosition={Move MyPosition} in
	    if NewPosition==null then ID=MyID P=MyPosition
	       {TreatStream T MyID MySpawn MyPosition IsAlive Pacmans Mode}
	    else
	       ID=MyID P=NewPosition
	       {TreatStream T MyID MySpawn NewPosition IsAlive Pacmans Mode}
	    end
	 else ID=null P=null
	    {TreatStream T MyID MySpawn MyPosition IsAlive Pacmans Mode}
	 end
      [] gotKilled()|T then
	 {TreatStream T MyID MySpawn null false Pacmans Mode}
      [] pacmanPos(ID Position)|T then
	 if {MemberWithID ID Pacmans} then {TreatStream T MyID MySpawn MyPosition IsAlive {UpdateWithID ID Pacmans Position} Mode}
	 else {TreatStream T MyID MySpawn MyPosition IsAlive ID#Position|Pacmans Mode}
	 end
      [] killPacman(ID)|T then
	 if {MemberWithID ID Pacmans} then {TreatStream T MyID MySpawn MyPosition IsAlive {RemoveWithID ID Pacmans} Mode}
	 else {TreatStream T MyID MySpawn MyPosition IsAlive Pacmans Mode}
	 end
      [] deathPacman(ID)|T then
	 if {MemberWithID ID Pacmans} then {TreatStream T MyID MySpawn MyPosition IsAlive {RemoveWithID ID Pacmans} Mode}
	 else {TreatStream T MyID MySpawn MyPosition IsAlive Pacmans Mode}
	 end
      [] setMode(NewMode)|T then
	 {TreatStream T MyID MySpawn MyPosition IsAlive Pacmans NewMode}
      else
	 {System.show 'GhostPlayerTeam65: Incompatible message'#Stream.1}
	 {TreatStream Stream.2 MyID MySpawn MyPosition IsAlive Pacmans Mode}
      end
   end
end