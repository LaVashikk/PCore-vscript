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
 * whose ID is the player's index in AllPlayers, appends the player to AllPlayers and runs the join hooks.
*/
::TrackPlayerJoins <- function() {
    for(local player; player = entLib.FindByClassname("player", player);) {
        if(player.GetUserData("Eye")) continue

        AttachEyeControl(player)
        InitPortalPair(AllPlayers.len())

        AllPlayers.append(player)
        ScriptEvents.Emit("event_player_joined", player)
    }
}

/*
 * Handles player events in MP: leaving, death and respawn.
 *
 * A tracked player that is no longer valid is removed from AllPlayers and runs the leave hooks. A player whose
 * health dropped to 0 or below gets PLAYER_DEATH_MARKER as health (so each death is handled once), a respawn
 * monitor (_monitorRespawn), and runs the death hooks.
 * The state is updated before the hooks run: a hook that throws can't make the same event fire again.
*/
::HandlePlayerEventsMP <- function() {
    local left = [] // portal 2 is shit btw, it works so randomly!!! but probably P2MM fixed that so its should work
    local died = []
    for(local i = AllPlayers.len() - 1; i >= 0; i--) {
        local player = AllPlayers[i]
        if(!player.IsValid()) {
            AllPlayers.remove(i)
            left.append(player)
            continue
        }

        if(player.GetHealth() > 0 || player.GetHealth() == PLAYER_DEATH_MARKER) continue

        player.SetHealth(PLAYER_DEATH_MARKER)
        ScheduleEvent.Add("global", _monitorRespawn, 0.3, [player])
        died.append(player)
    }

    foreach(player in left) ScriptEvents.Emit("event_player_left", player)
    foreach(player in died) ScriptEvents.Emit("event_player_death", player)
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
 * Handles player death in SP: once the player's health drops to 0 or below, sets it to PLAYER_DEATH_MARKER
 * and runs the death hooks, once per death.
*/
::HandlePlayerEventsSP <- function() {
    local h = AllPlayers[0].GetHealth()
    if(h > 0 || h == PLAYER_DEATH_MARKER) return
    AllPlayers[0].SetHealth(PLAYER_DEATH_MARKER)
    ScriptEvents.Emit("event_player_death", AllPlayers[0])
}

/*
 * Waits until a dead player respawns, then runs the respawn hooks. Ends silently if the player leaves.
 *
 * @param {pcapEntity} player - The dead player.
*/
function _monitorRespawn(player) {
    // A generator is fine here: this path only runs in multiplayer, which has no save/load.
    while(player.IsValid() && player.GetHealth() <= 0) {
        yield 0.3
    }
    if(player.IsValid())
        ScriptEvents.Emit("event_player_respawn", player)
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
 * Player hooks: any number of functions per event, each gets the player (pcapEntity).
 * They are ScriptEvents subscriptions underneath, so they run in the order they were added and an error in one
 * stops the rest for that event.
 *
 * @param {function} action - Called with the player.
 * @param {object} scope - `this` for the action. (optional, default is the root table)
 * @returns {integer} - The hook id, for RemovePlayerHook.
*/

// The player was added to AllPlayers
::AddPlayerJoinHook <- function(action, scope = null) {
    return ScriptEvents.On("event_player_joined", action, scope)
}

// MP only: the tracked player is no longer valid, already removed from AllPlayers
::AddPlayerLeaveHook <- function(action, scope = null) {
    return ScriptEvents.On("event_player_left", action, scope)
}

// The player's health dropped to 0 or below. Runs once per death
::AddPlayerDeathHook <- function(action, scope = null) {
    return ScriptEvents.On("event_player_death", action, scope)
}

// MP only: the dead player's health is above 0 again
::AddPlayerRespawnHook <- function(action, scope = null) {
    return ScriptEvents.On("event_player_respawn", action, scope)
}

/*
 * Removes a player hook.
 *
 * @param {integer} id - The id returned by one of the Add*Hook functions.
 * @returns {boolean} - True if it was there.
*/
::RemovePlayerHook <- function(id) {
    return ScriptEvents.Off(id)
}
