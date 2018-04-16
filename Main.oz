functor
import
   GUI
   Input
   PlayerManager
   Browser
define
   WindowPort
in
   
   % TODO add additionnal function

   thread
      % Create port for window
      WindowPort = {GUI.portWindow}

      % Open window
      {Send WindowPort buildWindow}

      % TODO complete
      

   end

end
