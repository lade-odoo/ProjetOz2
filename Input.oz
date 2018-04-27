functor
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   respawnTimePoint:RespawnTimePoint
   respawnTimeBonus:RespawnTimeBonus
   respawnTimePacman:RespawnTimePacman
   respawnTimeGhost:RespawnTimeGhost
   rewardPoint:RewardPoint
   rewardKill:RewardKill
   penalityKill:PenalityKill
   nbLives:NbLives
   huntTime:HuntTime
   nbPacman:NbPacman
   pacman:Pacman
   colorPacman:ColorPacman
   nbGhost:NbGhost
   ghost:Ghost
   colorGhost:ColorGhost
   thinkMin:ThinkMin
   thinkMax:ThinkMax
define
   IsTurnByTurn
   NRow
   NColumn
   Map
   RespawnTimePoint
   RespawnTimeBonus
   RespawnTimePacman
   RespawnTimeGhost
   RewardPoint
   RewardKill
   PenalityKill
   NbLives
   HuntTime
   NbPacman
   Pacman
   ColorPacman
   NbGhost
   Ghost
   ColorGhost
   ThinkMin
   ThinkMax
in

%%%% Style of game %%%%
   
   IsTurnByTurn = false

%%%% Description of the map %%%%
   
   NRow = 11
   NColumn = 20
   Map = [[1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1]
	  [1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
	  [1 0 1 1 1 1 0 1 0 0 0 1 0 1 0 0 0 1 0 1]
	  [1 0 1 4 0 0 0 1 3 0 3 1 0 1 1 0 0 1 0 1]
	  [1 0 1 0 0 0 0 1 0 0 0 1 0 1 4 0 0 1 0 1]
	  [0 0 1 1 1 0 0 0 0 0 0 0 0 1 0 1 0 1 0 0]
	  [1 0 1 0 0 0 0 1 0 0 0 1 0 1 0 0 4 1 0 1]
	  [1 0 1 0 0 0 0 1 3 0 3 1 0 1 0 0 1 1 0 1]
	  [1 0 1 0 0 0 0 1 1 0 1 1 0 1 0 0 0 1 0 1]
	  [1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
	  [1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1]]

%%%% Respawn times %%%%
   
   RespawnTimePoint = 5000 %50
   RespawnTimeBonus = 15000 %150
   RespawnTimePacman = 5000 %50
   RespawnTimeGhost = 5000 %50

%%%% Rewards and penalities %%%%

   RewardPoint = 1
   RewardKill = 5
   PenalityKill = 5

%%%%

   NbLives = 2
   HuntTime = 5000 %50
   
%%%% Players description %%%%

   NbPacman = 2
   %Pacman = [pacman000random pacman000random]
   Pacman = [pacman065random pacman065random]
   ColorPacman = [yellow red]
   NbGhost = 2
   Ghost = [ghost065intel ghost065intel]
   ColorGhost = [green white]% orange white]

%%%% Thinking parameters (only in simultaneous) %%%%
   
   ThinkMin = 500
   ThinkMax = 1500
   
end
