functor
import
  Input
   Browser
   OS
export
  portPlayer:StartPlayer
define   
   StartPlayer
   TreatStream
   
in
  % ID is a <pacman> ID
  fun{StartPlayer ID}
    Stream Port
  in
    {NewPort Stream Port}
    thread
       {TreatStream Stream}
    end
    Port
  end

  proc{TreatStream Stream} % has as many parameters as you want
     case Stream of ...
     end
  end
end
