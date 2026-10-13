/*
 * Applies portal transformations to a trace, calculating a new start and end position for the trace after passing through the portal.
 *
 * @param {Vector} startPos - The original start position of the trace.
 * @param {Vector} hitPos - The hit position of the trace on the portal.
 * @param {number} rayDist - The length of the new ray.
 * @param {pcapEntity} portal - The portal entity.
 * @param {pcapEntity} partnerPortal - The partner portal entity.
 * @returns {table} - A table containing the new startPos and endPos for the trace after passing through the portal.
*/
::_ApplyPortal <- function(startPos, hitPos, rayDist, portal, partnerPortal) {
    local portalAngles = portal.GetAngles();
    local partnerAngles = partnerPortal.GetAngles();
    local offset = math.vector.unrotate(hitPos - portal.GetOrigin(), portalAngles);
    local dir = math.vector.unrotate(hitPos - startPos, portalAngles);

    offset = Vector(offset.x * -1, offset.y * -1, offset.z)
    dir = Vector(dir.x * -1, dir.y * -1, dir.z)

    dir = math.vector.rotate(dir, partnerAngles)
    dir.Norm()

    local newStart = partnerPortal.GetOrigin() + math.vector.rotate(offset, partnerAngles)
    return {
        startPos = newStart,
        endPos = newStart + dir * rayDist
    }
}


/*
 * Performs a cheap trace with portal support: a trace that ends on a prop_portal or linked_portal_door
 * with a partner continues from the partner, up to MAX_PORTAL_CAST_DEPTH traces in total.
 *
 * @param {Vector} startPos - The start position of the trace.
 * @param {Vector} endPos - The end position of the trace.
 * @returns {TraceResult} - The last trace; the previous ones are chained through GetPortalEntryInfo.
*/
TracePlus["PortalCheap"] <- function(startPos, endPos) {
    local length = (endPos - startPos).Length()
    local previousTraceData
    // Portal castings
    for (local i = 0; i < MAX_PORTAL_CAST_DEPTH; i++) {
        local traceData = TracePlus.Cheap(startPos, endPos)
        traceData.portalEntryInfo = previousTraceData

        local hitPos = traceData.GetHitPos()
        length -= (hitPos - startPos).Length()

        // Find a nearby portal entity.
        local portal = entLib.FindByClassnameWithin("prop_portal", hitPos, 5)
        if(!portal)
            portal = entLib.FindByClassnameWithin("linked_portal_door", hitPos, 10)
        if(!portal)
            return traceData

        local normal = traceData.GetImpactNormal()
        if(normal.Dot(portal.GetForwardVector()) < 0.8)
            return traceData

        local partnerPortal = portal.GetPartnerInstance()
        if (partnerPortal == null) {
            return traceData
        }

        // Calculate new start and end positions for the trace after passing through the portal.
        local ray = _ApplyPortal(startPos, hitPos, length, portal, partnerPortal);
        // Adjust the start position slightly to prevent the trace from getting stuck.
        startPos = ray.startPos + partnerPortal.GetForwardVector()
        endPos = ray.endPos
        previousTraceData = traceData
        // todo: place portal info here!
    }
    return previousTraceData
}

/*
 * Performs a cheap trace with portal support from the player's eyes.
 *
 * @param {number} distance - The distance of the trace.
 * @param {CBaseEntity|pcapEntity} player - The player entity.
 * @returns {TraceResult} - The last trace; the previous ones are chained through GetPortalEntryInfo.
*/
 TracePlus["FromEyes"]["PortalCheap"] <- function(distance, player) {
    local startpos = player.EyePosition()
    local endpos = macros.GetEyeEndpos(player, distance)

    return TracePlus.PortalCheap(startpos, endpos)
}


/*
 * Performs a bbox cast with portal support: a cast that hits a prop_portal or linked_portal_door with a partner
 * continues from the partner, up to MAX_PORTAL_CAST_DEPTH casts in total. Portals marked with SetTraceIgnore
 * are not passed through. After a portal, the partner portal is added to the ignored entities.
 *
 * @param {Vector} startPos - The start position of the trace.
 * @param {Vector} endPos - The end position of the trace.
 * @param {array|ArrayEx|List|CBaseEntity|pcapEntity|null} ignoreEntities - A list of entities or a single entity to ignore during the trace. (optional)
 * @param {TraceSettings} settings - The settings to use for the trace. (optional, defaults to TracePlus.defaultSettings)
 * @returns {BboxTraceResult} - The last cast; the previous ones are chained through GetPortalEntryInfo.
*/
TracePlus["PortalBbox"] <- function(startPos, endPos, ignoreEntities = null, settings = null) {
    local length = (endPos - startPos).Length()
    local previousTraceData
    local insideTestPos = null
    // Portal castings
    for (local i = 0; i < MAX_PORTAL_CAST_DEPTH; i++) {
        local traceData = TracePlus.Bbox(startPos, endPos, ignoreEntities, settings, insideTestPos)
        traceData.portalEntryInfo = previousTraceData

        local hitPos = traceData.GetHitPos()
        local portal = traceData.GetEntity()
        length -= (hitPos - startPos).Length()

        if(!portal || portal.GetClassname() != "linked_portal_door")
            portal = entLib.FindByClassnameWithin("prop_portal", hitPos, 1) // todo: i should optimize it...
        if(!portal)
            return traceData

        local partnerPortal = portal.GetPartnerInstance()
        if (partnerPortal == null) {
            // dev.warning("Portal {} doesn't have a partner ;(", portal)
            return traceData
        }

        if(portal.GetUserData("TracePlusIgnore") || partnerPortal.GetUserData("TracePlusIgnore"))
            return traceData

        if(portal.GetClassname() == "prop_portal") {
            local normal = traceData.GetImpactNormal()
            if(normal.Dot(portal.GetForwardVector()) < 0.8)
                return traceData
        }

        ignoreEntities = TracePlus.Settings.UpdateIgnoreEntities(ignoreEntities, partnerPortal)

        local ray = _ApplyPortal(startPos, hitPos, length, portal, partnerPortal);
        // Start 7 units out of the exit portal so that the TraceLine does not start inside the wall.
        startPos = ray.startPos + partnerPortal.GetForwardVector() * 7
        // TODO: THIS SO FUCKING CURSED I HATE THIS!!! MAKE BETTER SHIT SOMEDAY PLEASE!
        insideTestPos = ray.startPos - partnerPortal.GetForwardVector()
        endPos = ray.endPos
        previousTraceData = traceData
    }
    return previousTraceData
}

/*
 * Performs a bbox cast with portal support from the player's eyes. The player itself is always ignored.
 *
 * @param {number} distance - The distance of the trace.
 * @param {CBaseEntity|pcapEntity} player - The player entity.
 * @param {array|ArrayEx|List|CBaseEntity|pcapEntity|null} ignoreEntities - A list of entities or a single entity to ignore during the trace. (optional)
 * @param {TraceSettings} settings - The settings to use for the trace. (optional, defaults to TracePlus.defaultSettings)
 * @returns {BboxTraceResult} - The last cast; the previous ones are chained through GetPortalEntryInfo.
*/
 TracePlus["FromEyes"]["PortalBbox"] <- function(distance, player, ignoreEntities = null, settings = null) {
    local startPos = player.EyePosition()
    local endPos = macros.GetEyeEndpos(player, distance)
    ignoreEntities = TracePlus.Settings.UpdateIgnoreEntities(ignoreEntities, player)

    return TracePlus.PortalBbox(startPos, endPos, ignoreEntities, settings)
}