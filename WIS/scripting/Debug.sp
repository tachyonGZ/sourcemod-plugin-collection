#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>
#include <vectorhint>
#include "INSExtendAPI"

#define PLUGIN_NAME "调试模块"
#define PLUGIN_AUTHOR "tg"
#define PLUGIN_DESCRIPTION "辅助调试"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "https://github.com/TFXX"

public Plugin myinfo = {
	name= PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

Handle g_fn;

public void OnPluginStart()
{
	
	GameData gd = LoadGameConfigFile("insurgency.games");

	/*
	DynamicDetour dtr = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	res = dtr.SetFromConf(gd, SDKConf_Signature, "CINSPlayer::OnNearPlayer");
	PrintToServer("%b", res);
	dtr.AddParam(HookParamType_CBaseEntity);
	dtr.AddParam(HookParamType_Float);
	res = dtr.Enable(Hook_Post, OnHookPost);
	PrintToServer("%b", res);
	*/

	//	CTeam::GetAliveMembers();
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTeam::GetAliveMembers");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_fn = EndPrepSDKCall();
	if (INVALID_HANDLE == g_fn)
	{
		SetFailState("SDKCALL初始化失");
	}

	PrintToServer("%d", MaxClients);

	RegConsoleCmd("d", cmd);
}

public void OnMapStart()
{
	char gamemode[32];
	FindConVar("mp_gamemode").GetString(gamemode, 32);
	PrintToServer(gamemode);
}

stock Action cmd(int client, int args)
{
	/*
	int weapon = CINSPlayer_GetActiveINSWeapon(client);
	int primary_ammo = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount");
	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	int entity = CreateEntityByName(classname);
	PrintToConsole(client, "%d %d", entity, primary_ammo);
	DispatchKeyValue(entity, "solid", "6");
	DispatchKeyValue(entity, "count", "9999");
	float ground_pos[3];
	GetClientAimGround(client, ground_pos);
	TeleportEntity(entity, ground_pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	SetEntityMoveType(entity, MOVETYPE_NONE);
	
	*/

	int offset = FindSendPropInfo("CINSPlayer", "m_EquippedGear");
	PrintToConsole(client, "offset : %d", offset);
	int gear[7];
	for (int i = 0; i < 7; i++)
	{
		gear[i] = GetEntData(client, i * 4 + offset);
		PrintToConsole(client, "%d : %d", i, gear[i]);
	}

	/*
	sec_light_armor
	ins_light_armor
	sec_heavy_armor
	ins_heavy_armor
	sec_chest_rig
	ins_chest_rig
	sec_chest_carrier
	ins_chest_carrier
	?nightmap
	*/

	return Plugin_Continue;
}

stock MRESReturn OnHookPost(int entity, DHookParam param)
{	
	int entity2 = DHookGetParam(param, 1);
	float d = DHookGetParam(param, 2);
	PrintToConsole(entity, "%d -> %d = %f", entity, entity2, d);
	return MRES_Ignored;
}



float DOWN_VECTOR[3] = {90.0, 0.0, 0.0};
stock bool GetClientAimGround(int client, float ground_pos[3])
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

const float MATH_PI = 3.14159265359;

public bool TraceWorldOnly_TRACE_FILTER(int entity, int contents_mask, any data)
{
	//return (entity != data && entity <= 0);
	if(entity == data || entity > 0)
		return false;
	return true;
}