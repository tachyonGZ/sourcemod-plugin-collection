#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include "INSExtendAPI"

#define PLUGIN_NAME "地图池文件重载"
#define PLUGIN_AUTHOR "tachyon_gz_"
#define PLUGIN_DESCRIPTION "地图池文件重载"
#define PLUGIN_VERSION "1.1"
#define PLUGIN_URL "https://github.com/TFXX"

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

KeyValues g_kv_mapcycle_link;

public void OnPluginStart()
{
	PrintToServer("%sV%s]initializing...", PLUGIN_NAME, PLUGIN_VERSION);

	LoadMapcycleFile(g_kv_mapcycle_link);
	UpdateMapcycleFile(g_kv_mapcycle_link);

	PrintToServer("%sV%s]initialized successfully. :)", PLUGIN_NAME, PLUGIN_VERSION);
}

void LoadMapcycleFile(KeyValues &kv)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/mapcyclefile-override.cfg");

	if(!FileExists(path))
	{
		SetFailStateFileNotExists(path);
		return;
	}

	kv = new KeyValues("mapcyclefile-override");
	
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		SetFailState("config file format error:%s", path);
	}
}

void UpdateMapcycleFile(KeyValues kv)
{
	char hostport[8];
	FindConVar("hostport").GetString(hostport, sizeof(hostport));

	kv.Rewind();
	if (!kv.JumpToKey(hostport))
	{
		PrintToServer("can't find mapcyclefile dedicated for server which port is %s.", hostport);
		return;
	}

	char mapcyclefile[256];
	kv.GetString("mapcyclefile", mapcyclefile, sizeof(mapcyclefile));

	FindConVar("mapcyclefile").SetString(mapcyclefile);

	PrintToServer("mapcyclefile used by server(port is %s) has been overridden", hostport);
}