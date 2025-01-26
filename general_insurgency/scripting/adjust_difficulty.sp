#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include "INSExtendAPI"
#include "utility_api"

#define PLUGIN_NAME ""
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION ""
#define PLUGIN_URL ""

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

ConVar g_cvar_CA_least_need;

public void OnPluginStart()
{
	g_cvar_CA_least_need = CreateConVar("sm_dynamic_difficulty_adjustment_ca_least_need", "3", "激活conter attack的最少人数");
	HookEventEx("player_team", PlayerTeamPost, EventHookMode_Post);
}

ConVar g_cvar_max_enemy_num;
ConVar g_cvar_infinite_on_ca;

public void OnAllPluginsLoaded()
{
	g_cvar_max_enemy_num = FindConVar("sm_custom_enemy_max_enemy_num");
	if (null == g_cvar_max_enemy_num) SetFailStateNotFindConvar(PLUGIN_NAME, g_cvar_max_enemy_num);
	g_cvar_infinite_on_ca = FindConVar("sm_custom_enemy_infinite_on_ca");
	if (null == g_cvar_infinite_on_ca) SetFailStateNotFindConvar(PLUGIN_NAME, g_cvar_infinite_on_ca);
}

ConVar g_cvar_gamemode;
ConVar g_cvar_checkpoint_counterattack_disable = null;
ConVar g_cvar_checkpoint_counterattack_duration = null;
ConVar g_cvar_checkpoint_counterattack_duration_finale = null;
ConVar g_cvar_capture_time;

public void OnMapStart()
{
	g_cvar_gamemode = FindConVar("mp_gamemode");
	if (null == g_cvar_gamemode) SetFailStateNotFindConvar(PLUGIN_NAME, g_cvar_gamemode);

	g_cvar_checkpoint_counterattack_disable = FindConVar("mp_checkpoint_counterattack_disable");
	if (null == g_cvar_checkpoint_counterattack_disable) SetFailStateNotFindConvar(PLUGIN_NAME, g_cvar_checkpoint_counterattack_disable);

	g_cvar_checkpoint_counterattack_duration = FindConVar("mp_checkpoint_counterattack_duration");
	if (null == g_cvar_checkpoint_counterattack_duration) SetFailStateNotFindConvar(PLUGIN_NAME, g_cvar_checkpoint_counterattack_duration);

	g_cvar_checkpoint_counterattack_duration_finale = FindConVar("mp_checkpoint_counterattack_duration_finale");
	if (null == g_cvar_checkpoint_counterattack_duration_finale) SetFailStateNotFindConvar(PLUGIN_NAME, g_cvar_checkpoint_counterattack_duration_finale);
	
	g_cvar_capture_time = FindConVar("mp_cp_capture_time");
	int flags = GetConVarFlags(g_cvar_capture_time);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(g_cvar_capture_time, flags);

	AdjustDifficulty();
}

public void OnClientConnected(int client)
{
	AdjustDifficulty();
}

public void OnClientDisconnect_Post(int client)
{
	AdjustDifficulty();
}

Action PlayerTeamPost(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("isbot")) return Plugin_Continue;

	AdjustDifficulty();
	return Plugin_Continue;
}

enum struct CheckpointDifficultyMapItem
{
	int security_cnt;
	int capture_time;
	int ca_duration;
	int ca_duration_finale;
	int max_enemy_num;
	bool infinite_on_ca;
}
enum struct OutpostDiffucultyMapItem
{
	int security_cnt;
	int max_enemy_num;
}

CheckpointDifficultyMapItem g_checkpoint_difficulty [] = {
	{0, 0, 0, 0, 0, true},
	{1, 20,	90, 90, 30, true},
	{2, 21, 90, 90, 60, true},
	{3, 22,	90, 90, 90, true},
	{4, 23, 90, 90, 120, true},
	{5, 24, 90, 90, 150, true},
	{6, 25, 90, 90, 180, true},
	{7, 26,	90, 90, 210, true},
	{8, 27, 90, 90, 240, true},
	{9, 28, 90, 90, 240, true},
	{10, 29, 90, 90, 240, true},
	{11, 30, 90, 90, 240, true},
	{12, 31, 90, 90, 240, true},
};

OutpostDiffucultyMapItem g_outpost_difficulty [] = 
{
	{0, 0},
	{1, 8},
	{2, 16},
	{3, 24},
	{4, 32},
	{5, 40},
	{6, 48},
	{7, 56},
	{8, 64},
	{9, 72},
	{10, 80},
	{11, 88},
	{12, 96},
};

void AdjustDifficulty()
{
	int security_cnt = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}

		if (IsFakeClient(i))
		{
			continue;
		}

		security_cnt += 1;
	}

	char gamemode[32];
	g_cvar_gamemode.GetString(gamemode, sizeof(gamemode));

	if (StrEqual(gamemode, "checkpoint"))
	{
		AdjustCheckpointDifficulty(security_cnt);
	}
	else if (StrEqual(gamemode, "outpost"))
	{
		AdjustOutpostDifficulty(security_cnt);
	}

	//PrintToChatAll("请各位玩家注意，因为玩家数量的发生变化(%d人)，游戏难度已经改变", security_cnt);
}

void AdjustCheckpointDifficulty(int security_cnt)
{
	g_cvar_checkpoint_counterattack_disable.IntValue = (security_cnt >= g_cvar_CA_least_need.IntValue)?(0):(1);

	int index = (security_cnt > 8)?(8):(security_cnt);
	g_cvar_capture_time.IntValue = g_checkpoint_difficulty[index].capture_time;
	g_cvar_checkpoint_counterattack_duration.IntValue = g_checkpoint_difficulty[index].ca_duration;
	g_cvar_checkpoint_counterattack_duration_finale.IntValue = g_checkpoint_difficulty[index].ca_duration_finale;
	g_cvar_max_enemy_num.IntValue = g_checkpoint_difficulty[index].max_enemy_num;
	g_cvar_infinite_on_ca.BoolValue = g_checkpoint_difficulty[index].infinite_on_ca;
}

void AdjustOutpostDifficulty(int security_cnt)
{
	int index = (security_cnt > 8)?(8):(security_cnt);
	g_cvar_max_enemy_num.IntValue = g_outpost_difficulty[index].max_enemy_num;
}