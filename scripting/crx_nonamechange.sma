#include <amxmodx>
#include <cromchat>
#include <fakemeta>

#define PLUGIN_VERSION "1.0"

new g_pAdminFlag, g_iFlag

public plugin_init()
{
	register_plugin("No Name Change", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXNoNameChange", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_forward(FM_ClientUserInfoChanged, "OnUserInfoChanged")
	register_dictionary("NoNameChange.txt")
	g_pAdminFlag = register_cvar("nnc_admin_flag", "")
}

public plugin_cfg()
{
	new szFlag[2]
	get_pcvar_string(g_pAdminFlag, szFlag, charsmax(szFlag))
	g_iFlag = read_flags(szFlag)
}

public OnUserInfoChanged(id)
{
	if(g_iFlag && get_user_flags(id) & g_iFlag)
		return FMRES_IGNORED
	
	static const szName[] = "name"
	static szOldName[32], szNewName[32]
	pev(id, pev_netname, szOldName, charsmax(szOldName))
	
	if(szOldName[0])
	{
		get_user_info(id, szName, szNewName, charsmax(szNewName))
		
		if(!equal(szOldName, szNewName))
		{
			set_user_info(id, szName, szOldName)
			CC_SendMessage(id, "%L", id, "NNC_MESSAGE")
			return FMRES_HANDLED
		}
	}
	
	return FMRES_IGNORED
}