#include <sourcemod>
#define VERSION "1.0.2"

new Handle:v_Verbose = INVALID_HANDLE;
new Handle:db = INVALID_HANDLE;
new g_iVerbose = 0;

public Plugin:myinfo = 
{
    name = "[Any] IP Tracker",
    author = "nesi",
    description = "Tracks IP addresses",
    version = VERSION,
    url = "nesi.dev"
}

public OnPluginStart()
{
    CreateConVar("sm_ip_tracker_version", VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
    v_Verbose = CreateConVar("sm_hvh_ip_tracker_verbose", "0", "Enable verbose logging.", 0, true, 0.0, true, 1.0);
    HookConVarChange(v_Verbose, UpdateCvar);
    Connect();
}

public UpdateCvar(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_iVerbose = StringToInt(newValue);
}

public OnClientPostAdminCheck(client)
{
    if (IsFakeClient(client))
        return;
    
    new String:ip[64];
    new String:steamID[256];
    decl String:name[256];
    GetClientIP(client, ip, sizeof(ip));
    GetClientName(client, name, sizeof(name));

    GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))
    
    if (db == INVALID_HANDLE)
    {
        //Log to file instead
        decl String:path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "logs/ip_tracker.log");
        new Handle:file = OpenFile(path, "a");
        WriteFileLine(file, "%L connected, IP address: %s", client, ip);
        CloseHandle(file);
        return;
    }
    
    SQL_EscapeString(db, name, name, sizeof(name));
    
    decl String:query[1024];
    Format(query, sizeof(query), "INSERT INTO `IPTracker` (`SteamID`, `Name`, `LastConnected`) VALUES ('%s', '%s', '%i') ON DUPLICATE KEY UPDATE `LastConnected` = '%i', `Name` = '%s';", steamID, name, GetTime(), GetTime(), name);
    SQL_TQuery(db, SQLErrorCheckCallback, query);
    
    Format(query, sizeof(query), "UPDATE `IPTracker` SET `IP10` = `IP9`, `IP9` = `IP8`, `IP8` = `IP7`, `IP7` = `IP6`, `IP6` = `IP5`, `IP5` = `IP4`, `IP4` = `IP3`, `IP3` = `IP2`, `IP2` = `IP1`, `IP1` = '%s' WHERE `SteamID` = '%s' AND `IP1` != '%s';", ip, steamID, ip);
    SQL_TQuery(db, SQLErrorCheckCallback, query);
    
    if (g_iVerbose == 1)
    {
        Format(query, sizeof(query), "INSERT INTO `IPTrackerLogs` (`SteamID`, `Name`, `IPAddress`, `ConnectTime`) VALUES ('%s', '%s', '%s', '%i');", steamID, name, ip, GetTime());
        SQL_TQuery(db, SQLErrorCheckCallback, query);
    }
}


// ################################
//
// SQL Connection and table stuffs below this point
//
// ################################

Connect()
{
    if (SQL_CheckConfig("iptracker"))
        SQL_TConnect(OnDatabaseConnect, "iptracker");
    else
        SetFailState("Can't find 'iptracker' entry in sourcemod/configs/databases.cfg!");
}

public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("Failed to connect! Error: %s", error);
        PrintToServer("Failed to connect: %s", error)
        SetFailState("Failed to connect, SQL Error:  %s", error);
        return;
    }
    LogMessage("[IP Tracker v%s] Online and connected to database!", VERSION);
    PrintToServer("[IP Tracker v%s] Online and connected to database!", VERSION);
    db = hndl;
    SQL_CreateTables();
}

SQL_CreateTables()
{
    new len = 0;
    new String:query[1256];
    len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `IPTracker` (");
    len += Format(query[len], sizeof(query)-len, "  `id` int(32) NOT NULL AUTO_INCREMENT,");
    len += Format(query[len], sizeof(query)-len, "  `SteamID` varchar(32) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `Name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `LastConnected` int(12) NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `IP1` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP2` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP3` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP4` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP5` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP6` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP7` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP8` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP9` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  `IP10` varchar(64) COLLATE utf8_unicode_ci DEFAULT '0.0.0.0',");
    len += Format(query[len], sizeof(query)-len, "  PRIMARY KEY (`id`),");
    len += Format(query[len], sizeof(query)-len, "  UNIQUE KEY `SteamID` (`SteamID`)");
    len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;");

    SQL_TQuery(db, SQLErrorCheckCallback, query);
    
    len = 0;
    Format(query, sizeof(query), ""); 	// Purge the string
    len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `IPTrackerLogs` (");
    len += Format(query[len], sizeof(query)-len, "  `id` int(32) NOT NULL AUTO_INCREMENT,");
    len += Format(query[len], sizeof(query)-len, "  `SteamID` varchar(32) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `IPAddress` varchar(64) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `Name` varchar(128) COLLATE utf8_unicode_ci NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  `ConnectTime` int(12) NOT NULL,");
    len += Format(query[len], sizeof(query)-len, "  PRIMARY KEY (`id`),");
    len += Format(query[len], sizeof(query)-len, "  KEY `SteamID` (`SteamID`)");
    len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;");
    
    SQL_TQuery(db, SQLErrorCheckCallback, query);
    
    Format(query, sizeof(query), "SET NAMES utf8;");
    SQL_TQuery(db, SQLErrorCheckCallback, query);
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (!StrEqual("", error))
        LogError("SQL Error: %s", error);
}
