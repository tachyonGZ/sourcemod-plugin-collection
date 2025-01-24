#pragma semicolon 1
#pragma newdecls required

#include "MedicalSystem"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <vectorhint>

#include "INSExtendAPI"

#define PLUGIN_NAME "医疗系统"
#define PLUGIN_AUTHOR "PakuPaku"
#define PLUGIN_DESCRIPTION "根据设定的规则自动恢复玩家血量"
#define PLUGIN_VERSION "3.3"
#define PLUGIN_URL "https://github.com/TFXX"

#define MAX_WEAPON_NAME_LENGTH 64

#define X_INDEX -1
#define Y_INDEX 1

static GlobalForward g_fwdOnPlayerHealed = null;

Handle hHealingTimer[MAXPLAYERS + 1];

ConVar g_cvarHealInterval;
ConVar g_cvarHeal;

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errMax)
{
	RegPluginLibrary("plugin_medical_system");
	return APLRes_Success;
}

public void OnPluginStart()
{
	PrintToServer("%sV%s]正在加载插件...", PLUGIN_NAME, PLUGIN_VERSION);

	create_forward();

	init_plugin_convars();
	HookEvents();

	InitCurativeWeaponClassNames();
	LoadCurativeWeaponClassNames();

	VectorHint_AddHint(X_INDEX, Y_INDEX);

	PrintToServer("%sV%s]插件加载完成！", PLUGIN_NAME, PLUGIN_VERSION);
}

static void create_forward()
{
	g_fwdOnPlayerHealed = new GlobalForward("on_player_healed", ET_Ignore, Param_Cell, Param_Cell);
}

static void init_plugin_convars()
{
	g_cvarHeal = CreateConVar("sm_medical_system_heal" , "10", "回血血量", FCVAR_NONE);
	g_cvarHealInterval = CreateConVar("sm_medical_system_heal_interval" , "1.0", "回血间隔", FCVAR_NONE);
}

void HookEvents()
{
	HookEventEx("player_death", event_player_death_post, EventHookMode_Post);
}

 Action event_player_death_post(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	if (is_healing(client))
	{
		StopCure(client);
	}

	return Plugin_Continue;
}

Action timer_healing(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
	{
		StopCure(client);
		
		return Plugin_Stop;
	}

	int max_health = get_player_max_health(client);
	int health = get_player_health(client);

	if (health >= max_health)
	{
		VectorHint_HideHint(X_INDEX, Y_INDEX, client);
		VectorHint_PrintHint(client);
		return Plugin_Continue;
	}

	health += g_cvarHeal.IntValue;

	if (health > max_health)
	{
		health = max_health;
	}

	SetEntProp(client, Prop_Send, "m_iHealth", health, 4);
	
	VectorHint_SetHint(X_INDEX, Y_INDEX, client, "你正在治疗自己");
	VectorHint_PrintHint(client);

	Call_StartForward(g_fwdOnPlayerHealed);
	Call_PushCell(client);
	Call_PushCell(g_cvarHeal.IntValue);
	Call_Finish();
	return Plugin_Continue;
}

bool is_healing(const int client)
{
	return INVALID_HANDLE != hHealingTimer[client];
}

void BeginCure(int client)
{
	hHealingTimer[client] = CreateTimer(g_cvarHealInterval.FloatValue, timer_healing, client, TIMER_REPEAT);
}

void StopCure(int client)
{
	VectorHint_HideHint(X_INDEX, Y_INDEX, client);
	VectorHint_PrintHint(client);
	if (INVALID_HANDLE != hHealingTimer[client])
	{
		KillTimer(hHealingTimer[client]);
		hHealingTimer[client] = INVALID_HANDLE;
	}
}

ArrayList g_curative_weapon_classnames;

void InitCurativeWeaponClassNames()
{
	g_curative_weapon_classnames = new ArrayList(MAX_WEAPON_NAME_LENGTH);
}

void LoadCurativeWeaponClassNames()
{
	g_curative_weapon_classnames.Clear();
	g_curative_weapon_classnames.PushString("weapon_kabar");
}

bool IsCurativeWeapon(int weapon)
{
	static char weapon_name[MAX_WEAPON_NAME_LENGTH];
	GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));
	for (int i = 0; i < g_curative_weapon_classnames.Length; i++)
	{
		static char curative_name[MAX_WEAPON_NAME_LENGTH];
		g_curative_weapon_classnames.GetString(i, curative_name, sizeof(curative_name));
		if (0 == strcmp(weapon_name, curative_name))
		{
			return true;
		}
	}

	return false;
}

public void CINSWeapon_OnDeployComplete_Post(int weapon)
{
	int client = CINSWeapon_GetINSPlayerOwner(weapon);
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}

	if (GetClientTeam(client) != TEAM_SECURITY)
	{
		return;
	}

	if (is_healing(client))
	{
		if (!IsCurativeWeapon(weapon))
		{
			StopCure(client);
		}
	}
	else
	{
		if(IsCurativeWeapon(weapon))
		{
			BeginCure(client);
		}
	}
}