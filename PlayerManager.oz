functor
import
   Pacman000random
   Pacman065random
   Ghost000random
   Ghost065intel
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
      end
   end
end
