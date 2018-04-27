#!/bin/bash
ozc -c Input.oz
ozc -c PlayerManager.oz
ozc -c GUI.oz
ozc -c Pacman065random.oz
ozc -c Ghost065intel.oz
ozc -c Initialisation.oz
ozc -c TurnByTurn.oz
ozc -c Simultaneous.oz
ozc -c Main.oz

ozengine Main.ozf > log.log