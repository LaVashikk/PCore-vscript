::InitedPortals <- {}


/*
 * Checks if the given `prop_portal` is a blue (primary) portal. The color comes from the pair detector,
 * or from the model name for a portal no initialized pair has seen.
*/
::IsBluePortal <- function(ent) {
    local isBlue = ent.GetUserData("PortalIsBlue")
    if(isBlue != null) return isBlue
    return ent.GetModelName().find("portal2") == null
}

/*
 * Initializes a portal pair for portal casting (tracing lines through portals).
 *
 * Creates a `func_portal_detector` for the `LinkageGroupID` `id` that keeps track of the group's prop_portals:
 * a placed portal gets the health `id + 1` (so the default 0 means "not tracked") and its color, a removed one
 * the health 9999, and every portal knows whether the engine has linked it right now.
 * FindPartnerForPropPortal reads this to find the paired portal during portal traces.
*/
::InitPortalPair <- function(id) {
    if(id in InitedPortals) return InitedPortals[id]

    local detector = _CreatePortalDetector("LinkageGroupID", id)
    InitedPortals[id] <- detector

    // compilestring bakes `id` into the code instead of a free variable: that syntax differs between Squirrel 2 and 3.
    detector.ConnectOutputEx("OnStartTouchPortal", compilestring("_OnPortalPlaced(activator, " + id + ")"))
    detector.ConnectOutputEx("OnStartTouchLinkedPortal", compilestring("_OnPortalLinked(activator, " + id + ")"))
    detector.ConnectOutputEx("OnStartTouchPortal1", function() {entLib.FromEntity(activator).SetUserData("PortalIsBlue", true)})
    detector.ConnectOutputEx("OnStartTouchPortal2", function() {entLib.FromEntity(activator).SetUserData("PortalIsBlue", false)})
    detector.ConnectOutputEx("OnEndTouchPortal", function() {
        local portal = entLib.FromEntity(activator)
        portal.SetHealth(9999)
        _SetPortalLinked(portal, false)
    })

    // Enabling it already reports every portal of the group with its links, no need to rescan on top of that
    _StartPortalRescan(id)
    return detector
}
/*
 * Initializes linked portal doors for portal tracing.
 * This function is not part of the public API.
 *
 * This function is called automatically at the initialization.
*/
::SetupLinkedPortals <- function() {
    local portalStateHandler = function(state) {
        local p = entLib.FromEntity(self)
        p.SetTraceIgnore(state)
        local p2 = p.GetPartnerInstance()
        if(p2) p2.SetTraceIgnore(state)
        return true
    }
    // The door itself has no size, the engine gives it to a portal_base2D the door owns (built from its width/height)
    local doorPortals = {}
    for(local p; p = Entities.FindByClassname(p, "portal_base2D");) {
        local owner = p.GetOwner()
        if(owner) doorPortals[owner] <- p
    }

    for(local portal; portal = entLib.FindByClassname("linked_portal_door", portal);) {
        if(portal.GetUserData("processed"))
            continue

        portal.SetInputHook("Open", function():(portalStateHandler) {return portalStateHandler(false)})
        portal.SetInputHook("Close", function():(portalStateHandler) {return portalStateHandler(true)})

        // Half sizes: the mapper's `model` "halfWidth halfHeight" wins, the door's own portal_base2D otherwise
        local halfWidth, halfHeight
        if(portal.GetModelName() != "") {
            local wpInfo = split(portal.GetModelName(), " ")
            halfWidth = wpInfo[0].tointeger()
            halfHeight = wpInfo[1].tointeger()
        }
        else if(portal.CBaseEntity in doorPortals) {
            local maxs = doorPortals[portal.CBaseEntity].GetBoundingMaxs()
            halfWidth = maxs.y
            halfHeight = maxs.z
        }
        else continue

        local wpBBox = Vector(8, fabs(halfWidth), fabs(halfHeight))
        portal.SetBBox(wpBBox * -1, wpBBox)
        portal.SetUserData("processed", true)
    }
}

/*
 * Finds the partner portal for a given `prop_portal` entity: the linked portal of the other color in the same
 * pair, as tracked by the InitPortalPair detectors. Portals of a pair that was never initialized have no partner.
 *
 * @param {pcapEntity} portal - The `prop_portal` entity to find the partner for.
 * @returns {pcapEntity|null} - The partner portal entity, or `null` if no partner is found.
*/
::FindPartnerForPropPortal <- function(portal) {
    // A map can hold any number of portals per LinkageGroupID, but the engine links at most one blue with one orange
    if(!portal.GetUserData("PortalLinked")) return null

    local group = portal.GetHealth()
    local isBlue = IsBluePortal(portal)
    for(local partner; partner = entLib.FindByClassname("prop_portal", partner);) {
        if(partner.GetHealth() == group && partner.GetUserData("PortalLinked") && IsBluePortal(partner) != isBlue && !partner.GetUserData("TracePlusIgnore"))
            return partner
    }

    return null
}


/*
 * Creates an enabled `func_portal_detector` with one extra key-value pair. Its bounds cover the whole map,
 * and TracePlus ignores it.
 *
 * This function is not part of the public API.
*/
::_CreatePortalDetector <- function(extraKey, extraValue) {
    local detector = entLib.CreateByClassname("func_portal_detector", {solid = 0, CollisionGroup = 10})
    detector.SetKeyValue(extraKey, extraValue)
    detector.SetBBox(Vector(32000, 32000, 32000) * -1, Vector(32000, 32000, 32000))
    detector.SetTraceIgnore(true)
    EntFireByHandle(detector, "Enable")

    return detector
}

/*
 * OnStartTouchPortal of a pair detector: marks the portal with its group and hooks its SetActivatedState once.
 * This function is not part of the public API.
*/
::_OnPortalPlaced <- function(portal, id) {
    portal = entLib.FromEntity(portal)
    portal.SetHealth(id + 1)
    if(portal.GetUserData("PortalHooked")) return

    portal.SetUserData("PortalHooked", true)
    // Closing through SetActivatedState fires no detector output, and the hook doesn't get the value (0 or 1)
    // So any SetActivatedState means "links may have changed", the rescan tells the truth
    portal.SetInputHook("SetActivatedState", function() {
        local id = self.GetHealth() - 1
        if(id in InitedPortals) _RescanPortalGroup(id)
        return true
    })
}

// The pair detectors own TracePlusIgnore of prop_portals: only a linked portal can be traced through
::_SetPortalLinked <- function(portal, linked) {
    portal.SetUserData("PortalLinked", linked)
    portal.SetTraceIgnore(!linked)
}

/*
 * OnStartTouchLinkedPortal of a pair detector.
 * This function is not part of the public API.
*/
::_OnPortalLinked <- function(portal, id) {
    _SetPortalLinked(entLib.FromEntity(portal), true)
    // The engine announces only the portal that just got linked, never its partner: replay the group to hear both
    _RescanPortalGroup(id)
}

/*
 * Replays a pair detector: Disable fires OnEndTouchPortal for every portal of the group (drops the links),
 * Enable a moment later reports them again with the links the engine has now.
 * For a few frames the group's portals have no partner.
 * This function is not part of the public API.
*/
::_RescanPortalGroup <- function(id) {
    local detector = InitedPortals[id]
    // The replay fires OnStartTouchLinkedPortal itself, that must not start another one
    if(detector.GetUserData("PortalRescanning")) return

    EntFireByHandle(detector, "Disable")
    EntFireByHandle(detector, "Enable", "", 0.05)
    _StartPortalRescan(id)
}

// Marks the group as rescanning until the replayed outputs are surely through
::_StartPortalRescan <- function(id) {
    InitedPortals[id].SetUserData("PortalRescanning", true)
    ScheduleEvent.Add("global", function(id) {InitedPortals[id].SetUserData("PortalRescanning", false)}, 0.2, [id])
}
