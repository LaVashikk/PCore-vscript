/*+--------------------------------------------------------------------------------+
|                           PCapture Vscripts Library                              |
+----------------------------------------------------------------------------------+
| Author:                                                                          |
|     Force Wrangler - Laefye                                                      |
+----------------------------------------------------------------------------------+
|    The PhysControl module, moving VPhysics props with real forces: controlled    |
|    props keep colliding, pushing other props and keep their momentum.           |
+----------------------------------------------------------------------------------+ */

/*
 * VScript can't set the velocity of VPhysics objects (`SetVelocity` only affects
 * QPhysics entities) and teleporting them every tick turns off client interpolation and
 * collisions. This module pushes props with script-created `point_push` entities instead,
 * so nothing has to be placed in the map.
 *
 * What a `point_push` does (measured in-game):
 *   - with "use angles" and "no falloff" it pushes along its forward vector;
 *   - each push changes the prop's velocity by `magnitude * 100 * FrameTime()`, whatever
 *     the prop's mass;
 *   - it pushes on its own think, every 0.05s - every 2nd tick at 30 ticks/s. Several
 *     pushers enabled one tick apart take turns, so the prop gets a push every tick;
 *   - it picks props whose bounds touch its radius, so a tiny radius at the prop's centre
 *     only ever affects that prop.
*/
::PhysControl <- {
    // How often a point_push pushes (its think interval).
    PUSH_INTERVAL = 0.05,
}

IncludeScript("PCapture-LIB/SRC/PhysControl/controller")
