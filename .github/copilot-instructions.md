# Copilot Instructions for sm-plugin-NoShake

## Repository Overview
This repository contains the **NoShake** SourceMod plugin for Source engine games. The plugin allows players to disable or enable screen shake effects (env_shake) on a per-client basis, with server-wide controls available to administrators.

**Primary File**: `addons/sourcemod/scripting/NoShake.sp` - Main plugin source code

## Technical Environment & Dependencies

### Core Technologies
- **Language**: SourcePawn (Source engine scripting language)
- **Platform**: SourceMod 1.11.0+ (scripting framework for Source games)
- **Build Tool**: SourceKnight (Python-based SourceMod build system)
- **Compiler**: SourcePawn Compiler (spcomp) - handled by SourceKnight

### Dependencies
- **SourceMod**: 1.11.0-git6934 or later
- **MultiColors**: Community include for colored chat messages
- **Standard SourceMod includes**: sourcemod, sdkhooks, clientprefs

### Build System
The project uses **SourceKnight** as defined in `sourceknight.yaml`:
```bash
# Build the plugin
sourceknight build

# Dependencies are automatically downloaded:
# - SourceMod from AlliedMods
# - MultiColors from GitHub
```

## Project Structure
```
/addons/sourcemod/scripting/
├── NoShake.sp              # Main plugin source
/sourceknight.yaml          # Build configuration
/.github/workflows/ci.yml   # CI/CD pipeline
```

## Code Style & Standards

### SourcePawn Conventions
- **ALWAYS** use `#pragma semicolon 1` and `#pragma newdecls required`
- Use **tabs for indentation** (4 spaces equivalent)
- **camelCase** for local variables and function parameters
- **PascalCase** for function names
- **g_** prefix for global variables
- **Descriptive names** for variables and functions

### Memory Management
- Use `delete` for Handle/object cleanup without null checks
- **Never use `.Clear()`** on StringMap/ArrayList - use `delete` and recreate
- Prefer `StringMap`/`ArrayList` over traditional arrays
- All SQL operations **must be asynchronous**

### Plugin Architecture
```sourcepawn
// Required pragmas
#pragma semicolon 1
#pragma newdecls required

// Standard includes
#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

// Global variables with g_ prefix
ConVar g_Cvar_PluginEnabled;
bool g_bPluginEnabled;
Handle g_hClientCookie;
```

## Plugin-Specific Patterns

### Client Preferences System
The plugin implements client cookies for persistent user preferences:
```sourcepawn
// Cookie registration in OnPluginStart()
g_hNoShakeCookie = RegClientCookie("noshake_cookie", "NoShake", CookieAccess_Protected);

// Reading cookies when client connects
public void OnClientCookiesCached(int client)
{
    ReadClientCookies(client);
}
```

### ConVar Management
ConVars use modern SourceMod methodology with change hooks:
```sourcepawn
g_Cvar_NoShakeGlobal = CreateConVar("sm_noshake_global", "0", "Description", 0, true, 0.0, true, 1.0);
g_Cvar_NoShakeGlobal.AddChangeHook(OnConVarChanged);
```

### User Message Hooking
The plugin intercepts the "Shake" user message:
```sourcepawn
HookUserMessage(GetUserMessageId("Shake"), MsgHook, true);
```

## Development Guidelines

### When Modifying Code
1. **Maintain existing functionality** - don't break current features
2. **Follow established patterns** - use the same coding style as existing code
3. **Test client preference persistence** - ensure cookies work correctly
4. **Verify ConVar functionality** - test global/force settings
5. **Check message interception** - ensure shake blocking works properly

### Adding New Features
- Add ConVars with proper bounds and descriptions
- Implement client preferences if user-configurable
- Use translation files for user-facing messages
- Follow the existing command structure pattern
- Add menu integration if applicable

### Common Pitfalls to Avoid
- **Don't** use synchronous SQL operations
- **Don't** use `.Clear()` on containers - use `delete`
- **Don't** forget to handle late plugin loading (`g_bLate`)
- **Don't** assume clients are valid - always check `IsClientInGame()`
- **Don't** hardcode strings - use the multicolors format

## Testing & Validation

### Build Process
The CI system automatically:
1. Downloads dependencies via SourceKnight
2. Compiles the plugin using spcomp
3. Packages the compiled .smx file
4. Creates releases on tags/master branch

### Manual Testing Checklist
- [ ] Plugin loads without errors
- [ ] Commands `sm_shake` and `sm_noshake` work
- [ ] Client preferences persist across disconnects
- [ ] Global disable/force settings function correctly
- [ ] Menu system accessible via client preferences
- [ ] Screen shake properly blocked/allowed based on settings

### ConVar Testing
```
// Test global disable
sm_noshake_global 1

// Test force shake (overrides global)
sm_force_shake 1

// Reset to default
sm_noshake_global 0
sm_force_shake 0
```

## Common Modification Scenarios

### Adding New ConVars
```sourcepawn
// In OnPluginStart()
g_Cvar_NewSetting = CreateConVar("sm_noshake_newsetting", "0", "Description", 0, true, 0.0, true, 1.0);
g_bNewSetting = g_Cvar_NewSetting.BoolValue;
g_Cvar_NewSetting.AddChangeHook(OnConVarChanged);

// In OnConVarChanged()
else if (convar == g_Cvar_NewSetting)
{
    g_bNewSetting = StringToInt(newValue) != 0;
    // Add notification logic if needed
}
```

### Extending Client Preferences
```sourcepawn
// Add new cookie
Handle g_hNewCookie = RegClientCookie("new_cookie", "Description", CookieAccess_Protected);

// Add to ReadClientCookies()
GetClientCookie(client, g_hNewCookie, sCookieValue, sizeof(sCookieValue));
g_bNewSetting[client] = StringToInt(sCookieValue) != 0;

// Add menu item in NotifierSetting()
menu.AddItem("newsetting", "New Setting");
```

## Debugging & Troubleshooting

### Common Issues
1. **Plugin not loading**: Check SourceMod version compatibility (requires 1.11.0+)
2. **Commands not working**: Verify command registration in OnPluginStart()
3. **Cookies not saving**: Ensure AreClientCookiesCached() before reading/writing
4. **Shake still happening**: Check force shake ConVar and message hook implementation

### Debug Commands
```
// Check plugin status
sm plugins list noshake

// Reload plugin for testing
sm plugins reload noshake

// Check ConVar values
sm_noshake_global
sm_force_shake

// Test user message system
// (requires game events that trigger shake)
```

### Log Analysis
Look for these patterns in SourceMod logs:
- Cookie loading errors
- ConVar validation warnings
- User message hook failures
- Plugin late loading messages

## File Locations & Deployment
- **Source**: `addons/sourcemod/scripting/NoShake.sp`
- **Compiled**: `addons/sourcemod/plugins/NoShake.smx` (auto-generated)
- **Config**: Auto-generated in `cfg/sourcemod/` on first run
- **Translations**: Not currently used but would go in `addons/sourcemod/translations/`

## Key Plugin Features Summary
- **Individual Control**: Players can toggle shake effects for themselves
- **Server Control**: Admins can globally disable or force shake effects
- **Persistent Settings**: Client preferences saved via SourceMod cookies
- **Admin Override**: Force shake setting overrides all other settings
- **Menu Integration**: Accessible through SourceMod client preferences menu
- **Late Loading Support**: Handles plugin loading on live servers

## Current Version & Authors
- **Version**: 1.0.6
- **Authors**: BotoX, .Rushaway
- **Plugin Info**: Located in `public Plugin myinfo` structure

## Performance Considerations
- Message hook is lightweight and only processes on shake events
- Cookie operations are cached and efficient
- ConVar changes broadcast to all clients with minimal overhead
- No timers or repeated operations that could impact server performance
- Uses player arrays for O(1) lookup of client settings

## Important Code Patterns in This Project

### Client Validation Pattern
```sourcepawn
if (!client || !IsClientInGame(client) || IsFakeClient(client))
    return;
```

### Cookie Value Handling
```sourcepawn
static char sCookieValue[2];
GetClientCookie(client, g_hNoShakeCookie, sCookieValue, sizeof(sCookieValue));
g_bNoShake[client] = StringToInt(sCookieValue) != 0;
```

### Message Response Format
Uses MultiColors plugin for consistent formatting:
```sourcepawn
CReplyToCommand(client, "{lightgreen}[NoShake]{default} has been %s!", condition ? "{green}enabled" : "{red}disabled");
```