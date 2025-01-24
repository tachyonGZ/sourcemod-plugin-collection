#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_NAME "Remove Blockzone"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "Remove Blockzone"
#define PLUGIN_VERSION ""
#define PLUGIN_URL ""

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntity(entity)) return;

	if (!StrEqual("ins_blockzone", classname, false)) return;

	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	RemoveEntity(entity);

	PrintToServer("remove a blockzone: %s", name);
}