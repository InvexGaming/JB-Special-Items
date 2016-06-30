#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required

// Plugin Informaiton  
#define VERSION "1.01"

int g_offCollisionGroup = -1;

//Convars
ConVar cvar_medicshot = null;
ConVar cvar_medicshot_team = null;
ConVar cvar_medicshot_ratio = null;
ConVar cvar_awarenessgrenade = null;
ConVar cvar_awarenessgrenade_team = null;
ConVar cvar_awarenessgrenade_ratio = null;

//Flags
AdminFlag vipFlag = Admin_Custom3;

public Plugin myinfo =
{
  name = "Jailbreak Special Items",
  author = "Invex | Byte",
  description = "Special items are spawned and given to players.",
  version = VERSION,
  url = "http://www.invexgaming.com.au"
};

// Plugin Start
public void OnPluginStart()
{
  //Translations
  LoadTranslations("jb_specialitems.phrases");  
  
  //Flags
  CreateConVar("sm_jbspecialitems_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
  
  //Hooks
  HookEvent("round_start", roundStart);
  
  //ConVars
  cvar_medicshot = CreateConVar("sm_jbspecialitems_givemedicshot", "1", "Give medic shots to players. 1 = enabled, 0 = disabled");
  cvar_medicshot_team = CreateConVar("sm_jbspecialitems_givemedicshot_team", "2", "Team to give medic shots to. 2 = T, 3 = CT");
  cvar_medicshot_ratio = CreateConVar("sm_jbspecialitems_givemedicshot_ratio", "0.2", "Percentage of players that get medic shot. 0.2 = default");
  cvar_awarenessgrenade = CreateConVar("sm_jbspecialitems_giveawarenessgrenade", "1", "Give awareness grenades to players. 1 = enabled, 0 = disabled");
  cvar_awarenessgrenade_team = CreateConVar("sm_jbspecialitems_giveawarenessgrenade_team", "3", "Team to give awareness grenades to. 2 = T, 3 = CT");
  cvar_awarenessgrenade_ratio = CreateConVar("sm_jbspecialitems_giveawarenessgrenade_ratio", "0.3", "Percentage of players that get awareness grenade. 0.3 = default");
  
  //Seed prng
  SetRandomSeed(RoundFloat(float(GetTime())));
}

public Action roundStart(Handle event, const char[] name, bool dontBroadcast) 
{
  if (GetConVarBool(cvar_medicshot))
  {
    //Give out medic shots
    int iMaxClients = GetMaxClients();
    int medicPlayerCount = 0;
    int medicEntryCount = 0;
    ArrayList eligblePlayers = CreateArray(iMaxClients*5);
    
    for (int i = 1; i <= iMaxClients; ++i) {
      if (IsClientInGame(i) && IsPlayerAlive(i)) {
        if (GetClientTeam(i) == GetConVarInt(cvar_medicshot_team)) {
          
          PushArrayCell(eligblePlayers, i);
          PushArrayCell(eligblePlayers, i);
          PushArrayCell(eligblePlayers, i);
          ++medicPlayerCount;
          medicEntryCount += 3;
          
          int isVIP = CheckCommandAccess(i, "", FlagToBit(vipFlag));
          if (isVIP) {
            //Extra chance
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            
            medicEntryCount += 5;
          }
        }
      }
    }
    
    //Calculate total number of people to give medic shots
    int totalToGive = RoundToCeil(float(medicPlayerCount) * GetConVarFloat(cvar_medicshot_ratio));
    
    for (int c = 0; c < totalToGive; ++c) {
      int rand = GetRandomInt(0, medicEntryCount - 1);
      int client = GetArrayCell(eligblePlayers, rand);
      GivePlayerItem(client, "weapon_Healthshot");
      removeClientFromArray(eligblePlayers, client);
      medicEntryCount = GetArraySize(eligblePlayers)
      CreateTimer(0.5, Timer_ShowHintMediShot, client);
    }

  }
  
  if (GetConVarBool(cvar_awarenessgrenade))
  {
    //Give out awareness grenades
    int iMaxClients = GetMaxClients();
    int awarenessPlayerCount = 0;
    int awarenessEntryCount = 0;
    ArrayList eligblePlayers = CreateArray(iMaxClients*5);
    
    for (int i = 1; i <= iMaxClients; ++i) {
      if (IsClientInGame(i) && IsPlayerAlive(i)) {
        if (GetClientTeam(i) == GetConVarInt(cvar_awarenessgrenade_team)) {
          
          PushArrayCell(eligblePlayers, i);
          PushArrayCell(eligblePlayers, i);
          PushArrayCell(eligblePlayers, i);
          ++awarenessPlayerCount;
          awarenessEntryCount += 3;
          
          int isVIP = CheckCommandAccess(i, "", FlagToBit(vipFlag));
          if (isVIP) {
            //Extra chance
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            PushArrayCell(eligblePlayers, i);
            
            awarenessEntryCount += 5;
          }
        }
      }
    }
    
    //Calculate total number of people to give medic shots
    int totalToGive = RoundToCeil(float(awarenessPlayerCount) * GetConVarFloat(cvar_awarenessgrenade_ratio));
    
    for (int c = 0; c < totalToGive; ++c) {
      int rand = GetRandomInt(0, awarenessEntryCount - 1);
      int client = GetArrayCell(eligblePlayers, rand);
      GivePlayerItem(client, "weapon_tagrenade");
      removeClientFromArray(eligblePlayers, client);
      awarenessEntryCount = GetArraySize(eligblePlayers);
      CreateTimer(0.5, Timer_ShowHintAwareness, client);
    }
  }
}

public Action Timer_ShowHintMediShot(Handle timer, int client)
{
  if (IsClientInGame(client))
    PrintHintText(client, "%t", "Gave Medi Shot");
}

public Action Timer_ShowHintAwareness(Handle timer, int client)
{
  if (IsClientInGame(client))
    PrintHintText(client, "%t", "Gave Awareness Grenade");
}

void removeClientFromArray(ArrayList array, int client)
{
  while (FindValueInArray(array, client) != -1)
  {
    RemoveFromArray(array, FindValueInArray(array, client));
  }
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "tagrenade_projectile"))
		return;
		
	SDKHook(entity, SDKHook_Spawn, OnTacticalNadeSpawned);
}

public Action OnTacticalNadeSpawned(int entity)
{
	if (g_offCollisionGroup == -1) {
		g_offCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
		if (g_offCollisionGroup == -1)
			return Plugin_Continue;
	}
  
	SetEntData(entity, g_offCollisionGroup, 2, 4, true);
	return Plugin_Continue;
}