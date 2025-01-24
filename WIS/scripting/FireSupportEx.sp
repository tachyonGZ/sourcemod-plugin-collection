#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <vectorhint>
#include "INSExtendAPI"

#define PLUGIN_NAME "火力支援拓展版"
#define PLUGIN_AUTHOR "PakuPaku"
#define PLUGIN_DESCRIPTION "火力支援拓展版"
#define PLUGIN_VERSION "2.1"
#define PLUGIN_URL "https://github.com/TFXX"

#define HINT_X_INDEX 0
#define HINT_Y_INDEX 2

public Plugin myinfo = {
	name= PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

KeyValues g_kv_rocket;

ClientFSP g_client_fsp;

public void OnPluginStart()
{
	HookEventEx("player_death", PlayerDeath_EVENT_POST, EventHookMode_Post);
	
	RegAdminCmd("fs", CmdCallAFS, 0);

	LoadRocket(g_kv_rocket);

	VectorHint_AddHint(HINT_X_INDEX, HINT_Y_INDEX);
}

Action PlayerDeath_EVENT_POST(Event event, const char[] name, bool cast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int attackerteam = event.GetInt("attackerteam");
	//int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	
	if (IsFakeClient(attacker))
	{
		return Plugin_Continue;
	}

	if (attackerteam == team)
	{
		return Plugin_Continue;
	}

	g_client_fsp.Add(attacker, 1);
	
	return Plugin_Continue;
}

int gBeamSprite;
public void OnMapStart()
{
	gBeamSprite = PrecacheModel("sprites/laserbeam.vmt");
}

public void OnClientPutInServer(int client)
{
	g_client_fsp.Reset(client);
}

enum struct ClientFSP
{
	int fsp_array[MAXPLAYERS + 1];

	void UpdateHint(int client)
	{
		static char hint[16];
		FormatEx(hint, sizeof(hint), "连杀奖励 %d", this.fsp_array[client]);
		VectorHint_SetHint(HINT_X_INDEX, HINT_Y_INDEX, client, hint);
	}

	void Reset(int client)
	{
		this.fsp_array[client] = 0;

		this.UpdateHint(client);
	}

	void Add(int client, int fsp)
	{
		this.fsp_array[client] += fsp;

		this.UpdateHint(client);
	}

	bool Use(int client, int fsp)
	{
		if (this.fsp_array[client] < fsp)
		{
			return false;
		}

		this.fsp_array[client] -= fsp;

		this.UpdateHint(client);
		return true;
	}
}

public void OnCAOEGrenade_Detonate_Post(int entity)
{
	char clsname[64];
	GetEntityClassname(entity, clsname, sizeof(clsname));

	if (!g_kv_rocket.JumpToKey(clsname))
	{
		return;
	}

	int client = CBaseDetonator_GetPlayerOwner(entity);

	if (!g_client_fsp.Use(client, g_kv_rocket.GetNum("cost")))
	{
		PrintCenterText(client, ">>你的支援点数不足，无法呼叫火力支援<<");
		return;
	}

	float pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

	FireSupport fire_support;
	fire_support.enable_delay_effect = false;
	fire_support.shells = g_kv_rocket.GetNum("shells");
	fire_support.spread = g_kv_rocket.GetNum("spread");
	fire_support.interval_time = g_kv_rocket.GetFloat("interval_time");
	fire_support.launch_time = g_kv_rocket.GetFloat("launch_time");
	g_kv_rocket.GetString("missile_name", fire_support.missile_name, sizeof(fire_support.missile_name));

	g_kv_rocket.Rewind();

	if (fire_support.Call(client, pos))
	{
	
	}
}

float UP_VECTOR[3] = {-90.0, 0.0, 0.0};
float DOWN_VECTOR[3] = {90.0, 0.0, 0.0};

const float MATH_PI = 3.14159265359;

public bool TraceWorldOnly_TRACE_FILTER(int entity, int contents_mask, any data)
{
	//return (entity != data && entity <= 0);
	if(entity == data || entity > 0)
		return false;
	return true;
}

static bool GetSkyPos(int client, float pos[3], float sky_pos[3])
{
	Handle ray = TR_TraceRayFilterEx(pos, UP_VECTOR, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceWorldOnly_TRACE_FILTER, client);

	if (!TR_DidHit(ray))
	{
		CloseHandle(ray);
		return false;
	}

	char surface_name[64];
	TR_GetSurfaceName(ray, surface_name, sizeof(surface_name));
	if (!StrEqual(surface_name, "TOOLS/TOOLSSKYBOX", false))
	{	
		CloseHandle(ray);
		return false;
	}
		
	TR_GetEndPosition(sky_pos, ray);
	CloseHandle(ray);
	return true;
}

Action CmdCallAFS(int client, int args)
{
	float ground[3];
	if (!GetClientAimGround(client, ground))
	{
		return Plugin_Handled;
	}

	ground[2] += 20.0;
	char missile_name[64];
	GetCmdArg(1, missile_name, sizeof(missile_name));

	FireSupport support;
	support.enable_delay_effect = false;
	support.interval_time = 1.0;
	support.launch_time = 1.0;
	support.shells = 5;
	support.spread = 800;
	support.SetMissileName(missile_name);
	if (support.Call(client, ground))
	{
	
	}
	return Plugin_Handled;
}

enum struct RocketStrike
{

}

enum struct HowitzerStrike
{

}

enum struct FireSupport
{
	float launch_time;
	float interval_time;
	
	int shells;
	int spread;
	bool enable_delay_effect;

	char missile_name[64];

	void SetMissileName(const char[] missile_name)
	{
		strcopy(this.missile_name, sizeof(this.missile_name), missile_name);
	}

	bool Call(int client, float pos[3])
	{
		float sky_pos[3];
		if(!GetSkyPos(client, pos, sky_pos))
		{
			return false;
		}

		sky_pos[2] -= 20.0;

		DataPack pack = new DataPack();

		if (this.enable_delay_effect)
		{
			ShowDelayEffect(pos, sky_pos, this.launch_time);
		}

		CreateDataTimer(this.launch_time, FireSupportLaunch_TIMER, pack, TIMER_FLAG_NO_MAPCHANGE);

		pack.WriteCell(client);
		pack.WriteCell(this.shells);
		pack.WriteCell(this.spread);
		pack.WriteFloat(this.interval_time);
		pack.WriteFloatArray(sky_pos, sizeof(sky_pos));
		pack.WriteString(this.missile_name);
		//CreateTimer(this.time + 0.05 + GetURandomFloat(), Timer_LaunchMissile, pack, TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(this.time + 0.05 + 1.05 * this.shells, Timer_DataPackExpire, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		return true;
	}
}

void ShowDelayEffect(float ground[3], float sky[3], float time)
{
	// WARNING: Tempent can't alive more than 25 second. must use env_beam entity
	TE_SetupBeamPoints(ground, sky, gBeamSprite, 0, 0, 1, time, 1.0, 0.0, 5, 0.0, {255, 0, 0, 255}, 10);
	TE_SendToAll();
	TE_SetupBeamRingPoint(ground, 500.0, 0.0, gBeamSprite, 0, 0, 1, time, 5.0, 0.0, {255, 0, 0, 255}, 10, 0);
	TE_SendToAll();
}

static Action FireSupportLaunch_TIMER(Handle timer, DataPack datapack_launch)
{
	datapack_launch.Reset();

	int client = datapack_launch.ReadCell();
	int shells = datapack_launch.ReadCell();
	int spread = datapack_launch.ReadCell();

	float interval_time = datapack_launch.ReadFloat();

	float sky_pos[3];
	datapack_launch.ReadFloatArray(sky_pos, sizeof(sky_pos));

	char missile_name[64];
	datapack_launch.ReadString(missile_name, sizeof(missile_name));

	DataPack datapack_interval = new DataPack();

	CreateDataTimer(interval_time, FireSupportInterval_TIMER, datapack_interval, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

	datapack_interval.WriteCell(client);
	datapack_interval.WriteCell(shells);
	datapack_interval.WriteCell(spread);
	datapack_interval.WriteFloatArray(sky_pos, sizeof(sky_pos));
	datapack_interval.WriteString(missile_name);
	return Plugin_Stop;
}

static Action FireSupportInterval_TIMER(Handle timer, DataPack datapack_interval)
{
	datapack_interval.Reset();

	int client = datapack_interval.ReadCell();
	DataPackPos cursor_shells = datapack_interval.Position;
	int shells = datapack_interval.ReadCell();
	int spread = datapack_interval.ReadCell();

	float sky_pos[3];
	datapack_interval.ReadFloatArray(sky_pos, sizeof(sky_pos));

	char missile_name[64];
	datapack_interval.ReadString(missile_name, sizeof(missile_name));

	float dir = GetURandomFloat() * MATH_PI * 8.0;	// not 2π for good result
	float length = GetURandomFloat() * spread;

	sky_pos[0] += Cosine(dir) * length;
	sky_pos[1] += Sine(dir) * length;

	CreateRocketMissle(client, missile_name, sky_pos, DOWN_VECTOR);

	if (shells <= 1)
	{
		return Plugin_Stop;
	}

	datapack_interval.Position = cursor_shells;
	datapack_interval.WriteCell(shells - 1);

	return Plugin_Handled;
}
/*
public Action Timer_LaunchMissile(Handle timer, DataPack pack)
{
	//float dir = GetURandomFloat() * MATH_PI * 8.0;	// not 2π for good result
	//float length = GetURandomFloat() * 800;

	pack.Reset();
	int client = pack.ReadCell();

	DataPackPos cursor = pack.Position;
	int shells = pack.ReadCell();
	pack.Position = cursor;
	pack.WriteCell(shells - 1);

	char missile_name[64];
	pack.ReadString(missile_name, sizeof(missile_name));

	float pos[3];
	//pos[0] = pack.ReadFloat() + Cosine(dir) * length;
	pos[0] = pack.ReadFloat();
	//pos[1] = pack.ReadFloat() + Sine(dir) * length;
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();

	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	CreateRocketMissle(client, missile_name, pos, DOWN_VECTOR);
	if (shells > 1)
	{
		CreateTimer(0.05 + GetURandomFloat(), Timer_LaunchMissile, pack, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}

public Action Timer_DataPackExpire(Handle timer, DataPack pack)
{
	return Plugin_Handled;
}
*/

bool GetClientAimGround(int client, float ground_pos[3])
{
	float pos[3];
	float angle[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle);
	
	Handle ray = TR_TraceRayFilterEx(pos, angle, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceWorldOnly_TRACE_FILTER, client);

	if (!TR_DidHit(ray))
	{
		CloseHandle(ray);
		return false;
	}

	TR_GetEndPosition(pos, ray);
	CloseHandle(ray);

	ray = TR_TraceRayFilterEx(pos, DOWN_VECTOR, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceWorldOnly_TRACE_FILTER, client);
	if (!TR_DidHit(ray))
	{
		CloseHandle(ray);
		return false;
	}

	
	TR_GetEndPosition(ground_pos, ray);
	CloseHandle(ray);
	return true;
}

void LoadRocket(KeyValues &kv_rocket)
{
	// ini file path
	char file_path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file_path, sizeof(file_path), "configs/rocket.ini");
	if(!FileExists(file_path))
	{
		SetFailStateFileNotExists(PLUGIN_NAME, file_path);
		return;
	}

	kv_rocket = new KeyValues("rocket");

	if(!kv_rocket.ImportFromFile(file_path))
	{
		delete kv_rocket;
		SetFailState("文件格式有误");
	}

	return;
}