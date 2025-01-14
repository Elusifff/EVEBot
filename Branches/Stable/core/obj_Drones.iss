/*
	Drone class

	Main object for interacting with the drones.  Instantiated by obj_Ship, only.

	-- CyberTech

*/

objectdef obj_Drones
{
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	variable index:int64 ActiveDroneIDList
	variable int CategoryID_Drones = 18
	variable int LaunchedDrones = 0
	variable int WaitingForDrones = 0
	variable bool DronesReady = FALSE
	variable int ShortageCount

	variable int64 MiningDroneTarget=0

	method Initialize()
	{
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		UI:UpdateConsole["obj_Drones: Initialized", LOG_MINOR]
	}
	method Shutdown()
	{
		if !${Me.InStation}
		{
			if (${Me.ToEntity.Mode} != 3)
			{
				UI:UpdateConsole["Recalling Drones prior to shutdown..."]
				This.ActiveDroneIDList:RemoveByQuery[${LavishScript.CreateQuery[GroupID = GROUP_FIGHTERDRONE]}]
				EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			}
		}
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method Pulse()
	{
		if ${EVEBot.Paused}
		{
			return
		}

		if ${This.WaitingForDrones}
		{
		    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
			{
				This.WaitingForDrones:Dec
    			if !${Me.InStation}
    			{
    				This.LaunchedDrones:Set[${This.DronesInSpace}]
    				if  ${This.LaunchedDrones} > 0
    				{
    					This.WaitingForDrones:Set[0]
    					This.DronesReady:Set[TRUE]

    					UI:UpdateConsole["${This.LaunchedDrones} drones deployed"]
    				}
                }

	    		This.NextPulse:Set[${Time.Timestamp}]
	    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
	    		This.NextPulse:Update
			}
		}
	}

	method LaunchMining()
	{
		variable index:item DroneListA
		variable index:int64 ListToLaunchA	
		variable iterator DroneIteratorA
		MyShip:GetDrones[DroneListA]		
		DroneListA:GetIterator[DroneIteratorA]

		UI:UpdateConsole["Step 1"]
		if ${DroneIteratorA:First(exists)}
		{	
			do
				{
					UI:UpdateConsole["Step 2"]
					if ${DroneIteratorA.Value.GroupID} == 101
					{
					ListToLaunchA:Insert[${DroneIteratorA.Value.ID}]
					}

				}
				while ${DroneIteratorA:Next(exists)}
			if ${ListToLaunchA.Used}
			{
				UI:UpdateConsole["Launching ${ListToLaunchA.Used} Mining Drones."]
				EVE:LaunchDrones[ListToLaunchA]
				This.WaitingForDrones:Set[${ListToLaunchA.Used}]
			}
		}
	}	
	
	method LaunchCombat()
	{
		variable index:item DroneListB
		variable index:int64 ListToLaunchB	
		variable iterator DroneIteratorB
		MyShip:GetDrones[DroneListB]		
		DroneListB:GetIterator[DroneIteratorB]

		UI:UpdateConsole["Step 1"]
		if ${DroneIteratorB:First(exists)}
		{	
			do
				{
					UI:UpdateConsole["Step 2"]
					if ${DroneIteratorB.Value.GroupID} == 100
					{
					ListToLaunchB:Insert[${DroneIteratorB.Value.ID}]
					}

				}
				while ${DroneIteratorB:Next(exists)}
			if ${ListToLaunchB.Used}
			{
				UI:UpdateConsole["Launching ${ListToLaunchB.Used} Combat Drones."]
				EVE:LaunchDrones[ListToLaunchB]
				This.WaitingForDrones:Set[${ListToLaunchB.Used}]
			}
		}
	}	
	
	method LaunchIceHarvester()
	{
		variable index:item DroneListC
		variable index:int64 ListToLaunchC	
		variable iterator DroneIteratorC
		MyShip:GetDrones[DroneListC]		
		DroneListC:GetIterator[DroneIteratorC]

		UI:UpdateConsole["Step 1"]
		if ${DroneIteratorC:First(exists)}
		{	
			do
				{
					UI:UpdateConsole["Step 2"]
					if ${DroneIteratorC.Value.GroupID} == 464
					{
					ListToLaunchC:Insert[${DroneIteratorC.Value.ID}]
					}

				}
				while ${DroneIteratorC:Next(exists)}
			if ${ListToLaunchC.Used}
			{
				UI:UpdateConsole["Launching ${ListToLaunchC.Used} Ice Harvester Drones."]
				EVE:LaunchDrones[ListToLaunchC]
				This.WaitingForDrones:Set[${ListToLaunchC.Used}]
			}
		}
	}
	method LaunchAll()
	{
		if ${This.DronesInBay} > 0
		{
			UI:UpdateConsole["Launching drones..."]
			MyShip:LaunchAllDrones
			This.WaitingForDrones:Set[5]
		}
	}

	member:int DronesInBay()
	{
		variable index:item DroneList
		MyShip:GetDrones[DroneList]
		return ${DroneList.Used}
	}

	member:int DronesInSpace(bool IncludeFighters=TRUE)
	{
		Me:GetActiveDroneIDs[This.ActiveDroneIDList]
		if !${IncludeFighters}
		{
			This.ActiveDroneIDList:RemoveByQuery[${LavishScript.CreateQuery[GroupID = GROUP_FIGHTERDRONE]}]
		}
		return ${This.ActiveDroneIDList.Used}
	}

	member:bool CombatDroneShortage()
	{
		if !${This.DronesReady}
		{
			return
		}

		if (${MyShip.DronebayCapacity} > 0 && \
   			${This.DronesInBay} == 0 && \
   			${This.DronesInSpace} < ${Config.Combat.MinimumDronesInSpace})
   		{
			ShortageCount:Inc
   			if ${ShortageCount} > 10
   			{
   				return TRUE
   			}
   		}
   		else
   		{
   			ShortageCount:Set[0]
   		}
   		return FALSE
	}

	; Returns the number of Drones in our station hanger.
	member:int DronesInStation()
	{
		return ${Station.DronesInStation.Used}
	}

	function StationToBay()
	{
		if ${This.DronesInStation} == 0 || \
			!${MyShip(exists)}
		{
			return
		}

		EVE:Execute[OpenDroneBayOfActiveShip]
		wait 15

		variable iterator CargoIterator
		Station.DronesInStation:GetIterator[CargoIterator]

		if ${CargoIterator:First(exists)}
		do
		{
			;UI:UpdateConsole["obj_Drones:TransferToDroneBay: ${CargoIterator.Value.Name}"]
			CargoIterator.Value:MoveTo[${MyShip.ID}, DroneBay,1]
			wait 30
		}
		while ${CargoIterator:Next(exists)}
		wait 10
		EVEWindow[MyDroneBay]:Close
		wait 10
	}


	method ReturnAllToDroneBay()
	{
		if ${This.DronesInSpace[FALSE]} > 0
		{
			UI:UpdateConsole["Recalling ${This.ActiveDroneIDList.Used} Drones"]
			This.ActiveDroneIDList:RemoveByQuery[${LavishScript.CreateQuery[GroupID = GROUP_FIGHTERDRONE]}]
			EVE:DronesReturnToDroneBay[This.ActiveDroneIDList]
			EVE:Execute[CmdDronesReturnToBay]
			This.ActiveDroneIDList:Clear

		}
		wait 500
	}

	method ActivateMiningDrones()
	{
		variable index:activedrone ActiveDroneListX
		variable iterator DroneIteratorX
		variable index:int64 LazyDrone
		Me:GetActiveDrones[ActiveDroneListX]
		ActiveDroneListX:GetIterator[DroneIteratorX]
		
		;UI:UpdateConsole["ASSSSSSSS"]
		if ${DroneIteratorX:First(exists)}
			do
			{
				if ${DroneIteratorX.Value.State} == 0
				{
					LazyDrone:Insert[${DroneIteratorX.Value.ID}]
					EVE:DronesMineRepeatedly[ActiveDroneListX]
				}
			}
			while ${DroneIteratorX:Next(exists)}
			
		if ${LazyDrone.Used} > 0
		{
			EVE:DronesMineRepeatedly[LazyDrone]
			LazyDrone:Clear
		}
		
		if ${Ship.Drones.DronesInSpace} == 0
		{
			UI:UpdateConsole["Broken?"]
			return
		}
		

		if (${This.DronesInSpace} > 0) && ${MiningDroneTarget} != ${Me.ActiveTarget} 
		{
			;UI:UpdateConsole["PISSSSSSSSSSSSSSS"]
			EVE:DronesMineRepeatedly[ActiveDroneListX]
			MiningDroneTarget:Set[${Me.ActiveTarget}]
		}
	}

	member:bool IsMiningAsteroidID(int64 EntityID)
	{
		if ${MiningDroneTarget} == ${EntityID}
		{
			return TRUE
		}
		return FALSE
	}

	method SendDrones()
	{
		if !${This.DronesReady}
		{
			return
		}

		if (${This.DronesInSpace} > 0)
		{
			variable iterator DroneIterator
			variable index:activedrone ActiveDroneList
			Me:GetActiveDrones[ActiveDroneList]
			ActiveDroneList:GetIterator[DroneIterator]
			variable index:int64 returnIndex
			variable index:int64 engageIndex

			do
			{
				if ${DroneIterator.Value.ToEntity.GroupID} != GROUP_FIGHTERDRONE && \
					(${DroneIterator.Value.ToEntity.ShieldPct} < 80 || \
					${DroneIterator.Value.ToEntity.ArmorPct} < 0)
				{
					UI:UpdateConsole["Recalling Damaged Drone ${DroneIterator.Value.ID} Shield %: ${DroneIterator.Value.ToEntity.ShieldPct} Armor %: ${DroneIterator.Value.ToEntity.ArmorPct}"]
					returnIndex:Insert[${DroneIterator.Value.ID}]

				}
				else
				{
					;UI:UpdateConsole["Debug: Engage Target ${DroneIterator.Value.ID}"]
					if ${DroneIterator.Value.State} == 0
					{
						engageIndex:Insert[${DroneIterator.Value.ID}]
					}
				}
			}
			while ${DroneIterator:Next(exists)}
			if ${returnIndex.Used} > 0
			{
				EVE:DronesReturnToDroneBay[returnIndex]
			}
			if ${engageIndex.Used} > 0
			{
				EVE:DronesEngageMyTarget[engageIndex]
			}
		}
	}
}