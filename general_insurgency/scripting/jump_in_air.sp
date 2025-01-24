#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Jump In Air"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "Allow player jump in air"
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

ConVar g_cvar_max;
ConVar g_cvar_boost;
ConVar g_cvar_trigger_event;

int g_jumpsCount[MAXPLAYERS + 1];
bool g_bLanded[MAXPLAYERS + 1];
bool g_bWasJump[MAXPLAYERS + 1];

public void OnPluginStart()
{
	g_cvar_max = CreateConVar("sm_jump_in_air_max" , "1", "连续在空中跳跃的最大次数，设置为0可以无限次连续跳跃");

	g_cvar_boost = CreateConVar("sm_jump_in_air_boost" , "250.0", "连续在在空中跳跃时候的纵向速度");

	g_cvar_trigger_event = CreateConVar("sm_jump_in_air_trigger_event", "0", "是否触发事件");
}

public void OnClientConnected(int client)
{
	if (IsClientInGame(client)) return;

	process_land(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Continue;

	rejump_check(client);

	return Plugin_Continue;
}

void rejump_check(int client)
{
	bool bGround = !!(GetEntityFlags(client) & FL_ONGROUND);
	bool bJump = !!(GetClientButtons(client) & IN_JUMP);

	if (!g_bLanded[client])
	{
		if (bGround)
		{
			process_land(client);
		}
		else
		{
			if (!g_bWasJump[client] && bJump)
			{
				process_rejump(client);
			}
		}
	}

	g_bLanded[client] = bGround;
	g_bWasJump[client] = bJump;
}

void process_land(const int client)
{
	g_jumpsCount[client] = 0;
}

void process_rejump(const int client)
{
	if ((++g_jumpsCount[client] <= g_cvar_max.IntValue) || (0 == g_cvar_max.IntValue))
	{
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		velocity[2] = g_cvar_boost.FloatValue;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

		if (g_cvar_trigger_event.BoolValue)
		{
			TriggerPlayerFootstepEvent(client);
		}
	}
}

void TriggerPlayerFootstepEvent(int client)
{
	Event event = CreateEvent("player_footstep");
	if (null == event) ThrowError("fail to find event: player_footstep");
	event.SetInt("userid", GetClientUserId(client));
	event.Fire();
}