#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#include "INSExtendAPI"

#define PLUGIN_NAME "叛乱2拓展API"
#define PLUGIN_AUTHOR "PakuPaku"
#define PLUGIN_DESCRIPTION "自定义了许多新的关于叛乱2的API，可供其他插件调用"
#define PLUGIN_VERSION "1.22"
#define PLUGIN_URL "https://github.com/TFXX"

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErrMax)
{
	RegPluginLibrary("plugin_ins_extend_api");

	CreateNative("get_player_carry_weight", NATIVE_get_player_carry_weight);
	CreateNative("set_player_carry_weight", NATIVE_set_player_carry_weight);
	CreateNative("get_player_health", NATIVE_get_player_health);
	CreateNative("set_player_health", NATIVE_set_player_health);
	CreateNative("get_player_max_health", NATIVE_get_player_max_health);
	CreateNative("set_player_max_health", NATIVE_set_player_max_health);
	CreateNative("get_player_recieved_tokens", NATIVE_get_player_recieved_tokens);
	CreateNative("set_player_recieved_tokens", NATIVE_set_player_recieved_tokens);
	CreateNative("get_player_weight_cache", NATIVE_get_player_weight_cache);
	CreateNative("set_player_weight_cache", NATIVE_set_player_weight_cache);
	CreateNative("get_player_available_tokens_tokens", NATIVE_get_player_available_tokens_tokens);
	CreateNative("set_player_available_tokens_tokens", NATIVE_set_player_available_tokens_tokens);
	CreateNative("get_weapon_slot", NATIVE_get_weapon_slot);
	CreateNative("CINSPLAYER_is_ready_to_spawn", NATIVE_CINSPLAYER_is_ready_to_spawn);
	CreateNative("CINSPLAYER_force_respawn", NATIVE_CINSPLAYER_force_respawn);
	CreateNative("CINSPLAYER_should_gain_instant_spawn", NATIVE_CINSPLAYER_should_gain_instant_spawn);
	CreateNative("CINSPlayer_GetActiveINSWeapon", CINSPlayer_GetActiveINSWeapon_NATIVE_CALL);
	CreateNative("CINSPlayer_RemoveAllItems", CINSPlayer_RemoveAllItems_NATIVE_CALL);
	CreateNative("CreateRocketMissle", NATIVE_create_rocket_missile);
	CreateNative("CINSWEAPON_get_max_clip_1", CINSWeapon_GetMaxClip1_NATIVE_CALL);
	CreateNative("CINSWeapon_GetINSPlayerOwner", CINSWeapon_GetINSPlayerOwner_NATIVE_CALL);
	CreateNative("CBaseCombatCharacter_RemoveAllWeapons", CBaseCombatCharacter_RemoveAllWeapons_NATIVE_CALL);
	CreateNative("CBaseCombatWeapon_Clip1", CBaseCombatWeapon_Clip1_NATIVE_CALL);
	CreateNative("CBaseCombatWeapon_Clip2", CBaseCombatWeapon_Clip2_NATIVE_CALL);
	CreateNative("CBaseDetonator_GetPlayerOwner", CBaseDetonator_GetPlayerOwner_NATIVE_CALL);
	CreateNative("CINSRules_ToggleSpawnZone", CINSRules_ToggleSpawnZone_NATIVE_CALL);
	CreateNative("CINSRules_IsCounterAttack", CINSRules_IsCounterAttack_NATIVE_CALL);
	CreateNative("CINSSpawnZone_PointInSpawnZone", CINSSpawnZone_PointInSpawnZone_NATIVE_CALL);
	CreateNative("CTeam_GetAliveMembers", CTeam_GetAliveMembers_NATIVE_CALL);
	CreateNative("GetBaseEntityByAddress", GetBaseEntityByAddress_NATIVE_CALL);
	
	return APLRes_Success;
}

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

	create_forward();

	//init_plugin_convars();
	init_sdk_calls();
	//hook_events();

	
	GameData gd = LoadGameConfigFile("insurgency.games");

	init_detours(gd);

	
	gd.Close();

	//g_cookieShowHealth = RegClientCookie("display_health", "是否显示血量", CookieAccess_Private);

	PrintToServer("%sV%s]插件加载完成！", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	//unhook_events();

	//delete_forward();
}

Handle g_fnGetSolt = INVALID_HANDLE;
Handle g_fnIsReadyToSpawn = INVALID_HANDLE;
Handle g_fnForceRespawn = INVALID_HANDLE;
Handle g_fnShouldGainInstant = INVALID_HANDLE;
Handle g_fnCreateRocketMissile = INVALID_HANDLE;
Handle g_fGetMaxClip1;

GlobalForward g_fwdCINSWeaponBallistic_finish_reload_POST;
GlobalForward g_fwdCINSWeaponMeleeBasePrimaryAttack;
GlobalForward g_fwdCBaseCombatCharacterOnChangeActiveWeaponPost;
GlobalForward g_gfwd_cinsweapon_onholstercomplete;
GlobalForward g_gfwd_cinsweapon_ondeploycomplete;
GlobalForward g_gfwd_CAOEGrenade_Detonate;
//GlobalForward g_fwdCINSWeaponBallisticPrimaryAttack;

DynamicDetour detourCINSWeaponBallisticFinishReload;
//DynamicDetour detour_CINSWeaponBallisticPrimaryAttack;
DynamicDetour detourCINSWeaponMeleeBasePrimaryAttack;
DynamicDetour detourCBaseCombatCharacterOnChangeActiveWeapon;

static void create_forward()
{
	g_fwdCINSWeaponBallistic_finish_reload_POST = new GlobalForward("on_ballistic_finish_reload_POST", ET_Ignore, Param_Cell);
	g_fwdCINSWeaponMeleeBasePrimaryAttack = new GlobalForward("on_CINSWEAPONMELEEBASE_primary_attack_POST", ET_Ignore, Param_Cell);
	g_fwdCBaseCombatCharacterOnChangeActiveWeaponPost = new GlobalForward("on_CBASECOMBATCHARACTER_on_change_active_weapon_POST", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
//	g_fwdCINSWeaponBallisticPrimaryAttack = new GlobalForward("OnCINSWeaponBallisticPrimaryAttack_POST", ET_Ignore, Param_Cell);
	g_gfwd_cinsweapon_onholstercomplete = new GlobalForward("CINSWeapon_OnHolsterComplete_Post", ET_Ignore, Param_Cell);
	g_gfwd_cinsweapon_ondeploycomplete = new GlobalForward("CINSWeapon_OnDeployComplete_Post", ET_Ignore, Param_Cell);
	g_gfwd_CAOEGrenade_Detonate = new GlobalForward("OnCAOEGrenade_Detonate_Post", ET_Ignore, Param_Cell);
}

Handle g_CBaseCombatCharacter_RemoveAllWeapons;
Handle g_CBaseCombatWeapon_Clip1;
Handle g_CBaseCombatWeapon_Clip2;
Handle g_CINSRules_ToggleSpawnZone;
Handle g_CINSRules_IsCounterAttack;
Handle g_CINSSpawnZone_PointInSpawnZone;
Handle g_GetBaseEntityByAddress;
Handle g_CINSWeapon_GetINSPlayerOwner;
Handle g_CINSPlayer_GetActiveINSWeapon;
Handle g_CINSPlayer_RemoveAllItems;
Handle g_CBaseDetonator_GetPlayerOwner;
Handle g_CTeam_GetAliveMembers;

static void init_sdk_calls()
{
	GameData gameData = LoadGameConfigFile("insurgency.games");
	if (null == gameData)
	{
		SetFailState("没有找到文件insurgency.games");
	}

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CINSWeapon::GetSlot");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_fnGetSolt = EndPrepSDKCall();
	if (INVALID_HANDLE == g_fnGetSolt)
	{
		SetFailState("SDKCALL初始化失败：CINSWeapon::GetSlot");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CINSPlayer::IsReadyToSpawn");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_fnIsReadyToSpawn = EndPrepSDKCall();
	if (INVALID_HANDLE == g_fnIsReadyToSpawn)
	{
		SetFailState("SDKCALL初始化失败：CINSPlayer::IsReadyToSpawn");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CINSPlayer::ForceRespawn");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_fnForceRespawn = EndPrepSDKCall();
	if (INVALID_HANDLE == g_fnForceRespawn)
	{
		SetFailState("SDKCALL初始化失败：CINSPlayer::ForceRespawn");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CINSPlayer::ShouldGainInstantSpawn");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_fnShouldGainInstant = EndPrepSDKCall();
	if (INVALID_HANDLE == g_fnShouldGainInstant)
	{
		SetFailState("SDKCALL初始化失败：CINSPlayer::ShouldGainInstantSpawn");
	}

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CINSWeapon::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_fGetMaxClip1 = EndPrepSDKCall();
	if (null == g_fGetMaxClip1)
	{
		SetFailState("没有找到函数\"CINSWeapon::GetMaxClip1\"!");
	}

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CBaseRocketMissile::CreateRocketMissile");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_ByValue);
	g_fnCreateRocketMissile = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CBaseCombatCharacter::RemoveAllWeapons");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_CBaseCombatCharacter_RemoveAllWeapons = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBaseCombatWeapon::Clip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_CBaseCombatWeapon_Clip1 = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBaseCombatWeapon::Clip2");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_CBaseCombatWeapon_Clip2 = EndPrepSDKCall();

	
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CINSRules::ToggleSpawnZone");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_CINSRules_ToggleSpawnZone = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CINSRules::IsCounterAttack");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_CINSRules_IsCounterAttack = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CINSSpawnZone::PointInSpawnZone");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, 0, VENCODE_FLAG_COPYBACK);
	g_CINSSpawnZone_PointInSpawnZone = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CINSSpawnZone::GetBaseEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	g_GetBaseEntityByAddress = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CINSWeapon::GetINSPlayerOwner");
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_CINSWeapon_GetINSPlayerOwner = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CINSPlayer::GetActiveINSWeapon");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_CINSPlayer_GetActiveINSWeapon = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CINSPlayer::RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_CINSPlayer_RemoveAllItems = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CBaseDetonator::GetPlayerOwner");
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_CBaseDetonator_GetPlayerOwner = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Signature, "CTeam::GetAliveMembers");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_CTeam_GetAliveMembers = EndPrepSDKCall();

	gameData.Close();
}


DynamicDetour g_dtr_cinsweapon_onholstercomplete;
DynamicDetour g_dtr_cinsweapon_ondeploycomplete;
DynamicDetour g_dtr_CAOEGrenade_Detonate;

static void init_detours(GameData gd)
{
	detourCINSWeaponBallisticFinishReload = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	if (null == detourCINSWeaponBallisticFinishReload)
	{
		SetFailState("create detour fail:detourTest");
	}

	if(!detourCINSWeaponBallisticFinishReload.SetFromConf(gd, SDKConf_Signature, "CINSWeaponBallistic::FinishReload"))
	{
		SetFailState("set detour fail:detourTest");
	}

	if(!detourCINSWeaponBallisticFinishReload.Enable(Hook_Post, HOOK_POST_CINSWEAPONBALLISIC_finish_reload))
	{
		SetFailState("enable detour fail:detourTest");
	}

	detourCINSWeaponMeleeBasePrimaryAttack = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	detourCINSWeaponMeleeBasePrimaryAttack.SetFromConf(gd, SDKConf_Signature, "CINSWeaponMeleeBase::PrimaryAttack");
	detourCINSWeaponMeleeBasePrimaryAttack.Enable(Hook_Post, HOOK_POST_CINSWEAPONMELEEBASE_primary_attack);

	detourCINSWeaponMeleeBasePrimaryAttack = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	detourCINSWeaponMeleeBasePrimaryAttack.SetFromConf(gd, SDKConf_Signature, "CINSWeaponMeleeBase::PrimaryAttack");
	detourCINSWeaponMeleeBasePrimaryAttack.Enable(Hook_Post, HOOK_POST_CINSWEAPONMELEEBASE_primary_attack);

	detourCBaseCombatCharacterOnChangeActiveWeapon = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	detourCBaseCombatCharacterOnChangeActiveWeapon.SetFromConf(gd, SDKConf_Signature, "CBaseCombatCharacter::OnChangeActiveWeapon");
	detourCBaseCombatCharacterOnChangeActiveWeapon.AddParam(HookParamType_CBaseEntity);
	detourCBaseCombatCharacterOnChangeActiveWeapon.AddParam(HookParamType_CBaseEntity);
	detourCBaseCombatCharacterOnChangeActiveWeapon.Enable(Hook_Post, HOOK_POST_CBASECOMBATCHARACTER_on_change_active_weapon);

	g_dtr_cinsweapon_onholstercomplete = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	g_dtr_cinsweapon_onholstercomplete.SetFromConf(gd, SDKConf_Signature, "CINSWeapon::OnHolsterComplete");
	g_dtr_cinsweapon_onholstercomplete.Enable(Hook_Post, CINSWeapon_OnHolsterComplete_Post_DHOOK);
	
	g_dtr_cinsweapon_ondeploycomplete = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	g_dtr_cinsweapon_ondeploycomplete.SetFromConf(gd, SDKConf_Signature, "CINSWeapon::OnDeployComplete");
	g_dtr_cinsweapon_ondeploycomplete.Enable(Hook_Post, CINSWeapon_OnDeployComplete_Post_DHOOK);

	
	g_dtr_CAOEGrenade_Detonate = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	g_dtr_CAOEGrenade_Detonate.SetFromConf(gd, SDKConf_Signature, "CAOEGrenade::Detonate");
	g_dtr_CAOEGrenade_Detonate.Enable(Hook_Post, CAOEGrenade_Detonate_Post_DHOOK);
}

any NATIVE_get_player_carry_weight(Handle hPlugin, int iParams)
{
	return GetEntProp(GetNativeCell(1), Prop_Send, "m_iCarryWeight", 4);
}

any NATIVE_set_player_carry_weight(Handle hPlugin, int iParams)
{
	return SetEntProp(GetNativeCell(1), Prop_Send, "m_iCarryWeight", GetNativeCell(2), 4);
}

any NATIVE_get_player_weight_cache(Handle hPlugin, int iParams)
{
	//Member: m_nWeightCache (offset 76) (type integer) (bits 32) ()
	return GetEntProp(GetNativeCell(1), Prop_Send, "m_nWeightCache", 4);
}

any NATIVE_set_player_weight_cache(Handle hPlugin, int iParams)
{
	//Member: m_nWeightCache (offset 76) (type integer) (bits 32) ()
	return SetEntProp(GetNativeCell(1), Prop_Send, "m_nWeightCache", GetNativeCell(2), 4);
}

any NATIVE_get_player_health(Handle hPlugin, int iParams)
{
	return GetEntProp(GetNativeCell(1), Prop_Send, "m_iHealth", 4);
}

any NATIVE_set_player_health(Handle hPlugin, int iParams)
{
	return SetEntProp(GetNativeCell(1), Prop_Send, "m_iHealth", GetNativeCell(2), 4);
}

any NATIVE_get_player_max_health(Handle hPlugin, int iParams)
{
	return GetEntProp(GetNativeCell(1), Prop_Send, "m_iMaxHealth", 4);
}

any NATIVE_set_player_max_health(Handle hPlugin, int iParams)
{
	return SetEntProp(GetNativeCell(1), Prop_Send, "m_iMaxHealth", GetNativeCell(2), 4);
}

any NATIVE_get_player_recieved_tokens(Handle hPlugin, int iParams)
{
	//Member: m_nRecievedTokens (offset 12) (type integer) (bits 8) (Unsigned)
	return GetEntProp(GetNativeCell(1), Prop_Send, "m_nRecievedTokens", 1);
}

any NATIVE_set_player_recieved_tokens(Handle hPlugin, int iParams)
{
	//Member: m_nRecievedTokens (offset 12) (type integer) (bits 8) (Unsigned)
	return SetEntProp(GetNativeCell(1), Prop_Send, "m_nRecievedTokens", GetNativeCell(2), 1); 
}

any NATIVE_get_player_available_tokens_tokens(Handle hPlugin, int iParams)
{
	//Member: m_nAvailableTokens (offset 8) (type integer) (bits 8) (Unsigned)
	return GetEntProp(GetNativeCell(1), Prop_Send, "m_nAvailableTokens", 1);
}

any NATIVE_set_player_available_tokens_tokens(Handle hPlugin, int iParams)
{
	//Member: m_nAvailableTokens (offset 8) (type integer) (bits 8) (Unsigned)
	return SetEntProp(GetNativeCell(1), Prop_Send, "m_nAvailableTokens", GetNativeCell(2), 1); 
}

any NATIVE_get_weapon_slot(Handle plugin, int iParams)
{
	return SDKCall(g_fnGetSolt, GetNativeCell(1));
}

any NATIVE_CINSPLAYER_is_ready_to_spawn(Handle hPlugin, int iParams)
{
	return SDKCall(g_fnIsReadyToSpawn, GetNativeCell(1));
}

any NATIVE_CINSPLAYER_force_respawn(Handle hPlugin, int iParams)
{
	return SDKCall(g_fnForceRespawn, GetNativeCell(1));
}

any NATIVE_CINSPLAYER_should_gain_instant_spawn(Handle hPlugin, int iParams)
{
	return SDKCall(g_fnShouldGainInstant, GetNativeCell(1));
}

any NATIVE_create_rocket_missile(Handle hPlugin, int iParams)
{
	char missile_name[64];
	GetNativeString(2, missile_name, sizeof(missile_name));

	float pos[3];
	GetNativeArray(3, pos, sizeof(pos));

	float angle[3];
	GetNativeArray(4, angle, sizeof(angle));

	return SDKCall(g_fnCreateRocketMissile, GetNativeCell(1), missile_name, pos, angle);
}

any CINSWeapon_GetMaxClip1_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_fGetMaxClip1, GetNativeCell(1));
}

any CBaseCombatCharacter_RemoveAllWeapons_NATIVE_CALL(Handle plugin, int params)
{
	return SDKCall(g_CBaseCombatCharacter_RemoveAllWeapons, GetNativeCell(1));
}

any CBaseCombatWeapon_Clip1_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CBaseCombatWeapon_Clip1, GetNativeCell(1));
}

any CBaseCombatWeapon_Clip2_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CBaseCombatWeapon_Clip2, GetNativeCell(1));
}

any CINSRules_ToggleSpawnZone_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CINSRules_ToggleSpawnZone, GetNativeCell(1), GetNativeCell(2));
}

any CINSRules_IsCounterAttack_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CINSRules_IsCounterAttack);
}

any CINSSpawnZone_PointInSpawnZone_NATIVE_CALL(Handle hPlugin, int iParams)
{
	float origin[3];
	GetNativeArray(1, origin, sizeof(origin));
	return SDKCall(g_CINSSpawnZone_PointInSpawnZone, origin, GetNativeCell(2), GetNativeCell(3));
}

any GetBaseEntityByAddress_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_GetBaseEntityByAddress, GetNativeCell(1));
}

any CINSWeapon_GetINSPlayerOwner_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CINSWeapon_GetINSPlayerOwner, GetNativeCell(1));
}

any CINSPlayer_GetActiveINSWeapon_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CINSPlayer_GetActiveINSWeapon, GetNativeCell(1));
}

any CINSPlayer_RemoveAllItems_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CINSPlayer_RemoveAllItems, GetNativeCell(1), GetNativeCell(2));
}

any CBaseDetonator_GetPlayerOwner_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CBaseDetonator_GetPlayerOwner, GetNativeCell(1));
}

any CTeam_GetAliveMembers_NATIVE_CALL(Handle hPlugin, int iParams)
{
	return SDKCall(g_CTeam_GetAliveMembers, GetNativeCell(1));
}

static MRESReturn HOOK_POST_CINSWEAPONBALLISIC_finish_reload(int entity, DHookReturn hReturn)
{
	Call_StartForward(g_fwdCINSWeaponBallistic_finish_reload_POST);
	Call_PushCell(entity);
	Call_Finish();
	return MRES_Ignored;
}

/*
static MRESReturn HOOK_POST_CINSWeaponBallisticPrimaryAttack(int entity, DHookReturn hReturn)
{
	Call_StartForward(g_fwdCINSWeaponMeleeBasePrimaryAttack);
	Call_PushCell(entity);
	Call_Finish();
	return MRES_Ignored;
}
*/

static MRESReturn HOOK_POST_CINSWEAPONMELEEBASE_primary_attack(int entity, DHookReturn hReturn)
{
	Call_StartForward(g_fwdCINSWeaponMeleeBasePrimaryAttack);
	Call_PushCell(entity);
	Call_Finish();
	return MRES_Ignored;
}

static MRESReturn HOOK_POST_CBASECOMBATCHARACTER_on_change_active_weapon(int entity, DHookReturn hReturn, DHookParam hParam)
{
	Call_StartForward(g_fwdCBaseCombatCharacterOnChangeActiveWeaponPost);
	Call_PushCell(entity);
	Call_PushCell(hParam.IsNull(1) ? (-1) : (hParam.Get(1)));
	Call_PushCell(hParam.IsNull(2) ? (-1) : (hParam.Get(2)));
	Call_Finish();
	return MRES_Ignored;
}

static MRESReturn CINSWeapon_OnHolsterComplete_Post_DHOOK(int entity, DHookReturn hReturn)
{
	Call_StartForward(g_gfwd_cinsweapon_onholstercomplete);
	Call_PushCell(entity);
	Call_Finish();
	return MRES_Ignored;
}

static MRESReturn CINSWeapon_OnDeployComplete_Post_DHOOK(int entity, DHookReturn hReturn)
{
	Call_StartForward(g_gfwd_cinsweapon_ondeploycomplete);
	Call_PushCell(entity);
	Call_Finish();
	return MRES_Ignored;
}

static MRESReturn CAOEGrenade_Detonate_Post_DHOOK(int entity)
{
	Call_StartForward(g_gfwd_CAOEGrenade_Detonate);
	Call_PushCell(entity);
	Call_Finish();
	return MRES_Ignored;
}