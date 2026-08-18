#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

#pragma newdecls required

Handle g_hNoShakeCookie;
ConVar g_Cvar_NoShakeGlobal;
ConVar g_Cvar_ForceShake;

bool g_bLate = false;

bool g_bNoShake[MAXPLAYERS + 1] = {false, ...};
bool g_bNoShakeGlobal = false;
bool g_bForceShake = false;

public Plugin myinfo =
{
	name 			= "NoShake",
	author 			= "BotoX, .Rushaway",
	description 	= "Disable env_shake",
	version 		= "1.0.8",
	url 			= ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("noshake.phrases");

	RegConsoleCmd("sm_shake", Command_Shake, "[NoShake] Disables or enables screen shakes.");
	RegConsoleCmd("sm_noshake", Command_Shake, "[NoShake] Disables or enables screen shakes.");

	g_hNoShakeCookie = RegClientCookie("noshake_cookie", "NoShake", CookieAccess_Protected);
	SetCookieMenuItem(CookieHandler, 0, "NoShake Settings");

	g_Cvar_NoShakeGlobal = CreateConVar("sm_noshake_global", "0", "Disable screenshake globally.", 0, true, 0.0, true, 1.0);
	g_bNoShakeGlobal = g_Cvar_NoShakeGlobal.BoolValue;
	g_Cvar_NoShakeGlobal.AddChangeHook(OnConVarChanged);

	g_Cvar_ForceShake = CreateConVar("sm_force_shake", "0", "Force screenshake. (This convar takes priority over sm_noshake_global)", 0, true, 0.0, true, 1.0);
	g_bForceShake = g_Cvar_ForceShake.BoolValue;
	g_Cvar_ForceShake.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true);

	HookUserMessage(GetUserMessageId("Shake"), MsgHook, true);

	if (!g_bLate)
		return;

	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientConnected(i) || IsFakeClient(i) || !AreClientCookiesCached(i))
			continue;

		ReadClientCookies(i);
	}

	g_bLate = false;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_Cvar_ForceShake)
	{
		CPrintToChatAll("%t", StringToInt(newValue) > StringToInt(oldValue) ? "NoShake Force Enabled" : "NoShake Force Disabled");
		g_bForceShake = StringToInt(newValue) != 0;
	}
	else if (convar == g_Cvar_NoShakeGlobal)
	{
		CPrintToChatAll("%t", StringToInt(newValue) > StringToInt(oldValue) ? "NoShake Global Enabled" : "NoShake Global Disabled");
		g_bNoShakeGlobal = StringToInt(newValue) != 0;
	}
}

stock void SetNoShake(int client)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	g_bNoShake[client] = !g_bNoShake[client];
	CReplyToCommand(client, "%t", g_bNoShake[client] ? "NoShake Personal Enabled" : "NoShake Personal Disabled");
	SetClientCookie(client, g_hNoShakeCookie, g_bNoShake[client] ? "1" : "0");
}

public void OnClientCookiesCached(int client)
{
	ReadClientCookies(client);
}

public void ReadClientCookies(int client)
{
	static char sCookieValue[2];
	GetClientCookie(client, g_hNoShakeCookie, sCookieValue, sizeof(sCookieValue));
	g_bNoShake[client] = StringToInt(sCookieValue) != 0;
}

public Action MsgHook(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (g_bForceShake)
		return Plugin_Continue;

	if (playersNum == 1 && (g_bNoShakeGlobal || g_bNoShake[players[0]]))
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public Action Command_Shake(int client, int args)
{
	if (g_bForceShake)
	{
		CReplyToCommand(client, "%t", "NoShake Force Notice");
		return Plugin_Handled;
	}

	if (g_bNoShakeGlobal)
	{
		CReplyToCommand(client, "%t", "NoShake Global Notice");
		return Plugin_Handled;
	}

	SetNoShake(client);
	return Plugin_Handled;
}

public void CookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_SelectOption:
		{
			NotifierSetting(client);
		}
	}
}

public void NotifierSetting(int client)
{
	Menu menu = new Menu(NotifierSettingHandler, MENU_ACTIONS_ALL);

	char title[64];
	FormatEx(title, sizeof(title), "%T", "NoShake Menu Title", client);
	menu.SetTitle(title);

	char shake[64];
	FormatEx(shake, sizeof(shake), "%T", "NoShake Menu Item", client);

	menu.AddItem("noshake", shake);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NotifierSettingHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_DisplayItem:
		{
			char type[32], info[64], display[64];
			menu.GetItem(param2, info, sizeof(info));
			if (strcmp(info, "noshake", false) == 0)
			{
				FormatEx(type, sizeof(type), "%T", g_bNoShake[param1] ? "NoShake State Enabled" : "NoShake State Disabled", param1);
				FormatEx(display, sizeof(display), "%T", "NoShake Menu Display", param1, type);
				return RedrawMenuItem(display);
			}
		}
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			if (strcmp(info, "noshake", false) == 0)
				SetNoShake(param1);

			NotifierSetting(param1);
		}
		case MenuAction_Cancel:
		{
			ShowCookieMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}
