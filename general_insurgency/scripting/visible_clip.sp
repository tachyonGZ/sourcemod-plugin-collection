/**
 * 3.1 完善了基础功能
 * 3.2 增加了ConVarHook相关代码，并修改了检测逻辑
 * 3.3 将WeaponEquip检测改为WeaponWitch检测，并弃用weapon_deploy事件检测
 * 3.4 	1.增加了控制是否显示最大弹匣容量的ConVar
 *		2.增加了插件卸载时unhook事件以及ConVar的代码
 * 4.0 采用回调更新状态
 * 4.1 添加了weapon_holster事件的相关逻辑
 * 5.0 主体逻辑采用拓展API中的回调实现
**/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <vectorhint>
#include "..\..\WIS\scripting\INSExtendAPI"

#define PLUGIN_NAME "Visible Clip"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "shown ammo of clip on screen"
#define PLUGIN_VERSION ""
#define PLUGIN_URL ""

#define HINT_X_INDEX 0
#define HINT_Y_INDEX 1

public Plugin myinfo = {
	name= PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

//static GlobalForward g_fwdOnClientAmmoStatusUpdate;

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	RegPluginLibrary("plugin_ammo_status");

	return APLRes_Success;
}

public void OnPluginStart()
{
	//AutoExecConfig(true,"plugin.AmmoStatus");
	HookEventEx("weapon_fire", event_ammo_update_post, EventHookMode_Post);
	VectorHint_AddHint(HINT_X_INDEX, HINT_Y_INDEX);
}

public void OnPluginEnd()
{
	UnhookEvent("weapon_fire", event_ammo_update_post, EventHookMode_Post);
}

public void on_ballistic_finish_reload_POST(int weapon)
{
	//int client = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
	int client = CINSWeapon_GetINSPlayerOwner(weapon);
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}

	UpdateAmmoStatus(client, weapon, true);
}

public void on_CBASECOMBATCHARACTER_on_change_active_weapon_POST(int client, int prevWeapon, int newWeapon)
{
	if (newWeapon < 0)
	{
		return;
	}

	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}

	UpdateAmmoStatus(client, newWeapon, false);
}

Action event_ammo_update_post(Event event, const char[] name, bool Broadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	int weapon = CINSPlayer_GetActiveINSWeapon(client);

	UpdateAmmoStatus(client, weapon, false);
	return Plugin_Continue;
}

void UpdateAmmoStatus(int client, int weapon, bool immediately)
{
	int clip1 = CBaseCombatWeapon_Clip1(weapon);
	int max_clip1 = CINSWEAPON_get_max_clip_1(weapon);

	if (-1 == clip1 && -1 == max_clip1)
	{
		VectorHint_HideHint(HINT_X_INDEX, HINT_Y_INDEX, client);
		return;
	}

	static char hint[32];
	FormatEx(hint, sizeof(hint), "弹匣 %d/%d", clip1, max_clip1);
	VectorHint_SetHint(HINT_X_INDEX, HINT_Y_INDEX, client, hint);

	if(immediately)
	{
		VectorHint_PrintHint(client);
	}
}