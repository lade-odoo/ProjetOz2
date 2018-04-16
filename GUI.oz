functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   Input
   Browser
export
   portWindow:StartWindow
define
   
   StartWindow
   TreatStream

   InitPacman
   InitGhost
   InitBonus
   InitPoint

   SpawnPacman
   SpawnGhost
   SpawnBonus
   SpawnPoint
   
   MovePacman
   MoveGhost

   HidePacman
   HideGhost
   HideBonus
   HidePoint
   
   UpdateScore
   UpdateLife
   
   ChangeMode

   BuildWindow
   
   Squares
   DrawMap

   StateModification

in

%%%%% Build the initial window and set it up (call only once)
   fun{BuildWindow}
      Grid GridLife GridScore Toolbar Desc DescLife DescScore Window
   in
      Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close))
      Desc=grid(handle:Grid height:50*Input.nRow width:50*Input.nColumn)
      DescLife=grid(handle:GridLife height:100 width:50*Input.nbPacman)
      DescScore=grid(handle:GridScore height:100 width:50*Input.nbPacman)
      Window={QTk.build td(Toolbar Desc DescLife DescScore)}
  
      {Window show}

      % configure rows and set headers
      for N in 1..Input.nRow do
	 {Grid rowconfigure(N minsize:50 weight:0 pad:5)}
      end
      % configure columns and set headers
      for N in 1..Input.nColumn do
	 {Grid columnconfigure(N minsize:50 weight:0 pad:5)}
      end
      % configure lifeboard
      {GridLife rowconfigure(1 minsize:50 weight:0 pad:5)}
      {GridLife columnconfigure(1 minsize:50 weight:0 pad:5)}
      {GridLife configure(label(text:"life" width:1 height:1) row:1 column:1 sticky:wesn)}
      for N in 1..(Input.nbPacman) do
	 {GridLife columnconfigure(N+1 minsize:50 weight:0 pad:5)}
      end
      % configure scoreboard
      {GridScore rowconfigure(1 minsize:50 weight:0 pad:5)}
      {GridScore columnconfigure(1 minsize:50 weight:0 pad:5)}
      {GridScore configure(label(text:"score" width:1 height:1) row:1 column:1 sticky:wesn)}
      for N in 1..(Input.nbPacman) do
	 {GridScore columnconfigure(N+1 minsize:50 weight:0 pad:5)}
      end
      
      {DrawMap Grid}
      
      handle(grid:Grid life:GridLife score:GridScore)
   end

   
%%%%% Squares of path and wall
   Squares = square(0:label(text:"" width:1 height:1 bg:c(0 0 204))
		    1:label(text:"" borderwidth:5 relief:raised width:1 height:1 bg:c(0 0 0))
		    2:label(text:"" width:1 height:1 bg:c(0 0 150))
		    3:label(text:"" width:1 height:1 bg:c(0 0 255))
		    4:label(text:"" width:1 height:1 bg:c(0 150 150))
		   )
   
%%%%% Function to draw the map
   proc{DrawMap Grid}
      proc{DrawColumn Column M N}
	 case Column
	 of nil then skip
	 [] T|End then
	    {Grid configure(Squares.T row:M column:N sticky:wesn)}
	    {DrawColumn End M N+1}
	 end
      end
      proc{DrawRow Row M}
	 case Row
	 of nil then skip
	 [] T|End then
	    {DrawColumn T M 1}
	    {DrawRow End M+1}
	 end
      end
   in
      {DrawRow Input.map 1}
   end

%%%%% Init the pacman & ghost
   fun{InitPacman Grid ID}
      Handle HandleLife HandleScore Id Color LabelPacman LabelLife LabelScore
   in
      pacman(id:Id color:Color name:_) = ID
      LabelPacman = label(text:"P" handle:Handle borderwidth:5 relief:raised bg:Color ipadx:5 ipady:5)
      LabelLife = label(text:Input.nbLives borderwidth:5 handle:HandleLife relief:solid bg:Color ipadx:5 ipady:5)
      LabelScore = label(text:0 borderwidth:5 handle:HandleScore relief:solid bg:Color ipadx:5 ipady:5)
      {Grid.grid configure(LabelPacman row:0 column:0 sticky:wesn)}
      {Grid.grid remove(Handle)}
      {Grid.life configure(LabelLife row:1 column:Id+1 sticky:wesn)}
      {Grid.score configure(LabelScore row:1 column:Id+1 sticky:wesn)}
      {HandleLife 'raise'()}
      {HandleScore 'raise'()}
      guiPacman(id:ID life:HandleLife score:HandleScore pacman:Handle)
   end

   
   fun{SpawnPacman Position}
      fun{$ Grid State}
	 {Grid.grid configure(State.pacman row:Position.y column:Position.x sticky:wesn)}
	 {State.pacman 'raise'()}
	 State
      end
   end
   fun{MovePacman Position}
      fun{$ Grid State}
	 {{SpawnPacman Position} Grid {{HidePacman} Grid State}}
      end
   end
   fun{HidePacman}
      fun{$ Grid State}
	 {Grid.grid remove(State.pacman)}
	 State
      end
   end
   
   fun{InitGhost Grid ID}
      Handle Color LabelGhost
   in
      ghost(id:_ color:Color name:_) = ID
      LabelGhost = label(text:"G" handle:Handle borderwidth:5 relief:raised bg:Color ipadx:5 ipady:5)
      {Grid.grid configure(LabelGhost row:0 column:0 sticky:wesn)}
      {Grid.grid remove(Handle)}
      guiGhost(id:ID ghost:Handle color:Color)
   end
   
   fun{SpawnGhost Position}
      fun{$ Grid State}
	 {Grid.grid configure(State.ghost row:Position.y column:Position.x sticky:wesn)}
	 {State.ghost 'raise'()}
	 State
      end
   end
   fun{MoveGhost Position}
      fun{$ Grid State}
	 {{SpawnGhost Position} Grid {{HideGhost} Grid State}}
      end
   end
   fun{HideGhost}
      fun{$ Grid State}
	 {Grid.grid remove(State.ghost)}
	 State
      end
   end

   fun{UpdateLife Life}
      fun{$ Grid State}
	 {State.life set(Life)}
	 State
      end
   end
   
   fun{UpdateScore Score}
      fun{$ Grid State}
	 {State.score set(Score)}
	 State
      end
   end

   fun{InitBonus Grid Position}
      Handle Label
   in
      Label = label(text:"" height:1 width:1 handle:Handle bg:red)
      {Grid.grid configure(Label row:0 column:0)}
      {Grid.grid remove(Handle)}
      guiBonus(position:Position bonus:Handle)
   end
   fun{SpawnBonus}
      fun{$ Grid State}
	 {Grid.grid configure(State.bonus row:State.position.y column:State.position.x)}
	 {State.bonus 'raise'()}
	 State
      end
   end
   fun{HideBonus}
      fun{$ Grid State}
	 {Grid.grid remove(State.bonus)}
	 State
      end
   end

   fun{InitPoint Grid Position}
      Handle Label
   in
      Label = label(text:"" height:1 width:1 handle:Handle bg:white)
      {Grid.grid configure(Label row:0 column:0)}
      {Grid.grid remove(Handle)}
      guiPoint(position:Position point:Handle)
   end
   fun{SpawnPoint}
      fun{$ Grid State}
	 {Grid.grid configure(State.point row:State.position.y column:State.position.x)}
	 {State.point 'raise'()}
	 State
      end
   end
   fun{HidePoint}
      fun{$ Grid State}
	 {Grid.grid remove(State.point)}
	 State
      end
   end

   fun{ChangeMode M State}
      case State
      of nil then nil
      [] guiGhost(id:_ ghost:Handle color:Color)|Next then
	 case M
	 of classic then
	    {Handle set(bg:Color)}
	 [] hunt then
	    {Handle set(bg:blue)}
	 end
	 State.1|{ChangeMode M Next}
      end
   end      
   
   fun{StateModification Grid Wanted State Fun}
      case State
      of nil then nil
      [] guiPacman(id:ID life:_ score:_ pacman:_)|Next then
	 if (ID == Wanted) then
	    {Fun Grid State.1}|Next
	 else
	    State.1|{StateModification Grid Wanted Next Fun}
	 end
      [] guiGhost(id:ID ghost:_ color:_)|Next then
	 if (ID == Wanted) then
	    {Fun Grid State.1}|Next
	 else
	    State.1|{StateModification Grid Wanted Next Fun}
	 end
      [] guiBonus(position:Position bonus:_)|Next then
	 if (Position == Wanted) then
	    {Fun Grid State.1}|Next
	 else
	    State.1|{StateModification Grid Wanted Next Fun}
	 end
      [] guiPoint(position:Position point:_)|Next then
	 if (Position == Wanted) then
	    {Fun Grid State.1}|Next
	 else
	    State.1|{StateModification Grid Wanted Next Fun}
	 end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{StartWindow}
      Stream
      Port
   in
      {NewPort Stream Port}
      thread
	 {TreatStream Stream nil nil nil nil nil}
      end
      Port
   end

   proc{TreatStream Stream Grid Pacmans Ghosts Point Bonus}
      {Browser.browse Stream.1}
      case Stream
      of nil then skip
      [] buildWindow|T then NewGrid in 
	 NewGrid = {BuildWindow}
	 {TreatStream T NewGrid Pacmans Ghosts Point Bonus}
      [] initPacman(ID)|T then NewState in
	 NewState = {InitPacman Grid ID}
	 {TreatStream T Grid NewState|Pacmans Ghosts Point Bonus}
      [] spawnPacman(ID Position)|T then
	 {TreatStream T Grid {StateModification Grid ID Pacmans {SpawnPacman Position}} Ghosts Point Bonus}
      [] movePacman(ID Position)|T then
	 {TreatStream T Grid {StateModification Grid ID Pacmans {MovePacman Position}} Ghosts Point Bonus}
      [] hidePacman(ID)|T then
	 {TreatStream T Grid {StateModification Grid ID Pacmans {HidePacman}} Ghosts Point Bonus}
      [] initGhost(ID)|T then NewState in
	 NewState = {InitGhost Grid ID} 
	 {TreatStream T Grid Pacmans NewState|Ghosts Point Bonus}
      [] spawnGhost(ID Position)|T then
	 {TreatStream T Grid Pacmans {StateModification Grid ID Ghosts {SpawnGhost Position}} Point Bonus}
      [] moveGhost(ID Position)|T then
	 {TreatStream T Grid Pacmans {StateModification Grid ID Ghosts {MoveGhost Position}} Point Bonus}
      [] hideGhost(ID)|T then
	 {TreatStream T Grid Pacmans {StateModification Grid ID Ghosts {HideGhost}} Point Bonus}
      [] lifeUpdate(ID Life)|T then
	 {TreatStream T Grid {StateModification Grid ID Pacmans {UpdateLife Life}} Ghosts Point Bonus}
      [] scoreUpdate(ID Score)|T then
	 {TreatStream T Grid {StateModification Grid ID Pacmans {UpdateScore Score}} Ghosts Point Bonus}
      [] initBonus(Position)|T then
	 {TreatStream T Grid Pacmans Ghosts Point {InitBonus Grid Position}|Bonus}
      [] spawnBonus(Position)|T then
	 {TreatStream T Grid Pacmans Ghosts Point {StateModification Grid Position Bonus {SpawnBonus}}}
      [] hideBonus(Position)|T then
	 {TreatStream T Grid Pacmans Ghosts Point {StateModification Grid Position Bonus {HideBonus}}}
      [] initPoint(Position)|T then
	 {TreatStream T Grid Pacmans Ghosts {InitPoint Grid Position}|Point Bonus}
      [] spawnPoint(Position)|T then
	 {TreatStream T Grid Pacmans Ghosts {StateModification Grid Position Point {SpawnPoint}} Bonus}
      [] hidePoint(Position)|T then
	 {TreatStream T Grid Pacmans Ghosts {StateModification Grid Position Point {HidePoint}} Bonus}
      [] setMode(M)|T then
	 {TreatStream T Grid Pacmans {ChangeMode M Ghosts} Point Bonus}
      [] displayWinner(ID)|_ then
	 {Browser.browse 'the winner is '#ID}
      [] M|T then
	 {Browser.browse 'unsupported message'#M}
	 {TreatStream T Grid Pacmans Ghosts Point Bonus}
      end
   end
   
  

   
end
