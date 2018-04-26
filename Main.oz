functor
import
   Initialisation
   Simultaneous
define
   CreateItemsMap
in 
   fun{CreateItemsMap ItemsPositions}
      case ItemsPositions
      of nil then nil
      [] H|T then H#enable|{CreateItemsMap T}
      end
   end
   
   thread
      {Initialisation.initialisation} {Delay 10000}
      local WindowPort=Initialisation.windowPort
	 Pacmans=Initialisation.pacmansMapping
	 Ghosts=Initialisation.ghostsMapping
	 Points={CreateItemsMap Initialisation.pointsSpawns}
	 Bonus={CreateItemsMap Initialisation.bonusSpawns}
      in
	 {Simultaneous.simultaneous WindowPort Pacmans Ghosts Points Bonus}
	 {Send WindowPort displayWinner(Simultaneous.winner.1)}
      end
   end
end