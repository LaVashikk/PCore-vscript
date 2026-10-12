::__anglesValueCalculator <- function(step, steps, v){return v.startAngles + v.angleDelta * v.easeFunc(step / steps)}
::__anglesPropertySetter <- function(ent, newAngle) {ent.SetAngles2(newAngle)}
/*
 * Creates an animation that transitions the angles of entities over time.
 * Each axis turns the shorter way, by at most 180 degrees.
 *
 * @param {string|array|ArrayEx|List|CBaseEntity|pcapEntity} entities - The entities to animate.
 * @param {Vector} startAngles - The starting angles. 
 * @param {Vector} endAngles - The ending angles. 
 * @param {number} time - The duration of the animation in seconds. 
 * @param {table} animSetting - A table containing additional animation settings. (optional) 
 * @returns {number} - The duration of the animation in seconds.
*/
animate["AnglesTransitionByTime"] <- function(entities, startAngles, endAngles, time, animSetting = {}) {
    if (typeof startAngles != "Vector")                     throw("AnglesTransitionByTime: 'startAngles' argument must be a Vector, but got " + typeof startAngles);
    if (typeof endAngles != "Vector")                       throw("AnglesTransitionByTime: 'endAngles' argument must be a Vector, but got " + typeof endAngles);
    if (typeof time != "integer" && typeof time != "float")  throw("AnglesTransitionByTime: 'time' argument must be a number, but got " + typeof time);
    if (typeof animSetting != "table")                      throw("AnglesTransitionByTime: 'animSetting' argument must be a table, but got " + typeof animSetting);

    local animSetting = AnimEvent("angles", animSetting, entities, time)

    local deltaAngleX = ((((endAngles.x - startAngles.x) % 360) + 540) % 360) - 180;
    local deltaAngleY = ((((endAngles.y - startAngles.y) % 360) + 540) % 360) - 180;
    local deltaAngleZ = ((((endAngles.z - startAngles.z) % 360) + 540) % 360) - 180;
    
    local vars = {
        startAngles = startAngles,
        angleDelta = Vector(deltaAngleX, deltaAngleY, deltaAngleZ),
        easeFunc = animSetting.easeFunc
    }

    animate.applyAnimation(
        animSetting, 
        __anglesValueCalculator,
        __anglesPropertySetter,
        vars
    )
    
    return animSetting.delay
}

/*
 * Real-time version of `animate.AnglesTransitionByTime`: frames are computed as the animation plays,
 * and `filterCallback` in `animSetting` can stop it. The parameters and return value are the same.
*/
animate.RT["AnglesTransitionByTime"] <- function(entities, startAngles, endAngles, time, animSetting = {}) {
    if (typeof startAngles != "Vector")                     throw("AnglesTransitionByTime: 'startAngles' argument must be a Vector, but got " + typeof startAngles);
    if (typeof endAngles != "Vector")                       throw("AnglesTransitionByTime: 'endAngles' argument must be a Vector, but got " + typeof endAngles);
    if (typeof time != "integer" && typeof time != "float") throw("AnglesTransitionByTime: 'time' argument must be a number, but got " + typeof time);
    if (typeof animSetting != "table")                      throw("AnglesTransitionByTime: 'animSetting' argument must be a table, but got " + typeof animSetting);

    local animSetting = AnimEvent("angles", animSetting, entities, time)

    local deltaAngleX = ((((endAngles.x - startAngles.x) % 360) + 540) % 360) - 180;
    local deltaAngleY = ((((endAngles.y - startAngles.y) % 360) + 540) % 360) - 180;
    local deltaAngleZ = ((((endAngles.z - startAngles.z) % 360) + 540) % 360) - 180;
    
    local vars = {
        startAngles = startAngles,
        angleDelta = Vector(deltaAngleX, deltaAngleY, deltaAngleZ),
        easeFunc = animSetting.easeFunc
    }

    animate.applyRTAnimation(
        animSetting, 
        __anglesValueCalculator,
        __anglesPropertySetter,
        vars
    )
    
    return animSetting.delay
}