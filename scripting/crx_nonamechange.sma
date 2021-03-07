#include <amxmodx>
#include <amxmisc>
#include <cromchat>
#include <fakemeta>
#include <nnc_const>

native cm_update_player_data(id)

new const g_szNatives[][] =
{
	"cm_update_player_data"
}

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

#if !defined MAX_NAME_LENGTH
const MAX_NAME_LENGTH = 32
#endif

new const PLUGIN_VERSION[] = "2.1"
new const INFO_NAME[] = "name"

new const NAME_CHANGE_CMDS[][] = { "amx_nick", "nnc_nick", "amx_name", "nnc_name" }

enum AllowChangeType
{
	AllowChange_Not,
	AllowChange_NoMsg,
	AllowChange_ShowMsg
}

new g_iChanges[MAX_PLAYERS + 1]
new AllowChangeType:g_iAllowChange[MAX_PLAYERS + 1]

new _nnc_admin_flag
new _nnc_max_changes
new _nnc_show_message
new _nnc_dead_immediate
new _nnc_user_name_changed

new _chatmanager

public plugin_init()
{
	register_plugin("No Name Change", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXNoNameChange", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("NoNameChange.txt")

	register_forward(FM_ClientUserInfoChanged, "OnUserInfoChanged")
	
	_nnc_admin_flag     = register_cvar("nnc_admin_flag",     "")
	_nnc_max_changes    = register_cvar("nnc_max_changes",    "0")
	_nnc_show_message   = register_cvar("nnc_show_message",   "1")
	_nnc_dead_immediate = register_cvar("nnc_dead_immediate", "0")

	_nnc_user_name_changed = CreateMultiForward("nnc_user_name_changed", ET_STOP, FP_CELL, FP_STRING, FP_STRING)

	if(LibraryExists("chatmanager", LibType_Library))
	{
		_chatmanager = true
	}

	CC_SetPrefix("&x04[NNC]")
}

public plugin_precache()
{
	for(new i; i < sizeof(NAME_CHANGE_CMDS); i++)
	{
		// Do this here in hope to override other plugins that register the same commands
		register_concmd(NAME_CHANGE_CMDS[i], "Cmd_ChangeName", ADMIN_SLAY, "<player> <new name> -- changes a player's name")
	}
}

public client_putinserver(id)
{
	g_iChanges[id] = 0
	g_iAllowChange[id] = AllowChange_Not
}

public Cmd_ChangeName(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
	{
		return PLUGIN_HANDLED
	}

	new szPlayer[MAX_NAME_LENGTH]
	read_argv(1, szPlayer, charsmax(szPlayer))

	new iPlayer = cmd_target(id, szPlayer, CMDTARGET_ALLOW_SELF|CMDTARGET_OBEY_IMMUNITY)

	if(!iPlayer)
	{
		return PLUGIN_HANDLED
	}

	new szAdminName[MAX_NAME_LENGTH], szOldName[MAX_NAME_LENGTH], szNewName[MAX_NAME_LENGTH]
	get_user_name(id, szAdminName, charsmax(szAdminName))
	get_user_name(iPlayer, szOldName, charsmax(szOldName))
	read_argv(2, szNewName, charsmax(szNewName))

	g_iAllowChange[iPlayer] = AllowChange_NoMsg
	change_name(iPlayer, szNewName)

	if(_chatmanager)
	{
		cm_update_player_data(iPlayer)
	}

	CC_LogMessage(0, _, "%L", LANG_PLAYER, "NNC_ADMIN_CHANGE", szAdminName, szOldName, szNewName)
	return PLUGIN_HANDLED
}

public OnUserInfoChanged(id)
{
	if(!is_user_connected(id))
	{
		return FMRES_IGNORED
	}
	
	static szOldName[MAX_NAME_LENGTH], szNewName[MAX_NAME_LENGTH]
	pev(id, pev_netname, szOldName, charsmax(szOldName))
	
	if(szOldName[0])
	{
		get_user_info(id, INFO_NAME, szNewName, charsmax(szNewName))
		
		if(equal(szOldName, szNewName))
		{
			return FMRES_IGNORED
		}
	}

	if(g_iAllowChange[id] != AllowChange_Not)
	{
		if(g_iAllowChange[id] == AllowChange_ShowMsg)
		{
			write_change_msg(id, szOldName, szNewName)
		}

		g_iAllowChange[id] = AllowChange_Not
		return FMRES_SUPERCEDE
	}

	new iReturn
	ExecuteForward(_nnc_user_name_changed, iReturn, id, szOldName, szNewName)

	switch(iReturn)
	{
		case NNC_BLOCK:
		{
			cant_change(id, szOldName)
			return FMRES_HANDLED
		}
		case NNC_ALLOW:
		{
			return FMRES_IGNORED
		}
	}

	new szFlag[2]
	get_pcvar_string(_nnc_admin_flag, szFlag, charsmax(szFlag))

	new iFlag = read_flags(szFlag)

	if(iFlag && get_user_flags(id) & iFlag)
	{
		return FMRES_IGNORED
	}

	new iMaxChanges = get_pcvar_num(_nnc_max_changes)

	if(g_iChanges[id] >= iMaxChanges)
	{
		cant_change(id, szOldName)
		return FMRES_HANDLED
	}

	g_iChanges[id]++
	
	new iChangesLeft = iMaxChanges - g_iChanges[id]
	CC_SendMessage(id, "%L", id, !iChangesLeft ? "NNC_CHANGE_ZERO" : iChangesLeft == 1 ? "NNC_CHANGE_ONE" : "NNC_CHANGE_MORE", iChangesLeft)

	if(get_pcvar_num(_nnc_dead_immediate) && !is_user_alive(id))
	{
		write_change_msg(id, szOldName, szNewName)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

cant_change(id, const szOldName[])
{
	change_name(id, szOldName)

	if(get_pcvar_num(_nnc_show_message))
	{
		CC_SendMessage(id, "%L", id, "NNC_MESSAGE")
	}
}

change_name(id, const szNewName[])
{
	set_user_info(id, "name", szNewName)
}

write_change_msg(id, const szOldName[], const szNewName[])
{
	static iSayText

	if(!iSayText)
	{
		iSayText = get_user_msgid("SayText")
	}

	message_begin(MSG_BROADCAST, iSayText)
	write_byte(id)
	write_string("#Cstrike_Name_Change")
	write_string(szOldName)
	write_string(szNewName)
	message_end()
}

public plugin_natives()
{
	register_library("nnc")
	set_native_filter("native_filter")

	register_native("nnc_change_user_name",      "_nnc_change_user_name")
	register_native("nnc_get_max_changes",       "_nnc_get_max_changes")
	register_native("nnc_get_user_changes_left", "_nnc_get_user_changes_left")
	register_native("nnc_get_user_changes",      "_nnc_get_user_changes")
	register_native("nnc_set_user_changes",      "_nnc_set_user_changes")
}

public native_filter(const szNative[], id, iTrap)
{
	if(!iTrap)
	{
		static i

		for(i = 0; i < sizeof(g_szNatives); i++)
		{
			if(equal(szNative, g_szNatives[i]))
			{
				return PLUGIN_HANDLED
			}
		}
	}

	return PLUGIN_CONTINUE
}

public _nnc_change_user_name()
{
	new id = get_param(1)
	g_iAllowChange[id] = get_param(3) != 0 ? AllowChange_ShowMsg : AllowChange_NoMsg

	new szNewName[MAX_NAME_LENGTH]
	get_string(2, szNewName, charsmax(szNewName))
	change_name(id, szNewName)
}
	
public _nnc_get_max_changes()
{
	return get_pcvar_num(_nnc_max_changes)
}

public _nnc_get_user_changes()
{
	return g_iChanges[get_param(1)]
}

public _nnc_set_user_changes()
{
	g_iChanges[get_param(1)] = get_param(2)
}

public _nnc_get_user_changes_left()
{
	return get_pcvar_num(_nnc_max_changes) - g_iChanges[get_param(1)]
}