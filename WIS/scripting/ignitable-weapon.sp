#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "utility-api"

#define PLUGIN_NAME "ignitable weapon"
#define PLUGIN_AUTHOR "tachyon_gz"
#define PLUGIN_DESCRIPTION "ignite player when player taking damage from ignitable weapon"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "https://github.com/TFXX"

#define MAX_CLASSNAME_LENGTH 64

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

enum struct IgnitableWeapon
{
	char classname[MAX_CLASSNAME_LENGTH];
	float ignition_lifetime;
}

StringMap g_map_ignitable;

ConVar g_cvar_damage;
ConVar g_cvar_death_message;

public void OnPluginStart()
{
	g_map_ignitable = new StringMap();

	LoadIgnitableWeaponConfig(g_map_ignitable);

	g_cvar_damage = CreateConVar("sm_ignitable_weapon_damage", "1.0");
	g_cvar_death_message = CreateConVar("sm_ignitable_weapon_death_message", "灼烧");
	HookEventEx("player_death", PlayerDeathPre, EventHookMode_Pre);
	HookEventEx("player_hurt", PlayerHurtPre, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
	if(!SDKHookEx(client, SDKHook_OnTakeDamage, OnTakeDamage_SDKHookCB)) ThrowError("failed hook");
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage_SDKHookCB);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Continue;

	int stance = GetEntProp(client, Prop_Send, "m_iCurrentStance");
	if(stance != 2) return Plugin_Continue;

	int entity = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
	if (!IsValidEntity(entity)) return Plugin_Continue;
	
	SetEntPropFloat(entity, Prop_Data, "m_flLifetime", 0.0);
	return Plugin_Continue;
}

Action PlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	char classname[MAX_CLASSNAME_LENGTH];
	event.GetString("weapon", classname, sizeof(classname));

	if (!StrEqual("entityflame", classname, false)) return Plugin_Continue;

	char death_message[64];
	g_cvar_death_message.GetString(death_message, sizeof(death_message));
	event.SetString("weapon", death_message);

	return Plugin_Continue;
}

Action PlayerHurtPre(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char classname[MAX_CLASSNAME_LENGTH];
	event.GetString("weapon", classname, sizeof(classname));

	if (!g_map_ignitable.ContainsKey(classname)) return Plugin_Continue;

	IgnitableWeapon ignitable;
	if (!g_map_ignitable.GetArray(classname, ignitable, sizeof(ignitable)))
	{
		ThrowError("can't get array from map{classname -> ignitable weapon}");
	}

	IgniteEntity(client, ignitable.ignition_lifetime);
	return Plugin_Continue;
}

Action OnTakeDamage_SDKHookCB(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!IsValidEntity(weapon)) return Plugin_Continue;
	char classname[MAX_CLASSNAME_LENGTH];
	GetEntityClassname(weapon, classname, sizeof(classname));

	if (!StrEqual("entityflame", classname)) return Plugin_Continue;

	damage = g_cvar_damage.FloatValue;
	return Plugin_Changed;
}

void IgnitableWeapon_ConfigInitializer(const char[] path)
{
	char root_section_name[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, root_section_name, sizeof(root_section_name));
	SplitString(root_section_name, ".smx", root_section_name, sizeof(root_section_name));

	KeyValues kv = new KeyValues(root_section_name);
	kv.JumpToKey("example_weapon_classname", true);
	kv.SetFloat("ignition_lifetime", 7.0);
	kv.Rewind();
	if (!kv.ExportToFile(path))
	{
		delete kv;
		ThrowError("failed write Keyvalues to %s", path);
	}
}

void LoadIgnitableWeaponConfig(StringMap map)
{
	char config_filename[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, config_filename, sizeof(config_filename));
	SplitString(config_filename, ".smx", config_filename, sizeof(config_filename));

	char path[PLATFORM_MAX_PATH];
	FormatEx(path, sizeof(path), "configs/%s/%s.cfg", config_filename, config_filename);
	BuildPath(Path_SM, path, sizeof(path), path);

	UtilityAPI_CreateConfigIfNotExist(path, IgnitableWeapon_ConfigInitializer);

	KeyValues kv = new KeyValues(config_filename);
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		ThrowError("failed read Keyvalues from %s", path);
	}

	map.Clear();
	if (kv.GotoFirstSubKey())
	{
		do{
			IgnitableWeapon ignitable_weapon;
			if (!kv.GetSectionName(ignitable_weapon.classname, sizeof(ignitable_weapon.classname)))
			{
				delete kv;
				ThrowError("failed get section name from %s", path);
			}
			ignitable_weapon.ignition_lifetime = kv.GetFloat("ignition_lifetime");
			if (map.ContainsKey(ignitable_weapon.classname))
			{
				delete kv;
				ThrowError("conflict key: %s", ignitable_weapon.classname);
			}
			map.SetArray(ignitable_weapon.classname, ignitable_weapon, sizeof(ignitable_weapon));
		}while(kv.GotoNextKey());
	}
}