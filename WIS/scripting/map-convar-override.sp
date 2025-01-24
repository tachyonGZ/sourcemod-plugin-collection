#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include "INSExtendAPI"

#define PLUGIN_NAME "Map Convar 重载"
#define PLUGIN_AUTHOR "tachyon_gz_"
#define PLUGIN_DESCRIPTION "Map Convar 重载"
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

KeyValues g_kv_theater;

ConVar g_cvar_hostport;

public void OnPluginStart()
{
	PrintToServer("%sV%s]initializing...", PLUGIN_NAME, PLUGIN_VERSION);

	g_cvar_hostport = FindConVar("hostport");

	
	LoadTheaterConfig(g_kv_theater);

	OverrideTheater();
	
	PrintToServer("%sV%s]initialized successfully. :)", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnMapStart()
{
	OverrideTheater();
}

void LoadTheaterConfig(KeyValues &kv)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/theater-override.cfg");

	if(!FileExists(path))
	{
		SetFailStateFileNotExists(path);
		return;
	}

	kv = new KeyValues("theater-override");
	
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		SetFailState("config file format error:%s", path);
	}
}

void OverrideTheater()
{
	char hostport[8];
	g_cvar_hostport.GetString(hostport, sizeof(hostport));

	g_kv_theater.Rewind();
	if (!g_kv_theater.JumpToKey(hostport))
	{
		PrintToServer("can't find mp_theater_override dedicated for server which port is %s.", hostport);
		return;
	}

	char theater_file[256];
	g_kv_theater.GetString("mp_theater_override", theater_file, sizeof(theater_file));

	FindConVar("mp_theater_override").SetString(theater_file);

	PrintToServer("theater file used by server(port is %s) has been overridden.", hostport);
}