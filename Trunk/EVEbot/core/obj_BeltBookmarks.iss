/*
	Belt Bookmark Class

	Belt-bookmark access.  Inherits obj_Bookmark

	-- CyberTech

*/

objectdef obj_BeltBookmarks inherits obj_Bookmark
{
	variable string SVN_REVISION = "$Rev$"
	variable int Version
	variable string LogPrefix
	variable set EmptyBelts

	method Initialize()
	{
		LogPrefix:Set["obj_BeltBookmarks(${This.ObjectName})"]
		This:Reset
		Logger:Log["${LogPrefix}: Initialized"]
	}

	method Reset()
	{
		; TODO - Check mode, use ratter prefix, hauler prefix, etc.
		if ${Config.Miner.IceMining}
		{
			This[parent]:Reset["${Config.Labels.IceBeltPrefix}"]
		}
		else
		{
			This[parent]:Reset["${Config.Labels.OreBeltPrefix}"]
		}
		Logger:Log["${LogPrefix}: Found ${Bookmarks.Used} bookmarks in this system"]
	}

	; Checks the belt name against the empty belt list.
	member IsBeltEmpty(string BeltName)
	{
		if ${This.EmptyBelts.Contains["${BeltName}"]}
		{
			Logger:Log["${LogPrefix}:IsBeltEmpty - ${BeltName} - TRUE", LOG_DEBUG]
			return TRUE
		}
		return FALSE
	}

	; Adds the named belt to the empty belt list
	method MarkBeltEmpty(string BeltName)
	{
		EmptyBelts:Add["${BeltName}"]
		Logger:Log["${LogPrefix}: Excluding empty belt ${BeltName}"]
	}

	member:bool AtBelt()
	{
		return ${This[parent].AtBookmark}
	}
}