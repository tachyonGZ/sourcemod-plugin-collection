#if defined _INS_EXTEND_API_
  #endinput
#endif
#define _INS_EXTEND_API_

#define TEAM_SPECTATE 1
#define TEAM_SECURITY 2
#define TEAM_INSURGENT 3

forward void on_ballistic_finish_reload_POST(int weapon);
forward void on_CINSWEAPONMELEEBASE_primary_attack_POST(int weapon);
forward void on_CBASECOMBATCHARACTER_on_change_active_weapon_POST(int client, int prevWeapon, int newWeapon);
forward void CINSWeapon_OnHolsterComplete_Post(int weapon);
forward void CINSWeapon_OnDeployComplete_Post(int weapon);
forward void OnCAOEGrenade_Detonate_Post(int aoe_grenade_entity);

native int get_player_carry_weight(int client);

native void set_player_carry_weight(int client, int iCarryWeight);

native int get_player_weight_cache(int client);

native void set_player_weight_cache(int client, const int nWeightCache);

native int get_player_health(const int client);

native int set_player_health(const int client, const int iHealth);

native int set_player_max_health(const int client, const int iMaxHealth)

native int get_player_max_health(const int client);

native int get_player_recieved_tokens(const int client);

native void set_player_recieved_tokens(const int client, const int nRecievedTokens);

native int get_player_available_tokens_tokens(const int client);

native void set_player_available_tokens_tokens(const int client, const int nAvailableTokens);

native int get_weapon_slot(const int weapon);

native bool CINSPLAYER_is_ready_to_spawn(const int client);

native bool CINSPLAYER_force_respawn(const int client);

native bool CINSPLAYER_should_gain_instant_spawn(const int client);

native void CreateRocketMissle(int client, char[] szMissleName, float pos[3], float angle[3]);
native int CINSWEAPON_get_max_clip_1(const int weapon);
native int CBaseCombatCharacter_RemoveAllWeapons(int client);
native int CBaseCombatWeapon_Clip1(int weapon);
native int CBaseCombatWeapon_Clip2(int weapon);
native void CINSRules_ToggleSpawnZone(int index, bool value);
native bool CINSRules_IsCounterAttack();
native void CINSSpawnZone_PointInSpawnZone(float origin[3], int spawn_point_entity, Address p_spawn_zone);
native int GetBaseEntityByAddress(Address ptr);
//_ZN10CINSWeapon17GetINSPlayerOwnerEv
native int CINSWeapon_GetINSPlayerOwner(int weapon);
//_ZNK10CINSPlayer18GetActiveINSWeaponEv
native int CINSPlayer_GetActiveINSWeapon(int client);
//_ZN10CINSPlayer14RemoveAllItemsEb
native void CINSPlayer_RemoveAllItems(int client, bool remove_suit);
//_ZNK14CBaseDetonator14GetPlayerOwnerEv
native int CBaseDetonator_GetPlayerOwner(int base_detonator);

native int CTeam_GetAliveMembers(int team_entity);

// 获取当前的推进点索引
stock int get_active_push_point_index()
{
	int res = FindEntityByClassname(-1, "ins_objective_resource");
	if (res == -1)
	{
		SetFailState("没有找到实体：ins_objective_resource");
		return -1;
	}
	return GetEntProp(res, Prop_Send, "m_nActivePushPointIndex");
}

stock int get_team_lives(int team)
{
	int livesCnt = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}

		if (GetClientTeam(i) != team)
		{
			continue;
		}

		livesCnt += 1;
	}
	return livesCnt
}

stock int get_team_clients(int team)
{
	int clientsCnt = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}

		if (GetClientTeam(i) != team)
		{
			continue;
		}

		clientsCnt += 1;
	}
	return clientsCnt
}