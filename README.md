# [Any] IP Tracker (NO VAC SERVERS)

Description:  
Logs players IP addresses to two database tables.

Cvars:  
- sm_ip_tracker_version
  - Plugin Version

- sm_ip_tracker_verbose  
    - Set to 1 and the plugin will also log to IPTrackerLogs.

Install Instructions:  
1. Place IPTracker.smx into your addons/sourcemod/plugins/ folder.
2. Update your databases.cfg file with an entry for "**iptracker**".

Notes:  
- If the plugin loses connection to the database server, it will log to the logs/iptracker_ip.log file as a backup solution.
This plugin does NOT support SQLite.

Original Plugin  
https://forums.alliedmods.net/showthread.php?t=179059