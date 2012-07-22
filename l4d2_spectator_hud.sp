#pragma semicolon 1

#define L4D2UTIL_STOCKS_ONLY

#include <sourcemod>
#include <l4d2_direct>
#include <l4d2util>

#define MAX_CUSTOM_NAME_LENGTH  64
#define MAX_SPECHUD_NAME_LENGTH 64
#define NUM_CUSTOM_ITEMS        5

const Float:SPECHUD_DRAW_INTERVAL = 0.5;

new const String:LongWeaponNames[WeaponId][] = {
    "None", "Pistol", "SMG", // 0
    "Wooden Shotgun", "Autoshotgun", "M-16", // 3
    "Hunting Rifle", "Silenced SMG", "Chrome Shotgun", // 6
    "Desert Rifle", "Military Sniper", "SPAS Shotgun", // 9
    "First Aid Kit", "Molotov", "Pipe Bomb", // 12
    "Pills", "Gascan", "Propane Tank", // 15
    "Oxygen Tank", "Melee", "Chainsaw", // 18
    "Grenade Launcher", "Ammo Pack", "Adrenaline", // 21
    "Defibrillator", "Bile Bomb", "AK-47", // 24
    "Gnome", "Cola Bottles", "Fireworks", // 27
    "Incendiary Ammo Pack", "Explosive Ammo Pack", "Magnum", // 30
    "MP5", "SG552", "AWP", // 33
    "Scout", "M60", "Tank Claw", // 36
    "Hunter Claw", "Charger Claw", "Boomer Claw", // 39
    "Smoker Claw", "Spitter Claw", "Jockey Claw", // 42
    "Turret", "vomit", "splat", // 45
    "pounce", "lounge", "pull", // 48
    "choke", "rock", "physics", // 51
    "ammo", "upgrade_item" // 54
};

enum SpecHudItem {
    ITEM_TITLE,
    ITEM_ROUND_NUMBER,
    ITEM_GAME_TIME,
    ITEM_MOB_TIMER,
    ITEM_CUSTOM1,
    ITEM_CUSTOM2,
    ITEM_CUSTOM3,
    ITEM_CUSTOM4,
    ITEM_CUSTOM5,
    ITEM_SURVIVOR_INFO,
    ITEM_INFECTED_INFO,
    ITEM_MAX
};

new const String:SpecHudItemNames[ITEM_MAX][] = {
    "title",
    "round",
    "time",
    "mobtimer",
    "custom1",
    "custom2",
    "custom3",
    "custom4",
    "custom5",
    "survivors",
    "infected"
};

new SurvivorClients[MAXPLAYERS];
new InfectedClients[MAXPLAYERS];

new String:g_SpecHudCustomNames[NUM_CUSTOM_ITEMS][MAX_CUSTOM_NAME_LENGTH];
new Handle:g_SpecHudCustomCvars[NUM_CUSTOM_ITEMS];

new Handle:g_hSpecHuds;
new Handle:g_hSpecHudNames;
new String:g_ClientSpecHuds[MAXPLAYERS][MAX_SPECHUD_NAME_LENGTH];

public Plugin:myinfo = {
    name = "L4D2 Spectator HUD",
    author = "Confogl Team",
    description = "Provides a HUD for spectators",
    version = "1.0"
}

public OnPluginStart() {
    RegConsoleCmd("myspechud", MySpecHudCmd, "myspechud <name>");
    RegServerCmd("spechud_create", SpecHudCreateCmd, "spechud_create <name>");
    RegServerCmd("spechud_delete", SpecHudDeleteCmd, "spechud_delete <name>");
    RegServerCmd("spechud_list", SpecHudListCmd, "spechud_list");
    RegServerCmd("spechud_show", SpecHudShowCmd, "spechud_show <spechud> <item> <true/false>");
    RegServerCmd("spechud_custom", SpecHudCustomCmd, "spechud_custom <#> <name> <cvar>");
    
    g_hSpecHuds = CreateTrie();
    g_hSpecHudNames = CreateArray(MAX_SPECHUD_NAME_LENGTH);
    
    for (new i = 0; i < MAXPLAYERS; ++i) {
        g_ClientSpecHuds[i][0] = 0;
    }
    
    for (new i = 0; i < NUM_CUSTOM_ITEMS; ++i) {
        g_SpecHudCustomCvars[i] = INVALID_HANDLE;
    }
    
    CreateTimer(SPECHUD_DRAW_INTERVAL, SpecHudDrawTimer, INVALID_HANDLE, TIMER_REPEAT);
}

static BuildClientArrays() {
    new nSurvivor = 0;
    new nInfected = 0;
    
    for (new client = 1; client < MaxClients+1; ++client) {
        if (IsSurvivor(client))
            SurvivorClients[nSurvivor++] = client;
        if (IsInfected(client))
            InfectedClients[nInfected++] = client;
    }
    
    SurvivorClients[nSurvivor] = 0;
    InfectedClients[nInfected] = 0;
}

public Action:SpecHudDrawTimer(Handle:hTimer) {
    BuildClientArrays();
    
    decl String:name[MAX_SPECHUD_NAME_LENGTH];
    decl bool:bShowSpecHudItems[ITEM_MAX];
    new size = GetArraySize(g_hSpecHudNames);
    
    for (new i = 0; i < size; ++i) {
        new Handle:hSpecHud = CreatePanel();
        
        GetArrayString(g_hSpecHudNames, i, name, sizeof(name));
        GetTrieArray(g_hSpecHuds, name, bShowSpecHudItems, sizeof(bShowSpecHudItems));
        
        DrawSpecHud(hSpecHud, bShowSpecHudItems);
        SendSpecHudToClients(hSpecHud, name);
        
        CloseHandle(hSpecHud);
    }
    
    return Plugin_Continue;
}

static FixupName(String:name[], length) {
    if (name[0] == '[') {
        decl String:temp[MAX_NAME_LENGTH];
        strcopy(temp, sizeof(temp), name);
        temp[sizeof(temp)-2] = 0;
        strcopy(name[1], length-1, temp);
        name[0] = ' ';
    }
    
    if (strlen(name) > 25) {
        name[22] = name[23] = name[24] = '.';
        name[25] = 0;
    }
}

static DrawCustomFields(Handle:hSpecHud, const bool:bShowSpecHudItem[]) {
    decl String:buffer[512];
    decl String:value[128];
    
    for (new i = 0; i < NUM_CUSTOM_ITEMS; ++i) {
        if (! bShowSpecHudItem[_:ITEM_CUSTOM1 + i])
            continue;
        
        if (g_SpecHudCustomCvars[i] == INVALID_HANDLE)
            continue;
        
        GetConVarString(g_SpecHudCustomCvars[i], value, sizeof(value));
        Format(buffer, sizeof(buffer), "%s: %s", g_SpecHudCustomNames[i], value);
        DrawPanelText(hSpecHud, buffer);
    }
}

static DrawSurvivorInfo(Handle:hSpecHud) {
    decl String:buffer[512];
    decl String:nameString[MAX_NAME_LENGTH+1];
    decl String:weaponString[64];
    
    for (new i = 0; i < MAXPLAYERS; ++i) {
        new client = SurvivorClients[i];
        
        if (client == 0)
            break;
        
        GetClientName(client, nameString, sizeof(nameString));
        FixupName(nameString, sizeof(nameString));
        
        if (! IsPlayerAlive(client)) {
            Format(buffer, sizeof(buffer), "%s: Dead", nameString);
            DrawPanelText(hSpecHud, buffer);
        }
        
        GetClientWeapon(client, weaponString, sizeof(weaponString));
        new WeaponId:weaponId = WeaponNameToId(weaponString);
        strcopy(weaponString, sizeof(weaponString), LongWeaponNames[_:weaponId]);
        
        new permHealth = GetSurvivorPermanentHealth(client);
        new tempHealth = GetSurvivorTemporaryHealth(client);
        new health = permHealth + tempHealth;
        new incapCount = GetSurvivorIncapCount(client);
        
        if (IsHangingFromLedge(client))
            Format(buffer, sizeof(buffer), "%s: %s [%d] (Hanging)", nameString, weaponString, permHealth);
        else if (IsIncapacitated(client))
            Format(buffer, sizeof(buffer), "%s: %s [%d] (Down)", nameString, weaponString, permHealth);
        else if (incapCount > 0)
            Format(buffer, sizeof(buffer), "%s: %s [%d] (%d Down)", nameString, weaponString, health, incapCount);
        else
            Format(buffer, sizeof(buffer), "%s: %s [%d]", nameString, weaponString, health, incapCount);
        
        DrawPanelText(hSpecHud, buffer);
    }
}

static DrawInfectedInfo(Handle:hSpecHud) {
    decl String:buffer[512];
    decl String:nameString[MAX_NAME_LENGTH+1];
    decl String:classString[64];
    
    for (new i = 0; i < MAXPLAYERS; ++i) {
        new client = InfectedClients[i];
        
        if (client == 0)
            break;
        
        GetClientName(client, nameString, sizeof(nameString));
        FixupName(nameString, sizeof(nameString));
        
        if (! IsPlayerAlive(client)) {
            new CountdownTimer:spawnTimer = L4D2Direct_GetSpawnTimer(client);
            new Float:timeLeft = -1.0;
            
            if (spawnTimer != CTimer_Null)
                timeLeft = CTimer_GetRemainingTime(spawnTimer);
            
            if (timeLeft < 0.0)
                Format(buffer, sizeof(buffer), "%s: Dead", nameString);
            else
                Format(buffer, sizeof(buffer), "%s: Dead (%d)", nameString, RoundToNearest(timeLeft));
        }
        else {
            new L4D2_Infected:zClass = GetInfectedClass(client);
            GetInfectedClassName(zClass, classString, sizeof(classString));
            
            if (IsInfectedGhost(client))
                Format(buffer, sizeof(buffer), "%s: Spawning (%s)", nameString, classString);
            else if (GetEntityFlags(client) & FL_ONFIRE)
                Format(buffer, sizeof(buffer), "%s: %s [%d (On Fire)]", nameString, classString, GetClientHealth(client));
            else if (zClass == L4D2Infected_Tank)
                Format(buffer, sizeof(buffer), "%s: %s [%d (%d%%)]", nameString, classString, GetClientHealth(client), GetTankFrustration(client));
            else
                Format(buffer, sizeof(buffer), "%s: %s [%d]", nameString, classString, GetClientHealth(client));                
        }
        
        DrawPanelText(hSpecHud, buffer);
    }
}

static DrawSpecHud(Handle:hSpecHud, const bool:bShowSpecHudItem[]) {
    decl String:buffer[512];
    
    if (bShowSpecHudItem[_:ITEM_TITLE]) {
        SetPanelTitle(hSpecHud, "Spectator HUD");
        DrawPanelText(hSpecHud, " ");
    }
    
    if (bShowSpecHudItem[_:ITEM_ROUND_NUMBER]) {
        Format(buffer, sizeof(buffer), "Round: %d", InSecondHalfOfRound() ? 2 : 1);
        DrawPanelText(hSpecHud, buffer);
    }
    
    if (bShowSpecHudItem[_:ITEM_GAME_TIME]) {
        decl String:timeString[16];
        new time = RoundToNearest(GetGameTime());
        FormatTime(timeString, sizeof(timeString), "%H:%M:%S", time);
        Format(buffer, sizeof(buffer), "Time: %s", timeString);
        DrawPanelText(hSpecHud, buffer);
    }
    
    if (bShowSpecHudItem[_:ITEM_MOB_TIMER]) {
        new CountdownTimer:mobTimer = L4D2Direct_GetMobSpawnTimer();
        if (mobTimer != CTimer_Null) {
            new Float:timeLeft = CTimer_GetRemainingTime(mobTimer);
            Format(buffer, sizeof(buffer), "Mob Timer: %ds", RoundToNearest(timeLeft));
            DrawPanelText(hSpecHud, buffer);
        }
    }
    
    DrawCustomFields(hSpecHud, bShowSpecHudItem);
    
    if (bShowSpecHudItem[_:ITEM_SURVIVOR_INFO]) {
        DrawPanelText(hSpecHud, " ");
        DrawSurvivorInfo(hSpecHud);
    }
    
    if (bShowSpecHudItem[_:ITEM_INFECTED_INFO]) {
        DrawPanelText(hSpecHud, " ");
        DrawInfectedInfo(hSpecHud);
    }
}

static SendSpecHudToClients(Handle:hSpecHud, const String:name[]) {
    for (new client = 1; client < MaxClients+1; ++client) {
        if (! IsClientInGame(client)
            || GetClientTeam(client) != _:L4D2Team_Spectator
            || IsFakeClient(client)
            || ! StrEqual(g_ClientSpecHuds[client], name)) {
            continue;
        }
        
        SendPanelToClient(hSpecHud, client, MenuHandler, 3);
    }
}

public MenuHandler(Handle:hMenu, MenuAction:action, param1, param2) {
}

public Action:MySpecHudCmd(client, args) {
    if (GetCmdArgs() != 1) {
        ReplyToCommand(client, "Syntax: myspechud <name>");
        return;
    }
    
    decl String:name[MAX_SPECHUD_NAME_LENGTH];
    GetCmdArg(1, name, sizeof(name));
    
    new idx = FindStringInArray(g_hSpecHudNames, name);
    if (idx == -1) {
        new size = GetArraySize(g_hSpecHudNames);
        if (size) {
            decl String:spechuds[128];
            spechuds[0] = 0;
            
            for (new i = 0; i < size; ++i) {
                if (i)
                    StrCat(spechuds, sizeof(spechuds), ", ");
                
                GetArrayString(g_hSpecHudNames, i, name, sizeof(name));
                StrCat(spechuds, sizeof(spechuds), name);
            }
            
            ReplyToCommand(client, "SpecHud %s not found. Available SpecHuds are: %s", name, spechuds);
        }
        else {
            ReplyToCommand(client, "No SpecHuds have been configured");
        }
        
        return;
    }
    
    strcopy(g_ClientSpecHuds[client], MAX_SPECHUD_NAME_LENGTH, name);
    ReplyToCommand(client, "%d %s", client, g_ClientSpecHuds[client]);
}

public Action:SpecHudCreateCmd(args) {
    if (GetCmdArgs() != 1) {
        PrintToServer("Syntax: spechud_create <name>");
        return;
    }
    
    decl String:name[MAX_SPECHUD_NAME_LENGTH];
    GetCmdArg(1, name, sizeof(name));
    if (FindStringInArray(g_hSpecHudNames, name) != -1) {
        PrintToServer("SpecHud %s already exists", name);
        return;
    }
    
    PushArrayString(g_hSpecHudNames, name);
    
    new bool:bItems[ITEM_MAX];
    SetTrieArray(g_hSpecHuds, name, bItems, sizeof(bItems));
}

public Action:SpecHudDeleteCmd(args) {
    if (GetCmdArgs() != 1) {
        PrintToServer("Syntax: spechud_delete <name>");
        return;
    }
    
    decl String:name[MAX_SPECHUD_NAME_LENGTH];
    GetCmdArg(1, name, sizeof(name));
    
    new idx = FindStringInArray(g_hSpecHudNames, name);
    if (idx == -1) {
        PrintToServer("SpecHud %s not found", name);
        return;
    }
    
    RemoveFromArray(g_hSpecHudNames, idx);
    RemoveFromTrie(g_hSpecHuds, name);
    
    // TODO: scan and remove from client spechuds
}

public Action:SpecHudListCmd(args) {
    new size = GetArraySize(g_hSpecHudNames);
    if (size == 0) {
        PrintToServer("No SpecHuds");
        return;
    }
    
    decl String:name[MAX_SPECHUD_NAME_LENGTH];
    for (new i = 0; i < size; ++i) {
        GetArrayString(g_hSpecHudNames, i, name, sizeof(name));
        PrintToServer(name);
    }
}

public Action:SpecHudShowCmd(args) {
    if (GetCmdArgs() != 3) {
        PrintToServer("Syntax: spechud_show <spechud> <item> <true/false>");
        return;
    }
    
    decl String:name[MAX_SPECHUD_NAME_LENGTH];
    decl String:item[128];
    decl String:visible[128];
    
    GetCmdArg(1, name, sizeof(name));
    GetCmdArg(2, item, sizeof(item));
    GetCmdArg(3, visible, sizeof(visible));
    
    if (FindStringInArray(g_hSpecHudNames, name) == -1) {
        PrintToServer("Unknown SpecHud %s", name);
        return;
    }
    
    new SpecHudItem:itemIdx = ITEM_MAX;
    for (new i = 0; i < _:ITEM_MAX; ++i) {
        if (StrEqual(item, SpecHudItemNames[i], false)) {
            itemIdx = SpecHudItem:i;
            break;
        }
    }
    
    if (itemIdx == ITEM_MAX) {
        decl String:items[512];
        items[0] = 0;
        for (new i = 0; i < _:ITEM_MAX; ++i) {
            if (i)
                StrCat(items, sizeof(items), ", ");
            
            StrCat(items, sizeof(items), SpecHudItemNames[i]);
        }
        PrintToServer("Invalid item. Available items are: %s", items);
        return;
    }
    
    new bool:bShow = true;
    if (StrEqual(visible, "true", false))
        bShow = true;
    else if (StrEqual(visible, "false", false))
        bShow = false;
    else {
        PrintToServer("Syntax: spechud_show <spechud> <item> <true/false>");
        return;
    }
    
    decl bool:bShowItems[ITEM_MAX];
    GetTrieArray(g_hSpecHuds, name, bShowItems, sizeof(bShowItems));
    bShowItems[itemIdx] = bShow;
    SetTrieArray(g_hSpecHuds, name, bShowItems, sizeof(bShowItems));
}

public Action:SpecHudCustomCmd(args) {
    if (GetCmdArgs() != 3) {
        PrintToServer("Syntax: spechud_custom <#> <name> <cvar>");
        return;
    }
    
    decl String:num[32];
    decl String:name[MAX_CUSTOM_NAME_LENGTH];
    decl String:cvar[128];
    
    GetCmdArg(1, num, sizeof(num));
    GetCmdArg(2, name, sizeof(name));
    GetCmdArg(3, cvar, sizeof(cvar));
    
    new idx = StringToInt(num);
    if (idx < 0 || idx > NUM_CUSTOM_ITEMS) {
        PrintToServer("Custom item number must be between 1 and %d", NUM_CUSTOM_ITEMS);
        return;
    }
    
    new Handle:hCvar = FindConVar(cvar);
    if (hCvar == INVALID_HANDLE) {
        PrintToServer("Could not find '%s' cvar", cvar);
    }
    
    --idx;
    strcopy(g_SpecHudCustomNames[idx], MAX_CUSTOM_NAME_LENGTH, name);
    g_SpecHudCustomCvars[idx] = hCvar;
}
