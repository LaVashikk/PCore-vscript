::InitedPortals <- {}

/*
 * Creates an enabled `func_portal_detector` with one extra key-value pair. Its bounds cover the whole map,
 * and TracePlus ignores it.
 * 
 * This function is not part of the public API.
 *
 * @param {string} extraKey - The key of the extra key-value pair (e.g. "LinkageGroupID").
 * @param {any} extraValue - The value of the extra key-value pair.
 * @returns {pcapEntity} - The created detector.
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
 * Initializes a portal pair for portal casting (tracing lines through portals). 
 * 
 * Creates a `func_portal_detector` for the `LinkageGroupID` `id`. When a portal of this pair is placed,
 * its health is set to `id`; when it is removed, to 9999. FindPartnerForPropPortal matches portals by this
 * health to find the paired portal during portal traces.
 * 
 * @param {number} id - The ID of the portal pair (`LinkageGroupID`).
 * @returns {pcapEntity} - The detector of the pair. If the pair is already initialized, its existing detector.
*/
::InitPortalPair <- function(id) {
    if(id in InitedPortals) return InitedPortals[id]

    local detector = _CreatePortalDetector("LinkageGroupID", id)

    // compilestring bakes `id` into the code instead of a free variable: that syntax differs between Squirrel 2 and 3.
    detector.ConnectOutputEx("OnStartTouchPortal", compilestring("activator.SetHealth(" + id + ")"))
    detector.ConnectOutputEx("OnEndTouchPortal", compilestring("activator.SetHealth(9999)"))
    InitedPortals[id] <- detector
    
    return detector
}

/*
 * Initializes linked portal doors for portal tracing.
 * This function is not part of the public API.
 * 
 * For each `linked_portal_door` that has not been processed yet:
 * 1. Hooks its Close and Open inputs: Close makes TracePlus ignore the door and its partner, Open makes them traceable again.
 * 2. Sets its bounding box from the "width height" pair in its `model` keyvalue.
 *    A door with an empty `model` keyvalue gets no bounding box.
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
    for(local portal; portal = entLib.FindByClassname("linked_portal_door", portal);) {
        if(portal.GetUserData("processed"))
            continue
    
        portal.SetInputHook("Open", function():(portalStateHandler) {return portalStateHandler(false)})
        portal.SetInputHook("Close", function():(portalStateHandler) {return portalStateHandler(true)})

        local partner = portal.GetPartnerInstance()
    
        if(portal.GetModelName() == "") 
            continue
        
        local wpInfo = split(portal.GetModelName(), " ")
        local wpBBox = math.vector.abs(Vector(8, wpInfo[0].tointeger(), wpInfo[1].tointeger()))
        portal.SetBBox(wpBBox * -1, wpBBox)
        portal.SetUserData("processed", true)
    }
}

/*
 * Finds the partner portal for a given `prop_portal` entity: another `prop_portal` with the same pair ID
 * in its health (set by the InitPortalPair detectors) that TracePlus does not ignore.
 * 
 * @param {pcapEntity} portal - The `prop_portal` entity to find the partner for. 
 * @returns {pcapEntity|null} - The partner portal entity, or `null` if no partner is found. 
*/
::FindPartnerForPropPortal <- function(portal) {    
    local portalPairId = portal.GetHealth()
    for(local partner; partner = entLib.FindByClassname("prop_portal", partner);) { 
        local partnerPairId = partner.GetHealth() 
        if(portalPairId != partnerPairId || partner.entindex() == portal.entindex() || partner.GetClassname() != "prop_portal" || partner.GetUserData("TracePlusIgnore"))
            continue
        
        return partner 
    }

    return null
}

/*
 * Checks if the given `prop_portal` is a blue (primary) portal, by its model name.
 *
 * @param {pcapEntity} ent - The `prop_portal` to check.
 * @returns {boolean} - True if the model name does not contain "portal2" (the orange portal model), false otherwise.
*/
::IsBluePortal <- function(ent) { 
    return ent.GetModelName().find("portal2") == null
}