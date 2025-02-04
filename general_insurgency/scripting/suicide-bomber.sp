#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "INSExtendAPI"
#include "utility_api"

#define PLUGIN_NAME "Suicide Bomber"
#define PLUGIN_DESCRIPTION "Spawn some Bomber which can make suicide bomb"
#define PLUGIN_VERSION "2.5"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "Suicide"
#define PLUGIN_AUTHOR "tachyon_gz_"
#define PLUGIN_URL ""

public Plugin myinfo = {
	name            = PLUGIN_NAME,
	author          = PLUGIN_AUTHOR,
	description     = PLUGIN_DESCRIPTION,
	version         = PLUGIN_VERSION,
	url             = PLUGIN_URL
};

/*
char s_type[64];
char s_class[MAXPLAYERS+1][64];
float f_detonate_range;
float f_resist;
*/

ConVar g_cvar_range;
ConVar g_cvar_probability;
ConVar g_cvar_snd;
public void OnPluginStart()
{
	//cvarBomber = CreateConVar("sm_suicide_bomber", "sharpshooter", "Let bot suicide", FCVAR_NOTIFY);
	g_cvar_range = CreateConVar("sm_suicide_bomber_ex_range", "600", "Detonate range");
	g_cvar_probability = CreateConVar("sm_suicide_bomber_ex_probability", "0.1", "probability ememy carry bomb when he spawn");
	g_cvar_snd = CreateConVar("sm_suicide_bomber_snd", "soundscape/emitters/oneshot/alarm_03.ogg", "snd file url, it will emitted when bomb launch");
	//g_cvar_resist = CreateConVar("sm_suicide_resist", "20", "Damage resistance", FCVAR_NOTIFY);
	//cvarDetoDelay = CreateConVar("sm_suicide_delay", "0.01", "Detonate delay", FCVAR_NOTIFY);
	
	//HookEvent("player_pick_squad", Event_PlayerPickSquad);
	HookEventEx("round_start", RoundStartPost, EventHookMode_PostNoCopy);
	HookEventEx("round_end", RoundEndPost, EventHookMode_PostNoCopy);
	HookEventEx("player_spawn", PlayerSpawnPost, EventHookMode_Post);
}

public void OnMapStart()
{
	PrecacheModel("models/weapons/w_ied.mdl",true);
	PrecacheSound("weapons/IED/handling/IED_throw.wav", true);
	PrecacheSound("weapons/IED/handling/IED_trigger_ins.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_01.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_02.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_03.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_dist_01.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_dist_02.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_dist_03.wav", true);
	PrecacheSound("weapons/IED/IED_bounce_01.wav", true);
	PrecacheSound("weapons/IED/IED_bounce_02.wav", true);
	PrecacheSound("weapons/IED/IED_bounce_03.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_01.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_02.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_03.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_dist_01.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_dist_02.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_dist_03.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_far_dist_01.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_far_dist_02.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_far_dist_03.wav", true);

	char snd[PLATFORM_MAX_PATH];
	g_cvar_snd.GetString(snd, sizeof(snd));
	PrecacheSound(snd);
}

enum struct	BomberList
{
	bool is_bomber[MAXPLAYERS + 1];

	void toggle_is_bomber(int client, bool is_bomber)
	{
		this.is_bomber[client] = is_bomber;
		if (is_bomber)
		{
			CINSPlayer_RemoveAllItems(client, false);
		}
	}

	bool IsBomber(int client)
	{
		return this.is_bomber[client];
	}
}

BomberList g_bomber_list;

Action PlayerSpawnPost(Event event, const char []name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bomber_list.toggle_is_bomber(client, false);

	if (TEAM_INSURGENT != GetClientTeam(client)) return Plugin_Continue;

	g_bomber_list.toggle_is_bomber(client, GetRandomFloat(0.0, 1.0) <= g_cvar_probability.FloatValue);
	return Plugin_Continue;
}


Handle g_repeater;

Action RoundStartPost(Event event, const char []name, bool dontBroadcast)
{
	g_repeater = CreateTimer(1.0, SuicideFrame_Timer, _, TIMER_REPEAT);
	return Plugin_Continue;
}

Action RoundEndPost(Event event, const char []name, bool dontBroadcast)
{
	if (g_repeater != INVALID_HANDLE)
	{
		KillTimer(g_repeater);
		g_repeater = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

// make bomber more tank
public void OnClientPutInServer(int client)
{
	// SDKHook(client, SDKHook_TraceAttack, FTraceAttack);
}

/*
public Action:FTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (i_enabled && IsFakeClient(victim) && StrContains(s_class[victim], s_type, false) != -1) {
		damage *= f_resist;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}



public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	decl String:class_template[64];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	if(IsValidPlayer(client) && strlen(class_template) > 1) {
		strcopy(s_class[client], 64, class_template);
	}
	return;
}
*/

Action SuicideFrame_Timer(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client)) continue;

		if (!g_bomber_list.IsBomber(client)) continue;

		CheckExplode(client);
	}
	return Plugin_Continue;
}

void CheckExplode(int client)
{
	/*
	if (!i_enabled || StrContains(s_class[client], s_type, false) == -1) {
		SetEntityRenderColor(client, 255, 255, 255, 255);
		return;
	}
	*/
	float origin[2][3];
	GetClientEyePosition(client, origin[0]);

	bool check = false;

	float range_square = Pow(g_cvar_range.FloatValue, 2.0);
	for(int j = 1; j <= MaxClients; j++)
	{
		if (!IsClientInGame(j) || !IsPlayerAlive(j) || TEAM_INSURGENT == GetClientTeam(j))
		{
			continue;
		}

		GetClientEyePosition(j, origin[1]);
		float distance_square = GetVectorDistance(origin[0], origin[1], true);

		if (distance_square > range_square) continue;

		if (!UtilityAPI_IsNothingBetweenClient(client, j)) continue;

		check = true;
		break;
	}

	if (!check) return;

	g_bomber_list.toggle_is_bomber(client, false);

	int entity = CreateEntityByName("grenade_ied");
	if(!IsValidEntity(entity)) ThrowError("failed to create grenade_ied");
	TeleportEntity(entity, origin[0]);
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
	//SetEntProp(entity, Prop_Data, "m_nNextThinkTick", GetConVarFloat(cvarDetoDelay)); //for smoke
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 0.01); //for smoke
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	SetEntProp(entity, Prop_Data, "m_iHealth", 1);
	DispatchSpawn(entity);
	ActivateEntity(entity);

	if (!DispatchSpawn(entity)) return;

	// sound
	char snd[PLATFORM_MAX_PATH];
	g_cvar_snd.GetString(snd, sizeof(snd));
	EmitSoundToAll(snd, _, _, SNDLEVEL_MINIBIKE, _, _, _, _, origin[0]);

	DataPack pack = new DataPack();
	CreateDataTimer(1.0, Launch_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(client);
	pack.WriteCell(entity);
}

Action Launch_Timer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int ent = pack.ReadCell();
	DealDamage(ent,380,client,DMG_BLAST,"weapon_c4_ied");
	return Plugin_Stop;
}

void DealDamage(int victim,int damage,int attacker=0,int dmg_type=DMG_GENERIC,char[] weapon="")
{
	if(victim>0 && IsValidEdict(victim) && damage>0)
	{
		/*
		char dmg_str[16];
		IntToString(damage,dmg_str,16);
		char dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		*/
		int pointHurt = CreateEntityByName("point_hurt");
		if(!IsValidEntity(pointHurt)) ThrowError("failed to create entity: point_hurt");
		DispatchKeyValue(victim,"targetname","hurtme");
		DispatchKeyValue(pointHurt,"DamageTarget","hurtme");
		DispatchKeyValueInt(pointHurt,"Damage", damage);
		DispatchKeyValueInt(pointHurt,"DamageType", dmg_type);
		if(!StrEqual(weapon,""))
		{
			DispatchKeyValue(pointHurt,"classname",weapon);
		}
		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
		DispatchKeyValue(pointHurt,"classname","point_hurt");
		DispatchKeyValue(victim,"targetname","donthurtme");
		//RemoveEdict(pointHurt);
		RemoveEntity(pointHurt);
	}
}