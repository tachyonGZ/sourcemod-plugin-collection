#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include "INSExtendAPI"

#define PLUGIN_NAME "Respawn Player"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "Respawn Player"
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

ConVar g_cvarRespawnInterval;

enum struct PlayerManager
{
	Handle timer_respawn[MAXPLAYERS + 1];
	void WaitForRespawn(int client)
	{
		DataPack pack = new DataPack();
		this.timer_respawn[client] = CreateDataTimer(0.125, RespawnPlayer_Timer, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(client);
		pack.WriteFloat(g_cvarRespawnInterval.FloatValue + GetGameTime());
		TriggerTimer(this.timer_respawn[client]);
	}
}

PlayerManager g_player_manager;

public void OnPluginStart()
{
	g_cvarRespawnInterval = CreateConVar("sm_respawn_player_respawn_interval" , "5.0", "复活间隔");

	HookEventEx("player_first_spawn", event_player_first_spawn_post, EventHookMode_Post);
	HookEventEx("player_spawn", event_player_spawn_post, EventHookMode_Post);
	HookEventEx("player_death", PlayerDeathPost, EventHookMode_Post);
	HookEventEx("round_start", 	RoundStartPost, EventHookMode_PostNoCopy);
	HookEventEx("round_end", 	RoundEndPost, EventHookMode_PostNoCopy);
}

public void OnClientPutInServer(int client)
{
	g_player_manager.WaitForRespawn(client);
}

Action event_player_first_spawn_post(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Continue;
}

Action event_player_spawn_post(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Continue;
}


Action PlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsClientInGame(client) || TEAM_SECURITY != GetClientTeam(client))
	{
		return Plugin_Continue;
	}

	g_player_manager.WaitForRespawn(client);

	return Plugin_Continue;
}

Action RoundStartPost(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Continue;	
}

Action RoundEndPost(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Continue;	
}

Action RespawnPlayer_Timer(Handle hTimer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	float time = pack.ReadFloat();

	if (!IsClientInGame(client)) return Plugin_Stop;

	float current_time = GetGameTime();
	if (current_time < time)
	{
		PrintCenterText(client, "您将在%.2f秒后重生", time - current_time);
		return Plugin_Continue;
	}
	else
	{
		PrintCenterText(client, "");
	}

	if (TEAM_SECURITY != GetClientTeam(client) || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	if (!CINSPLAYER_is_ready_to_spawn(client))
	{
		return Plugin_Continue;
	}

	CINSPLAYER_force_respawn(client);
	return Plugin_Stop;
}



/*
Action TIMER_check_respawn_frame(Handle hTimer)
{

	float flCurTime = GetGameTime();
	float flRemainingTime;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || TEAM_SECURITY != GetClientTeam(client) || IsPlayerAlive(client))
		{
			continue;
		}

		if (!g_bWaitingRespawn[client] || !CINSPLAYER_is_ready_to_spawn(client))
		{
			continue;
		}

		if (!check_player_respawn_permission(client, flCurTime, flRemainingTime))
		{
			show_player_remaining_respawn_time(client, flRemainingTime);
			continue;
		}

		CINSPLAYER_force_respawn(client);
		g_bWaitingRespawn[client] = false;
	}
	return Plugin_Continue;
}

bool check_player_respawn_permission(int client, float flCurTime, float &flRemainTime)
{
	flRemainTime = g_flExpectedRespawnTime[client] - flCurTime;

	return flRemainTime <= 0;
}

void set_player_expected_respawn_time(int client)
{
	// 确保玩家在游戏中，并且是真人
	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}

	g_flExpectedRespawnTime[client] = GetGameTime() + g_cvarRespawnInterval.FloatValue;
	g_bWaitingRespawn[client] = true;
}
*/
/*
void show_player_remaining_respawn_time(int client, float flRemainingTime)
{
	PrintCenterText(client, "您将在%.2f秒后重生", flRemainingTime);

	if(g_cvarLogged.BoolValue)
	{
		PrintToServer("%sV%s]%N将在%.2f秒后重生", PLUGIN_NAME, PLUGIN_VERSION, client, flRemainingTime);
	}
}

*/
/*
Action timer_respawn(Handle timer, int client)
{
	// 停止重生计时
	if (is_waiting_respawn(client))
	{
		stop_wait_respawn(client);
	}

	// 确保玩家有效、活着
	if (!IsClientInGame(client) || IsFakeClient(client) || IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	// 重生玩家
	

	if(g_cvarLogged.BoolValue)
	{
		PrintToServer("%sV%s]%N已经重生", PLUGIN_NAME, PLUGIN_VERSION, client);
	}

	return Plugin_Stop ;
}

stock void begin_wait_respawn(int client)
{
	hRespawnTimer[client] = CreateTimer(g_cvarRespawnInterval.FloatValue, timer_respawn, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	PrintCenterText(client, "您将在%.2f秒后重生", g_cvarRespawnInterval.FloatValue);

	if(g_cvarLogged.BoolValue)
	{
		PrintToServer("%sV%s]%N将在%.2f秒后重生", PLUGIN_NAME, PLUGIN_VERSION, client, g_cvarRespawnInterval.FloatValue);
	}
}

stock bool is_waiting_respawn(int client)
{
	return null != hRespawnTimer[client];
}

stock void stop_wait_respawn(int client)
{
	KillTimer(hRespawnTimer[client]);
	hRespawnTimer[client];
}
*/