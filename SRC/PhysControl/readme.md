# PhysControl Module

The `PhysControl` module moves VPhysics props (cubes, `prop_physics`, turrets...) with real forces. VScript can't do this on its own: `SetVelocity` only affects QPhysics entities, and teleporting a prop every tick with `SetOrigin` makes it jitter, pass through other props and lose its momentum.

A prop driven by `PhysControl` stays fully simulated: it collides with walls, pushes other props, is interpolated smoothly on the client and keeps its velocity when released. This is enough to build things like a Garry's Mod style physgun, tractor beams, hover platforms or "magnets". Nothing has to be placed in the map.

## Table of Contents

1. [How it works](#how-it-works)
2. [PhysControl/init.nut](#physcontrolinitnut)
3. [PhysControl/controller.nut](#physcontrolcontrollernut)
    * [`PhysControl.Controller(entity)`](#physcontrolcontrollerentity)
        * [`SetTarget(point)`](#settargetpoint)
        * [`ClearTarget()`](#cleartarget)
        * [`SetHoldOffset(localOffset)`](#setholdoffsetlocaloffset)
        * [`SetHoldPoint(worldPoint)`](#setholdpointworldpoint)
        * [`GetHoldPoint()`](#getholdpoint)
        * [`SetTargetVelocity(velocity)`](#settargetvelocityvelocity)
        * [`ClearTargetVelocity()`](#cleartargetvelocity)
        * [`SetAcceleration(acceleration)`](#setaccelerationacceleration)
        * [`SetStiffness(value)`](#setstiffnessvalue)
        * [`SetDamping(value)`](#setdampingvalue)
        * [`SetMaxAcceleration(value)`](#setmaxaccelerationvalue)
        * [`SetMaxSpeed(value)`](#setmaxspeedvalue)
        * [`SetGravityCompensation(enabled)`](#setgravitycompensationenabled)
        * [`SetGravity(value)`](#setgravityvalue)
        * [`GetVelocity()`](#getvelocity)
        * [`GetEntity()`](#getentity)
        * [`IsValid()`](#isvalid)
        * [`Release()`](#release)
4. [Example](#example)
5. [Limitations](#limitations)

## How it works

Each controller creates its own `point_push` entities. With the "use angles" and "no falloff" flags, a `point_push` pushes physics props along its forward vector. These are its properties, as measured in-game:

* Each push changes the prop's velocity by `magnitude * 100 * FrameTime()`, **whatever the prop's mass**. A cube with 4x the mass reacts exactly the same.
* It pushes on its own think, every 0.05s (every 2nd tick at 30 ticks/s). The controller creates one pusher per tick of that interval and enables them one tick apart, so they take turns and the prop gets a push every tick.
* It affects props whose bounds touch its radius. The pushers use a radius of 2 units and sit at the prop's centre, so they only ever push that prop, even when other props touch it.

Every tick the controller:

1. tracks the prop's velocity from its position (the built-in `GetVelocity()` returns zero for VPhysics objects),
2. computes the acceleration it wants (spring-damper towards a target, velocity tracking, constant acceleration, speed limit, gravity compensation),
3. aims the pushers along it, sets `magnitude = acceleration / 100`, and moves them to where the prop will be next tick.

In-game, a cube held with the default settings stays within 0.05 units of its target.

> Why not `trigger_vphysics_motion`? It works, but only as a brush entity placed in the map: one created from script never attaches to props, even with `SetSize` or a brush model (`*N`) set after spawn, because its VPhysics trigger is only built when it spawns.

## [PhysControl/init.nut](init.nut)

Declares the global `::PhysControl` table (with `PhysControl.PUSH_INTERVAL`, the `point_push` think interval) and includes the module's files.

## [PhysControl/controller.nut](controller.nut)

### `PhysControl.Controller(entity)`

**Constructor**

Takes control of a VPhysics prop. The prop is woken up; by default gravity is cancelled out, so the prop floats until you give it a goal. Any number of props can be controlled at the same time.

**Parameters:**

* `entity` (CBaseEntity or pcapEntity): The prop to control. It must not be motion-disabled (`EnableMotion` it first if needed).

**Throws:** if the entity is invalid.

**Example:**

```js
local cube = entLib.FindByClassname("prop_weighted_cube")
local ctrl = PhysControl.Controller(cube)
```

### `SetTarget(point)`

Pulls the controller's hold point towards a world position, like a spring with a damper. Call it every tick with a moving point to drag the prop around: the controller also follows the point's own motion, so the prop doesn't lag behind.

**Parameters:**

* `point` (Vector): The world position.

**Returns:** the controller (for chaining).

```js
ctrl.SetTarget(player.EyePosition() + player.EyeForwardVector() * 128)
```

### `ClearTarget()`

Stops pulling the prop towards a position.

### `SetHoldOffset(localOffset)`

Sets the hold point in the prop's local space (forward, left, up). The target pulls this point. Default: the prop's origin.

### `SetHoldPoint(worldPoint)`

Sets the hold point from a world position on or near the prop, e.g. where a trace hit it. Holding a prop by the point that was grabbed keeps that point under the crosshair.

```js
local trace = TracePlus.FromEyes.Bbox(2048, player)
ctrl.SetHoldPoint(trace.GetHitPos())
```

### `GetHoldPoint()`

Returns the hold point in world space.

### `SetTargetVelocity(velocity)`

Drives the prop towards a velocity. Can be combined with a target and an acceleration.

**Parameters:**

* `velocity` (Vector): The desired velocity in units/s.

```js
ctrl.SetTargetVelocity(Vector(0, 0, 100)) // slowly rises
```

### `ClearTargetVelocity()`

Stops driving the prop towards a velocity.

### `SetAcceleration(acceleration)`

Sets a constant extra acceleration, applied on top of everything else.

**Parameters:**

* `acceleration` (Vector): The acceleration in units/s^2.

### `SetStiffness(value)`

How snappily the prop follows the target: the spring frequency in rad/s. Higher is snappier, too high makes the prop jitter. Default: `14`.

### `SetDamping(value)`

The damping ratio: `1` is critically damped (no overshoot), below `1` wobbles, above `1` is sluggish. Default: `1`.

### `SetMaxAcceleration(value)`

Caps the acceleration the controller applies (not counting gravity compensation) - this is how hard the prop can push other props. Default: `9000`.

### `SetMaxSpeed(value)`

Caps the prop's speed while it is controlled: anything above it is braked away. Default: `2500`.

### `SetGravityCompensation(enabled)`

With gravity compensation the prop is weightless while controlled; without it gravity pulls on it as usual. Default: `true`.

### `SetGravity(value)`

The gravity that gets cancelled out. VScript can't read `sv_gravity`, so set this if the map changes it. Default: `600`.

### `GetVelocity()`

Returns the prop's velocity (Vector, units/s), tracked from its position every tick.

### `GetEntity()`

Returns the controlled prop as a `pcapEntity`.

### `IsValid()`

Returns `false` once the controller is released or the prop is gone (a fizzled prop releases its controller automatically).

### `Release()`

Lets the prop go and removes the pushers (at the end of the frame, like any removed entity). The prop keeps whatever velocity it has, so releasing a moving prop throws it.

## Example

Hold the cube in front of the player (see also [`Examples/PhysHold.nut`](../../Examples/PhysHold.nut), a small physgun):

```js
local player = entLib.FromEntity(GetPlayer())
local cube = entLib.FindByClassname("prop_weighted_cube")
local ctrl = PhysControl.Controller(cube)

ScheduleEvent.AddInterval("hold_cube", function() : (ctrl, player) {
    ctrl.SetTarget(player.EyePosition() + player.EyeForwardVector() * 128)
}, 0.01)

// later: throw it
ScheduleEvent.Cancel("hold_cube")
ctrl.Release()
```

## Limitations

* Motion-disabled props are not moved.
* Only the prop's position is controlled; its rotation is left to physics.
* `PUSH_INTERVAL` assumes `point_push` thinks every 0.05s; at other tick rates the number of pushers adapts automatically.
