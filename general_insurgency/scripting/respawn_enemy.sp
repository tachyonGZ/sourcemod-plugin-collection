#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <vectorhint>
#include "INSExtendAPI"

#include "respawn_enemy"

#define PLUGIN_NAME "Respawn Enemy"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "Respawn Enemy"
#define PLUGIN_VERSION ""
#define PLUGIN_URL ""

#define HINT_X_INDEX 1
#define HINT_Y_INDEX 0

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

GlobalForward g_fwdOnGameEnemyStatusUpdate;
GlobalForward g_fwdOnEnemyStatusStartPush;
GlobalForward g_fwdOnEnemyStatusEndPush;

ConVar g_cvar_adjust;
ConVar g_cvar_adjust_distance;

StringMap hSpawnZone;
StringMapSnapshot hSpawnZoneKeys;

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	RegPluginLibrary("plugin_respawn_bot_2");
	return APLRes_Success;
}

ConVar g_cvar_respawn_dealy;
ConVar g_cvar_respawn_dealy_on_ca;
ConVar g_cvar_max_enemy_num;
ConVar g_cvar_infinite_on_ca;

public void OnPluginStart()
{
	g_fwdOnGameEnemyStatusUpdate = CreateGlobalForward("on_game_enemy_status_update", ET_Ignore, Param_Cell, Param_Cell);
	g_fwdOnEnemyStatusStartPush = CreateGlobalForward("on_enemy_status_start_push", ET_Ignore);
	g_fwdOnEnemyStatusEndPush = CreateGlobalForward("on_enemy_status_end_push", ET_Ignore);

	g_cvar_adjust = CreateConVar("sm_botrespawn_adjust", "1", "Adjust spawn location to where player can't see.", FCVAR_NONE);

	g_cvar_adjust_distance = CreateConVar("sm_botrespawn_adjust_distance", "16", "Adjust spawn location when someone close enough (Include teams)", FCVAR_NONE, true, 50.0);
	g_cvar_max_enemy_num = CreateConVar("sm_custom_enemy_max_enemy_num", "0", "Max enemy num", FCVAR_NONE);
	g_cvar_infinite_on_ca = CreateConVar("sm_custom_enemy_infinite_on_ca", "1", "Whether enemy infinite respawn on ca", FCVAR_NONE);

	g_cvar_respawn_dealy = CreateConVar("sm_custom_enemy_respawn_dealy", "2", "How many seconds wait before spawn for insurgent, 0 is disable delay", FCVAR_NONE);
	g_cvar_respawn_dealy_on_ca = CreateConVar("sm_custom_enemy_respawn_dealy_on_ca", "4", "How many seconds wait before spawn for insurgent, 0 is disable delay", FCVAR_NONE);
	
	HookEventEx("player_death", PlayerDeathPost, EventHookMode_Post);
	HookEventEx("round_start", 	RoundStartPost, EventHookMode_PostNoCopy);
	HookEventEx("round_end", 	RoundEndPost, EventHookMode_PostNoCopy);
	HookEventEx("round_begin", 	RoundBeginPost, EventHookMode_PostNoCopy);
	HookEventEx("controlpoint_captured", ControlpointCapturedPost, EventHookMode_PostNoCopy);
	HookEventEx("object_destroyed", ObjectDestroyedPost, EventHookMode_PostNoCopy);

	hSpawnZone = new StringMap();
	hSpawnZoneKeys = hSpawnZone.Snapshot();
	BuildSpawnZoneList();

	VectorHint_AddHint(HINT_X_INDEX, HINT_Y_INDEX);
}

#define SND_CLEAN "ui/sfx/insurgent_khali.wav"

public void OnMapStart()
{
	Call_StartForward(g_fwdOnEnemyStatusStartPush);
	if (SP_ERROR_NONE != Call_Finish())
	{
		SetFailState("开始回调失败: g_fwdOnEnemyStatusStartPush");
	}

	BuildSpawnZoneList();

	PrecacheSound(SND_CLEAN);
}

public void OnMapEnd()
{
	Call_StartForward(g_fwdOnEnemyStatusEndPush);
	if (SP_ERROR_NONE != Call_Finish())
	{
		SetFailState("开始回调失败: g_fwdOnEnemyStatusEndPush");
	}
}

EnemyManager g_enemy_manager;

stock void push_on_game_enemy_status_update(bool bIsCounterAttack, int nEnemyCount)
{
	Call_StartForward(g_fwdOnGameEnemyStatusUpdate);
	Call_PushCell(bIsCounterAttack);
	Call_PushCell(nEnemyCount);
	if (SP_ERROR_NONE != Call_Finish())
	{
		SetFailState("推送回调函数g_fwdOnGameEnemyStatusUpdate失败");
	}
}

Action RoundBeginPost(Event event, const char[] name, bool dontBroadcast)
{
	g_enemy_manager.SetRemainingNum(g_cvar_max_enemy_num.IntValue);
	return Plugin_Continue;
}

Action RoundStartPost(Event event, const char[] name, bool dontBroadcast)
{
	g_enemy_manager.SetRemainingNum(g_cvar_max_enemy_num.IntValue);
	return Plugin_Continue;
}

Action RoundEndPost(Event event, const char[] name, bool dontBroadcast)
{
	g_enemy_manager.StopWaittingRespawnAll();

	for (int client = 1; client <= MaxClients; client++)
	{
		VectorHint_HideHint(HINT_X_INDEX, HINT_Y_INDEX, client);
	}
	return Plugin_Continue;
}

Action ControlpointCapturedPost(Handle event, const char[] name, bool dontBroadcast)
{
	g_enemy_manager.SetRemainingNum(g_cvar_max_enemy_num.IntValue);
	return Plugin_Continue;
}

Action ObjectDestroyedPost(Handle event, const char[] name, bool dontBroadcast)
{
	g_enemy_manager.SetRemainingNum(g_cvar_max_enemy_num.IntValue);
	return Plugin_Continue;
}

Action PlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsClientInGame(client) || TEAM_INSURGENT != GetClientTeam(client))
	{
		return Plugin_Continue;
	}
	g_enemy_manager.WaitForRespawn(client);
	return Plugin_Continue;
}

void AdjustEnemySpawnLocation(int enemy, float location[3])
{
	TeleportEntity(enemy, location, NULL_VECTOR, NULL_VECTOR);
}

bool FixSpawnPoint(int team, float pos[3])
{
	int cp = get_active_push_point_index();
	char key[4];
	ArrayList list;
	Format(key, sizeof(key), "%s%d", ((team == TEAM_SECURITY) ? "S" : "I"), cp);
	if (hSpawnZone.GetValue(key, list))
	{
		for(int i = 0; i < list.Length; ++i)
		{
			GetEntPropVector(list.Get(i), Prop_Send, "m_vecOrigin", pos);
			if (!IsPosCloseToPlayer(pos))
			{
				return true;
			}
		}
	}

	Format(key, sizeof(key), "%s%d", ((team == TEAM_SECURITY) ? "S" : "I"), cp - 1);
	if (hSpawnZone.GetValue(key, list))
	{
		if (0 == list.Length)
		{
			return false;
		}

		int i = GetRandomInt(1, list.Length) - 1;
		GetEntPropVector(list.Get(i), Prop_Send, "m_vecOrigin", pos);
		/*
		for(int i = 0; i < list.Length; ++i)
		{
			GetEntPropVector(list.Get(i), Prop_Send, "m_vecOrigin", pos);
			if (!IsPosCloseToPlayer(pos))
			{
				return true;
			}
		}
		*/
	}

	return false;
}

bool IsPosCloseToPlayer(float pos[3])
{
	float distance_square = Pow(g_cvar_adjust_distance.FloatValue, 2.0);
	for(int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SECURITY)
		{
			continue;
		}

		if(IsPosCloseToClient(pos, i, distance_square))
		{
			return true;
		}
	}

	return false;
}



bool IsPosCloseToClient(float pos[3], int client, float distance_square)
{
	float client_pos[3];
	GetClientAbsOrigin(client, client_pos);
	return GetVectorDistance(pos, client_pos, true) <= distance_square;
}

/*

bool EnemyInSightOrClose(int client, float pos[3]) {
	int team = GetClientTeam(client);
	int eteam = (team == TEAM_SECURITY) ? TEAM_INSURGENT : TEAM_SECURITY;
	float minDist = Pow(g_cvar_adjust_distance.FloatValue, 2.0);
	float org[3];
	for(int i = 1; i <= MaxClients; ++i) {
		if (i != client && IsClientInGame(i) && IsPlayerAlive(i)) {
			GetClientEyePosition(i, org);
			if (GetVectorDistance(pos, org, true) <= minDist) {
				return true;
			}

			if (GetClientTeam(i) == eteam) {
				if (NothingBetweenClient(client, i, pos, org)) {
					return true;
				}
			}
		}
	}

	return false;
}
bool NothingBetweenClient(int client1, int client2, float c1Vec[3], float c2Vec[3]) {
	Handle tr = TR_TraceRayFilterEx(c1Vec, c2Vec, MASK_PLAYERSOLID, RayType_EndPoint, Filter_Caller, client1);
	if (TR_DidHit(tr)) {
		if (TR_GetEntityIndex(tr) == client2) {
			CloseHandle(tr);
			return true;
		}

		CloseHandle(tr);
		return false;
	}
	CloseHandle(tr);
	return true;
}

bool Filter_Caller(int entity, int contentsMask, int client) {
	if (entity == client) {
		return false;
	}

	return true;
}
*/
int FindSpawnZone(int spawn_point) {
	Address p_spawn_zone = Address_Null;
	float origin[3];
	GetEntPropVector(spawn_point, Prop_Data, "m_vecAbsOrigin", origin);
	//SDKCall(fPointInSpawnZone, origin, spawn_point, pSpawnZone);
	CINSSpawnZone_PointInSpawnZone(origin, spawn_point, p_spawn_zone);
	if (p_spawn_zone == Address_Null) {
		return -1;
	}
	//return SDKCall(fGetBaseEntity, p_spawn_zone);
	return GetBaseEntityByAddress(p_spawn_zone);
}

stock void BuildSpawnZoneList()
{
	ArrayList listIns;
	ArrayList listSec;
	char key[4];
	for(int i = 0; i < hSpawnZoneKeys.Length; ++i) {
		hSpawnZoneKeys.GetKey(i, key, sizeof(key));
		if (hSpawnZone.GetValue(key, listIns)) {
			delete listIns;
		}
	}
	hSpawnZone.Clear();

	int objective = FindEntityByClassname(-1, "ins_objective_resource");
	if (objective == -1)
		return;

	int numOfSpawnZone = GetEntProp(objective, Prop_Send, "m_iNumControlPoints");
	for(int i = 0; i <= numOfSpawnZone; ++i)
	{
		//SDKCall(fToggleSpawnZone, i, false);
		CINSRules_ToggleSpawnZone(i, false);
	}

	int point = -1;
	int zone = -1;
	int team = 1;
	for(int i = 0; i <= numOfSpawnZone; ++i)
	{
		//SDKCall(fToggleSpawnZone, i, true);
		CINSRules_ToggleSpawnZone(i, false);
		listIns = new ArrayList();
		listSec = new ArrayList();

		point = FindEntityByClassname(-1, "ins_spawnpoint");
		while(point != -1)
		{
			zone = FindSpawnZone(point);
			if (zone != -1)
			{
				team = GetEntProp(point, Prop_Send, "m_iTeamNum");
				float pos[3];
				GetEntPropVector(point, Prop_Send, "m_vecOrigin", pos);
				if (team == TEAM_SECURITY)
				{
					listSec.Push(point);
				}
				else if (team == TEAM_INSURGENT)
				{
					listIns.Push(point);
				}
			}
			point = FindEntityByClassname(point, "ins_spawnpoint");
		}

		Format(key, sizeof(key), "I%d", i);
		hSpawnZone.SetValue(key, listIns, true);
		Format(key, sizeof(key), "S%d", i);
		hSpawnZone.SetValue(key, listSec, true);

		CINSRules_ToggleSpawnZone(i, false);
	}
	
	hSpawnZoneKeys = hSpawnZone.Snapshot();
	CINSRules_ToggleSpawnZone(get_active_push_point_index(), true);
}

enum struct EnemyManager
{
	Handle respawn_timer[MAXPLAYERS + 1];

	int remaining_num;

	void Respawn(int client)
	{
		CINSPLAYER_force_respawn(client);
	}

	void WaitForRespawn(int client)
	{
		bool IsInfiniteRespawn = (CINSRules_IsCounterAttack() && g_cvar_infinite_on_ca.BoolValue);

		if (!IsInfiniteRespawn && this.remaining_num < 0)
		{
			return;
		}

		this.remaining_num -= 1;
		
		if (0 == this.remaining_num)
		{
			
		}

		float interval = (CINSRules_IsCounterAttack()) ? g_cvar_respawn_dealy_on_ca.FloatValue : g_cvar_respawn_dealy.FloatValue;

		if (this.respawn_timer[client] != INVALID_HANDLE)
		{
			//KillTimer(this.respawn_timer[client]);
		}

		this.respawn_timer[client] = CreateTimer(interval, RespawnTimer, client, TIMER_REPEAT);

		this.UpdateHint();
	}

	void StopWaittingRespawnAll()
	{
		for (int i = 0; i < MAXPLAYERS + 1; i++)
		{
			if (this.respawn_timer[i] != INVALID_HANDLE)
			{
				//KillTimer(this.respawn_timer[i]);
				this.respawn_timer[i] = INVALID_HANDLE;
			}
		}
	}

	void SetRemainingNum(int remaining_num)
	{
		this.remaining_num = remaining_num;
		this.UpdateHint();
	}

	void UpdateHint()
	{
		static char hint[64];
		if (CINSRules_IsCounterAttack() && g_cvar_infinite_on_ca.BoolValue)
		{
			FormatEx(hint, sizeof(hint), "敌方正在发起大规模反攻");
		}
		else
		{
			FormatEx(hint, sizeof(hint), "敌方剩余兵力 %d", this.remaining_num);
		}

		for (int client = 1; client <= MaxClients; client++)
		{
			if(!IsClientInGame(client) || IsFakeClient(client))
			{
				continue;
			}

			VectorHint_SetHint(HINT_X_INDEX, HINT_Y_INDEX, client, hint);
		}
	}
}

Action RespawnTimer(Handle timer, int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_INSURGENT || IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	float pos[3];
	if (g_cvar_adjust.BoolValue)
	{
		if(!FixSpawnPoint(TEAM_INSURGENT, pos))
		{
			// fix spawn point fail;
			return Plugin_Continue;
		}
	}

	g_enemy_manager.Respawn(client);

	if (g_cvar_adjust.BoolValue)
	{
		AdjustEnemySpawnLocation(client, pos);
	}

	return Plugin_Stop;
}