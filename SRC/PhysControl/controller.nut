/*
 * A controller that moves a VPhysics prop with real forces.
 *
 * While a controller exists, it pushes the prop every tick. Combine any of:
 *   - a target point the prop's hold point is pulled to (spring-damper),
 *   - a target velocity the prop is driven towards,
 *   - a constant extra acceleration.
 * By default gravity is cancelled out, so the prop is weightless while controlled.
 * `Release()` lets the prop go with whatever velocity it has.
*/
PhysControl["Controller"] <- class {
    // The controlled prop (CBaseEntity).
    entity = null;
    // The point_push entities pushing the prop, or null once released.
    pushers = null;
    // The ActionScheduler event that runs the per-tick update.
    eventName = null;

    // Settings
    stiffness = 14.0;
    damping = 1.0;
    maxAcceleration = 9000.0;
    maxSpeed = 2500.0;
    gravity = 600.0;
    compensateGravity = true;

    // Goals
    acceleration = null;
    target = null;
    holdOffset = null;
    targetVelocity = null;

    // Tracking (GetVelocity() is always zero on VPhysics objects)
    velocity = null;
    lastPos = null;
    lastTime = 0.0;
    lastTarget = null;
    targetMotion = null;
    nextWake = 0.0;

    /*
     * Constructor for a Controller object.
     *
     * @param {CBaseEntity|pcapEntity} entity - The VPhysics prop to control (it must not be motion-disabled).
    */
    constructor(entity) {
        local ent = entLib.FromEntity(entity)
        if (ent == null || !ent.IsValid())
            throw("PhysControl.Controller: 'entity' must be a valid entity")

        this.entity = ent.CBaseEntity
        this.acceleration = Vector()
        this.holdOffset = Vector()
        this.velocity = Vector()
        this.targetMotion = Vector()
        this.lastPos = this.entity.GetOrigin()
        this.lastTime = Time()
        this.eventName = UniqueString("PhysControl")

        // One pusher per tick of the push interval, enabled one tick apart so they take turns.
        local tick = FrameTime()
        local count = ceil(PhysControl.PUSH_INTERVAL / tick - 0.001).tointeger()
        if (count < 1) count = 1
        this.pushers = []
        for(local i = 0; i < count; i++) {
            local pusher = Entities.CreateByClassname("point_push")
            pusher.__KeyValueFromInt("spawnflags", 2 + 4 + 16) // use angles, no falloff, physics only
            pusher.__KeyValueFromFloat("magnitude", 0)
            pusher.__KeyValueFromFloat("radius", 2)            // only touches the prop it sits in
            pusher.SetOrigin(this.entity.GetCenter())
            EntFireByHandle(pusher, "Disable")
            EntFireByHandle(pusher, "Enable", "", i == 0 ? 0 : (i - 0.4) * tick)
            this.pushers.append(pusher)
        }
        EntFireByHandle(this.entity, "Wake")

        ScheduleEvent.AddInterval(this.eventName, this._Update, 0.01, 0, null, this)
    }

    // Pulls the hold point towards a world position.
    function SetTarget(point) null
    // Stops pulling towards a position.
    function ClearTarget() null
    // Sets the hold point in the prop's local space (default: its origin).
    function SetHoldOffset(localOffset) null
    // Sets the hold point from a world position on/near the prop.
    function SetHoldPoint(worldPoint) null
    // Gets the hold point in world space.
    function GetHoldPoint() null
    // Drives the prop towards a velocity.
    function SetTargetVelocity(velocity) null
    // Stops driving towards a velocity.
    function ClearTargetVelocity() null
    // Sets a constant extra acceleration.
    function SetAcceleration(acceleration) null

    // Spring frequency in rad/s.
    function SetStiffness(value) null
    // Damping ratio (1 = critically damped).
    function SetDamping(value) null
    // Caps the acceleration the controller applies.
    function SetMaxAcceleration(value) null
    // Caps the prop's speed while controlled.
    function SetMaxSpeed(value) null
    // Cancels out gravity while controlled (default: true).
    function SetGravityCompensation(enabled) null
    // Sets the gravity to cancel out (default: 600, the default sv_gravity).
    function SetGravity(value) null

    // Gets the prop's tracked velocity.
    function GetVelocity() null
    // Gets the controlled prop.
    function GetEntity() null
    // Checks whether the controller still controls a valid prop.
    function IsValid() null
    // Lets the prop go and removes the pushers.
    function Release() null

    function _typeof() return "PhysController"
    function _tostring() return "PhysController: " + this.entity
}


/*
 * Pulls the controller's hold point towards a world position, like a spring with a damper.
 * Call it every tick with a moving point to drag the prop around; the controller also
 * follows the point's own motion, so it doesn't lag behind.
 *
 * @param {Vector} point - The world position to pull the hold point to.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetTarget(point) {
    if (typeof point != "Vector") throw("PhysControl.Controller.SetTarget: 'point' must be a Vector, but got " + typeof point)
    this.target = point * 1.0
    return this
}

/*
 * Stops pulling the prop towards a position.
 *
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::ClearTarget() {
    this.target = null
    this.lastTarget = null
    this.targetMotion = Vector()
    return this
}

/*
 * Sets the hold point in the prop's local space. The target pulls this point.
 *
 * @param {Vector} localOffset - The offset from the prop's origin, in its local axes.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetHoldOffset(localOffset) {
    if (typeof localOffset != "Vector") throw("PhysControl.Controller.SetHoldOffset: 'localOffset' must be a Vector, but got " + typeof localOffset)
    this.holdOffset = localOffset * 1.0
    return this
}

/*
 * Sets the hold point from a world position, e.g. where a trace hit the prop.
 *
 * @param {Vector} worldPoint - A world position on or near the prop.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetHoldPoint(worldPoint) {
    if (typeof worldPoint != "Vector") throw("PhysControl.Controller.SetHoldPoint: 'worldPoint' must be a Vector, but got " + typeof worldPoint)
    local rel = worldPoint - this.entity.GetOrigin()
    this.holdOffset = Vector(rel.Dot(this.entity.GetForwardVector()), rel.Dot(this.entity.GetLeftVector()), rel.Dot(this.entity.GetUpVector()))
    return this
}

/*
 * Gets the hold point in world space.
 *
 * @returns {Vector} - The hold point.
*/
function PhysControl::Controller::GetHoldPoint() {
    local o = this.holdOffset
    return this.entity.GetOrigin() + this.entity.GetForwardVector() * o.x + this.entity.GetLeftVector() * o.y + this.entity.GetUpVector() * o.z
}

/*
 * Drives the prop towards a velocity. Works together with a target and an acceleration.
 *
 * @param {Vector} velocity - The desired velocity in units/s.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetTargetVelocity(velocity) {
    if (typeof velocity != "Vector") throw("PhysControl.Controller.SetTargetVelocity: 'velocity' must be a Vector, but got " + typeof velocity)
    this.targetVelocity = velocity * 1.0
    return this
}

/*
 * Stops driving the prop towards a velocity.
 *
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::ClearTargetVelocity() {
    this.targetVelocity = null
    return this
}

/*
 * Sets a constant extra acceleration, applied on top of everything else.
 *
 * @param {Vector} acceleration - The acceleration in units/s^2.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetAcceleration(acceleration) {
    if (typeof acceleration != "Vector") throw("PhysControl.Controller.SetAcceleration: 'acceleration' must be a Vector, but got " + typeof acceleration)
    this.acceleration = acceleration * 1.0
    return this
}

/*
 * Sets how snappily the prop follows the target (spring frequency in rad/s).
 * Higher is snappier; too high makes the prop jitter. Default: 14.
 *
 * @param {number} value - The stiffness.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetStiffness(value) {
    if (typeof value != "integer" && typeof value != "float") throw("PhysControl.Controller.SetStiffness: 'value' must be a number, but got " + typeof value)
    this.stiffness = value.tofloat()
    return this
}

/*
 * Sets the damping ratio: 1 is critically damped, below 1 wobbles, above 1 is sluggish. Default: 1.
 *
 * @param {number} value - The damping ratio.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetDamping(value) {
    if (typeof value != "integer" && typeof value != "float") throw("PhysControl.Controller.SetDamping: 'value' must be a number, but got " + typeof value)
    this.damping = value.tofloat()
    return this
}

/*
 * Caps the acceleration the controller applies (not counting gravity compensation).
 * This is how hard the prop can push other props. Default: 9000.
 *
 * @param {number} value - The maximum acceleration in units/s^2.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetMaxAcceleration(value) {
    if (typeof value != "integer" && typeof value != "float") throw("PhysControl.Controller.SetMaxAcceleration: 'value' must be a number, but got " + typeof value)
    this.maxAcceleration = value.tofloat()
    return this
}

/*
 * Caps the prop's speed while it is controlled: anything above it is braked away. Default: 2500.
 *
 * @param {number} value - The maximum speed in units/s.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetMaxSpeed(value) {
    if (typeof value != "integer" && typeof value != "float") throw("PhysControl.Controller.SetMaxSpeed: 'value' must be a number, but got " + typeof value)
    this.maxSpeed = value.tofloat()
    return this
}

/*
 * Enables or disables gravity compensation. With it the prop is weightless while
 * controlled; without it gravity pulls on it as usual. Default: true.
 *
 * @param {bool} enabled - Whether to cancel out gravity.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetGravityCompensation(enabled) {
    this.compensateGravity = enabled
    return this
}

/*
 * Sets the gravity the controller cancels out. VScript can't read sv_gravity,
 * so set this if the map changes it. Default: 600.
 *
 * @param {number} value - The gravity in units/s^2.
 * @returns {PhysController} - The controller (for chaining).
*/
function PhysControl::Controller::SetGravity(value) {
    if (typeof value != "integer" && typeof value != "float") throw("PhysControl.Controller.SetGravity: 'value' must be a number, but got " + typeof value)
    this.gravity = value.tofloat()
    return this
}

/*
 * Gets the prop's velocity, tracked from its position every tick
 * (the built-in GetVelocity() always returns zero for VPhysics objects).
 *
 * @returns {Vector} - The velocity in units/s.
*/
function PhysControl::Controller::GetVelocity() {
    return this.velocity * 1.0
}

/*
 * Gets the controlled prop.
 *
 * @returns {pcapEntity} - The prop.
*/
function PhysControl::Controller::GetEntity() {
    return entLib.FromEntity(this.entity)
}

/*
 * Checks whether the controller still controls a valid prop.
 *
 * @returns {bool} - False once released or if the prop was removed.
*/
function PhysControl::Controller::IsValid() {
    return this.pushers != null && this.entity != null && this.entity.IsValid()
}

/*
 * Lets the prop go and removes the pushers.
 * The prop keeps whatever velocity it has, so releasing a moving prop throws it.
*/
function PhysControl::Controller::Release() {
    if (this.pushers == null)
        return
    // Removal only happens at the end of the frame, so make sure they can't push once more.
    foreach(pusher in this.pushers) {
        if (!pusher.IsValid())
            continue
        pusher.__KeyValueFromFloat("magnitude", 0)
        EntFireByHandle(pusher, "Disable")
        pusher.Destroy()
    }
    this.pushers = null
    // cancelled from the scheduler loop itself, so let the current pass finish first
    ScheduleEvent.TryCancel(this.eventName, 0.01)
}


/*
 * Per-tick update: tracks the prop and re-aims the pushers.
 * This function is not part of the public API.
*/
function PhysControl::Controller::_Update() {
    if (this.pushers == null)
        return
    if (!this.entity.IsValid()) {
        this.Release()
        return
    }

    local now = Time()
    local dt = now - this.lastTime
    if (dt < 0.001)
        return

    // Velocity from the position change. A jump far beyond the speed limit is a
    // teleport (e.g. a portal), which says nothing about the speed.
    local origin = this.entity.GetOrigin()
    local moved = origin - this.lastPos
    if (moved.Length() < this.maxSpeed * dt * 2 + 64)
        this.velocity = this.velocity * 0.3 + moved * (0.7 / dt)
    this.lastPos = origin
    this.lastTime = now

    local kd = 2.0 * this.damping * this.stiffness
    local accel = this.acceleration * 1.0

    if (this.target != null) {
        if (this.lastTarget != null)
            this.targetMotion = this.targetMotion * 0.5 + (this.target - this.lastTarget) * (0.5 / dt)
        this.lastTarget = this.target
        accel = accel + (this.target - this.GetHoldPoint()) * (this.stiffness * this.stiffness) + (this.targetMotion - this.velocity) * kd
    }
    if (this.targetVelocity != null)
        accel = accel + (this.targetVelocity - this.velocity) * kd

    // brake anything above the speed limit over a couple of ticks
    local speed = this.velocity.Length()
    if (speed > this.maxSpeed)
        accel = accel - this.velocity * ((speed - this.maxSpeed) / speed * 0.5 / dt)

    local magnitude = accel.Length()
    if (magnitude > this.maxAcceleration)
        accel = accel * (this.maxAcceleration / magnitude)
    if (this.compensateGravity)
        accel = accel + Vector(0, 0, this.gravity)

    this._Push(accel)

    // A resting prop falls asleep and stops simulating.
    if (now >= this.nextWake) {
        EntFireByHandle(this.entity, "Wake")
        this.nextWake = now + 0.25
    }
}

/*
 * Aims the pushers so the prop gets `accel` (units/s^2) until the next update.
 * One of them pushes every tick, changing the velocity by magnitude * 100 * FrameTime(),
 * so magnitude = |accel| / 100. They're placed where the prop will be next tick.
 * This function is not part of the public API.
*/
function PhysControl::Controller::_Push(accel) {
    local strength = accel.Length()
    local pitch = 0.0
    local yaw = 0.0
    if (strength > 0.001) {
        pitch = -atan2(accel.z, accel.Length2D()) * 180.0 / PI
        yaw = atan2(accel.y, accel.x) * 180.0 / PI
    }
    local pos = this.entity.GetCenter() + this.velocity * FrameTime()
    foreach(pusher in this.pushers) {
        pusher.SetAngles(pitch, yaw, 0)
        pusher.__KeyValueFromFloat("magnitude", strength / 100.0)
        pusher.SetOrigin(pos)
    }
}
