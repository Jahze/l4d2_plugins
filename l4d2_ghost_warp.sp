#pragma semicolon 1

#define L4D2UTIL_STOCKS_ONLY

#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <l4d2_direct>

#define GHOSTWARP_INTERVAL_TIME 0.5

const SurvivorCharacter:MAX_SURVIVOR_CHARACTERS = SurvivorCharacter:8;

new bool:g_bDelay[MAXPLAYERS+1] = false;
new SurvivorCharacter:g_LastTarget[MAXPLAYERS+1] = SC_NONE;

public Plugin:myinfo = {
    name = "L4D2 Ghost Infected Warp",
    author = "Confogl Team",
    description = "Provides some features to allow warping of infected ghosts",
    version = "1.0",
    url = "https://github.com/Jahze/l4d2_plugins"
}

public OnPluginStart() {
    HookEvent("player_death", PlayerDeathEvent);
    RegConsoleCmd("sm_warptosurvivor", WarpToSurvivorCmd);
    RegConsoleCmd("sm_warptosurvivorflow", WarpToFlowCmd);
}

static bool:IsEligibleForGhostWarp(client) {
    if (client != 0
    && IsClientInGame(client)
    && ! g_bDelay[client]
    && IsInfected(client)
    && IsInfectedGhost(client)) {
        return true;
    }
    return false;
}

static bool:IsValidWarpTarget(client) {
    if (client != 0
    && IsClientInGame(client)
    && IsSurvivor(client)) {
        return true;
    }
    return false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
    if ((buttons & IN_ATTACK2) && IsEligibleForGhostWarp(client)) {
        g_bDelay[client] = true;
        CreateTimer(GHOSTWARP_INTERVAL_TIME, ResetDelayTimer, client);
        WarpToSurvivorCharacter(client, SC_NONE);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public PlayerDeathEvent(Handle:hEvent, const String:name[], bool:bDontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    g_LastTarget[client] = SC_NONE;
}

public Action:ResetDelayTimer(Handle:hTimer, any:client) {
    g_bDelay[_:client] = false;
}

public Action:WarpToSurvivorCmd(client, args) {
    if (args != 1 || !IsEligibleForGhostWarp(client)) {
        return;
    }

    decl String:number[16];
    GetCmdArg(1, number, sizeof(number));
    WarpToSurvivorCharacter(client, SurvivorCharacter:StringToInt(number));
    return;
}

public Action:WarpToFlowCmd(client, args) {
    if (args != 1 || !IsEligibleForGhostWarp(client)) {
        return;
    }

    decl String:number[16];
    GetCmdArg(1, number, sizeof(number));
    WarpToSurvivorFlow(client, StringToInt(number));
}

static WarpToSurvivorCharacter(client, SurvivorCharacter:character) {
    new target;

    if (character == SC_NONE)
        target = FindNextCharacterClient(client);
    else
        target = GetCharacterClient(character);

    if (target == 0)
        return;

    WarpToSurvivor(client, target);
}

static WarpToSurvivor(client, target) {
    // Prevent people from spawning and then warp to survivor
    SetEntProp(client, Prop_Send, "m_ghostSpawnState", 256);

    decl Float:position[3];
    decl Float:angles[3];

    GetClientAbsOrigin(target, position);
    GetClientAbsAngles(target, angles);
    TeleportEntity(client, position, angles, NULL_VECTOR);
}

static FindNextCharacterClient(client) {
    new SurvivorCharacter:character = SurvivorCharacter:(_:g_LastTarget[client] + 1);
    do {
        if (character >= MAX_SURVIVOR_CHARACTERS) {
            character = SurvivorCharacter:0;
        }

        new characterClient = GetCharacterClient(character);
        if (characterClient != 0) {
            g_LastTarget[client] = character;
            return characterClient;
        }

        character++;
    } while (character != g_LastTarget[client]);

    return 0;
}

static GetCharacterClient(SurvivorCharacter:character) {
    for (new client = 1; client < MaxClients+1; ++client) {
        if (IsValidWarpTarget(client) && IdentifySurvivor(client) == character)
            return client;
    }
    return 0;
}

static WarpToSurvivorFlow(client, index) {
    decl clients[MaxClients+1];
    decl Float:flows[MaxClients+1];
    new count = 0;

    for (new i = 1; i < MaxClients+1; ++i) {
        if (IsValidWarpTarget(i)) {
            new Float:flow = L4D2Direct_GetFlowDistance(i);
            SortedInsert(clients, flows, i, flow, count++);
        }
    }

    if (index < 0 || index >= count)
        return;

    WarpToSurvivor(client, clients[index]);
}

static SortedInsert(clients[], Float:flows[], client, Float:flow, count) {
    if (count == 0) {
        clients[0] = client;
        flows[0] = flow;
        return;
    }

    for (new i = 0; i < count; ++i) {
        if (flow > flows[i]) {
            for (new j = count; j > i; --j) {
                clients[j] = clients[j-1];
                flows[j] = flows[j-1];
            }
            clients[i] = client;
            flows[i] = flow;
            return;
        }
    }

    clients[count] = client;
    flows[count] = flow;
}

