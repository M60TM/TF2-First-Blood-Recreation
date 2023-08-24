#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

#define TF_ARENA_MODE_FAST_FIRST_BLOOD_TIME 20.0
#define TF_ARENA_MODE_SLOW_FIRST_BLOOD_TIME 50.0

ConVar g_CvarEnabled;
ConVar g_CvarCheckDeadRinger;
ConVar g_CvarFirstBloodDuration;
ConVar g_CvarFirstBloodLimit;
ConVar g_CvarOriginalFirstBlood;

float g_RoundStartTime = 0.0;
bool g_IsArenaGamemode;
bool g_IsRoundActive = false;
bool g_IsFirstBlood = false;
bool g_RequestSetConVar = false;

public Plugin myinfo = {
	name        = "[TF2] First Blood Recreation",
	author      = "Sandy",
	description = "Recreation of First Blood Critical.",
	version     = "1.0.0",
	url         = ""
};

public void OnPluginStart() {
	g_CvarEnabled = CreateConVar("tf_fbr_enabled", "1", "Enable first blood recreation", 0, true, 0.0, true, 1.0);
	g_CvarEnabled.AddChangeHook(OnEnabledChanged);
	
	g_CvarCheckDeadRinger = CreateConVar("tf_fbr_check_dead_ringer", "1", "1 to ignore dead ringer, 0 to consider dead ringer as real death.", 0, true, 0.0, true, 1.0);
	g_CvarFirstBloodDuration = CreateConVar("tf_fbr_duration", "5.0", "Duration of first blood critical.", 0, true, 0.0);
	g_CvarFirstBloodLimit = CreateConVar("tf_fbr_limit", "0.0", "The time limit of getting first blood critical.", 0, true, 0.0);

	g_CvarOriginalFirstBlood = FindConVar("tf_arena_first_blood");

	HookEvent("arena_round_start", OnArenaStarted);
	HookEvent("arena_win_panel", OnArenaEnd);

	HookEvent("teamplay_round_active", OnTeamplayRoundActive);
	HookEvent("teamplay_round_win", OnTeamplayRoundEnd);
	HookEvent("teamplay_round_stalemate", OnTeamplayRoundEnd);

	HookEvent("player_death", OnPlayerDeath);
}

public void OnMapStart() {
	PrecacheScriptSound("Announcer.AM_FirstBloodFast");
	PrecacheScriptSound("Announcer.AM_FirstBloodFinally");
	PrecacheScriptSound("Announcer.AM_FirstBloodRandom");
	
	int logicArena = FindEntityByClassname(-1, "tf_logic_arena");
	if(logicArena != -1)
		g_IsArenaGamemode = true;
	else
		g_IsArenaGamemode = false;
}

// Arena-Gamemode.
void OnArenaStarted(Event event, const char[] name, bool dontBroadcast) {
	if (!g_CvarEnabled.BoolValue)
		return;
	
	g_CvarOriginalFirstBlood.BoolValue = false;
	g_IsFirstBlood = false;
	g_IsRoundActive = true;
	g_RoundStartTime = GetGameTime();
}

void OnArenaEnd(Event event, const char[] name, bool dontBroadcast) {
	if (!g_CvarEnabled.BoolValue)
		return;
	
	g_IsRoundActive = false;

	if (g_RequestSetConVar) {
		g_RequestSetConVar = false;
		if (g_CvarOriginalFirstBlood) {
			g_CvarOriginalFirstBlood.BoolValue = g_CvarOriginalFirstBlood.BoolValue ? false : true;
		}
	}
}

// Non-Arena-Gamemode.
void OnTeamplayRoundActive(Event event, const char[] name, bool dontBroadcast) {
	if (!g_CvarEnabled.BoolValue)
		return;
	
	g_IsFirstBlood = false;
	g_IsRoundActive = true;
	g_RoundStartTime = GetGameTime();
}

void OnTeamplayRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	if (!g_CvarEnabled.BoolValue)
		return;
	
	g_IsRoundActive = false;
}

// Both.
void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (!g_CvarEnabled.BoolValue)
		return;
	
	if (!g_IsRoundActive)
		return;
	
	if (!g_IsFirstBlood) {
		int victim = GetClientOfUserId(event.GetInt("userid"));
		if (!IsValidClient(victim))
			return;
		
		if (g_CvarCheckDeadRinger.BoolValue && event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
			return;
		
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (!IsValidClient(attacker))
			return;
		
		if (GetClientTeam(victim) == GetClientTeam(attacker))
			return;
		
		g_IsFirstBlood = true;

		float RoundTime = GetGameTime() - g_RoundStartTime;
		if (g_CvarFirstBloodLimit.FloatValue && g_CvarFirstBloodLimit.FloatValue > RoundTime) {
			return;
		}

		if (RoundTime <= TF_ARENA_MODE_FAST_FIRST_BLOOD_TIME) {
			EmitGameSoundToAll("Announcer.AM_FirstBloodFast");
		} else if (RoundTime >= TF_ARENA_MODE_SLOW_FIRST_BLOOD_TIME) {
			EmitGameSoundToAll("Announcer.AM_FirstBloodFinally");
		} else {
			EmitGameSoundToAll("Announcer.AM_FirstBloodRandom");
		}

		TF2_AddCondition(attacker, TFCond_CritOnFirstBlood, g_CvarFirstBloodDuration.FloatValue);
	}
}

// Enabled ConVar Changed.
void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	// We don't need to toggle when gamemode isn't arena.
	if (!g_IsArenaGamemode)
		return;
	
	if (g_CvarOriginalFirstBlood == null)
		return;
	
	if (g_IsRoundActive && !g_RequestSetConVar) {
		g_RequestSetConVar = true;
		return;
	}
	
	if (convar.BoolValue) {
		g_CvarOriginalFirstBlood.BoolValue = false;
	} else {
		g_CvarOriginalFirstBlood.BoolValue = true;
	}
}

// stock.
stock bool IsValidClient(int client, bool replaycheck = true) {
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if (replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}