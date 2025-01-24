/**
 * 1.1 添加了丢枪时速度的计算
 * 2.0 BOT被击中手臂会掉落武器
 * 2.1 修改了检测武器所在槽位的代码
 * 		添加了输入命令后的反馈提示
 * 2.2 底层API改用拓展API
**/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#include "INSExtendAPI"

#define PLUGIN_NAME "扔枪增强版"
#define PLUGIN_AUTHOR "PakuPaku"
#define PLUGIN_DESCRIPTION "玩家可以扔枪"
#define PLUGIN_VERSION "2.5"
#define PLUGIN_URL "https://github.com/TFXX"

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

ConVar g_cvarLogged;

public void OnPluginStart()
{
	PrintToServer("%sV%s]正在加载插件...", PLUGIN_NAME, PLUGIN_VERSION);

	InitPluginConvars();
	hook_events();
	reg_cmds();

	PrintToServer("%sV%s]插件加载完成！", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	unhook_events();
}

void InitPluginConvars()
{
	g_cvarLogged = CreateConVar("sm_drop_weapon_ex_logged", "0", "是否记录", FCVAR_NONE);
	AutoExecConfig(true,"plugin.DropWeaponEx");
}

void hook_events()
{
	HookEventEx("player_hurt", EVENT_POST_player_hurt, EventHookMode_Post);
}

static void unhook_events()
{
	UnhookEvent("player_hurt", EVENT_POST_player_hurt, EventHookMode_Post);
}

static void reg_cmds()
{
	RegConsoleCmd("r", CMD_drop_weapon);
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

	if (g_cvarLogged.BoolValue)
	{
		char weaponName[32];
		GetEntityClassname(weapon, weaponName, 32);
		PrintToServer("%sV%s]%N被击中丢掉了枪%s(%d)", PLUGIN_NAME, PLUGIN_VERSION, client, weaponName, weapon);
	}
	return Plugin_Continue;
}