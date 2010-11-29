/*
	The missioneer object

	The obj_Missioneer object is the main bot module for the
	mission running bot.

	-- GliderPro
*/

objectdef obj_Missioneer
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string CurrentState
	variable time NextPulse
	variable int PulseIntervalInSeconds = 2

	method Initialize()
	{
		EVEBot.BehaviorList:Insert["Missioneer"]
		Logger:Log["obj_Missioneer: Initialized", LOG_MINOR]
	}

	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			This:SetState
    		This.NextPulse:Set[${Time.Timestamp}]
    		This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
    		This.NextPulse:Update
		}
	}

	method Shutdown()
	{
	}

	/* NOTE: The order of these if statements is important!! */
	method SetState()
	{
		if ${Config.Common.Behavior.NotEqual[Missioneer]}
		{
			return
		}

		if ${Defense.Hiding}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${EVEBot.ReturnToStation} && ${Me.InSpace}
		{
			This.CurrentState:Set["ABORT"]
		}
		elseif ${EVEBot.ReturnToStation}
		{
			This.CurrentState:Set["IDLE"]
		}
		elseif ${This.CurentState.Equal["RUN_MISSION"]}
		{
			return
		}
		elseif ${Agents.HaveMission}
		{
			This.CurrentState:Set["RUN_MISSION"]
		}
		else
		{
			This.CurrentState:Set["GET_MISSION"]
		}
	}

	function ProcessState()
	{
		if ${Config.Common.Behavior.NotEqual[Missioneer]}
		{
			return
		}

		switch ${This.CurrentState}
		{
			case ABORT
				call Station.Dock
				break
			case GET_MISSION
				Agents:PickAgent
				call Agents.MoveTo
				call Agents.RequestMission
				break
			case RUN_MISSION
				call Missions.RunMission
				break
			case IDLE
				break
		}
	}
}

