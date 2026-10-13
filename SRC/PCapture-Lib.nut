/*+--------------------------------------------------------------------------------+
|                           PCapture Vscripts Library                               |
 +---------------------------------------------------------------------------------+
| Author:                                                                           |
|     One-of-a-Kind - laVashik                                                      |
 +---------------------------------------------------------------------------------+
| pcapture-lib.nut                                                                  |
|       The main file in the library. initializes required parts of the library     |
|    GitHud repo: https://github.com/LaVashikk/PCapture-LIB                          |
+----------------------------------------------------------------------------------+ */

local version = "PCapture-Lib 5.0 DEV"
local rootScope = getroottable()

// `Self` must be in any case, even if the script is run directly by the interpreter
if (!("self" in this)) {
    self <- Entities.First()
} else {
    getroottable()["self"] <- self
}

if("LIB_VERSION" in getroottable() && version.find("Debug") == null) {
    printl("\n")
    dev.warning("PCapture-Lib already initialized.")
    if(LIB_VERSION != version) {
        printl("\n======================== WARNING ========================")
        printl("Attempting to initialize different versions of the PCapture-Lib library!")
        macros.fprint("Inited version \"{}\" != \"{}\"", LIB_VERSION, version)
        printl("==========================================================\n")
    }
    return
}

/*
 * Global tables shared by the modules, keyed by CBaseEntity:
 * pcapEntityCache - the pcapEntity wrappers returned by entLib.
 * EntitiesScopes - the user data of pcapEntity.SetUserData/GetUserData.
 * TracePlusIgnoreEnts - the pcapEntity.SetTraceIgnore flags, read by TracePlus.
*/
::pcapEntityCache <- {}
::EntitiesScopes <- {}
::TracePlusIgnoreEnts <- {}

DoIncludeScript("PCapture-LIB/SRC/IDT/init.nut", rootScope)
DoIncludeScript("PCapture-LIB/SRC/Math/init.nut", rootScope)
DoIncludeScript("PCapture-LIB/SRC/ActionScheduler/init.nut", rootScope)
DoIncludeScript("PCapture-LIB/SRC/Utils/init.nut", rootScope)

::LibLogger <- LoggerLevels.Info
::MAX_PORTAL_CAST_DEPTH <- 4
::ALWAYS_PRECACHED_MODEL <- "models/weapons/w_portalgun.mdl" // needed for pcapEntity::EmitSoundEx

DoIncludeScript("PCapture-LIB/SRC/TracePlus/init.nut", rootScope)
DoIncludeScript("PCapture-LIB/SRC/Animations/init.nut", rootScope)
DoIncludeScript("PCapture-LIB/SRC/ScriptEvents/init.nut", rootScope)
DoIncludeScript("PCapture-LIB/SRC/HUD/init.nut", rootScope)

// Every 5 seconds, drop the entries of deleted entities from the global tables above.
ScheduleEvent.AddInterval("global", function() {
    foreach(ent, _ in EntitiesScopes) {
        if(!ent || !ent.IsValid()) {
            delete EntitiesScopes[ent]
        }
    }
    foreach(ent, _ in pcapEntityCache) {
        if(!ent || !ent.IsValid()) {
            delete pcapEntityCache[ent]
        }
    }
    foreach(ent, _ in TracePlusIgnoreEnts) {
        if(!ent || !ent.IsValid()) {
            delete TracePlusIgnoreEnts[ent]
        }
    }
    // linked_portal_door spawned after the map start, cheap enough to check here
    for(local door; door = entLib.FindByClassname("linked_portal_door", door);) {
        if(!door.GetUserData("processed")) {
            SetupLinkedPortals()
            break
        }
    }
}, 5, 0)



if(IsMultiplayer()) {
    ScheduleEvent.Add("global", TrackPlayerJoins, 2) // Thanks Volve for making it take so long for players to initialize
    ScheduleEvent.AddInterval("global", HandlePlayerEventsMP, 0.3)

    if("TEAM_SINGLEPLAYER" in getroottable())
        // This session is running in P2MM, actively monitoring players.
        ScheduleEvent.AddInterval("global", TrackPlayerJoins, 1, 2)
}

// No player and no portal_base2D for linked doors yet, the map isn't spawned
RunWhenPlayerExists(function() {
    TrackPlayerJoins()
    SetupLinkedPortals()
    if(!IsMultiplayer())
        ScheduleEvent.AddInterval("global", HandlePlayerEventsSP, 0.5)
})


::LIB_VERSION <- version
::PCaptureLibInited <- true

printl("\n----------------------------------------")
printl("Welcome to " + LIB_VERSION)
printl("Author: laVashik Production") // The God of VScripts :P
printl("GitHub: https://github.com/LaVashikk/PCapture-LIB")
printl("----------------------------------------\n")
