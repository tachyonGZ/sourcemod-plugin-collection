#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <vectorhint>

#define PLUGIN_NAME "Vector Hint Refresh"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "Vector Hint Refresh"
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

public void OnMapStart()
{
	CreateTimer(1.0, Frame, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

Action Frame(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
		{
			continue;
		}

		VectorHint_PrintHint(client);
	}

	return Plugin_Continue;
}