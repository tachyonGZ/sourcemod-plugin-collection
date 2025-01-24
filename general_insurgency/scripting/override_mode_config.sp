#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include "utility_api"

#define PLUGIN_NAME "Override Mode Config"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "Override Mode Config"
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

KeyValues g_kv;

public void OnMapInit(const char[] mapName)
{
	OverrideConfig();
}

public void OnMapStart()
{
	
	OverrideConfig();
}

public void OnPluginStart()
{
	char plugin_filename[PLATFORM_MAX_PATH];
	GetPluginFilename(null, plugin_filename, sizeof(plugin_filename));
	SplitString(plugin_filename, ".smx", plugin_filename, sizeof(plugin_filename));

	// load config
	char path[PLATFORM_MAX_PATH];
	FormatEx(path, sizeof(path), "configs/%s/%s.cfg", plugin_filename, plugin_filename);
	BuildPath(Path_SM, path, sizeof(path), path);

	if(!FileExists(path))
	{
		SetFailStateFileNotExists(path);
		return;
	}

	g_kv = new KeyValues("override_mode_config");
	
	if (!g_kv.ImportFromFile(path))
	{
		delete g_kv;
		SetFailState("config file format error:%s", path);
	}
}

// override map config
void OverrideConfig()
{
	char sz_gamemode[32];
	FindConVar("mp_gamemode").GetString(sz_gamemode, sizeof(sz_gamemode));


	char filename[PLATFORM_MAX_PATH];
	g_kv.GetString(sz_gamemode, filename, sizeof(filename));

	char cmd_buf[256];
	ServerCommandEx(cmd_buf, sizeof(cmd_buf), "exec %s", filename);

	
	//PrintToServer("%s %s %s", sz_gamemode,  filename, cmd_buf);
}