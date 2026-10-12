if("GetPlayerEx" in getroottable()) {
    return
}

::_frametime <- FrameTime
/*
 * Returns the current frame time, ensuring it is never zero.
 *
 * Overrides the native FrameTime: returns 0.016 when the engine reports a frame time of 0.
 *
 * @returns {number} - The current frame time in seconds.
*/
::FrameTime <- function() {
    local tick = _frametime()
    if(tick == 0)
        return 0.016
    return tick
}

::_uniquestring <- UniqueString
/*
 * Generates a unique string with the specified prefix.
 *
 * Overrides the native UniqueString: the result is the prefix, "_", and a unique id.
 *
 * @param {string} prefix - The prefix to use for the unique string. (optional, default="u")
 * @returns {string} - The generated unique string.
*/
::UniqueString <- function(prefix = "u") {
    return prefix + "_" + _uniquestring().slice(0, -1)
}

::_EntFireByHandle <- EntFireByHandle
/*
 * Fires an input on an entity. Overrides the native EntFireByHandle.
 *
 * Accepts pcapEntity for target, activator and caller. With `eventName`, the delay is handled by ScheduleEvent
 * under that event instead of the engine I/O queue, so the input can be cancelled with ScheduleEvent.Cancel(eventName).
 *
 * @param {CBaseEntity|pcapEntity} target - The target entity to trigger the input on.
 * @param {string} action - The name of the input to trigger.
 * @param {string} value - The value to pass to the input. (optional, default "")
 * @param {number} delay - The delay in seconds before triggering the input. (optional, default 0)
 * @param {CBaseEntity|pcapEntity} activator - The activator entity (!activator of the input). (optional)
 * @param {CBaseEntity|pcapEntity} caller - The caller entity (!caller of the input). (optional)
 * @param {string} eventName - The ScheduleEvent event to schedule the input under. (optional)
*/
::EntFireByHandle <- function(target, action, value = "", delay = 0, activator = null, caller = null, eventName = null) {
    if (typeof target == "pcapEntity")
        target = target.CBaseEntity
    if (typeof activator == "pcapEntity")
        activator = activator.CBaseEntity
    if (typeof caller == "pcapEntity")
        caller = caller.CBaseEntity

    if(!eventName)
        return _EntFireByHandle(target, action, value, delay, activator, caller)
    ScheduleEvent.Add(eventName, _EntFireByHandle, delay, [target, action, value, 0, activator, caller])
}

/*
 * Returns a player as a pcapEntity.
 *
 * @param {int} index - The index of the player in AllPlayers (0-based, join order). Ignored in single-player. (optional, default 0)
 * @returns {pcapEntity|null} - The player, or null if there is no player at that index.
*/
::GetPlayerEx <- function(index = 0) {
    if(!IsMultiplayer())
        return entLib.FromEntity(GetPlayer())

    if(index >= AllPlayers.len()) return null
    return AllPlayers[index]
}