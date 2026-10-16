local results = TracePlus["Result"]

results["Cheap"] <- class {
    traceHandler = null;
    hitpos = null;

    surfaceNormal = null;
    portalEntryInfo = null;

    constructor(traceHandler, hitpos) {
        this.traceHandler = traceHandler
        this.hitpos = hitpos
    }

    /*
     * Gets the start position of the trace.
     *
     * @returns {Vector} - The start position.
    */
    function GetStartPos() {
        return this.traceHandler.startpos
    }

    /*
     * Gets the end position of the trace.
     *
     * @returns {Vector} - The end position.
    */
    function GetEndPos() {
        return this.traceHandler.endpos
    }

    /*
     * Gets the hit position of the trace.
     *
     * @returns {Vector} - The hit position. 
    */
    function GetHitPos() {
        return this.hitpos
    }

    /*
     * Gets the fraction of the trace distance where the hit occurred.
     *
     * @returns {number} - The hit fraction.
    */
    function GetFraction() {
        return this.traceHandler.fraction
    }

    /*
     * Checks if the trace hit anything.
     *
     * @returns {boolean} - True if the trace hit something, false otherwise.
    */
    function DidHit() {
        return fabs(this.traceHandler.fraction - 1.0) > 0.0001
    }

    /*
     * Gets the normalized direction vector of the trace.
     *
     * @returns {Vector} - The direction vector.
    */
    function GetDir() {
        local dir = (this.traceHandler.endpos - this.traceHandler.startpos); dir.Norm()
        return dir
    }

    /*
     * Gets the trace that entered the portal this trace continues from (portal casting only).
     *
     * @returns {TraceResult|null} - The previous trace, or null for the first one.
    */
    function GetPortalEntryInfo() {
        return this.portalEntryInfo
    }

    /*
     * Gets every trace of a portal casting, from the first one to this one.
     *
     * @returns {List} - The TraceResult objects in cast order, this trace last.
    */
    function GetAggregatedPortalEntryInfo() {
        local list = List(this)
        for(local trace = this; trace = trace.portalEntryInfo;) {
            list.append(trace)
        }
        return list.reverse()
    }

    /*
     * Gets the impact normal of the surface hit by the trace.
     * Calculated with CalculateImpactNormal on the first call, then cached.
     *
     * @returns {Vector} - The impact normal vector.
    */
    function GetImpactNormal() {
        if(this.surfaceNormal)
            return this.surfaceNormal
        
        this.surfaceNormal = CalculateImpactNormal(this.traceHandler.startpos, this.hitpos)
        return this.surfaceNormal 
    } 

    // Stubs for interface compatibility with Bbox trace results
    function GetEntity() return null                                                                             
    function GetEntityClassname() return null                                                                    
    function DidHitWorld() return this.DidHit()                                                                  
    function GetTraceSettings() return null                                                                      

    function _typeof() return "TraceResult"
    function _tostring() {
        return "TraceResult | startpos: " + GetStartPos() + ", endpos: " + GetEndPos() + ", fraction: " + GetFraction() + ", hitpos: " + GetHitPos()
    }
}



// Don't forget, the class extension is broken in VScripts
// Valvo's, I hate u :<
results["Bbox"] <- class {
    traceHandler = null;
    hitpos = null;
    hitent = null;

    surfaceNormal = null;
    portalEntryInfo = null;

    constructor(traceHandler, hitpos, hitent) {
        this.traceHandler = traceHandler
        this.hitpos = hitpos
        this.hitent = hitent
    }

    /*
     * Gets the start position of the trace.
     *
     * @returns {Vector} - The start position.
    */
    function GetStartPos() {
        return this.traceHandler.startpos
    }

    /*
     * Gets the end position of the trace.
     *
     * @returns {Vector} - The end position.
    */
    function GetEndPos() {
        return this.traceHandler.endpos
    }

    /*
     * Gets the hit position of the trace.
     *
     * @returns {Vector} - The hit position. 
    */
    function GetHitPos() {
        return this.hitpos
    }

    /*
     * Gets the entity hit by the trace.
     *
     * @returns {pcapEntity|null} - The hit entity, or null if no entity was hit or it is no longer valid.
    */
    function GetEntity() {
        if(this.hitent && this.hitent.IsValid())
            return entLib.FromEntity(this.hitent)
    }

    /*
     * Gets the classname of the entity hit by the trace.
     *
     * @returns {string|null} - The classname of the hit entity, or null if no entity was hit or it is no longer valid.
    */
    function GetEntityClassname() {
        return (this.hitent && this.hitent.IsValid()) ? this.hitent.GetClassname() : null 
    }

    /*
     * Gets the list of entities that were ignored during the trace.
     *
     * @returns {array|ArrayEx|List|CBaseEntity|pcapEntity|null} - The `ignoreEntities` value the trace was called with.
    */
    function GetIngoreEntities() {
        return this.traceHandler.ignoreEntities
    }

    /*
     * Gets the settings used for the trace.
     *
     * @returns {TraceSettings} - The trace settings object. 
    */
    function GetTraceSettings() {
        return this.traceHandler.settings
    }

    /*
     * Checks if the trace hit anything.
     *
     * @returns {boolean} - True if the trace hit something, false otherwise.
    */
    function DidHit() {
        return fabs(this.GetFraction() - 1.0) > 0.0001
    }

    /*
     * Checks if the trace hit the world geometry (not an entity). 
     *
     * @returns {boolean} - True if the trace hit the world, false otherwise.
    */
    function DidHitWorld() {
        return !this.GetEntity() && DidHit()
    }

    /*
     * Gets the fraction of the trace distance where the hit occurred.
     *
     * @returns {number} - The hit fraction. 
    */
    function GetFraction() {
        local length = macros.GetDist(this.traceHandler.startpos, this.traceHandler.endpos)
        // A zero-length trace goes nowhere and hits nothing, 0 / 0 would be NaN (and NaN != 1, so "hit")
        if(length == 0) return 1.0
        return macros.GetDist(this.traceHandler.startpos, this.hitpos) / length
    }

    /*
     * Gets the normalized direction vector of the trace.
     *
     * @returns {Vector} - The direction vector.
    */
    function GetDir() {
        local dir = (this.traceHandler.endpos - this.traceHandler.startpos); dir.Norm()
        return dir
    }

    /*
     * Gets the cast that entered the portal this cast continues from (portal casting only).
     *
     * @returns {BboxTraceResult|null} - The previous cast, or null for the first one.
    */
    function GetPortalEntryInfo() {
        return this.portalEntryInfo
    }

    /*
     * Gets every cast of a portal casting, from the first one to this one.
     *
     * @returns {List} - The BboxTraceResult objects in cast order, this cast last.
    */
    function GetAggregatedPortalEntryInfo() {
        local list = List(this)
        for(local trace = this; trace = trace.portalEntryInfo;) {
            list.append(trace)
        }
        return list.reverse()
    }

    /*
     * Gets the impact normal of the surface hit by the trace.
     * For an entity hit it is the normal of the entered bbox face, set by the trace itself. Otherwise it is
     * calculated on the first call, then cached: CalculateImpactNormalFromBbox for a valid hit entity
     * (a trace that started inside its box), CalculateImpactNormal for the world.
     *
     * @returns {Vector} - The impact normal vector.
    */
    function GetImpactNormal() {
        if(this.surfaceNormal)
            return this.surfaceNormal

        local hitEnt = this.GetEntity()
        if(hitEnt) {
            this.surfaceNormal = CalculateImpactNormalFromBbox(this.GetStartPos(), this.hitpos, hitEnt)
        } else {
            this.surfaceNormal = CalculateImpactNormal(this.GetStartPos(), this.hitpos)
        }

        return this.surfaceNormal
    } 

    function _typeof() return "BboxTraceResult"
    function _tostring() {
        return "TraceResult | startpos: " + GetStartPos() + ", endpos: " + GetEndPos() + ", hitpos: " + GetHitPos() + ", entity: " + GetEntity()
    }
}