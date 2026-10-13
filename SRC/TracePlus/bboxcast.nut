/*
 * Performs a bbox cast: a ray that stops at world geometry (TraceLine) or at the first entity bounding box
 * it enters, filtered by the settings. See BboxTraceAnalyzer::Trace.
 *
 * @param {Vector} startPos - The start position of the trace.
 * @param {Vector} endPos - The end position of the trace.
 * @param {array|ArrayEx|List|CBaseEntity|pcapEntity|null} ignoreEntities - A list of entities or a single entity to ignore during the trace. Invalid entities in it are skipped. (optional)
 * @param {TraceSettings} settings - The settings to use for the trace. (optional, defaults to TracePlus.defaultSettings)
 * @returns {BboxTraceResult} - The trace result object.
*/
TracePlus["Bbox"] <- function(startPos, endPos, ignoreEntities = null, settings = null) {
    if(typeof startPos != "Vector") throw("TracePlus.Bbox: 'startPos' argument must be a Vector, but got " + typeof startPos);
    if(typeof endPos != "Vector") throw("TracePlus.Bbox: 'endPos' argument must be a Vector, but got " + typeof endPos);

    return TracePlus._BboxCast(startPos, endPos, ignoreEntities, TracePlus._IgnoreSet(ignoreEntities), TracePlus._Settings(settings), null)
}

/*
 * Performs a bbox cast from the player's eyes. The player itself is always ignored.
 *
 * @param {number} distance - The distance of the trace.
 * @param {CBaseEntity|pcapEntity} player - The player entity.
 * @param {array|ArrayEx|List|CBaseEntity|pcapEntity|null} ignoreEntities - A list of entities or a single entity to ignore during the trace. Invalid entities in it are skipped. (optional)
 * @param {TraceSettings} settings - The settings to use for the trace. (optional, defaults to TracePlus.defaultSettings)
 * @returns {BboxTraceResult} - The trace result object.
*/
TracePlus["FromEyes"]["Bbox"] <- function(distance, player, ignoreEntities = null, settings = null) {
    local startPos = player.EyePosition()
    local endPos = macros.GetEyeEndpos(player, distance)

    local ignoreSet = TracePlus._IgnoreSet(ignoreEntities)
    ignoreSet[player.entindex()] <- true

    return TracePlus._BboxCast(startPos, endPos, ignoreEntities, ignoreSet, TracePlus._Settings(settings), null)
}

/*
 * The bbox cast itself, shared by the public casts, which validate the arguments first.
*/
TracePlus["_BboxCast"] <- function(startPos, endPos, ignoreEntities, ignoreSet, settings, insideTestPos) {
    local SCOPE = {} // TODO potential place for improvement

    SCOPE.startpos <- startPos;
    SCOPE.endpos <- endPos;
    SCOPE.ignoreEntities <- ignoreEntities
    SCOPE.settings <- settings

    local result = BboxTraceAnalyzer(startPos, endPos, ignoreSet, settings, insideTestPos)

    local traceResult = TracePlus.Result.Bbox(SCOPE, result.hitpos, result.hitent)
    traceResult.surfaceNormal = result.hitnormal
    return traceResult
}

/*
 * Validates an ignoreEntities value and turns it into the set the analyzer checks.
*/
TracePlus["_IgnoreSet"] <- function(ignoreEntities) {
    local set = {}
    if(ignoreEntities == null) return set

    local type = typeof ignoreEntities
    if(type == "ArrayEx") ignoreEntities = ignoreEntities.arr
    
    // foreach over a List itself throws, iter() is the way
    else if(type == "List") ignoreEntities = ignoreEntities.iter()
    else if(type != "array") ignoreEntities = [ignoreEntities]

    foreach(ent in ignoreEntities) {
        if(typeof ent != "pcapEntity" && !(ent instanceof CBaseEntity))
            throw("TracePlus: 'ignoreEntities' must be an entity handle, a list of them or null, but got " + typeof ent)
        if(ent.IsValid()) set[ent.entindex()] <- true
    }
    return set
}

/*
 * Resolves the settings argument of the public casts.
*/
TracePlus["_Settings"] <- function(settings) {
    if(settings == null) return TracePlus.defaultSettings
    if(typeof settings != "TraceSettings") throw("TracePlus: 'settings' argument must be a TraceSettings, but got " + typeof settings)
    return settings
}
