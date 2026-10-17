::macros <- {}

/* 
 * Precaches a sound script or a list of sound scripts for later use.
 * 
 * @param {string|array|ArrayEx|List} soundPath - The path to the sound script or a list of paths.
*/
macros["Precache"] <- function(soundPath) {
    if(typeof soundPath == "string")
        return self.PrecacheSoundScript(soundPath)
    local iter = typeof soundPath == "List" ? soundPath.iter() : soundPath
    foreach(path in iter)
        self.PrecacheSoundScript(path)
}


/* 
 * Gets a value from a table, returning a default value if the key is missing or its value is null.
 *
 * @param {table} table - The table to retrieve the value from. 
 * @param {any} key - The key of the value to get. 
 * @param {any} defaultValue - The value to return if the key is missing or its value is null. (optional, default null)
 * @returns {any} - The value associated with the key, or the default value.
*/ 
macros["GetFromTable"] <- function(table, key, defaultValue = null) {
    if(key in table && table[key] != null) 
        return table[key]
    return defaultValue
}

/* 
 * Gets a list of all keys in a table.
 *
 * @param {table} table - The table to retrieve the keys from.
 * @returns {List} - A list containing all the keys in the table.
*/ 
macros["GetKeys"] <- function(table) {
    local result = List()
    foreach(key, _ in table) {
        result.append(key)
    }
    return result
}

/*
 * Gets a list of all values in a table.
 *
 * @param {table} table - The table to retrieve the values from.
 * @returns {List} - A list containing all the values in the table.
*/ 
macros["GetValues"] <- function(table) {
    local result = List()
    foreach(value in table) {
        result.append(value)
    }
    return result
}

/*
 * Inverts a table, swapping keys and values.
 *
 * @param {table} table - The table to invert.
 * @returns {table} - A new table with keys and values swapped.
*/ 
macros["InvertTable"] <- function(table) {
    local result = {}
    foreach(key, value in table) {
        result[value] <- key
    }
    return result
}

/*
 * Prints the keys and values of an iterable object to the console. 
 *
 * @param {iterable} iterable - The iterable object to print.
*/
macros["PrintIter"] <- function(iterable) {
    iterable = typeof iterable == "List" ? iterable.iter() : iterable
    foreach(k, i in iterable) 
        macros.fprint("{}: {}", k, i)
}

/*
 * Generates a list of numbers from start to end, inclusive.
 *
 * @param {number} start - The starting value of the range.
 * @param {number} end - The last value of the range (inclusive).
 * @param {number} step - The increment between values, must be positive. (optional, default 1)
 * @returns {List} - A list of numbers within the specified range.
 * @throws - If step is 0.
*/ 
macros["Range"] <- function(start, end, step = 1) {
    // A negative step never reaches `end`, the loop would freeze the game
    if(step <= 0) throw("macros.Range: step must be greater than 0, but got " + step);
    
    local result = List()
    for (local i = start; i <= end; i += step) {
        result.append(i)
    }
    return result
}

/*
 * Generates an iterator that yields numbers from start to end, inclusive.
 *
 * @param {number} start - The starting value of the range.
 * @param {number} end - The last value of the range (inclusive).
 * @param {number} step - The increment between values, must be positive. (optional, default 1)
 * @yields {number} - The next number in the range.
 * @throws - If step is 0.
*/ 
macros["RangeIter"] <- function(start, end, step = 1) {
    if(step <= 0) throw("macros.RangeIter: step must be greater than 0, but got " + step);

    for (local i = start; i <= end; i += step) {
        yield i
    }
    return null
}

/*
 * Finds the first element of `iter` that is a substring of `match`.
 *
 * @param {array|ArrayEx|List} iter - The substrings (masks) to look for.
 * @param {string} match - The string to search in.
 * @returns {int|null} - The index of the first element found in `match`, or null if there is none.
 *           If the first element of iter is '*', returns 0. 
*/
macros["MaskSearch"] <- function(iter, match) {
    if(iter.len() == 0) return null
    if(iter[0] == "*") return 0

    foreach(idx, val in typeof iter == "List" ? iter.iter() : iter) {
        if(match.find(val) >= 0)
            return idx
    }
    return null
}

/*
 * Formats a message: replaces each `{}` placeholder with the next argument, converted to a string.
 * 
 * @param {string} msg - The message string containing `{}` placeholders.
 * @param {...any} vargv - The values for the placeholders, in order.
 * @returns {string} - The formatted message.
 * @throws - If the number of placeholders differs from the number of arguments.
*/
macros["format"] <- function(msg, ...) {
    // One pass over the "{}"s. split(msg, "{}") split on every brace, so a lone { or } vanished
    local result = ""
    local argIdx = 0
    local start = 0
    for(local i = msg.find("{}"); i != null; i = msg.find("{}", start)) {
        if(argIdx >= vargc) break
        result += msg.slice(start, i) + vargv[argIdx]
        argIdx++
        start = i + 2
    }

    if(argIdx != vargc || msg.find("{}", start) != null)
        throw("Discrepancy between the number of arguments and substitutions")
    return result + msg.slice(start)
}

/*
 * Formats a message with macros.format and prints it to the console.
 *
 * @param {string} msg - The message string containing `{}` placeholders. 
 * @param {...any} vargv - The values for the placeholders, in order.
*/
macros["fprint"] <- function(msg, ...) {
    local args = array(vargc + 2)
    args[0] = this
    args[1] = msg

    for(local i = 0; i< vargc; i++) {
        args[i + 2] = vargv[i]
    }

    printl(macros.format.acall(args))
}
::dev.fprint <- macros.fprint // legacy alias from earlier versions of the lib

/*
 * Formats a string with macros.format and compiles the result into a function.
 *
 * @param {string} funcBody - The body of the function to be compiled, with `{}` placeholders.
 * @param {...any} vargv - The values for the placeholders, in order.
 * @returns {function} - The compiled function.
*/
macros["CompileFromStr"] <- function(funcBody, ...) {
    local args = array(vargc + 2)
    args[0] = this
    args[1] = funcBody

    for(local i = 0; i< vargc; i++) {
        args[i + 2] = vargv[i]
    }

    return compilestring(macros.format.acall(args))
}

/* 
 * Calculates the distance between two vectors.
 *
 * @param {Vector} vec1 - The first vector.
 * @param {Vector} vec2 - The second vector.
 * @returns {number} - The distance between the vectors.
*/
macros["GetDist"] <- function(vec1, vec2) {
    return (vec2 - vec1).Length()
}

/* 
 * Converts a string to a Vector object.
 * 
 * @param {string} str - The string representation of the vector, e.g., "x y z".
 * @param {string} sep - The separator characters; each of them splits the string. (optional, default " ")
 * @returns {Vector} - The converted vector.
 * @throws - If the string does not split into exactly 3 numbers.
*/
macros["StrToVec"] <- function(str, sep = " ") {
    local str_arr = split(str, sep)
    if (str_arr.len() != 3) throw(format("macros.StrToVec: Input string '%s' is malformed. Expected 3 components separated by '%s', but got %d.", str, sep, str_arr.len()));
    try {
        local vec = Vector(str_arr[0].tofloat(), str_arr[1].tofloat(), str_arr[2].tofloat())
        return vec
    }
    catch(ex) {
        throw(format("macros.StrToVec: Failed to convert components of string '%s' to numbers. Details: %s", str, ex));
    }

}

/*
 * Converts a Vector object to a string representation.
 * 
 * @param {Vector} vec - The vector to convert. 
 * @param {string} sep - The separator between the components. (optional, default " ")
 * @returns {string} - The string "x<sep>y<sep>z".
*/
macros["VecToStr"] <- function(vec, sep = " ") {
    return vec.x + sep + vec.y + sep + vec.z 
}

/*
 * Gets the duration of a sound by its name. 
 * 
 * @param {string} soundName - The name of the sound. 
 * @returns {number} - The duration of the sound in seconds.
*/
macros["GetSoundDuration"] <- function(soundName) {
    return self.GetSoundDuration(soundName, "")
}

/*
 * Creates a simple console alias.
 *
 * @param {string} key - The alias name.
 * @param {string} action - The command to be executed when the alias is called.
 * @returns {void}
*/
macros["CreateAlias"] <- function(key, action) {
    SendToConsole(::format("alias \"%s\" \"%s\"", key, action))
}

/*
 * Creates a console command: an alias named `key` that runs `command`,
 * plus an empty setinfo variable with the same name.
 *
 * @param {string} key - The name of the command.
 * @param {string} command - The command to be executed.
*/
 macros["CreateCommand"] <- function(key, command) {
    SendToConsole(::format("setinfo %s \"\"", key))
    macros.CreateAlias(key, command)
}

/*
 * Checks if two values are equal, handling different data types.
 *
 * If either value is a CBaseEntity, their entity indices are compared. Floats are compared rounded to
 * 3 decimal places, Vectors with math.vector.IsEqual (which rounds both in place), Quaternion, Matrix
 * and pcapEntity values with their IsEqual method, other values with ==.
 *
 * @param {any} val1 - The first value.
 * @param {any} val2 - The second value.
 * @returns {boolean} - True if the values are equal, false otherwise. 
*/
macros["IsEqual"] <- function(val1, val2) {
    if((typeof val1 == "instance" || typeof val2 == "instance") && (val1 instanceof CBaseEntity || val2 instanceof CBaseEntity)) 
        return val1.entindex() == val2.entindex()
    
        switch (typeof val1) {
        case "integer": 
            return val1 == val2 
        case "float": 
            return math.round(val1, 1000) == math.round(val2, 1000)
        case "Vector": 
            return math.vector.IsEqual(val1, val2)
        case "instance": 
            return val1 == val2; 
        case "Quaternion": 
        case "Matrix": 
        case "pcapEntity": 
            return val1.IsEqual(val2)  
    }
}

/*
 * Creates a deep copy of a container (table, array, ArrayEx, or List).
 * Nested containers are copied recursively; any other value, including class instances and Vectors, is shared.
 * Note: The container must not have circular references.
 *
 * @param {table|array|ArrayEx|List} container - The container to be copied.
 * @param {any} _ - Unused. It lets DeepCopy be passed to map(), which also passes the index.
 * @returns {table|array|ArrayEx|List} - A deep copy of the container.
*/
macros["DeepCopy"] <- function(container, _ = null) { 
    switch (typeof container) {
        case "table": 
            local result = clone container; 
            foreach( k,v in container) result[k] = macros.DeepCopy(v); 
            return result; 
        
        case "array": 
            local a = array(container.len());
            for (local i=0; i<container.len(); i++) a[i] = macros.DeepCopy(container[i]);
            return a;

        case "ArrayEx": 
        case "List":
            return container.map(macros.DeepCopy); 
        
        default: return container; 
    }
}


/*
 * Gets the prefix of an entity name: everything up to and including the last "-".
 *
 * @param {string} name - The entity name. 
 * @returns {string} - The prefix of the entity name ("door-" for "door-1"), or the original name if no "-" is found.
*/
macros["GetPrefix"] <- function(name) {
    local parts = split(name, "-")
    if(parts.len() == 0)
        return name
    
    local lastPartLength = parts.pop().len()
    local prefix = name.slice(0, -lastPartLength)
    return prefix;
}


/* 
 * Gets the postfix of an entity name: everything from the first "-" on.
 *
 * @param {string} name - The entity name. 
 * @returns {string} - The postfix of the entity name ("-1" for "door-1"), or the original name if no "-" is found.
*/
macros["GetPostfix"] <- function(name) {
    local parts = split(name, "-")
    if(parts.len() == 0)
        return name

    local lastPartLength = parts[0].len();
    local prefix = name.slice(lastPartLength);
    return prefix;
}

/*
 * Calculates the end position of a ray cast from the player's eyes.
 * 
 * @param {CBaseEntity|pcapEntity} player - The player entity.
 * @param {number} distance - The distance of the ray cast.
 * @returns {Vector} - The end position of the ray cast. 
*/
macros["GetEyeEndpos"] <- function(player, distance) {
    if(typeof player != "pcapEntity") 
        player = entLib.FromEntity(player)
    return player.EyePosition() + player.EyeForwardVector() * distance
}

/*
 * Gets one vertex of a bounding box: the point (x.x, y.y, z.z) rotated by `ang` around the origin, not translated.
 * 
 * @param {Vector} x - The bound (mins or maxs) that gives the x coordinate.
 * @param {Vector} y - The bound (mins or maxs) that gives the y coordinate.
 * @param {Vector} z - The bound (mins or maxs) that gives the z coordinate.
 * @param {Vector} ang - The Euler angles in degrees (pitch, yaw, roll) to rotate the vertex by.
 * @returns {Vector} - The rotated vertex, relative to the entity origin.
*/
macros["GetVertex"] <- function(x, y, z, ang) {
    return math.vector.rotate(Vector(x.x, y.y, z.z), ang)
}

/*
 * Creates a triangle representation from three vertices. 
 *
 * @param {Vector} v1 - The first vertex of the triangle.
 * @param {Vector} v2 - The second vertex of the triangle.
 * @param {Vector} v3 - The third vertex of the triangle.
 * @returns {table} - A table with `origin` (the centroid of the triangle) and `vertices` ([v1, v2, v3]).
*/
macros["GetTriangle"] <- function(v1, v2, v3) {
    return {
        origin = (v1 + v2 + v3) * 0.3333,
        vertices = [v1, v2, v3]
    }
}

/*
 * Creates a rectangle object from four vertices. 
 *
 * @param {Vector} v1 - The first vertex.
 * @param {Vector} v2 - The second vertex. 
 * @param {Vector} v3 - The third vertex. 
 * @param {Vector} v4 - The fourth vertex.
 * @returns {table} - A table with `origin` (the average of the vertices) and `vertices` ([v1, v2, v3, v4]).
*/
macros["GetRectangle"] <- function(v1, v2, v3, v4) {
    return {
        origin = (v1 + v2 + v3 + v4) * 0.25,
        vertices = [v1, v2, v3, v4]
    }
}

/*
 * Checks if a point is inside a bounding box. Points on the boundary count as inside.
 * 
 * @param {Vector} point - The point to check.
 * @param {Vector} bMin - The minimum corner of the bounding box. 
 * @param {Vector} bMax - The maximum corner of the bounding box. 
 * @returns {boolean} - True if the point is inside the bounding box, false otherwise.
*/
macros["PointInBBox"] <- function(point, bMin, bMax) {
    return (
        point.x >= bMin.x && point.x <= bMax.x &&
        point.y >= bMin.y && point.y <= bMax.y &&
        point.z >= bMin.z && point.z <= bMax.z
    )
}

/*
 * Checks if two Axis-Aligned Bounding Boxes (AABB) intersect (overlap)
 *
 * @param {Vector} b1Min - Minimum point of Box 1.
 * @param {Vector} b1Max - Maximum point of Box 1.
 * @param {Vector} b2Min - Minimum point of Box 2.
 * @param {Vector} b2Max - Maximum point of Box 2.
 * @returns {boolean} - True if they intersect, false otherwise.
*/
macros["BBoxIntersect"] <- function(b1Min, b1Max, b2Min, b2Max) {
    return (
        b1Min.x <= b2Max.x && b1Max.x >= b2Min.x &&
        b1Min.y <= b2Max.y && b1Max.y >= b2Min.y &&
        b1Min.z <= b2Max.z && b1Max.z >= b2Min.z
    )
}


/*
 * Checks if a point is within the map: a TraceLine of 64000 units from the point along each of
 * the six axis directions must hit something before 98% of its length.
 *
 * @param {Vector} point - The point to check.
 * @returns {boolean} - True if the point is within the bounds, false otherwise.
*/
macros["PointInBounds"] <- function(point) {
    local m = 64000
    return (
        TraceLine(point, point + Vector(m, 0, 0), null) >= 0.98 ||
        TraceLine(point, point - Vector(m, 0, 0), null) >= 0.98 ||
        TraceLine(point, point + Vector(0, m, 0), null) >= 0.98 ||
        TraceLine(point, point - Vector(0, m, 0), null) >= 0.98 || 
        TraceLine(point, point + Vector(0, 0, m), null) >= 0.98 ||
        TraceLine(point, point - Vector(0, 0, m), null) >= 0.98
    ) == false
}

__defaultValueCalculator <- function(step, steps, v) {return v.start + v.delta * v.easeFunc(step / steps)}
/*
 * Creates a function that animates a property of one or more entities.
 * 
 * @param {string} name - The name of the animation. Used in error messages and in the default event name.
 * @param {function} propertySetterFunc - Called as propertySetterFunc(entity, value) on every frame for each entity to set the property.
 * @param {function} valueCalculator - Called as valueCalculator(step, steps, vars) to compute the value of a frame, where vars is
 *   {start, delta, easeFunc} and delta is endValue - startValue. Default: start + delta * easeFunc(step / steps). (optional)
 * @returns {function} - A function that starts the animation and returns its duration in seconds. It takes the following arguments:
 *   * `entities` {string|array|ArrayEx|List|CBaseEntity|pcapEntity} - The entities to animate. See the `AnimEvent` constructor for details.
 *   * `startValue` {any} - The starting value for the property. Must support `endValue - startValue`.
 *   * `endValue` {any} - The ending value for the property.
 *   * `time` {number} - The duration of the animation in seconds.
 *   * `animSetting` {table} (optional) - A table of additional animation settings. See the `AnimEvent` constructor for details.
 *   It throws if `entities` is null or `time` is not positive.
 * @throws - If propertySetterFunc is not a function, or valueCalculator is neither a function nor null.
*/
macros["BuildAnimateFunction"] <- function(name, propertySetterFunc, valueCalculator = null) {
    if (typeof propertySetterFunc != "function") throw("macros.BuildAnimateFunction: 'propertySetterFunc' must be a function, but got " + typeof propertySetterFunc);
    if (valueCalculator != null && typeof valueCalculator != "function") throw("macros.BuildAnimateFunction: 'valueCalculator' must be a function or null, but got " + typeof valueCalculator);

    return function(entities, startValue, endValue, time, animSetting = {}) : (name, propertySetterFunc, valueCalculator) {
        if(!entities) throw(name+" Anim: entities cannot be null")
        if(time <= 0) throw(name+" Anim: time must be positive")
    
        local animSetting = AnimEvent(name, animSetting, entities, time) 
        local varg = {
            start = startValue,
            delta = endValue - startValue,
            easeFunc = animSetting.easeFunc
        }

        animate.applyAnimation(
            animSetting,
            valueCalculator ? valueCalculator : __defaultValueCalculator,
            propertySetterFunc,
            varg
        ) 

        return animSetting.delay
    }
}

/*
 * Same as BuildAnimateFunction, but the built function starts a real-time animation (animate.applyRTAnimation),
 * which computes each frame when it is played instead of scheduling all frames upfront.
*/
macros["BuildRTAnimateFunction"] <- function(name, propertySetterFunc, valueCalculator = null) {
    if (typeof propertySetterFunc != "function") throw("macros.BuildAnimateFunction: 'propertySetterFunc' must be a function, but got " + typeof propertySetterFunc);
    if (valueCalculator != null && typeof valueCalculator != "function") throw("macros.BuildAnimateFunction: 'valueCalculator' must be a function or null, but got " + typeof valueCalculator);
    
    return function(entities, startValue, endValue, time, animSetting = {}) : (name, propertySetterFunc, valueCalculator) {
        local animSetting = AnimEvent(name, animSetting, entities, time) 
        local varg = {
            start = startValue,
            delta = endValue - startValue,
            easeFunc = animSetting.easeFunc
        }

        animate.applyRTAnimation(
            animSetting,
            valueCalculator ? valueCalculator : __defaultValueCalculator,
            propertySetterFunc,
            varg
        ) 

        return animSetting.delay
    }
}