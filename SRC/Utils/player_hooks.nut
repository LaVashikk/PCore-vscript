if("AllPlayers" in getroottable()) return

::AllPlayers <- ArrayEx()
const PLAYER_DEATH_MARKER = -999

/*
 * Gets all tracked players.
 *
 * @returns {ArrayEx} - The `AllPlayers` array itself (not a copy): the players as pcapEntity, in join order.
*/
::GetPlayers <- function() {
    return AllPlayers
}


/*
 * Tracks players joining the game and initializes them.
 *
 * For each player without "Eye" user data (not tracked yet): attaches eye control, initializes the portal pair
 * whose ID is the player's index in AllPlayers, appends the player to AllPlayers and calls OnPlayerJoined.
*/
::TrackPlayerJoins <- function() {
    for(local player; player = entLib.FindByClassname("player", player);) {
        if(player.GetUserData("Eye")) continue

        AttachEyeControl(player)
        InitPortalPair(AllPlayers.len())

        AllPlayers.append(player)
        OnPlayerJoined(player)
    }
}

/*
 * Handles player events in MP: leaving, death and respawn.
 *
 * A tracked player that is no longer valid gets OnPlayerLeft and is removed from AllPlayers. A player whose
 * health dropped to 0 or below gets OnPlayerDeath and a respawn monitor (_monitorRespawn), and its health is
 * set to PLAYER_DEATH_MARKER so that each death is handled once.
*/
::HandlePlayerEventsMP <- function() {
    local playersToRemove = []
    foreach(idx, player in AllPlayers){
        if(!player.IsValid()) {
            OnPlayerLeft(player)
            playersToRemove.append(idx)
            continue
        }

        if(player.GetHealth() > 0 || player.GetHealth() == PLAYER_DEATH_MARKER) continue

        OnPlayerDeath(player)
        ScheduleEvent.Add("global", _monitorRespawn, 0.3, [player])
        player.SetHealth(PLAYER_DEATH_MARKER)
    }

    if(playersToRemove.len() > 0) {
        for(local i = playersToRemove.len() - 1; i >= 0; i--) {
            AllPlayers.remove(playersToRemove[i])
        }
    }
}


/*
 * Runs `action` once a player exists.
*/
::RunWhenPlayerExists <- function(action) {
    // logic_script runs SUPER early, but the player always spawns after every map entity
    ScheduleEvent.Add("global", function():(action) {
        while (!Entities.FindByClassname(null, "player")) {
            yield 0.01
        }

        action()
    }, 0.1)
}

/*
 * Handles player death in SP: calls OnPlayerDeath once when the player's health drops to 0 or below,
 * then sets the health to PLAYER_DEATH_MARKER.
*/
::HandlePlayerEventsSP <- function() {
    local h = AllPlayers[0].GetHealth()
    if(h > 0 || h == PLAYER_DEATH_MARKER) return
    OnPlayerDeath(AllPlayers[0])
    AllPlayers[0].SetHealth(PLAYER_DEATH_MARKER)
}

/*
 * Waits until a dead player respawns, then calls OnPlayerRespawn. Ends silently if the player leaves.
 *
 * @param {pcapEntity} player - The dead player.
*/
function _monitorRespawn(player) {
    // A generator is fine here: this path only runs in multiplayer, which has no save/load.
    while(player.IsValid() && player.GetHealth() <= 0) {
        yield 0.3
    }
    if(player.IsValid())
        OnPlayerRespawn(player)
}


/*
 * Attaches eye tracking to a player: a logic_measure_movement copies the player's eye position and angles
 * to an info_target, which is stored as the player's "Eye" user data. Does nothing if the player already has it.
 *
 * @param {pcapEntity} player - The player.
*/
function AttachEyeControl(player) {
    if(player.GetUserData("Eye")) return

    local controlName = UniqueString("eyeControl")
    local eyeControlEntity = entLib.CreateByClassname("logic_measure_movement", {
        targetname = controlName, measuretype = 1}
    )

    local eyeName = UniqueString("eyePoint")
    local eyePointEntity = entLib.CreateByClassname("info_target", {targetname = eyeName})

    local playerName = player.GetName() == "" ? "!player" : player.GetName()

    EntFireByHandle(eyeControlEntity, "setmeasuretarget", playerName)
    EntFireByHandle(eyeControlEntity, "setmeasurereference", controlName);
    EntFireByHandle(eyeControlEntity, "SetTargetReference", controlName);
    EntFireByHandle(eyeControlEntity, "Settarget", eyeName);
    EntFireByHandle(eyeControlEntity, "Enable")

    player.SetUserData("Eye", eyePointEntity)
}


/*
 * Player hooks, empty by default. Each gets the player as a pcapEntity. Define your own versions
 * after the library is loaded: loading it replaces earlier definitions.
 *
 * OnPlayerJoined - The player was added to AllPlayers.
 * OnPlayerLeft - MP only. The tracked player is no longer valid.
 * OnPlayerDeath - The player's health dropped to 0 or below. Called once per death.
 * OnPlayerRespawn - MP only. The dead player's health is above 0 again.
*/
function OnPlayerJoined(player) {}
function OnPlayerLeft(player) {}
function OnPlayerDeath(player) {}
function OnPlayerRespawn(player) {}