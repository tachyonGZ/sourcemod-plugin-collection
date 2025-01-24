#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include "utility_api"

#define PLUGIN_NAME "Override Hostname"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "使服务器名称中的中文字符可以正常显示"
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

ConVar g_cvar_default_hostname;

enum struct Hostname
{
	char hostname[256];

	void Reload()
	{
		char config_filename[PLATFORM_MAX_PATH];
		GetPluginFilename(INVALID_HANDLE, config_filename, sizeof(config_filename));
		SplitString(config_filename, ".smx", config_filename, sizeof(config_filename));

		char path[PLATFORM_MAX_PATH];
		FormatEx(path, sizeof(path), "configs/%s/%s.cfg", config_filename, config_filename);
		BuildPath(Path_SM, path, sizeof(path), path);

		UtilityAPI_CreateConfigIfNotExist(path, Hostname_ConfigInitializer);

		KeyValues kv = new KeyValues(config_filename);
		if (!kv.ImportFromFile(path))
		{
			delete kv;
			ThrowError("failed read Keyvalues from %s", path);
		}

		kv.GetString("hostname", this.hostname, sizeof(this.hostname));
	}

	void Update()
	{
		FindConVar("hostname").SetString(this.hostname, true, true);
	}
}

Hostname g_hostname;

public void OnPluginStart()
{
	g_cvar_default_hostname = CreateConVar("sm_hostname_override_default_hostname", "I am a server");

	RegServerCmd("sm-reload-hostname", SRC_CMD_reload_hostname, "reload hostname from config");

	g_hostname.Reload();
	g_hostname.Update();
}

Action SRC_CMD_reload_hostname(int nArgs)
{
	g_hostname.Reload();
	g_hostname.Update();
	return Plugin_Continue;
}

void Hostname_ConfigInitializer(const char[] path)
{
	char plugin_filename[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, plugin_filename, sizeof(plugin_filename));
	SplitString(plugin_filename, ".smx", plugin_filename, sizeof(plugin_filename));
	
	KeyValues kv = new KeyValues(plugin_filename);

	char hostname[256];
	g_cvar_default_hostname.GetString(hostname, sizeof(hostname));
	kv.SetString("hostname", hostname);
	if (!kv.ExportToFile(path))
	{
		delete kv;
		ThrowError("failed write Keyvalues to %s", path);
	}
}