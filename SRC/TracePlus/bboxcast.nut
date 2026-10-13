/*
 * Performs a bbox cast: a ray that stops at world geometry (TraceLine) or at the first entity bounding box
 * it enters, filtered by the settings. See BboxTraceAnalyzer::Trace.
 *
 * @param {Vector} startPos - The start position of the trace.
 * @param {Vector} endPos - The end position of the trace.
 * @param {array|CBaseEntity|null} ignoreEntities - A list of entities or a single entity to ignore during the trace. (optional)
 * @param {TraceSettings} settings - The settings to use for the trace. (optional, defaults to TracePlus.defaultSettings) 
 * @returns {BboxTraceResult} - The trace result object. 
*/
TracePlus["Bbox"] <- function(startPos, endPos, ignoreEntities = null, settings = TracePlus.defaultSettings, insideTestPos = null) { // todo: fucking insideTestPos here! its garbage
    if(typeof startPos != "Vector") throw("TracePlus.Bbox: 'startPos' argument must be a Vector, but got " + typeof startPos);
    if(typeof endPos != "Vector") throw("TracePlus.Bbox: 'endPos' argument must be a Vector, but got " + typeof endPos);
    if(typeof settings != "TraceSettings")  throw("TracePlus.Bbox: 'settings' argument must be a TraceSettings, but got " + typeof settings);
    if(ignoreEntities != null) {
        local ignoreType = typeof ignoreEntities;
        if (ignoreType == "array" || ignoreType == "ArrayEx" || ignoreType == "List") {
            foreach(idx, ent in ignoreEntities) {
                if(!ent || !ent.IsValid()) throw(format("TracePlus.Bbox: 'ignoreEntities' array/list contains a not-valid entity at index %d", idx))
                if (typeof ent != "pcapEntity" && !(ent instanceof CBaseEntity)) {
                    throw(format("TracePlus.Bbox: 'ignoreEntities' array/list contains a non-entity value at index %d (got %s). It must contain only entity handles.", idx, typeof ent));
                }
            }
        } else if (ignoreType != "pcapEntity" && !(ignoreEntities instanceof CBaseEntity)) {
            throw("TracePlus.Bbox: 'ignoreEntities' argument must be an entity handle, an array/list of entities, or null, but got " + ignoreType);
        }
    }

    local SCOPE = {} // TODO potential place for improvement
    
    SCOPE.startpos <- startPos;
    SCOPE.endpos <- endPos;
    SCOPE.ignoreEntities <- ignoreEntities 
    SCOPE.settings <- settings

    // todo: remove LEGACY from code! 
    local result = BboxTraceAnalyzer(startPos, endPos, ignoreEntities, settings, insideTestPos)

    local traceResult = TracePlus.Result.Bbox(SCOPE, result.hitpos, result.hitent)
    traceResult.surfaceNormal = result.hitnormal
    return traceResult
}

/*
 * Performs a bbox cast from the player's eyes. The player itself is always ignored.
 *
 * @param {number} distance - The distance of the trace.
 * @param {CBaseEntity|pcapEntity} player - The player entity.
 * @param {array|ArrayEx|List|CBaseEntity|pcapEntity|null} ignoreEntities - A list of entities or a single entity to ignore during the trace. (optional)
 * @param {TraceSettings} settings - The settings to use for the trace. (optional, defaults to TracePlus.defaultSettings)
 * @returns {BboxTraceResult} - The trace result object.
*/
TracePlus["FromEyes"]["Bbox"] <- function(distance, player, ignoreEntities = null, settings = TracePlus.defaultSettings) {
    local startPos = player.EyePosition()
    local endPos = macros.GetEyeEndpos(player, distance)

    ignoreEntities = TracePlus.Settings.UpdateIgnoreEntities(ignoreEntities, player)

    return TracePlus.Bbox(startPos, endPos, ignoreEntities, settings)
}