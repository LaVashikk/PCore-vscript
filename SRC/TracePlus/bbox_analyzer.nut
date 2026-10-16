// Enhanced entity cache with aggressive caching
class BufferedEntity {
    // todo: if this well be global and bbox will be changed, stuff broke
    entity = null;
    origin = null;
    // World AABB: the broad phase for everyone, and the exact box for not `rotated` entities
    bboxMax = null;
    bboxMin = null;

    // Cached rounded origin and angles
    roundedOriginX = null;
    roundedOriginY = null;
    roundedOriginZ = null;
    roundedAnglesX = null;
    roundedAnglesY = null;
    roundedAnglesZ = null;

    // local bounds in entity space, F/L/U are the local x/y/z axes in world
    rotated = false;
    localMin = null;
    localMax = null;
    Fx = 0.0; Fy = 0.0; Fz = 0.0;
    Lx = 0.0; Ly = 0.0; Lz = 0.0;
    Ux = 0.0; Uy = 0.0; Uz = 0.0;

    // Zero-size box (ambient_generic, game_text...): only a ray going exactly through the point could hit it
    isPoint = false;

    // Cached expensive C++ calls
    classname = null;
    modelname = null;
    entindex = null;
    
    // Result of shouldHitEntityCached, reused only by the trace with the id cachedTraceId.
    cachedShouldHit = null;
    cachedTraceId = null;
    // cachedSettingsId = null; // todo: maybe for future improvements

    constructor(entity) { 
        this.entity = entLib.FromEntity(entity)
        this.entindex = entity.entindex()  // Cache once!
        this.origin = entity.GetOrigin()
        this.classname = entity.GetClassname()  // Cache once!
        this.modelname = entity.GetModelName()  // Cache once!

        // round and CACHE!
        local angles = entity.GetAngles()
        this.roundedOriginX = floor(this.origin.x * 1000.0 + 0.5)
        this.roundedOriginY = floor(this.origin.y * 1000.0 + 0.5)
        this.roundedOriginZ = floor(this.origin.z * 1000.0 + 0.5)
        this.roundedAnglesX = floor(angles.x * 1000.0 + 0.5)
        this.roundedAnglesY = floor(angles.y * 1000.0 + 0.5)
        this.roundedAnglesZ = floor(angles.z * 1000.0 + 0.5)

        local mins = entity.GetBoundingMins()
        local maxs = entity.GetBoundingMaxs()
        this.isPoint = mins.x == maxs.x && mins.y == maxs.y && mins.z == maxs.z

        // Player bounds stay world-aligned whatever the angles, the engine never rotates them
        if((this.roundedAnglesX == 0 && this.roundedAnglesY == 0 && this.roundedAnglesZ == 0) || this.classname == "player") {
            this.bboxMin = mins + origin
            this.bboxMax = maxs + origin
            return
        }

        // evil math part. FOR PERFORMANCE!
        local F = entity.GetForwardVector()
        local U = entity.GetUpVector()
        local L = U.Cross(F) // GetLeftVector returns the RIGHT one xd
        this.rotated = true
        this.localMin = mins
        this.localMax = maxs
        this.Fx = F.x; this.Fy = F.y; this.Fz = F.z
        this.Lx = L.x; this.Ly = L.y; this.Lz = L.z
        this.Ux = U.x; this.Uy = U.y; this.Uz = U.z

        // The world AABB around the OBB
        local c = (mins + maxs) * 0.5
        local h = (maxs - mins) * 0.5
        local center = origin + F * c.x + L * c.y + U * c.z
        local half = Vector(
            fabs(F.x) * h.x + fabs(L.x) * h.y + fabs(U.x) * h.z,
            fabs(F.y) * h.x + fabs(L.y) * h.y + fabs(U.y) * h.z,
            fabs(F.z) * h.x + fabs(L.z) * h.y + fabs(U.z) * h.z
        )
        this.bboxMin = center - half
        this.bboxMax = center + half
    }

    // World point to entity space
    function ToLocal(point) {
        local x = point.x - origin.x
        local y = point.y - origin.y
        local z = point.z - origin.z
        return Vector(x * Fx + y * Fy + z * Fz, x * Lx + y * Ly + z * Lz, x * Ux + y * Uy + z * Uz)
    }

    function Contains(point) {
        // todo: inline this?
        if(rotated) return macros.PointInBBox(this.ToLocal(point), localMin, localMax)
        return macros.PointInBBox(point, bboxMin, bboxMax)
    }

    // FREE world normal of the box face
    function FaceNormal(axis, sign) {
        if(!rotated) {
            local n = Vector(0, 0, 0)
            if(axis == 0) n.x = sign
            else if(axis == 1) n.y = sign
            else n.z = sign
            return n
        }
        if(axis == 0) return Vector(Fx * sign, Fy * sign, Fz * sign)
        if(axis == 1) return Vector(Lx * sign, Ly * sign, Lz * sign)
        return Vector(Ux * sign, Uy * sign, Uz * sign)
    }

    function _tostring() return this.entity.tostring()
}

::EntBufferTable <- {} // To avoid repeated operations on objects that do not change their position.
::_traceIdCounter <- 0 

/*
 * A class for performing precise trace line analysis. 
 * 
 * This class provides methods for tracing lines with more precision and considering entity priorities and ignore settings. 
*/
::BboxTraceAnalyzer <- class {
    settings = null;
    hitpos = null;
    hitent = null;
    // Normal of the hit box face, null for world hits and for hits right at the segment start
    hitnormal = null;
    traceId = null;

    constructor(startpos, endpos, ignoreSet, settings) {
        if(typeof settings != "TraceSettings") throw("Invalid trace settings provided. Expected an instance of TracePlus.Settings")
        this.settings = settings
        this.traceId = _traceIdCounter++

        local result = this.Trace(startpos, endpos, ignoreSet)
        this.hitpos = result[0]
        this.hitent = result[1]
        this.hitnormal = result[2]
    }

    function Trace(startPos, endPos, ignoreSet) array(hitPos, hitEnt, hitNormal)
    function shouldHitEntityCached(BEnt, ignoreEntities) bool
}

/*
 * VScript TraceLine has its trace mask hardcoded to world geometry only.
 * This method adds entities on top of it by testing their bounding boxes along the ray: fast, and filterable through TraceSettings
*/
function BboxTraceAnalyzer::Trace(startPos, endPos, ignoreSet) {
    // Preventing VScript errors and ensuring correct results even with a broken TraceLine
    if(macros.PointInBounds(startPos) == false) return [startPos, null, null]

    // World hit from TraceLine; entities are only searched up to it.
    local hitPos = startPos + (endPos - startPos) * TraceLine(startPos, endPos, null)
    local dist = hitPos - startPos

    const JumpPercent = 0.25
    const HalfJump = 0.125
    local halfSegment = dist * HalfJump
    local searchRadius = halfSegment.Length()
    
    // Use array instead of List for better performance [// todo: maybe create with some capacity, or use global one with shadowing indecies? \\]
    local entBuffer = [] 
    // TODO shit: Entities the trace starts inside of. Per trace on purpose: EntBufferTable is global and outlives it
    local skipped = {}

    for(local segment = 0.0; segment < 1.0; segment += JumpPercent) {
        //* "DIRTY" Search - collect candidate entities near the current segment
        local segmentCenter = startPos + dist * (segment + HalfJump)
        local segmentStart = segmentCenter - halfSegment
        local segmentEnd = segmentCenter + halfSegment

        // exp: FindInSphere, not FindByClassnameWithin("*"): same set minus edict-less ents. A bit faster!
        for(local ent; ent = Entities.FindInSphere(ent, segmentCenter, searchRadius);) {
            local idx = ent.entindex()
            
            // == Avoid expensive shouldHitEntity ==
            // 1. Ignore entities set check
            if(idx in ignoreSet) continue
            // 2.Entity should 'Ignore Trace' check // todo change comment
            if((ent in TracePlusIgnoreEnts) && TracePlusIgnoreEnts[ent] == true) continue
            // 3. The trace started inside this entity (flagged at segment 0 below)
            if(idx in skipped) continue
            // 4. Ignored by class: skip before any cache work, a moving viewmodel would be rebuilt on every trace otherwise
            // Not with a collision filter, it may let an ignored class through
            if(!settings.shouldRayHitEntity && settings._isClassIgnored(ent.GetClassname())) continue

            local BEnt = null
            
            // Optimized cache check with inline Vector comparison :p
            if(idx in EntBufferTable) { 
                BEnt = EntBufferTable[idx]
                if(BEnt.entity.IsValid()) {
                    local currentOrigin = ent.GetOrigin()
                    local currentAngles = ent.GetAngles()

                    // Inline rounded comparison
                    if(BEnt.roundedOriginX == floor(currentOrigin.x * 1000.0 + 0.5) &&
                        BEnt.roundedOriginY == floor(currentOrigin.y * 1000.0 + 0.5) &&
                        BEnt.roundedOriginZ == floor(currentOrigin.z * 1000.0 + 0.5) &&
                        BEnt.roundedAnglesX == floor(currentAngles.x * 1000.0 + 0.5) &&
                        BEnt.roundedAnglesY == floor(currentAngles.y * 1000.0 + 0.5) &&
                        BEnt.roundedAnglesZ == floor(currentAngles.z * 1000.0 + 0.5)) {
                        // Cache hit - entity hasn't moved or turned
                    } else {
                        // Moved or turned - rebuild cache
                        BEnt = BufferedEntity(ent)
                        EntBufferTable[idx] <- BEnt
                    }
                } else {
                    // Dissolve() makes the wrapper invalid right away, but the engine keeps the entity for a second or two
                    // It's on its way out: skip it, no need to rebuild it on every trace either
                    if(BEnt.entity.CBaseEntity == ent && BEnt.entity.GetUserData("Dissolved")) continue
                    // Weird... Invalid/outdated entity with same id - let's rebuild
                    BEnt = BufferedEntity(ent)
                    // BEnt.cachedSettingsId = this.settings.id
                    EntBufferTable[idx] <- BEnt
                }
            } else {
                // Not in cache - create new
                BEnt = BufferedEntity(ent)
                EntBufferTable[idx] <- BEnt
                // Dissolved before it ever got into the cache
                if(BEnt.entity.GetUserData("Dissolved")) continue
            }

            if(BEnt.isPoint) continue

            // Check shouldHitEntity, now with caching :}
            if(!this.shouldHitEntityCached(BEnt)) continue
            

            // This handles the specific case where the trace starts *inside* an entity's bounding box
            if(segment == 0.0 && BEnt.Contains(startPos)) {
                if( !settings._isHitInside(BEnt.classname) ) {
                    skipped[idx] <- true
                    continue
                }
            }

            // Quick broad-phase check
            if(RayAabbIntersectFast(segmentStart, segmentEnd, BEnt.bboxMin, BEnt.bboxMax))
                entBuffer.append(BEnt)
        }

        if(entBuffer.len() == 0) continue

        //* Analytic narrow-phase: compute exact hit using 'slab method'
        local bestT = 999999999.9
        local bestEnt = null
        local bestAxis = -1
        local bestSign = 0.0

        foreach(BEnt in entBuffer) {
            // Get precise intersection data using optimized slab method [i actually unrolled loop, lol]
            // Rotated ones go through entity space: a linear map, so t is the same t on the world segment
            local res = BEnt.rotated
                ? RayAabbHitOptimized(BEnt.ToLocal(segmentStart), BEnt.ToLocal(segmentEnd), BEnt.localMin, BEnt.localMax)
                : RayAabbHitOptimized(segmentStart, segmentEnd, BEnt.bboxMin, BEnt.bboxMax)
            if(!res) continue

            local tEnter = res[1]
            if(tEnter < 0.0) tEnter = 0.0
            else if(tEnter > 1.0) tEnter = 1.0

            if(tEnter < bestT) {
                bestT = tEnter
                bestEnt = BEnt
                bestAxis = res[3]
                bestSign = res[4]
            }
        }

        // If we found a hit in this segment, return immediately
        if(bestEnt != null) {
            local hitPoint = segmentStart + (segmentEnd - segmentStart) * bestT
            local normal = bestAxis >= 0 ? bestEnt.FaceNormal(bestAxis, bestSign) : null
            return [hitPoint, bestEnt.entity, normal]
        }
        
        entBuffer.clear()
    }

    // No entity hit: return the TraceLine hit position.
    return [hitPos, null, null]
}

/*
 * Narrow phase: where the segment enters the box and through which face, for the hit point and its normal.
 * Returns null on a miss, or [true, tEnter, tExit, axis, sign]. Axis is -1 if start is already inside
*/
function RayAabbHitOptimized(start, end, bmin, bmax) {
    // Pre-compute direction once
    local dx = end.x - start.x
    local dy = end.y - start.y  
    local dz = end.z - start.z
    const EPS = 0.000001

    local tEnter = 0.0
    local tExit = 1.0
    local nAxis = -1
    local nSign = 0.0

    // Unrolled X axis
    local adx = fabs(dx)
    if(adx < EPS) {
        if(start.x < bmin.x || start.x > bmax.x) return null
    } else {
        local invDx = 1.0 / dx
        local t1 = (bmin.x - start.x) * invDx
        local t2 = (bmax.x - start.x) * invDx
        
        if(t1 > t2) {
            if(t2 > tEnter) { tEnter = t2; nAxis = 0; nSign = 1.0 }
            if(t1 < tExit) tExit = t1
        } else {
            if(t1 > tEnter) { tEnter = t1; nAxis = 0; nSign = -1.0 }
            if(t2 < tExit) tExit = t2
        }
        if(tEnter > tExit) return null
    }

    // Unrolled Y axis
    local ady = fabs(dy)
    if(ady < EPS) {
        if(start.y < bmin.y || start.y > bmax.y) return null
    } else {
        local invDy = 1.0 / dy
        local t1 = (bmin.y - start.y) * invDy
        local t2 = (bmax.y - start.y) * invDy
        
        if(t1 > t2) {
            if(t2 > tEnter) { tEnter = t2; nAxis = 1; nSign = 1.0 }
            if(t1 < tExit) tExit = t1
        } else {
            if(t1 > tEnter) { tEnter = t1; nAxis = 1; nSign = -1.0 }
            if(t2 < tExit) tExit = t2
        }
        if(tEnter > tExit) return null
    }

    // Unrolled Z axis
    local adz = fabs(dz)
    if(adz < EPS) {
        if(start.z < bmin.z || start.z > bmax.z) return null
    } else {
        local invDz = 1.0 / dz
        local t1 = (bmin.z - start.z) * invDz
        local t2 = (bmax.z - start.z) * invDz
        
        if(t1 > t2) {
            if(t2 > tEnter) { tEnter = t2; nAxis = 2; nSign = 1.0 }
            if(t1 < tExit) tExit = t1
        } else {
            if(t1 > tEnter) { tEnter = t1; nAxis = 2; nSign = -1.0 }
            if(t2 < tExit) tExit = t2
        }
        if(tEnter > tExit) return null
    }

    // Final range check
    if(tExit < 0.0 || tEnter > 1.0) return null

    return [true, tEnter, tExit, nAxis, nSign]
}

/*
 * Broad phase: just yes or no, no hit data and no allocation.
 * Most candidates from the sphere miss the segment, and this throws them out cheaper than RayAabbHitOptimized
*/
function RayAabbIntersectFast(start, end, bmin, bmax) {
    // TODO: can be improved, because now kinda copy-paste with narrow-phase!!
    local dx = end.x - start.x
    local dy = end.y - start.y
    local dz = end.z - start.z
    
    local tmin = 0.0
    local tmax = 1.0
    
    // X axis - optimized with early exit
    if(dx != 0.0) {
        local invDx = 1.0 / dx
        local t1 = (bmin.x - start.x) * invDx
        local t2 = (bmax.x - start.x) * invDx
        if(t1 > t2) { local tmp = t1; t1 = t2; t2 = tmp }
        if(t1 > tmin) tmin = t1
        if(t2 < tmax) tmax = t2
        if(tmin > tmax) return false
    } else if(start.x < bmin.x || start.x > bmax.x) return false
    
    // Y axis
    if(dy != 0.0) {
        local invDy = 1.0 / dy
        local t1 = (bmin.y - start.y) * invDy
        local t2 = (bmax.y - start.y) * invDy
        if(t1 > t2) { local tmp = t1; t1 = t2; t2 = tmp }
        if(t1 > tmin) tmin = t1
        if(t2 < tmax) tmax = t2
        if(tmin > tmax) return false
    } else if(start.y < bmin.y || start.y > bmax.y) return false
    
    // Z axis
    if(dz != 0.0) {
        local invDz = 1.0 / dz
        local t1 = (bmin.z - start.z) * invDz
        local t2 = (bmax.z - start.z) * invDz
        if(t1 > t2) { local tmp = t1; t1 = t2; t2 = tmp }
        if(t1 > tmin) tmin = t1
        if(t2 < tmax) tmax = t2
        if(tmin > tmax) return false
    } else if(start.z < bmin.z || start.z > bmax.z) return false
    
    return true
}

/*
 * TraceSettings verdict for an entity, kept in BEnt for the rest of the trace.
 * Checks the ignore filter, the collision filter, then the ignored classes and models.
 * Neighbor segments' spheres overlap, so the same entity comes up again, and the filters are user callbacks
*/
function BboxTraceAnalyzer::shouldHitEntityCached(BEnt) {
    // Result cached earlier in this trace
    if(BEnt.cachedTraceId == this.traceId) {
        return BEnt.cachedShouldHit
    }
    
    local ent = BEnt.entity.CBaseEntity
    BEnt.cachedTraceId = this.traceId
    
    // Settings filters
    // inlined 'ApplyIgnoreFilter'
    if(settings.shouldIgnoreEntity && settings.shouldIgnoreEntity(ent)) {
        BEnt.cachedShouldHit = false
        return false
    }
    
    // inlined 'ApplyCollisionFilter'
    if(settings.shouldRayHitEntity && settings.shouldRayHitEntity(ent)) { 
        BEnt.cachedShouldHit = true
        return true
    }

    // Use cached classname and modelname, the settings cache the verdicts per name
    if(settings._isClassIgnored(BEnt.classname) || settings._isModelIgnored(BEnt.modelname)) {
        BEnt.cachedShouldHit = false
        return false
    }

    BEnt.cachedShouldHit = true
    return true
}