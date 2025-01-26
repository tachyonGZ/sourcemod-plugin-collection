#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <vectorhint>

#define PLUGIN_NAME "Change Level"
#define PLUGIN_AUTHOR "tachyon_gz_"
#define PLUGIN_DESCRIPTION "change server level by client vote"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL ""

#define MAX_LEVELNAME_LENGTH 256

#define X_INDEX -2
#define Y_INDEX 1

public Plugin myinfo = {
	name= PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

ConVar g_cvar_delay;
ConVar g_cvar_vote_duration;

ConVar g_cvar_mapcyclefile;

ArrayList g_list_levelname;

Menu g_menu_level;

public void OnPluginStart()
{
	g_cvar_delay = CreateConVar("sm_change_level_delay", "5.0");
	g_cvar_vote_duration = CreateConVar("sm_change_vote_duration", "10");

	g_cvar_mapcyclefile = FindConVar("mapcyclefile");

	g_list_levelname = new ArrayList(MAX_LEVELNAME_LENGTH);

	char mapcycle_filename[64];
	g_cvar_mapcyclefile.GetString(mapcycle_filename, sizeof(mapcycle_filename));
	PrintToServer("mapcycle file : %s", mapcycle_filename);

	FileToArrayList(mapcycle_filename, g_list_levelname);

	g_menu_level = CreateChangeLevelMenu(g_list_levelname);

	RegConsoleCmd("m", ShowChangeLevelMenu_ConCmd, "show a menu which can change level to client");

	VectorHint_AddHint(X_INDEX, Y_INDEX);
}

void FileToArrayList(char[] filename, ArrayList list)
{
	File mapcycle_file = OpenFile(filename, "r");
	if (null == mapcycle_file)
	{
		SetFailState("Can not open file:%s", filename);
	}

	while (!IsEndOfFile(mapcycle_file))
	{
		char line[MAX_LEVELNAME_LENGTH];
		if(!ReadFileLine(mapcycle_file, line, sizeof(line)))
		{
			mapcycle_file.Close();
			SetFailState("can not read file line");
		}

		//PrintToServer(line);
		list.PushString(line);
	}

	mapcycle_file.Close();
}

Menu CreateChangeLevelMenu(ArrayList list_levelname)
{
	Menu menu = new Menu(ChangeLevel_MenuHandler);

	for (int i = 0; i < list_levelname.Length; i++)
	{
		char levelname[MAX_LEVELNAME_LENGTH];
		list_levelname.GetString(i, levelname, sizeof(levelname));
		menu.AddItem(levelname, levelname);
	}

	menu.ExitButton = true;
	menu.SetTitle("更换游玩地图 /m或!m");
	return menu;
}

Action ShowChangeLevelMenu_ConCmd(int client, int nArgs)
{
	g_menu_level.Display(client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

int ChangeLevel_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char levelname[MAX_LEVELNAME_LENGTH];
			menu.GetItem(param2, levelname, sizeof(levelname));
			DoChangeLevelVote(levelname);
		}
	}
	return 0;
}

void DoChangeLevelVote(char[] levelname)
{
	if (IsVoteInProgress())
	{
		return;
	}

	Menu menu = new Menu(ChangeLevelVote_MenuHandler);

	menu.VoteResultCallback = ChangeLevelVote_VoteHandler;
	menu.ExitButton = true;
	menu.SetTitle("您是否赞成将当前游玩的地图更换为%s?", levelname);
	menu.AddItem(levelname, "赞成 :)");
	menu.AddItem("", "反对 :(");
	menu.DisplayVoteToAll(g_cvar_vote_duration.IntValue);
}


int ChangeLevelVote_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

void ChangeLevelVote_VoteHandler(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	PrintToServer("%d %d %d", num_items, item_info[0][VOTEINFO_ITEM_VOTES], item_info[0][VOTEINFO_ITEM_INDEX]);

	if (!IsVotePass(num_items, item_info))
	{
		return;
	}

	char levelname[MAX_LEVELNAME_LENGTH];
	menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], levelname, sizeof(levelname));

	PrepareChangeLevel(levelname);
}

bool IsVotePass(int num_items, const int[][] item_info)
{
	return (1 == num_items && item_info[0][VOTEINFO_ITEM_INDEX] == 0) || (item_info[0][VOTEINFO_ITEM_VOTES] > item_info[1][VOTEINFO_ITEM_VOTES]);
}

void PrepareChangeLevel(char[] levelname)
{
	DataPack pack = new DataPack();
	CreateTimer(g_cvar_delay.FloatValue, ChangeLevel_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteString(levelname);

	
	char hint[64];
	FormatEx(hint, sizeof(hint), "服务器将在%.0f秒后将更换地图", g_cvar_delay.FloatValue, levelname);
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
		{
			continue;
		}

		VectorHint_SetHint(X_INDEX, Y_INDEX, client, hint);
	}
}


Action ChangeLevel_Timer(Handle timer, DataPack pack)
{
	pack.Reset();

	char levelname[MAX_LEVELNAME_LENGTH];
	pack.ReadString(levelname, sizeof(levelname));

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
		{
			continue;
		}

		VectorHint_HideHint(X_INDEX, Y_INDEX, client);
	}

	ForceChangeLevel(levelname, "test");

	return Plugin_Continue;
}