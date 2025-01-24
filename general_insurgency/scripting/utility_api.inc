#if defined __UTILITY_API__
  #endinput
#endif
#define __UTILITY_API__

typedef ConfigInitializer = function void(const char[] path);
native void UtilityAPI_CreateConfigIfNotExist(const char[] path, ConfigInitializer config_initializer);

native bool UtilityAPI_IsNothingBetweenClient(int client, int client_other);

stock void SetFailStateNotFindConvar(char[] plugin_name, ConVar cvar)
{
	char convar_name[256];
	cvar.GetName(convar_name, sizeof(convar_name));
	SetFailState("%s]没有找到Convar：%s", plugin_name, convar_name);
}

stock void SetFailStateFileNotExists(char[] file_path)
{
	SetFailState("没有找到文件：%s", file_path);
}