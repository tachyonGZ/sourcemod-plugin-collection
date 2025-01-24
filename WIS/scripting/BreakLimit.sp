/**
 * 1.0 添加了玩家无限负重的功能
 * 1.1 添加了玩家无限支援点的功能
 * 1.2 添加player_pick_squad的相关逻辑
**/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include "INSExtendAPI"

#define PLUGIN_NAME "限制修改"
#define PLUGIN_AUTHOR "PakuPaku"
#define PLUGIN_DESCRIPTION "限制修改"
#define PLUGIN_VERSION "1.2"
#define PLUGIN_URL "https://github.com/TFXX"

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
	PrintToServer("%sV%s]正在加载插件...", PLUGIN_NAME, PLUGIN_VERSION);

	//create_forward();

	init_plugin_convars();
	//init_sdk_calls();
	hook_events();

	//g_cookieShowHealth = RegClientCookie("display_health", "是否显示血量", CookieAccess_Private);

	PrintToServer("%sV%s]插件加载完成！", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	unhook_events();

	//delete_forward();
}

static ConVar g_cvarInfCarryWeight = null;
static ConVar g_cvarInfSupplyPoint = null;

static void init_plugin_convars()
{
    g_cvarInfCarryWeight = CreateConVar("sm_break_limit_infinite_carry_weight", "1", "是否让玩家的负重为无限", FCVAR_NONE);
    g_cvarInfSupplyPoint = CreateConVar("sm_break_limit_infinite_supply_point", "0", "是否让玩家的支援点为无限", FCVAR_NONE);
    AutoExecConfig(true, "plugin.BreakLimit");
}

static void hook_events()
{
    HookEventEx("player_pick_squad", EVENTS_POST_player_pick_squad, EventHookMode_Post);
    HookEventEx("weapon_deploy", EVENTS_POST_weapon_deploy, EventHookMode_Post);
}

static void unhook_events()
{
    UnhookEvent("weapon_deploy", EVENTS_POST_weapon_deploy, EventHookMode_Post);
    UnhookEvent("player_pick_squad", EVENTS_POST_player_pick_squad, EventHookMode_Post);
}

static Action EVENTS_POST_player_pick_squad(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    make_carry_weight_infinite(client);
    make_supply_point_infinite(client);
    return Plugin_Continue;
}

static Action EVENTS_POST_weapon_deploy(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    make_carry_weight_infinite(client);
    make_supply_point_infinite(client);
    return Plugin_Continue;
}

static void make_carry_weight_infinite(int client)
{
    if (!g_cvarInfCarryWeight.BoolValue)
    {
        return;
    }

    //set_player_carry_weight(client, 0);
    set_player_weight_cache(client, 0);
}

static void make_supply_point_infinite(int client)
{
    if (!g_cvarInfSupplyPoint.BoolValue)
    {
        return;
    }

    set_player_recieved_tokens(client, 255);
    set_player_available_tokens_tokens(client, 255);
}