#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include "utility_api"

#define PLUGIN_NAME "玩家加入提示"
#define PLUGIN_AUTHOR "tachyon_gz_"
#define PLUGIN_DESCRIPTION "玩家加入提示"
#define PLUGIN_VERSION "3.9"
#define PLUGIN_URL "https://github.com/TFXX"

#define MAX_ROUND_TIP_LENGTH 64

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

//ConVar g_cvarRoundTipsEnabled;
ConVar g_cvarWelcomeMenuEnabled;
ConVar g_cvarWelcomeMenuTime;
ConVar g_cvarEnableJoinTeamEcho;


enum struct RoundTips
{
	ArrayList list;
	int cnt;

	void Initialize()
	{
		this.list = new ArrayList(MAX_ROUND_TIP_LENGTH);
		this.cnt = 0;
	}

	void Reload()
	{
		char path[PLATFORM_MAX_PATH];
		FormatEx(path, sizeof(path), "configs/round-tips/round-tips.cfg");
		BuildPath(Path_SM, path, sizeof(path), path);

		UtilityAPI_CreateConfigIfNotExist(path, RoundTips_ConfigInitializer);

		KeyValues kv = new KeyValues("round-tips");
		if (!kv.ImportFromFile(path))
		{
			delete kv;
			ThrowError("failed read Keyvalues from %s", path);
		}

		if (!kv.GotoFirstSubKey())
		{
			delete kv;
			ThrowError("failed goto first subkey: %s", path);
		}

		this.list.Clear();
		this.cnt = 0;

		do{
			char sz_round_tip[256];
			kv.GetString("tip", sz_round_tip, sizeof(sz_round_tip));
			this.list.PushString(sz_round_tip);
		}while(kv.GotoNextKey());
	}

	void PrintToServer()
	{
		for (int i = 0; i < this.list.Length; i++)
		{
			char[] sz_round_tip = new char[this.list.BlockSize];
			this.list.GetString(i, sz_round_tip, this.list.BlockSize);
			PrintToServer("%s", sz_round_tip);
		}
	}

	void Get(char[] round_tip, int length)
	{
		this.list.GetString(this.cnt, round_tip, length);
		this.cnt = (this.cnt + 1) % this.list.Length;
	}
}

RoundTips g_round_tips;

Menu g_menu_welcome;

public void OnPluginStart()
{
	//g_cvarRoundTipsEnabled = CreateConVar("sm_join_msg_round_tips_enabled", "1", "是否开启会和提示功能", FCVAR_NONE);
	g_cvarEnableJoinTeamEcho = CreateConVar("sm_join_msg_enable_join_team_echo", "0", "是否开启加入团队回显", FCVAR_NONE);
	g_cvarWelcomeMenuEnabled = CreateConVar("sm_join_msg_welcome_menu_enabled", "1", "是否开启欢迎菜单功能", FCVAR_NONE);
	g_cvarWelcomeMenuTime = CreateConVar("sm_join_msg_welcome_menu_time", "15", "欢迎菜单显示时间，0代表手动关闭菜单", FCVAR_NONE);

	HookEventEx("round_start", RoundStartPost, EventHookMode_PostNoCopy);
	HookEventEx("round_freeze_end", RoundFreezeEndPost, EventHookMode_PostNoCopy);
	
	HookEventEx("player_team", PlayerTeam_EVENT_POST, EventHookMode_Post);
	
	RegServerCmd("reload-round-tips", ReloadRoundTips_SrvCmd, "重新加载回合提示");

	g_menu_welcome = CreateWelcomeMenu();

	g_round_tips.Initialize();
	g_round_tips.Reload();
	g_round_tips.PrintToServer();
}

Menu CreateWelcomeMenu()
{
	g_menu_welcome = new Menu(Welcome_MenuHandler);
	g_menu_welcome.AddItem("", "服务器QQ群:862188702");
	g_menu_welcome.AddItem("", "服务器oopz频道ID:198819909");
	g_menu_welcome.AddItem("", "服务器oopz频道链接:https://oopz.cn/i/n9ayam");
	g_menu_welcome.ExitButton = true;
	return g_menu_welcome;
}

void RoundStartPost(Event event, const char[] szName, bool bDontBoardCast)
{
	char round_tip[MAX_ROUND_TIP_LENGTH];
	g_round_tips.Get(round_tip, sizeof(round_tip));
	PrintToChatAll("提示：%s", round_tip);
}

void RoundFreezeEndPost(Event event, const char[] szName, bool bDontBoardCast)
{

}

static void PlayerTeam_EVENT_POST(Event event, const char[] szName, bool bDontBoardCast)
{
	EchoPlayerJoinedTeam(GetClientOfUserId(event.GetInt("userid")), event.GetInt("team"));
}

Action ReloadRoundTips_SrvCmd(int nArgs)
{
	g_round_tips.Reload();
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client)) return;

	ShowWelcomeMenuToClient(g_menu_welcome, client, g_cvarWelcomeMenuTime.IntValue);
}

void ShowWelcomeMenuToClient(Menu welcome_menu, int client, int time)
{
	if (!g_cvarWelcomeMenuEnabled.BoolValue)
	{
		return;
	}

	char client_name[MAX_NAME_LENGTH];
	GetClientName(client, client_name, sizeof(client_name));
	welcome_menu.SetTitle("尊敬的%s，欢迎您游玩本服务器", client_name);

	welcome_menu.Display(client, (0 == time)?(MENU_TIME_FOREVER):(time));
}

int Welcome_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

void EchoPlayerJoinedTeam(int client, int team)
{
	if (!g_cvarEnableJoinTeamEcho.BoolValue)
	{
		return;
	}

	if (IsFakeClient(client))
	{
		return;
	}

	char team_name[32];
	GetTeamName(team, team_name, sizeof(team_name));
	PrintToChatAll("%N已加入【%s】", client, team_name);
}

void RoundTips_ConfigInitializer(const char[] path)
{
	KeyValues kv = new KeyValues("round-tips");
	kv.JumpToKey("0", true);
	kv.SetString("tip", "I am a exmaple round tip");
	kv.Rewind();
	kv.JumpToKey("1", true);
	kv.SetString("tip", "I am another exmaple round tip");
	kv.Rewind();
	if (!kv.ExportToFile(path))
	{
		delete kv;
		ThrowError("failed write Keyvalues to %s", path);
	}
}