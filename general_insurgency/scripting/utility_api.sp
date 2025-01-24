#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include "utility_api"

#define PLUGIN_NAME "Utility API"
#define PLUGIN_AUTHOR ""
#define PLUGIN_DESCRIPTION "provide API of utility"
#define PLUGIN_VERSION ""
#define PLUGIN_URL ""

public Plugin myinfo = {
	name= PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("UtilityAPI_CreateConfigIfNotExist", Native_CreateConfigIfNotExist);
	CreateNative("UtilityAPI_IsNothingBetweenClient", Native_IsNothingBetweenClient);
	RegPluginLibrary("utility-api");
	return APLRes_Success;
}

any Native_CreateConfigIfNotExist(Handle plugin, int args)
{
	int path_length;
	GetNativeStringLength(1, path_length);
	char[] path = new char[path_length + 1];
	GetNativeString(1, path, path_length + 1);

	char[] dir_path = new char[path_length + 1];
	strcopy(dir_path, FindCharInString(path, '/', true) + 1, path);

	PrivateForward pfwd = new PrivateForward(ET_Ignore, Param_String);
	pfwd.AddFunction(plugin, GetNativeFunction(2));

	if (!DirExists(dir_path))
	{
		if(!CreateDirectory(dir_path, 777))
		{
			ThrowNativeError(SP_ERROR_NATIVE, "failed to create path: %s", dir_path);
		}
	}

	if(FileExists(path)) return false;

	File file = OpenFile(path, "w");
	if (null == file)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "failed to create file: %s", path);
	}
	file.Close();

	Call_StartForward(pfwd);
	Call_PushString(path);
	if (SP_ERROR_NONE != Call_Finish())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "failed call forward");
	}

	return true;
}

any Native_IsNothingBetweenClient(Handle plugin, int args)
{
	int client[2];
	client[0] = GetNativeCell(1);
	client[1] = GetNativeCell(2);

	float origin[2][3];
	GetClientEyePosition(client[0], origin[0]);
	GetClientEyePosition(client[1], origin[1]);
	
	Handle tr = TR_TraceRayFilterEx(origin[0], origin[1], MASK_PLAYERSOLID, RayType_EndPoint, IsNothingBetweenClient_Filter, client[0]);

	return !TR_DidHit(tr) || (TR_GetEntityIndex(tr) == client[1]);
}

bool IsNothingBetweenClient_Filter(int entity, int contentsMask, int client)
{
	return entity != client;
}