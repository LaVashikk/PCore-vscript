math["lerp"] <- {}
local lerp = math["lerp"]


/*
 * Performs linear interpolation (lerp) between start and end based on the parameter t.
 *
 * @param {number} start - The starting value.
 * @param {number} end - The ending value.
 * @param {number} t - The interpolation parameter.
 * @returns {number} - The interpolated value.
*/
lerp["number"] <- function(start, end, t) {
    return start * (1 - t) + end * t;
}


/*
 * Performs linear interpolation (lerp) between two vectors.
 *
 * @param {Vector} start - The starting vector.
 * @param {Vector} end - The ending vector.
 * @param {number} t - The interpolation parameter.
 * @returns {Vector} - The interpolated vector.
*/
lerp["vector"] <- function(start, end, t) {
    return Vector(math.lerp.number(start.x, end.x, t), math.lerp.number(start.y, end.y, t), math.lerp.number(start.z, end.z, t));
}


/*
 * Performs linear interpolation (lerp) between two colors.
 *
 * @param {Vector|string} start - The starting color vector or string representation (e.g., "255 0 0").
 * @param {Vector|string} end - The ending color vector or string representation.
 * @param {number} t - The interpolation parameter.
 * @returns {string} - The interpolated color as "r g b", each component floored (e.g., "127 0 127").
*/
lerp["color"] <- function(start, end, t) {
    if (type(start) == "string") {
        start = macros.StrToVec(start)
    }
    if (type(end) == "string") {
        end = macros.StrToVec(end)
    }

    return floor(math.lerp.number(start.x, end.x, t)) + " " + floor(math.lerp.number(start.y, end.y, t)) + " " + floor(math.lerp.number(start.z, end.z, t))
}

/*
 * Performs spherical linear interpolation (slerp) between two orientations given as Euler angles.
 *
 * @param {Vector} start - The starting Euler angles in degrees (pitch, yaw, roll).
 * @param {Vector} end - The ending Euler angles in degrees (pitch, yaw, roll).
 * @param {number} t - The interpolation parameter.
 * @returns {Vector} - The interpolated Euler angles in degrees (pitch, yaw, roll).
*/
lerp["sVector"] <- function(start, end, t) {
    local q1 = math.Quaternion.fromEuler(start)
    local q2 = math.Quaternion.fromEuler(end)
    return q1.slerp(q2, t).toVector()
}

/*
 * Computes the smoothstep weight of a value between two edges.
 *
 * The position t of `value` in [edge0, edge1] is clamped to 0..1 and smoothed as t * t * (3 - 2t).
 * Returns 0 if edge0 is equal to edge1.
 *
 * @param {number} edge0 - The edge where the weight is 0.
 * @param {number} edge1 - The edge where the weight is 1.
 * @param {number} value - The value to weigh.
 * @returns {number} - The weight in the range 0..1.
*/
lerp["SmoothStep"] <- function(edge0, edge1, value) {
    if(edge0 == edge1) return 0
    local t = math.clamp((value - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t)
}


/*
 * Linearly maps `value` from the range [i1, i2] to the range [f1, f2]. The result is not clamped.
 * Returns f2 if i1 is equal to i2.
 *
 * @param {number} f1 - The result at i1.
 * @param {number} f2 - The result at i2.
 * @param {number} i1 - The start of the input range.
 * @param {number} i2 - The end of the input range.
 * @param {number} value - The value to map.
 * @returns {number} - The mapped value.
*/
lerp["FLerp"] <- function( f1, f2, i1, i2, value ) {
    if(i1 == i2) return f2
    return f1 + (f2 - f1) * (value - i1) / (i2 - i1);
}