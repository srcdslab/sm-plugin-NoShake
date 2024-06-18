#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

#pragma newdecls required

Handle g_hNoShakeCookie;
ConVar g_Cvar_NoShakeGlobal;
ConVar g_Cvar_ForceShake;

bool g_bNoShake[MAXPLAYERS + 1] = {false, ...};
bool g_bNoShakeGlobal = false;
bool g_bForceShake = false;

public Plugin myinfo =
{
	name 			= "NoShake",
	author 			= "BotoX, .Rushaway",
	description 	= "Disable env_shake",
	version 		= "1.0.4",
	url 			= ""
};

public void OnPluginStart()
{
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

	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i))
			OnClientPutInServer(i);
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_Cvar_ForceShake)
	{
		CPrintToChatAll("{lightgreen}[NoShake]{default} Map/Server %s {default}the usage of Shake.", StringToInt(newValue) > StringToInt(oldValue) ? "{red}Forced" : "{green}Unforced");
		g_bForceShake = StringToInt(newValue) != 0;
	}
	else if (convar == g_Cvar_NoShakeGlobal)
	{
		CPrintToChatAll("{lightgreen}[NoShake]{default} %s {default}NoShake globally!", StringToInt(newValue) > StringToInt(oldValue) ? "{green}Enabled" : "{red}Disabled");
		g_bNoShakeGlobal = StringToInt(newValue) != 0;
	}
}

public void OnClientPutInServer(int client)
{
	if (AreClientCookiesCached(client))
		ReadClientCookies(client);
}

public void OnClientDisconnect(int client)
{
	if (!AreClientCookiesCached(client) || IsFakeClient(client))
		return;

	static char sCookieValue[2];
	IntToString(g_bNoShake[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, g_hNoShakeCookie, sCookieValue);
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
		CReplyToCommand(client, "{lightgreen}[NoShake]{default} The map/server has {red}forced {default}the usage of Shake.");
		return Plugin_Handled;
	}

	if (g_bNoShakeGlobal)
	{
		CReplyToCommand(client, "{lightgreen}[NoShake]{default} Screen Shake is {red}disabled {default}globally.");
		return Plugin_Handled;
	}

	g_bNoShake[client] = !g_bNoShake[client];
	CReplyToCommand(client, "{lightgreen}[NoShake]{default} has been %s!", g_bNoShake[client] ? "{green}enabled" : "{red}disabled");

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
	menu.SetTitle("NoShake Settings");

	char shake[64];
	FormatEx(shake, 64, "NoShake");

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
				FormatEx(type, sizeof(type), g_bNoShake[param1] ? "Enabled" : "Disabled");
				FormatEx(display, sizeof(display), "NoShake: %s", type);
				return RedrawMenuItem(display);
			}
		}
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			if (strcmp(info, "noshake", false) == 0)
			{
				g_bNoShake[param1] = !g_bNoShake[param1];
				CReplyToCommand(param1, "{lightgreen}[NoShake]{default} has been %s!", g_bNoShake[param1] ? "{green}enabled" : "{red}disabled");
			}

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
