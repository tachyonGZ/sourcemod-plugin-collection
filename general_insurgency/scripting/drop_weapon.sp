#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#include "INSExtendAPI"

#define PLUGIN_NAME "Drop Weapon"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "allow client drop weapon"
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

public void OnPluginStart()
{
	HookEventEx("player_hurt", EVENT_POST_player_hurt, EventHookMode_Post);
	RegConsoleCmd("r", CMD_drop_weapon);
}

public void OnPluginEnd()
{
	UnhookEvent("player_hurt", EVENT_POST_player_hurt, EventHookMode_Post);
}

Action CMD_drop_weapon(int client, int args)
{
	if (!IsClientInGame(client))
	{
		ReplyToCommand(client, "【提示】不在游戏中，无法丢弃武器");
		return Plugin_Continue;
	}

	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "【提示】当前状态无法丢弃武器");
		return Plugin_Continue;
	}

	int weapon = CINSPlayer_GetActiveINSWeapon(client);

	float vecAngles[3];
	GetClientEyeAngles(client, vecAngles);
	float vecVelocity[3];
	GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);

	for (int i = 0; i < 3; i++)
	{
		vecVelocity[i] *= 300;
	}

	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vecVelocity);

	return Plugin_Continue;
}

Action EVENT_POST_player_hurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	//int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int hitgroup = GetEventInt(event, "hitgroup");
	//int damage = GetEventInt(event, "dmg_health");
	//int health = GetClientHealth(client);

	if (4 != hitgroup && 5 != hitgroup)
	{
		return Plugin_Continue;
	}

	int weapon = CINSPlayer_GetActiveINSWeapon(client);

	if (-1 == weapon)
	{
		return Plugin_Continue;
	}
	
	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Continue;
}