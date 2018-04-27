functor
import
   Pacman000random
   Pacman000other
   PacmanTeam65
   Ghost000random
   GhostTeam65
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
      [] pacmanTeam65 then {PacmanTeam65.portPlayer ID}
      [] ghostTeam65 then {GhostTeam65.portPlayer ID}
      end
   end
end
