/*
	EVEBot class

	Object to contain miscellaneous helper methods and members that don't properly belong elsewhere.

	-- CyberTech

*/

objectdef obj_EVEBot
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version

	variable bool ReturnToStation = FALSE
	variable bool _Paused = FALSE
	variable time NextPulse
	variable int PulseIntervalInSeconds = 4
	variable int LastSessionFrame
	variable bool LastSessionResult
	variable index:string Threads

	variable index:string BehaviorList
	variable iterator Behaviors

	; Cached static items
	variable int CharID
	method Initialize()
	{
		This:SetVersion
		Event[EVENT_ONFRAME]:AttachAtom[This:Pulse]
		This.CharID:Set[${Me.CharID}]
		BehaviorList:GetIterator[Behaviors]

		Logger:Log["obj_EVEBot: Initialized", LOG_MINOR]
	}

	method Shutdown()
	{
		Event[EVENT_ONFRAME]:DetachAtom[This:Pulse]
	}

	method EndBot()
	{
		variable int i
		Logger:Log["EVEBot shutting down..."]
		for (i:Set[1]; ${i} <= ${Threads.Used}; i:Inc)
		{
			Logger:Log[" Stopping ${Threads.Get[${i}]} thread..."]
			endscript ${Threads.Get[${i}]}
		}
		Logger:Log["Finished"]
		endscript ${Script.Filename}
	}

	method Pulse()
	{
	    if ${Time.Timestamp} >= ${This.NextPulse.Timestamp}
		{
			if !${This.SessionValid}
			{
				return
			}

			; TODO this doesn't disable rendering if it's not forground and disablescreenwhenbackgrounded = false
			if ${Display.Foreground}
			{
				if ${Config.Common.DisableUI}
				{
					if ${EVE.IsUIDisplayOn}
					{
						EVE:ToggleUIDisplay
						Logger:Log["Disabling UI Rendering"]
					}
				}
				elseif !${EVE.IsUIDisplayOn}
				{
					EVE:ToggleUIDisplay
					Logger:Log["Enabling UI Rendering"]
				}

				if ${Config.Common.Disable3D}
				{
					if ${EVE.Is3DDisplayOn}
					{
						EVE:Toggle3DDisplay
						Logger:Log["Disabling 3D Rendering"]
					}
				}
				elseif !${EVE.Is3DDisplayOn}
				{
					EVE:Toggle3DDisplay
					Logger:Log["Enabling 3D Rendering"]
				}
			}
			elseif ${Config.Common.DisableScreenWhenBackgrounded}
			{
				if ${EVE.IsUIDisplayOn}
				{
					EVE:ToggleUIDisplay
					Logger:Log["Background EVE: Disabling UI Rendering"]
				}
				if ${EVE.Is3DDisplayOn}
				{
					EVE:Toggle3DDisplay
					Logger:Log["Background EVE: Disabling 3D Rendering"]
				}
			}

			; This is processed here rather than in the obj_Fleet pulse to avoid timing issues closing the invite.
			Fleet:ProcessInvitations

			if !${This._Paused}
			{
				EVE:CloseAllMessageBoxes
				EVE:CloseAllChatInvites

				/*
					TODO
						[15:52] <CyberTechWork> the downtime check could be massively optimized
						[15:52] <CyberTechWork> by calcing how long till downtime and setting a timed event to call back
						[15:52] <CyberTechWork> don't know why we didn't think of that in the first place
				*/
				if !${This.ReturnToStation} && ${Me(exists)}
				{
					if ( ${This.GameHour} == 10 && \
						( ${This.GameMinute} >= 50 && ${This.GameMinute} <= 57) )
					{
						Logger:Log["EVE downtime approaching, pausing operations", LOG_CRITICAL]
						This.ReturnToStation:Set[TRUE]
					}
					else
					{
						variable int Hours = ${Math.Calc[(${Script.RunningTime}/1000/60/60)%60].Int}

						;;; Logger:Log["DEBUG: ${Config.Common.MaxRuntime} ${Hours}"]
						if ${Config.Common.MaxRuntime} > 0 && ${Config.Common.MaxRuntime} <= ${Hours}
						{
							Logger:Log["Maximum runtime exceeded, pausing operations", LOG_CRITICAL]
							This.ReturnToStation:Set[TRUE]
						}
					}
				}

				if ${This.ReturnToStation} && ${Me(exists)}
				{
					if (${This.GameHour} == 10 && ${This.GameMinute} >= 58)
					{
						Logger:Log["EVE downtime approaching - Quitting Eve", LOG_CRITICAL]
						EVE:Execute[CmdQuitGame]
					}
				}

				if ${This.Behaviors:First(exists)}
				do
				{
					if ${This.Behaviors.Value(exists)}
					{
						${This.Behaviors.Value}:Pulse
					}
				}
				while ${This.Behaviors:Next(exists)}

			}

			This.NextPulse:Set[${Time.Timestamp}]
			This.NextPulse.Second:Inc[${This.PulseIntervalInSeconds}]
			This.NextPulse:Update
		}
	}

	member:bool SessionValid()
	{
		if ${This.LastSessionFrame} == ${Script.RunningTime}
		{
			return ${This.LastSessionResult}
		}

		if ${Me.InSpace} || ${Me.InStation}
		{
			This.LastSessionFrame:Set[${Script.RunningTime}]
			This.LastSessionResult:Set[TRUE]
			return TRUE
		}

		This.LastSessionFrame:Set[${Script.RunningTime}]
		This.LastSessionResult:Set[FALSE]
		return FALSE
	}

	member:bool Paused()
	{
		if ${This._Paused} || \
			${Script.Paused}
		{
			return TRUE
		}

		if !${This.SessionValid}
		{
			return TRUE
		}

		return FALSE
	}

	method Pause(string ErrMsg)
	{
		Logger:Log["${ErrMsg}", LOG_CRITICAL]
		This._Paused:Set[TRUE]
	}

	method Resume()
	{
		Logger:Log["Resumed", LOG_CRITICAL]
		This._Paused:Set[FALSE]
		Script:Resume
	}

	method SetVersion(int Version=${VersionNum})
	{
		if ${APP_HEADURL.Find["EVEBot/branches/stable"]}
		{
			AppVersion:Set["${APP_NAME} Stable Revision ${VersionNum}"]
		}
		else
		{
			AppVersion:Set["${APP_NAME} Dev Revision ${VersionNum}"]
		}
	}

	member:int GameHour()
	{
		variable string HourStr = ${EVETime.Time}
		variable string Hour = 00

		if ${HourStr(exists)}
		{
			 Hour:Set[${HourStr.Token[1, :]}]
		}
		return ${Hour}
	}

	member:int GameMinute()
	{
		variable string MinuteStr = ${EVETime.Time}
		variable string Minute = 18

		if ${MinuteStr(exists)}
		{
			 Minute:Set[${MinuteStr.Token[2, :]}]
		}
		return ${Minute}
	}

	member:string MetersToKM_Str(float64 Meters)
	{
		if ${Meters(exists)} && ${Meters} > 0
		{
			return "${Math.Calc[${Meters} / 1000].Centi}km"
		}
		else
		{
			return "0km"
		}
	}

	member:string ISK_To_Str(float64 Total)
	{
		if ${Total(exists)}
		{
			if ${Total} > 1000000000
			{
				return "${Math.Calc[${Total}/100000000].Precision[3]}b isk"
			}
			elseif ${Total} > 1000000
			{
				return "${Math.Calc[${Total}/1000000].Precision[2]}m isk"
			}
			elseif ${Total} > 1000
			{
				return "${Math.Calc[${Total}/1000].Round}k isk"
			}
			else
			{
				return "${Total.Round} isk"
			}
		}

		return "0 isk"
	}

	member Runtime()
	{
		/* TODO - this is expensive (4-5fps for me), replace with something better -- CyberTech */
		DeclareVariable RunTime float ${Math.Calc[${Script.RunningTime}/1000/60]}

		DeclareVariable Hours string ${Math.Calc[(${RunTime}/60)%60].Int.LeadingZeroes[2]}
		DeclareVariable Minutes string ${Math.Calc[${RunTime}%60].Int.LeadingZeroes[2]}
		DeclareVariable Seconds string ${Math.Calc[(${RunTime}*60)%60].Int.LeadingZeroes[2]}

		return "${Hours}:${Minutes}:${Seconds}"
	}
}
