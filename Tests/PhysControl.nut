// PhysControl Module Unit Tests
if(!("RunTests" in getroottable())) IncludeScript("PCapture-LIB/Tests/test_exec")

// These tests need a prop_weighted_cube in the map; without one they only check argument validation.
::_physTestCube <- entLib.FindByClassname("prop_weighted_cube")

::_physThrows <- function(func) {
    try { func() } catch(exception) { return exception }
    return null
}

::_physCountPushers <- function() {
    local count = 0
    for(local ent; ent = Entities.FindByClassname(ent, "point_push");) count++
    return count
}

physcontrol_tests <- {
    function invalid_entity_throws() {
        return assert(_physThrows(function() { PhysControl.Controller(null) }) != null)
    },

    // (the pushers are removed at the end of the frame, so their count can't be checked here)
    function controller_creates_pushers_and_releases() {
        if (!_physTestCube) return
        local before = _physCountPushers()
        local ctrl = PhysControl.Controller(_physTestCube)
        assert(ctrl.IsValid())
        assert(_physCountPushers() > before)
        ctrl.Release()
        return assert(!ctrl.IsValid())
    },

    function several_controllers_at_once() {
        if (!_physTestCube) return
        local ctrls = [PhysControl.Controller(_physTestCube), PhysControl.Controller(_physTestCube), PhysControl.Controller(_physTestCube)]
        local valid = true
        foreach(ctrl in ctrls) {
            valid = valid && ctrl.IsValid()
            ctrl.Release()
        }
        return assert(valid)
    },

    function setters_chain() {
        if (!_physTestCube) return
        local ctrl = PhysControl.Controller(_physTestCube)
        local same = ctrl.SetTarget(Vector(0, 0, 0)).SetTargetVelocity(Vector(0, 0, 0)).SetAcceleration(Vector(0, 0, 0))
            .SetStiffness(10).SetDamping(1).SetMaxAcceleration(5000).SetMaxSpeed(1000)
            .SetGravityCompensation(false).SetGravity(600).ClearTarget().ClearTargetVelocity()
        ctrl.Release()
        return assert(same == ctrl)
    },

    function setters_check_types() {
        if (!_physTestCube) return
        local ctrl = PhysControl.Controller(_physTestCube)
        local errors = [
            _physThrows(function() : (ctrl) { ctrl.SetTarget("here") }),
            _physThrows(function() : (ctrl) { ctrl.SetTargetVelocity(1) }),
            _physThrows(function() : (ctrl) { ctrl.SetStiffness("fast") }),
        ]
        ctrl.Release()
        foreach(err in errors) assert(err != null)
        return true
    },

    function hold_point_roundtrip() {
        if (!_physTestCube) return
        local ctrl = PhysControl.Controller(_physTestCube)
        local point = _physTestCube.GetOrigin() + Vector(5, -3, 7)
        ctrl.SetHoldPoint(point)
        local back = ctrl.GetHoldPoint()
        ctrl.Release()
        return assert((back - point).Length() < 0.01)
    },
}

// Run all tests
RunTests("PhysControl", physcontrol_tests)
