#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#include "INSExtendAPI"

#define PLUGIN_NAME "Override Win Condition"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "Override Win Condition"
#define PLUGIN_VERSION ""
#define PLUGIN_URL ""

public Plugin myinfo = {
	name= PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

DynamicHook g_dhkCheckWinConditions;

public void OnPluginStart()
{
	
	g_dhkCheckWinConditions = new DynamicHook(248, HookType_GameRules, ReturnType_Int, ThisPointer_Ignore);
	g_dhkCheckWinConditions.AddParam(HookParamType_Bool);
	g_dhkCheckWinConditions.AddParam(HookParamType_Bool);
}

public void OnPluginEnd()
{
	if (g_dhkCheckWinConditions != null) delete g_dhkCheckWinConditions;
}

public void OnMapStart()
{

	if (INVALID_HOOK_ID == g_dhkCheckWinConditions.HookGamerules(Hook_Pre, DHOOK_PRE_check_win_conditions))
	{
		SetFailState("g_hCheckWinConditions");
	}
}

static MRESReturn DHOOK_PRE_check_win_conditions(Handle hReturn, DHookParam hParams)
{
	int sec_team_entity = GetTeamEntity(TEAM_SECURITY);
	int alives = CTeam_GetAliveMembers(sec_team_entity);

	/*
	int livesCnt = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}

		if (GetClientTeam(i) != 2)
		{
			continue;
		}

		livesCnt += 1;
	}

	PrintToServer("HOOK_POST_check_win_conditions team 2 livesCnt:%d", livesCnt);
	
	*/

	if (alives <= 0)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
		//return MRES_Override;
	}

	return MRES_Ignored;
}