/*
	Missions class

	Object to contain members related to missions.

	-- GliderPro

*/

objectdef obj_MissionCache
{

	variable string CONFIG_FILE = "${Script.CurrentDirectory}/Config/${Me.Name} Mission Cache.xml"
	variable string SET_NAME = "Missions"

	variable index:entity entityIndex
	variable iterator     entityIterator
		
	variable index:entity BestAsteroidList
	variable index:entity AsteroidList
	variable iterator OreTypeIterator
	

	
	method Initialize()
	{
		LavishSettings[MissionCache]:Clear
		LavishSettings:AddSet[MissionCache]
		LavishSettings[MissionCache]:AddSet[${This.SET_NAME}]
		LavishSettings[MissionCache]:Import[${This.CONFIG_FILE}]
		UI:UpdateConsole["obj_MissionCache: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		LavishSettings[MissionCache]:Export[${This.CONFIG_FILE}]
		LavishSettings[MissionCache]:Clear
	}

	member:settingsetref MissionsRef()
	{
		return ${LavishSettings[MissionCache].FindSet[${This.SET_NAME}]}
	}

	member:settingsetref MissionRef(int agentID)
	{
		return ${This.MissionsRef.FindSet[${agentID}]}
	}

	method AddMission(int agentID, string name)
	{
		This.MissionsRef:AddSet[${agentID}]
		This.MissionRef[${agentID}]:AddSetting[Name,"${name}"]
	}

	member:int FactionID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[FactionID,-1]}
	}

	method SetFactionID(int agentID, int factionID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[FactionID,${factionID}]
	}

	member:int TypeID(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[TypeID,-1]}
	}

	method SetTypeID(int agentID, int typeID)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[TypeID,${typeID}]
	}

	member:float Volume(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[Volume,0]}
	}

	method SetVolume(int agentID, float volume)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[Volume,${volume}]
	}
	
	member:bool GasHarvesting(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[GasHarvesting,FALSE]}
	}

	method SetGasHarvesting(int agentID, bool isGasHarvesting)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[GasHarvesting,${isGasHarvesting}]
	}
	member:bool LowSec(int agentID)
	{
		return ${This.MissionRef[${agentID}].FindSetting[LowSec,FALSE]}
	}

	method SetLowSec(int agentID, bool isLowSec)
	{
		if !${This.MissionsRef.FindSet[${agentID}](exists)}
		{
			This.MissionsRef:AddSet[${agentID}]
		}

		This.MissionRef[${agentID}]:AddSetting[LowSec,${isLowSec}]
	}
}

;objectdef obj_MissionDatabase
;{
;	variable string SVN_REVISION = "$Rev$"
;	variable int Version
;
;	variable string CONFIG_FILE = "${BaseConfig.CONFIG_PATH}/Mission Database.xml"
;	variable string SET_NAME = "Mission Database"
;
;	method Initialize()
;	{
;		if ${LavishSettings[${This.SET_NAME}](exists)}
;		{
;			LavishSettings[${This.SET_NAME}]:Clear
;		}
;		LavishSettings:Import[${CONFIG_FILE}]
;		LavishSettings[${This.SET_NAME}]:GetSettingIterator[This.agentIterator]
;     This:DumpDatabase
;	UI:UpdateConsole["obj_MissionDatabase: Initialized", LOG_MINOR]
;	}
;
;   method DumpDatabase()
;   {
;
;   }
;
;}

objectdef obj_Missions
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable obj_MissionCache MissionCache
;   variable obj_MissionDatabase MissionDatabase
	variable obj_Combat Combat

	method Initialize()
	{
		UI:UpdateConsole["obj_Missions: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
	}

	function RunMission()
	{
		variable index:agentmission amIndex
		variable iterator amIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		UI:UpdateConsole["obj_Missions: DEBUG: amIndex.Used = ${amIndex.Used}", LOG_DEBUG]
		if ${amIterator:First(exists)}
		{
			do
			{
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.AgentID = ${amIterator.Value.AgentID}"]
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.State = ${amIterator.Value.State}"]
				UI:UpdateConsole["obj_Missions: DEBUG: amIterator.Value.Type = ${amIterator.Value.Type}"]
				if ${amIterator.Value.State} == 2
				{
					if ${amIterator.Value.Type.Find[Courier](exists)}
					{
						call This.RunCourierMission ${amIterator.Value.AgentID}
					}
					elseif ${amIterator.Value.Type.Find[Trade](exists)}
					{
						call This.RunTradeMission ${amIterator.Value.AgentID}
					}
					elseif ${amIterator.Value.Type.Find[Mining](exists)}
					{
						call This.RunMiningMission ${amIterator.Value.AgentID}
					}
					elseif ${amIterator.Value.Type.Find[Encounter](exists)}
					{
						call This.RunCombatMission ${amIterator.Value.AgentID}
					}
					else
					{
						UI:UpdateConsole["obj_Missions: ERROR!  Unknown mission type!"]
						Script:Pause
					}
				}
			}
			while ${amIterator:Next(exists)}
		}
	}

	function RunCourierMission(int agentID)
	{
		variable int        QuantityRequired
		variable string     itemName
		variable float      itemVolume
		variable bool       haveCargo = FALSE
		variable bool       allDone = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

		call Cargo.CloseHolds
		call Cargo.OpenHolds

	    Agents:SetActiveAgent[${EVE.Agent[id, ${agentID}].Name}]

		if ${This.MissionCache.Volume[${agentID}]} == 0
		{
			call Agents.MissionDetails
		}

		if ${This.MissionCache.Volume[${agentID}]} > ${Config.Missioneer.SmallHaulerLimit}
		{
			UI:UpdateConsole["Too Small"]
			call Ship.ActivateShip "${Config.Missioneer.LargeHauler}"
		}
		else
		{
			UI:UpdateConsole["Too Large"]
			call Ship.ActivateShip "${Config.Missioneer.SmallHauler}"
		}

		TypeID:Set[${This.MissionCache.TypeID[${agentID}]}]
		if ${TypeID} == -1
		{
			UI:UpdateConsole["ERROR: RunCourierMission: Unable to retrieve item type from mission cache for ${agentID}. Stopping."]
			Script:Pause
		}
		itemName:Set[${EVEDB_Items.Name[${TypeID}]}]
		itemVolume:Set[${EVEDB_Items.Volume[${TypeID}]}]
		if ${itemVolume} > 0
		{
			UI:UpdateConsole[DEBUG: RunCourierMission: ${TypeID}:${itemName} has volume ${itemVolume}.]
			QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${itemVolume}]}]
		}
		else
		{
			UI:UpdateConsole["DEBUG: RunCourierMission: ${This.MissionCache.TypeID[${agentID}]}: Item not found!  Assuming one unit to move."]
			QuantityRequired:Set[1]
		}

		do
		{
			Cargo:FindShipCargoByType[${This.MissionCache.TypeID[${agentID}]}]
			if ${Cargo.CargoToTransferCount} == 0
			{
				UI:UpdateConsole["obj_Missions: MoveToPickup"]
				call Agents.MoveToPickup
				UI:UpdateConsole["obj_Missions: TransferCargoToShip"]
				wait 50
				call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
				allDone:Set[${Cargo.LastTransferComplete}]
			}

			UI:UpdateConsole["obj_Missions: MoveToDropOff"]
			call Agents.MoveToDropOff
			wait 50

			call Cargo.CloseHolds
			call Cargo.OpenHolds

			UI:UpdateConsole["DEBUG: RunCourierMission: Checking ship's cargohold for ${QuantityRequired} units of ${itemName}."]
			MyShip:GetCargo[CargoIndex]
			CargoIndex:GetIterator[CargoIterator]
			if ${CargoIterator:First(exists)}
			{
				do
				{
					TypeID:Set[${CargoIterator.Value.TypeID}]
					ItemQuantity:Set[${CargoIterator.Value.Quantity}]
					UI:UpdateConsole["DEBUG: RunCourierMission: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantity} >= ${QuantityRequired})
					{
						UI:UpdateConsole["DEBUG: RunCourierMission: Found required items in ship's cargohold."]
						haveCargo:Set[TRUE]
						break
					}
				}
				while ${CargoIterator:Next(exists)}
			}

			if ${haveCargo} == TRUE
			{
				break
			}

			call Cargo.TransferItemTypeToHangar ${This.MissionCache.TypeID[${agentID}]}
			wait 50

			if ${Station.Docked}
			{
				UI:UpdateConsole["DEBUG: RunCourierMission: Checking station hangar for ${QuantityRequired} units of ${itemName}."]
				Me:GetHangarItems[CargoIndex]
				CargoIndex:GetIterator[CargoIterator]

				if ${CargoIterator:First(exists)}
				{
					do
					{
						TypeID:Set[${CargoIterator.Value.TypeID}]
						ItemQuantity:Set[${CargoIterator.Value.Quantity}]
						UI:UpdateConsole["DEBUG: RunCourierMission: Station Hangar: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

						if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
						   (${ItemQuantity} >= ${QuantityRequired})
						{
							UI:UpdateConsole["DEBUG: RunCourierMission: Found required items in station hangar."]
							allDone:Set[TRUE]
							break
						}
					}
					while ${CargoIterator:Next(exists)}
				}
			}
		}
		while !${allDone}

		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}

	function RunTradeMission(int agentID)
	{
		variable int        QuantityRequired
		variable string     itemName
		variable bool       haveCargo = FALSE
		variable index:item CargoIndex
		variable iterator   CargoIterator
		variable int        TypeID
		variable int        ItemQuantity

	    Agents:SetActiveAgent[${EVE.Agent[id,${agentID}]}]

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${EVEDB_Items.Volume[${This.MissionCache.TypeID[${agentID}]}]}]}]}]

		call Cargo.CloseHolds
		call Cargo.OpenHolds

		;;; Check the cargohold of your ship
		MyShip:GetCargo[CargoIndex]
		CargoIndex:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		{
			do
			{
				TypeID:Set[${CargoIterator.Value.TypeID}]
				ItemQuantity:Set[${CargoIterator.Value.Quantity}]
				UI:UpdateConsole["DEBUG: RunTradeMission: Ship's Cargo: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

				if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
				   (${ItemQuantity} >= ${QuantityRequired})
				{
					UI:UpdateConsole["DEBUG: RunTradeMission: Found required items in ship's cargohold."]
					haveCargo:Set[TRUE]
				}
			}
			while ${CargoIterator:Next(exists)}
		}

		if ${This.MissionCache.Volume[${agentID}]} > ${Config.Missioneer.SmallHaulerLimit}
		{
			call Ship.ActivateShip "${Config.Missioneer.LargeHauler}"
		}
		else
		{
			call Ship.ActivateShip "${Config.Missioneer.SmallHauler}"
		}

		;;; Check the hangar of the current station
		if ${haveCargo} == FALSE && ${Station.Docked}
		{
			Me:GetHangarItems[CargoIndex]
			CargoIndex:GetIterator[CargoIterator]

			if ${CargoIterator:First(exists)}
			{
				do
				{
					TypeID:Set[${CargoIterator.Value.TypeID}]
					ItemQuantity:Set[${CargoIterator.Value.Quantity}]
					UI:UpdateConsole["DEBUG: RunTradeMission: Station Hangar: ${ItemQuantity} units of ${CargoIterator.Value.Name}(${TypeID})."]

					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantity} >= ${QuantityRequired})
					{
						UI:UpdateConsole["DEBUG: RunTradeMission: Found required items in station hangar."]
						if ${Agents.InAgentStation} == FALSE
						{
							call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
						}
						haveCargo:Set[TRUE]
					}
				}
				while ${CargoIterator:Next(exists)}
			}
		}

		;;;  Try to buy the item
		if ${haveCargo} == FALSE
		{
		  	if ${Station.Docked}
		  	{
			 	call Station.Undock
		  	}

			call Market.GetMarketOrders ${This.MissionCache.TypeID[${agentID}]}
			call Market.FindBestWeightedSellOrder ${Config.Missioneer.AvoidLowSec} ${quantity}
			call Ship.TravelToSystem ${Market.BestSellOrderSystem}
			call Station.DockAtStation ${Market.BestSellOrderStation}
			call Market.PurchaseItem ${This.MissionCache.TypeID[${agentID}]} ${quantity}

			call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}

			if ${Cargo.LastTransferComplete} == FALSE
			{
				UI:UpdateConsole["obj_Missions: ERROR: Couldn't carry all the trade goods!  Pasuing script!!"]
				Script:Pause
			}
		}

		;;;UI:UpdateConsole["obj_Missions: MoveTo Agent"]
		call Agents.MoveTo
		wait 50
		;;;call Cargo.TransferItemTypeToHangar ${This.MissionCache.TypeID[${agentID}]}
		;;;wait 50

		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}

	function RunMiningMission(int agentID)
	{
		
	;	This is used to keep track of what we are approaching and when we started
		variable int64 Approaching = 0
		variable int TimeStartedApproaching = 0
		variable bool ApproachingOrca=FALSE
	
	;	Variables used to target and track asteroids
		variable index:entity LockedTargets
		variable iterator Target
		variable int AsteroidsLocked=0
		variable iterator AsteroidIterator
		variable int AsteroidsNeeded=1
	
		variable int        QuantityRequired
		variable string     itemName
		variable bool       haveCargo = FALSE
		variable index:item HangarIndex
		variable iterator   HangarIterator
		variable index:item OreIndex
		variable iterator	OreIterator
		variable int        TypeID
		variable int        ItemQuantityA
		variable float		itemVolume
		variable int		ItemQuantityB
		
		variable index:item hsIndex
		variable iterator hsIterator
		variable string shipName
	    
		
		Agents:SetActiveAgent[${Agent[id, ${agentID}].Name}]		
		;if ${This.MissionCache.Volume[${agentID}]} == 0
		;{
			call Agents.MissionDetails ${agentID}
		;}

		itemName:Set[${EVEDB_Items.Name[${This.MissionCache.TypeID[${agentID}]}]}]
		itemVolume:Set[${EVEDB_Items.Volume[${TypeID}]}]
		
		;QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${EVEDB_Items.Volume[${This.MissionCache.TypeID[${agentID}]}]}]}]}]
		QuantityRequired:Set[${Math.Calc[${This.MissionCache.Volume[${agentID}]}/${itemVolume}]}
		
		call Ship.OpenCargo
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold](exists)}
			{
				EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold]:MakeActive
				EVEWindow["Inventory"]:StackAll
			}
		wait 10
		if ${Station.Docked}
		{
			call Cargo.TransferOreToStationHangar
			wait 50
			OreIndex:Clear
			MyShip:GetOreHoldCargo[OreIndex]
			wait 10
			OreIndex:GetIterator[OreIterator]
		}
		if ${OreIterator:First(exists)} && ${Station.Docked}
		{
			do
			{
				TypeID:Set[${OreIterator.Value.TypeID}]
				ItemQuantityA:Set[${OreIterator.Value.Quantity}]
				UI:UpdateConsole["DEBUG: Miner: Ship's Cargo: A ${ItemQuantityA} units of ${OreIterator.Value.Name}(${TypeID})."]

				if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
				   (${ItemQuantityA} >= ${QuantityRequired})
				{
					UI:UpdateConsole["DEBUG: Miner: Found required items in ship's cargohold."]
					haveCargo:Set[TRUE]
				}
			}
			while ${OreIterator:Next(exists)}
		}
		;;; Check the hangar of the current station
		if ${haveCargo} == FALSE && ${Station.Docked}
		{
			HangarIndex:Clear
			Me:GetHangarItems[HangarIndex]
			HangarIndex:GetIterator[HangarIterator]

			if ${HangarIterator:First(exists)}
			{
				do
				{
					TypeID:Set[${HangarIterator.Value.TypeID}]
					ItemQuantityB:Set[${HangarIterator.Value.Quantity}]
					UI:UpdateConsole["DEBUG: Miner: Station Hangar: B ${ItemQuantityB} units of ${HangarIterator.Value.Name}(${TypeID})."]

					if (${TypeID} == ${This.MissionCache.TypeID[${agentID}]}) && \
					   (${ItemQuantityB} >= ${QuantityRequired})
					{
						UI:UpdateConsole["DEBUG: Miner: Found required items in station hangar."]
						if ${Agents.InAgentStation} == FALSE
						{
							call Cargo.TransferHangarItemToShip ${This.MissionCache.TypeID[${agentID}]}
						}
						haveCargo:Set[TRUE]
					}
				}
				while ${HangarIterator:Next(exists)}
			}
		}
		if ${haveCargo} == TRUE
		{
			call Agents.TurnInMission
			wait 50
		}
		;Determine ShipType Needed
		;if ${This.MissionCache.GasHarvesting[${agentID}]} == TRUE
		;{
		;	UI:UpdateConsole["GAS SITE its alright"]
			;Script:Pause
		;	call Ship.ActivateShip "Gas Venture"
		;}	
		; EVEBOT CAN'T CHANGE SHIPS AT THE MOMENT, CRAP
		;else
		
		;{
		;	call Ship.ActivateShip "${Config.Missioneer.SmallHauler}"
		
		if ${Config.Miner.UseMiningDrones} && ${Ship.TotalMiningLasers} == 0
		{
			call This.WarpToEncounter ${agentID}		
			while ${Ship.InWarp}
			{
				wait 75
			}
			
			Asteroids.AsteroidList:GetIterator[AsteroidIterator]

			if ${AsteroidList.Used} == 0
			{
				call Asteroids.UpdateList
			}

			call Asteroids.UpdateList
			call Asteroids.MissionTargetNext
			LockedTargets:Clear
			Me:GetTargets[LockedTargets]
			LockedTargets:GetIterator[Target]
			Ship.Drones:LaunchMining
			
			do
			{
				
				do	
				{
					if (${Math.Calc[${Me.TargetCount} + ${Me.TargetingCount}]} < 1
						{
							call Asteroids.MissionTargetNext
						}
						LockedTargets:Clear
						Me:GetTargets[LockedTargets]
						LockedTargets:GetIterator[Target]
					
					if ${Me.ActiveTarget.Distance} > 25000 && ${Miner.Mine.Approaching} == 0 
					{
						UI:UpdateConsole["Miner.Mine: Approaching ${Me.ActiveTarget.Name}"]
						call Ship.Approach ${Me.ActiveTarget.ID} 10000
						Ship:Activate_AfterBurner
						Miner.Mine.Approaching:Set[${Me.ActiveTarget.ID}]
						Miner.Mine.TimeStartedApproaching:Set[${Time.Timestamp}]
						return
					}
					; Mining Drone Controls
					
					if ${Config.Miner.UseMiningDrones} && ${Me.TargetedByCount} == 0
					
				{
							variable iterator DroneIteratorC
							variable index:activedrone ActiveDroneListC
							Me:GetActiveDrones[ActiveDroneListC]
							ActiveDroneListC:GetIterator[DroneIteratorC]
							variable index:int64 returnIndex
							variable index:int64 engageIndex
							variable index:int64 WrongDrones2
							
							
							if ${DroneIteratorC:First(exists)}
							do
							{
								if ${DroneIteratorC.Value.ToEntity.GroupID} != 101
								{
									UI:UpdateConsole["Mine Function Recall"]
									WrongDrones2:Insert[${DroneIteratorC.Value.ID}]
								}
							}
							while ${DroneIteratorC:Next(exists)}
						
							if ${WrongDrones2.Used} > 0
								{
								Ship.Drones:ReturnAllToDroneBay
								UI:UpdateConsole["Wrong Drones Recall"]
								WrongDrones2:Clear
								}
								do
								{
									wait 20
								}
								while ${WrongDrones2.Used} > 0 && ${Ship.Drones.DronesInSpace[FALSE]} > 0
								
							if ${Ship.Drones.DronesInSpace[FALSE]} == 0
							{
								Ship.Drones:LaunchMining
								wait 50
							}
							variable iterator DroneIteratorD
							variable index:activedrone ActiveDroneListD					
							Me:GetActiveDrones[ActiveDroneListD]
							ActiveDroneListD:GetIterator[DroneIteratorD]
							if ${DroneIteratorD:First(exists)}
							do
							{
							
								if ${DroneIteratorD.Value.ToEntity.GroupID} != GROUP_FIGHTERDRONE && \
								(${DroneIteratorD.Value.ToEntity.ShieldPct} < 80 || \
								${DroneIteratorD.Value.ToEntity.ArmorPct} < 0)
								{
									UI:UpdateConsole["Recalling Damaged Drone ${DroneIteratorD.Value.ID} Shield %: ${DroneIterator.Value.ToEntity.ShieldPct} Armor %: ${DroneIterator.Value.ToEntity.ArmorPct}"]
									returnIndex:Insert[${DroneIteratorD.Value.ID}]

								}
								else
								{
									wait 10
									UI:UpdateConsole["Debug: Engage Target ${DroneIteratorD.Value.ID}"]
									engageIndex:Insert[${DroneIteratorD.Value.ID}]
								}
							}
							while ${DroneIteratorD:Next(exists)}
						
							if ${returnIndex.Used} > 0
							{
								EVE:DronesReturnToDroneBay[returnIndex]
							}
							if ${Ship.Drones.DronesInSpace[FALSE]} > 0
								{
									Ship.Drones:ActivateMiningDrones
								}
							call Asteroids.UpdateList
				}
						
						do
						{
							variable int64 Attacking=-1
							variable iterator GetData
							variable index:entity targetIndexB
							variable iterator     targetIteratorB

							EVE:QueryEntities[targetIndexB, "CategoryID = CATEGORYID_ENTITY"]
							targetIndexB:GetIterator[targetIteratorB]
							
							
							if ${Me.TargetedByCount} > 0
							{
								call This.TargetAgressors
							}
							
							if ${targetIteratorB:First(exists)}
								do
								{
									if ${targetIteratorB.Value.IsTargetingMe}
									{
									Attacking:Set[${targetIteratorB.Value.ID}]
									}
								}
								while ${targetIterator:Next(exists)}
							
							if ${Attacking} != -1 && ${Entity[${Attacking}].IsLockedTarget} && ${Entity[${Attacking}](exists)}
							{
									Entity[${Attacking}]:MakeActiveTarget
									wait 50 ${Me.ActiveTarget.ID} == ${Attacking}

									variable index:activedrone ActiveDroneListE
									variable index:activedrone ActiveDroneListF
									variable iterator DroneIteratorE
									variable iterator DroneIteratorF
									variable index:int64 AttackDronesE
									variable index:int64 WrongDronesE

									Me:GetActiveDrones[ActiveDroneListE]
									ActiveDroneListE:GetIterator[DroneIteratorE]
									if ${DroneIteratorE:First(exists)}
									do
									{
										; Hard coded TypeIDs for all mining drones you are likely to use while mining.
										;if ${DroneIterator.Value.TypeID} == 10246
										if ${DroneIteratorE.Value.ToEntity.GroupID} == 101
										{
											WrongDronesE:Insert[${DroneIteratorE.Value.ID}]
											UI:UpdateConsole["Wrong Drones"]
										}
									}
									while ${DroneIteratorE:Next(exists)}
									
									if ${WrongDronesE.Used} > 0
										{
											Ship.Drones:ReturnAllToDroneBay
											UI:UpdateConsole["Wrong Drones Recall"]
											WrongDronesE:Clear
										}
										do
										{
											wait 30
											Ship.Drones:ReturnAllToDroneBay
										}
										while ${Ship.Drones.DronesInSpace[FALSE]} > 0 && ${AttackDronesE.Used} == 0
									
								
									if ${Ship.Drones.DronesInSpace[FALSE]} == 0
									{
										Ship.Drones:LaunchCombat
										wait 50
									}
									
									Me:GetActiveDrones[ActiveDroneListF]
									ActiveDroneListF:GetIterator[DroneIteratorF]		
								
										if ${DroneIteratorF:First(exists)}
										do
										{
											if ${DroneIteratorF.Value.ToEntity.GroupID} == 100
											{
											AttackDronesE:Insert[${DroneIteratorF.Value.ID}]
											}
										}
										while ${DroneIteratorF:Next(exists)}
										

										if ${AttackDronesE.Used} > 0
										{
											Entity[${Attacking}]:MakeActiveTarget
											UI:UpdateConsole["Miner.Defend: Sending ${AttackDronesE.Used} Drones to attack ${Entity[${Attacking}].Name}"]
											EVE:DronesEngageMyTarget[AttackDronesE]
										}
										if ${Me.TargetedByCount} == 0 && ${AttackDronesE.Used} > 0
										{
											UI:UpdateConsole["No Attackers, Recalling Drones"]
											Ship.Drones:ReturnAllToDroneBay
											AttackDronesE:Clear
											break
											
										}
								
							}
							
						} 
						while ${Me.TargetedByCount} > 0

				}
				while ${Target:Next(exists)} && ${Me.TargetedByCount} == 0
			}
			while ${Asteroids.FieldEmpty} == FALSE
			
			Ship.Drones:ReturnAllToDroneBay
			wait 50
			call Agents.MoveTo ${agentID}
			wait 50
			call Agents.TurnInMission
			
		}
		elseif ${amIterator.Value.Name.Equal[Gas Injections]}
		{
			UI:UpdateConsole["Gas Site"]
			call This.WarpToEncounter ${agentID}
			UI:UpdateConsole["Move To Mining Site"]
			while ${Ship.InWarp}
			{
				wait 75
			}
		
			;Ship.Drones:LaunchAll
			do
			{
				wait 15
				call Asteroids.UpdateList
				wait 20
				if ${AsteroidIterator.Value.Distance} >= 11000
				{
					call Ship.Approach ${AsteroidIterator.Value.ID} 1000
					wait 50
				}
				if (${Math.Calc[${Me.TargetCount} + ${Me.TargetingCount}]} < 1
				{
					call Asteroids.MissionTargetNext
				}
				wait 20
				wait 50 ${Me.TargetingCount} == 0
				LockedTargets:Clear
				Me:GetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				do
				{
					LockedTargets:Clear
					Me:GetTargets[LockedTargets]
					LockedTargets:GetIterator[Target]
					;if ${Ship.Drones.DronesInSpace} == 0
					;{
					;	Ship.Drones:LaunchAll
					;}
					if ${Entity[${Target.Value.ID}].Distance} >= 1000
					{
					wait 50
					Me.ActiveTarget:Orbit[1000]
					}
					;if ${Miner.MinerFull}
					;{
					;	EVE:Execute[CmdDronesReturnToBay]
					;	wait 50
					;	call Agents.MoveTo ${agentID}
					;	wait 50
					;	call Cargo.TransferOreToStationHangar
					;	wait 50
					;	call This.WarpToEncounter ${agentID}
					;}
					call Asteroids.UpdateList
					if ${Me.ActiveTarget.Distance} <= 1500
					{
						;EVE:Execute[CmdStopShip]
						;call Ship.ActivateFreeMiningLaser ${Me.ActiveTarget}
						wait 50
						call Ship.ActivateFreeMiningLaser ${Me.ActiveTarget}
					}
					if ${Me.ToEntity.Mode} == 4 || ${Me.ToEntity.Mode} == 1
					{
						; already orbiting something
						;This:Activate_AfterBurner
						;return
					}
					else
					{
					Me.ActiveTarget:Orbit[1000]
					}
				}
				while ${Target:First(exists)}
			}
			while ${Asteroids.FieldEmpty} == FALSE
			;EVE:Execute[CmdDronesReturnToBay]
			wait 50
			call Agents.MoveTo ${agentID}
			wait 50
			call Cargo.TransferOreToStationHangar
			wait 50
			call Agents.TurnInMission
		}
		
		
		elseif ${Config.Miner.IceMining}
		{
			call This.WarpToEncounter ${agentID}
			UI:UpdateConsole["Move To Mining Site"]
			while ${Ship.InWarp}
			{
				wait 75
			}
			EVEinvWindow[Inventory]:MakeChildActive[SpecializedOreHold]
			Ship.Drones:LaunchAll
			do
			{	
				
				wait 15
				call Asteroids.UpdateList
				Asteroids.AsteroidList:GetIterator[AsteroidIterator]
				wait 20
				if ${AsteroidIterator.Value.Distance} >= 11000
				{
					Me.ActiveTarget:Orbit[7500]
					wait 50
				}
				if (${Math.Calc[${Me.TargetCount} + ${Me.TargetingCount}]} < 1
				{
					call Asteroids.MissionTargetNext
				}
				wait 20
				wait 50 ${Me.TargetingCount} == 0
				LockedTargets:Clear
				Me:GetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				do
				{
					LockedTargets:Clear
					Me:GetTargets[LockedTargets]
					LockedTargets:GetIterator[Target]
					if ${Ship.Drones.DronesInSpace} == 0
					{
						Ship.Drones:LaunchAll
					}
					if ${Entity[${Target.Value.ID}].Distance} >= 8000
					{
						if !${Me.ToEntity.Mode} == 4 || !${Me.ToEntity.Mode} == 1
						{
							Me.ActiveTarget:Orbit[7500]
							wait 50
						}
					}
					if ${Miner.MinerFull}
					{
						EVE:Execute[CmdDronesReturnToBay]
						wait 50
						call Agents.MoveTo ${agentID}
						wait 50
						call Cargo.TransferOreToStationHangar
						wait 50
						call This.WarpToEncounter ${agentID}
					}
					call Asteroids.UpdateList
					if ${Me.ActiveTarget.Distance} <= 8000
					{
						;EVE:Execute[CmdStopShip]
						;call Ship.ActivateFreeMiningLaser ${Me.ActiveTarget}
						wait 50
						call Ship.ActivateFreeMiningLaser ${Me.ActiveTarget}
					}
					if ${Me.ToEntity.Mode} == 4 || ${Me.ToEntity.Mode} == 1
					{
						; already orbiting something
						;This:Activate_AfterBurner
						;return
					}
					else
					{
					Me.ActiveTarget:Orbit[7500]
					}
				}
				while ${Target:First(exists)}
			}
			while ${Asteroids.FieldEmpty} == FALSE
			
			;while ${Me.TargetedByCount} > 0
			;{
			;	call This.TargetAgressors
			;	wait 50
			;	Ship.Drones:SendDrones
			;	wait 25
			;}
			EVE:Execute[CmdDronesReturnToBay]
			wait 50
			call Agents.MoveTo ${agentID}
			wait 50
			call Cargo.TransferOreToStationHangar
			wait 50
			call Agents.TurnInMission
		}
		
		else
		{
			call This.WarpToEncounter ${agentID}
			UI:UpdateConsole["Move To Mining Site"]
			while ${Ship.InWarp}
			{
				wait 75
			}
		
			Ship.Drones:LaunchAll
			do
			{
				wait 15
				call Asteroids.UpdateList
				wait 20
				if ${AsteroidIterator.Value.Distance} >= 14000
				{
					call Ship.Approach ${AsteroidIterator.Value.ID} 10000
				}
				if (${Math.Calc[${Me.TargetCount} + ${Me.TargetingCount}]} < 1
				{
					call Asteroids.MissionTargetNext
				}
				wait 20
				wait 50 ${Me.TargetingCount} == 0
				LockedTargets:Clear
				Me:GetTargets[LockedTargets]
				LockedTargets:GetIterator[Target]
				do
				{
					if ${Ship.Drones.DronesInSpace} == 0
					{
						Ship.Drones:LaunchAll
					}
					Asteroids.AsteroidList:GetIterator[AsteroidIterator]
					if ${Entity[${Target.Value.ID}].Distance} >= 15000
					{
					call Ship.Approach ${AsteroidIterator.Value.ID} 10000
					}
					if ${Miner.MinerFull}
					{
						EVE:Execute[CmdDronesReturnToBay]
						wait 50
						call Agents.MoveTo ${agentID}
						wait 50
						call Cargo.TransferOreToStationHangar
						wait 50
						call This.WarpToEncounter ${agentID}
					}
					call Asteroids.UpdateList
					if ${Entity[${Target.Value.ID}].Distance} <= 15000
					{
						EVE:Execute[CmdStopShip]
						call Ship.ActivateFreeMiningLaser ${Me.ActiveTarget}
						wait 50
						call Ship.ActivateFreeMiningLaser ${Me.ActiveTarget}
					}
					else
					{
						if ${Entity[${Target.Value.ID}].Distance} >=${Ship.OptimalMiningRange[1]}
						call Ship.Approach ${Me.ActiveTarget} 14000
					}

				}
				while ${Target:Next(exists)}
			}
			while ${Asteroids.FieldEmpty} == FALSE
			EVE:Execute[CmdDronesReturnToBay]
			wait 50
			call Agents.MoveTo ${agentID}
			wait 50
			call Agents.TurnInMission
		}
	}

	function RunCombatMission(int agentID)
	{
		call Ship.ActivateShip "${Config.Missioneer.CombatShip}"
		wait 10
		call This.WarpToEncounter ${agentID}
		wait 50

;       do
;       {
;            EVE:QueryEntities[entityIndex, "TypeID = TYPE_ACCELERATION_GATE"]
;            call Ship.Approach ${entityIndex.Get[1].ID} JUMP_RANGE
;            entityIndex.Get[1]:Activate
;        }
;        while ${entityIndex.Used} == 1

		UI:UpdateConsole["obj_Missions: DEBUG: ${Ship.Type} (${Ship.TypeID})"]
		switch ${Ship.TypeID}
		{
			case TYPE_PUNISHER
				call This.PunisherCombat ${agentID}
				break
			case TYPE_HAWK
				call This.HawkCombat ${agentID}
				break
			case TYPE_KESTREL
				call This.KestrelCombat ${agentID}
				break
			case TYPE_RAVEN
				call This.RavenCombat ${agentID}
				break
			default
				UI:UpdateConsole["obj_Missions: WARNING!  Unknown Ship Type."]
				call This.DefaultCombat ${agentID}
				break
		}

		call This.WarpToHomeBase ${agentID}
		wait 50
		UI:UpdateConsole["obj_Missions: TurnInMission"]
		call Agents.TurnInMission
	}

	function DefaultCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}

	function PunisherCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}

	function RavenCombat(int agentID)
	{
		UI:UpdateConsole["obj_Missions: Paused Script.  Complete mission manually and then run the script."]
		Script:Pause
	}
	function HawkCombat(int agentID)
	{
		wait 100
		while ${This.TargetNPCs} && ${Social.IsSafe}
		{
			This.Combat:SetState
			call This.Combat.ProcessState
			wait 10
		}
	}

	function KestrelCombat(int agentID)
	{
	  variable bool missionComplete = FALSE
	  variable time breakTime

	  while !${missionComplete}
	  {
		 ; wait up to 15 seconds for spawns to appear
		 breakTime:Set[${Time.Timestamp}]
		 breakTime.Second:Inc[15]
		 breakTime:Update

		 while TRUE
		 {
			if ${This.HostileCount} > 0
			{
			   break
			}

			if ${Time.Timestamp} >= ${breakTime.Timestamp}
			{
			   break
			}

			wait 1
		 }

		 if ${This.HostileCount} > 0
		 {
			; wait up to 15 seconds for agro
			breakTime:Set[${Time.Timestamp}]
			breakTime.Second:Inc[15]
			breakTime:Update

			while TRUE
			{
			   if ${Me.TargetedByCount} > 0
			   {
				  break
			   }

			   if ${Time.Timestamp} >= ${breakTime.Timestamp}
			   {
				  break
			   }

			   wait 1
			}

			while ${This.HostileCount} > 0
			{
			   if ${Me.TargetedByCount} > 0 || ${Math.Calc[${Me.TargetingCount}+${Me.TargetCount}]} > 0
			   {
				  call This.TargetAgressors
			   }
			   else
			   {
				  call This.PullTarget
			   }

			   This.Combat:SetState
			   call This.Combat.ProcessState

			   wait 1
			}
		}
		elseif ${This.MissionCache.TypeID[${agentID}]} && ${This.ContainerCount} > 0
		{
			/* loot containers */
		}
		elseif ${This.GatePresent}
		{
			/* activate gate and go to next room */
			call Ship.Approach ${Entity["TypeID = TYPE_ACCELERATION_GATE"].ID} DOCKING_RANGE
			wait 10
			UI:UpdateConsole["Activating Acceleration Gate..."]
			while !${This.WarpEntered}
			{
			   Entity["TypeID = TYPE_ACCELERATION_GATE"]:Activate
			   wait 10
			}
			call Ship.WarpWait
			if ${Return} == 2
			{
			   return
			}
		}
		else
		{
			missionComplete:Set[TRUE]
		}

		wait 1
		}
	}

   function TargetAgressors()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator

	  EVE:QueryEntities[targetIndex, "CategoryID = CATEGORYID_ENTITY"]
	  targetIndex:GetIterator[targetIterator]

	  UI:UpdateConsole["TargetingCount = ${Me.TargetingCount}, TargetCount = ${Me.TargetCount}"]
	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			if ${targetIterator.Value.IsTargetingMe} && \
			   !${targetIterator.Value.BeingTargeted} && \
			   !${targetIterator.Value.IsLockedTarget} && \
			   ${Ship.SafeMaxLockedTargets} > ${Math.Calc[${Me.TargetingCount}+${Me.TargetCount}]}
			{
			   if ${targetIterator.Value.Distance} > ${Ship.OptimalTargetingRange}
			   {
				  Ship:Activate_AfterBurner
				  targetIterator.Value:Approach
				  wait 10
			   }
			   else
			   {
				  EVE:Execute[CmdStopShip]
				  Ship:Deactivate_AfterBurner
				  targetIterator.Value:LockTarget
				  wait 10
			   }
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }
   }

   function PullTarget()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator

	  EVE:QueryEntities[targetIndex, "CategoryID = CATEGORYID_ENTITY"]
	  targetIndex:GetIterator[targetIterator]

	  /* FOR NOW just pull the closest target */
	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			switch ${targetIterator.Value.GroupID}
			{
			   case GROUP_LARGECOLLIDABLEOBJECT
			   case GROUP_LARGECOLLIDABLESHIP
			   case GROUP_LARGECOLLIDABLESTRUCTURE
				  continue

			   default
				  if ${targetIterator.Value.Distance} > ${Ship.OptimalTargetingRange}
				  {
					 Ship:Activate_AfterBurner
					 targetIterator.Value:Approach
				  }
				  else
				  {
					 EVE:Execute[CmdStopShip]
					 Ship:Deactivate_AfterBurner
					 targetIterator.Value:LockTarget
					 wait 10
					 return
				  }
				  break
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }
   }

   member:int HostileCount()
   {
	  variable index:entity targetIndex
	  variable iterator     targetIterator
	  variable int          targetCount = 0

	  EVE:QueryEntities[targetIndex, "CategoryID = CATEGORYID_ENTITY"]
	  targetIndex:GetIterator[targetIterator]

	  if ${targetIterator:First(exists)}
	  {
		 do
		 {
			switch ${targetIterator.Value.GroupID}
			{
			   case GROUP_LARGECOLLIDABLEOBJECT
			   case GROUP_LARGECOLLIDABLESHIP
			   case GROUP_LARGECOLLIDABLESTRUCTURE
				  continue

			   default
				  targetCount:Inc
				  break
			}
		 }
		 while ${targetIterator:Next(exists)}
	  }

	  return ${targetCount}
   }

   member:int ContainerCount()
   {
	  return 0
   }

   member:bool GatePresent()
   {
	  return ${Entity["TypeID = TYPE_ACCELERATION_GATE"](exists)}
   }

	function WarpToEncounter(int agentID)
	{
		variable index:agentmission amIndex
		variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							if ${mbIterator.Value.LocationType.Equal["dungeon"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value.ID}
								return
							}
						}
						while ${mbIterator:Next(exists)}
					}
				}
			}
			while ${amIterator:Next(exists)}
		}
	}

	function WarpToHomeBase(int agentID)
	{
		variable index:agentmission amIndex
		variable index:bookmark mbIndex
		variable iterator amIterator
		variable iterator mbIterator

		EVE:GetAgentMissions[amIndex]
		amIndex:GetIterator[amIterator]

		if ${amIterator:First(exists)}
		{
			do
			{
				if ${amIterator.Value.AgentID} == ${agentID}
				{
					amIterator.Value:GetBookmarks[mbIndex]
					mbIndex:GetIterator[mbIterator]

					if ${mbIterator:First(exists)}
					{
						do
						{
							UI:UpdateConsole["obj_Agents: DEBUG: mbIterator.Value.LocationType = ${mbIterator.Value.LocationType}"]
							if ${mbIterator.Value.LocationType.Equal["agenthomebase"]} || \
							   ${mbIterator.Value.LocationType.Equal["objective"]}
							{
								call Ship.WarpToBookMark ${mbIterator.Value.ID}
								return
							}
						}
						while ${mbIterator:Next(exists)}
					}
				}
			}
			while ${amIterator:Next(exists)}
		}
	}

	member:bool TargetStructures(int agentID)
	{
		variable index:entity Targets
		variable iterator Target
		variable bool HasTargets = FALSE

	  UI:UpdateConsole["DEBUG: TargetStructures"]

		if ${MyShip.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Jammed, cant target..."]
			return TRUE
		}

		EVE:QueryEntities[Targets, "GroupID = GROUP_LARGECOLLIDABLESTRUCTURE"]
		Targets:GetIterator[Target]

		if ${Target:First(exists)}
		{
		   do
		   {
			if ${Me.TargetedByCount} > 0 && ${Target.Value.IsLockedTarget}
			{
				   Target.Value:UnlockTarget
			}
			   elseif ${This.SpecialStructure[${agentID},${Target.Value.Name}]} && \
				 !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
			   {
				  ;variable int OrbitDistance
				  ;OrbitDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
				  ;OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
				  ;Target.Value:Orbit[${OrbitDistance}]
				  variable int KeepAtRangeDistance
				  KeepAtRangeDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
				  KeepAtRangeDistance:Set[${Math.Calc[${KeepAtRangeDistance}*1000]}]
				  Target.Value:KeepAtRange[${KeepAtRangeDistance}]

				   if ${Me.TargetCount} < ${Ship.MaxLockedTargets}
				   {
					   UI:UpdateConsole["Locking ${Target.Value.Name}"]
					   Target.Value:LockTarget
				   }
			   }

			   ; Set the return value so we know we have targets
			   HasTargets:Set[TRUE]
		   }
		   while ${Target:Next(exists)}
	  }

		return ${HasTargets}
	}

	member:bool TargetNPCs()
	{
		variable index:entity Targets
		variable iterator Target
		variable bool HasTargets = FALSE

		if ${MyShip.MaxLockedTargets} == 0
		{
			UI:UpdateConsole["Jammed, cant target..."]
			return TRUE
		}

		EVE:QueryEntities[Targets, "CategoryID = CATEGORYID_ENTITY"]
		Targets:GetIterator[Target]

		if ${Target:First(exists)}
		{
		   do
		   {
			switch ${Target.Value.GroupID}
			{
			   case GROUP_LARGECOLLIDABLEOBJECT
			   case GROUP_LARGECOLLIDABLESHIP
			   case GROUP_LARGECOLLIDABLESTRUCTURE
				  continue

			   default
				  break
			}

			   if !${Target.Value.IsLockedTarget} && !${Target.Value.BeingTargeted}
			   {
				   if ${Me.TargetCount} < ${Ship.MaxLockedTargets}
				   {
					   UI:UpdateConsole["Locking ${Target.Value.Name}"]
					   Target.Value:LockTarget
				   }
			   }

			   ; Set the return value so we know we have targets
			   HasTargets:Set[TRUE]
		   }
		   while ${Target:Next(exists)}
	  }

		if ${HasTargets} && ${Me.ActiveTarget(exists)}
		{
			variable int OrbitDistance
			OrbitDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
			OrbitDistance:Set[${Math.Calc[${OrbitDistance}*1000]}]
			Me.ActiveTarget:Orbit[${OrbitDistance}]
		}

		if ${HasTargets} && ${Me.ActiveTarget(exists)}
		{
			variable int KeepAtRangeDistance
			KeepAtRangeDistance:Set[${Math.Calc[${MyShip.MaxTargetRange}*0.40/1000].Round}]
			KeepAtRangeDistance:Set[${Math.Calc[${KeepAtRangeDistance}*1000]}]
			Me.ActiveTarget:KeepAtRange[${KeepAtRangeDistance}]
		}

		return ${HasTargets}
	}

   member:bool SpecialStructure(int agentID, string name)
   {
	  if ${This.MissionCache.Name[${agentID}](exists)}
	  {
		 if ${This.MissionCache.Name.Equal["avenge a fallen comrade"]} && \
			${name.Equal["habitat"]}
		 {
			return TRUE
		 }
		 ; elseif {...}
		 ; etc...
	  }

	  return FALSE
   }
 }
