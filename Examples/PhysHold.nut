// Initialize the PCapture-Lib library. This must be done before any library functions are used.
DoIncludeScript("PCapture-Lib/SRC/PCapture-Lib", getroottable())

/*
 * A tiny physgun built on the PhysControl module: hold the attack button to grab the
 * physics prop under the crosshair, let go to drop it - or throw it by swinging the view.
 *
 * The held prop is moved with real forces, so it still collides with walls and pushes
 * other props around. Nothing has to be placed in the map.
 */

class PhysHold {
    // Props that can be grabbed.
    static PHYS_CLASSES = {
        prop_weighted_cube = true,
        prop_monster_box = true,
        prop_physics = true,
        prop_physics_override = true,
        prop_physics_paintable = true,
    }
    // The player using the "gun".
    player = null;
    // The PhysControl.Controller of the held prop, or null.
    controller = null;
    // How far in front of the eyes the prop is held.
    distance = 0;

    constructor(owner) {
        this.player = entLib.FromEntity(owner)

        // Capture the mouse buttons with a game_ui, like in Gun.nut.
        local holder = this
        local gameui = entLib.CreateByClassname("game_ui", {FieldOfView = -1})
        gameui.ConnectOutputEx("PressedAttack", function() : (holder) {
            holder.TryGrab()
        })
        gameui.ConnectOutputEx("UnpressedAttack", function() : (holder) {
            holder.Release()
        })
        EntFireByHandle(gameui, "Activate", "", 0, this.player)

        // Move the target point with the view every tick.
        ScheduleEvent.AddInterval("global", this.Think, FrameTime(), 0, null, this)
    }

    // Grabs the physics prop under the crosshair, if there is one.
    function TryGrab() {
        if (this.controller) return
        local trace = TracePlus.FromEyes.Bbox(2048, this.player)
        local ent = trace.GetEntity()
        if (!ent || !(ent.GetClassname() in this.PHYS_CLASSES)) return
        this.Grab(ent, trace.GetHitPos())
    }

    // Takes control of the prop, holding it by the point that was hit.
    function Grab(ent, hitPos) {
        this.controller = PhysControl.Controller(ent)
            .SetHoldPoint(hitPos)       // keep the grabbed point under the crosshair
        this.distance = (hitPos - this.player.EyePosition()).Length()
    }

    function Think() {
        if (!this.controller) return
        // A fizzled prop releases its controller automatically.
        if (!this.controller.IsValid()) {
            this.controller = null
            return
        }
        this.controller.SetTarget(this.player.EyePosition() + this.player.EyeForwardVector() * this.distance)
    }

    // Lets go: the prop keeps its velocity, so a swing throws it.
    function Release() {
        if (!this.controller) return
        this.controller.Release()
        this.controller = null
    }
}

::physHold <- PhysHold(GetPlayer())
