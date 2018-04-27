functor
import
   Pacman000random
   Ghost000random
   Pacman065random
   Ghost065intel
   Pacman018riseleft
   Ghost018hunter
   Pacman092intel
   Ghost092random
   Pacman063other
   Ghost063other
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   % Kind is one valid name to describe the wanted player, ID is either the <pacman> ID, either the <ghost> ID corresponding to the player
   fun{PlayerGenerator Kind ID}
      case Kind
      of pacman000random then {Pacman000random.portPlayer ID}
      [] ghost000random then {Ghost000random.portPlayer ID}
      [] pacman065random then {Pacman065random.portPlayer ID}
      [] ghost065intel then {Ghost065intel.portPlayer ID}
	  [] pacman018riseleft then {Pacman018riseleft.portPlayer ID}
	  [] ghost018hunter then {Ghost018hunter.portPlayer ID}
	  [] pacman092intel then {Pacman092intel.portPlayer ID}
	  [] ghost092random then {Ghost092random.portPlayer ID}
	  [] pacman063other then {Pacman063other.portPlayer ID}
	  [] ghost063other then {Ghost063other.portPlayer ID}
      end
   end
end
