#pragma semicolon 1
#pragma newdecls required

#include "HealthSystem"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <vectorhint>

#include "MedicalSystem"
#include "INSExtendAPI"

#define PLUGIN_NAME "血量系统"
#define PLUGIN_AUTHOR "PakuPaku"
#define PLUGIN_DESCRIPTION "血量系统"
#define PLUGIN_VERSION "3.0"
#define PLUGIN_URL "https://github.com/TFXX"

#define HINT_X_INDEX 0
#define HINT_Y_INDEX 0

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

GlobalForward g_fwdOnClientHealthStatusUpdate;

ConVar g_cvarMaxHealth = null;

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	RegPluginLibrary("plugin_health_system");
	return APLRes_Success;
}

public void OnPluginStart()
{
	PrintToServer("%sV%s]正在加载插件...", PLUGIN_NAME, PLUGIN_VERSION);

	create_forward();

	init_plugin_convars();
	hook_events();

	VectorHint_AddHint(HINT_X_INDEX, HINT_Y_INDEX);

	PrintToServer("%sV%s]插件加载完成！", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	unhook_events();

	delete_forward();
}

public void OnClientPutInServer(int client)
{
	
}

public void on_player_healed(int client, int healValue)
{
	push_forward_on_client_health_status_update(client);
}

// 创建回调
static void create_forward()
{
	g_fwdOnClientHealthStatusUpdate = new GlobalForward("on_client_health_status_update", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

static void delete_forward()
{
	CloseHandle(g_fwdOnClientHealthStatusUpdate);
}

// 加载ConVar
static void init_plugin_convars()
{
	g_cvarMaxHealth = CreateConVar("sm_health_system_max_health", "100", "自定义最大血量", FCVAR_NONE);
	AutoExecConfig(true,"plugin.HealthSystem");
}

void hook_events()
{
	HookEventEx("player_hurt", EVENT_POST_player_hurt, EventHookMode_Post);
	HookEventEx("player_spawn", EVENT_POST_player_spawn, EventHookMode_Post);
	HookEventEx("player_spawn", EVENT_PRE_player_spawn, EventHookMode_Pre);
}

void unhook_events()
{
	UnhookEvent("player_hurt", EVENT_POST_player_hurt, EventHookMode_Post);
	UnhookEvent("player_spawn", EVENT_POST_player_spawn, EventHookMode_Post);
	UnhookEvent("player_spawn", EVENT_PRE_player_spawn, EventHookMode_Pre);
}

static Action EVENT_POST_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	push_forward_on_client_health_status_update(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

static Action EVENT_POST_player_spawn(Event event, const char[]szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	set_player_health(client, g_cvarMaxHealth.IntValue);
	push_forward_on_client_health_status_update(client);
	return Plugin_Continue;
}

static Action EVENT_PRE_player_spawn(Event event, const char[]szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	set_player_max_health(client, g_cvarMaxHealth.IntValue);
	return Plugin_Continue;
}

stock void push_forward_on_client_health_status_update(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}

	
	int iHealth = get_player_health(client);
	int iMaxHealth = get_player_max_health(client);
	
	/*
	Call_StartForward(g_fwdOnClientHealthStatusUpdate);
	Call_PushCell(client);
	Call_PushCell(iHealth);
	Call_PushCell(iMaxHealth);
	Call_Finish();
	*/

	char hint[16];
	FormatEx(hint, sizeof(hint),"血量 %d/%d", iHealth, iMaxHealth);

	VectorHint_SetHint(HINT_X_INDEX, HINT_Y_INDEX, client, hint);
}