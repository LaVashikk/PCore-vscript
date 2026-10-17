/*
 * Log levels for `::LibLogger`. A dev.* log function prints only if its level is at least LibLogger.
*/
::LoggerLevels <- class {
    Trace = 1
    Debug = 5
    Info = 10
    Warning = 30
    Error = 60
    Off = 1000
}


/*
 * A collection of debugging utilities. 
 * The draw and log functions below do nothing while `developer` is 0. The log functions format their message
 * with macros.format, so the number of `{}` placeholders must match the number of extra arguments.
*/
::dev <- {
    /*
     * Draws the bounding box of an entity for the specified time: its bounding mins and maxs
     * around the origin, not rotated.
     * 
     * @param {CBaseEntity|pcapEntity} ent - The entity to draw the bounding box for.
     * @param {Vector} color - The color of the box.
     * @param {number} time - The duration of the display in seconds. 
    */
    DrawEntityBBox = function(ent, color, time) {
        if (developer() == 0) return
        DebugDrawBox(ent.GetOrigin(), ent.GetBoundingMins(), ent.GetBoundingMaxs(), color.x, color.y, color.z, 9, time)
    },

    /*
     * Draws the AABB of an entity for the specified time: the axis-aligned box around its rotated bounding box.
     * 
     * @param {pcapEntity} ent - The entity to draw the bounding box for.
     * @param {Vector} color - The color of the box.
     * @param {number} time - The duration of the display in seconds. 
    */
    DrawEntityAABB = function(ent, color, time) {
        if (developer() == 0) return
        local aabb = ent.GetAABB()
        DebugDrawBox(ent.GetOrigin(), aabb.min, aabb.max, color.x, color.y, color.z, 9, time)
    },

    /*
     * Draws a 2x2x2 box at the specified vector position for the specified time.
     * 
     * @param {Vector} vector - The position of the box.
     * @param {Vector} color - The color of the box. (optional, default Vector(125, 125, 125))
     * @param {number} time - The duration of the display in seconds. (optional, default 0.05)
    */
    drawbox = function(vector, color = Vector(125, 125, 125), time = 0.05) {
        if (developer() == 0) return
        DebugDrawBox(vector, Vector(-1,-1,-1), Vector(1,1,1), color.x, color.y, color.z, 100, time)
    },

    /*
     * Logs a trace message to the console if LibLogger is at most LoggerLevels.Trace.
     * Used for PCapture-Lib debugging.
     *
     * @param {string} msg - The trace message string containing `{}` placeholders.
     * @param {...any} vargv - The values for the placeholders, in order.
    */
    trace = function(msg, ...) {
        if (developer() == 0 || LibLogger > LoggerLevels.Trace) return
        // region - repeatable code, thanks to Squirrel
        local args = array(vargc + 2)
        args[0] = this
        args[1] = msg

        for(local i = 0; i< vargc; i++) {
            args[i + 2] = vargv[i]
        }
        // endregion

        local msg = macros.format.acall(args)
        printl("-- PCapture-Lib [" + Time().tostring() + "]: " + msg)
    },

    /*
     * Logs a debug message to the console if LibLogger is at most LoggerLevels.Debug.
     *
     * @param {string} msg - The debug message string containing `{}` placeholders. 
     * @param {...any} vargv - The values for the placeholders, in order.
    */ 
    debug = function(msg, ...) {
        if (developer() == 0 || LibLogger > LoggerLevels.Debug) return
        // region - repeatable code, thanks to Squirrel
        local args = array(vargc + 2)
        args[0] = this
        args[1] = msg

        for(local i = 0; i< vargc; i++) {
            args[i + 2] = vargv[i]
        }
        // endregion

        local msg = macros.format.acall(args)
        printl("[VScripts Debug (" + Time().tostring() + ")]: " + msg)
    },


    /*
     * Logs an info message to the console if LibLogger is at most LoggerLevels.Info.
     * 
     * @param {string} msg - The info message string containing `{}` placeholders.
     * @param {...any} vargv - The values for the placeholders, in order.
    */
    info = function(msg, ...) {
        if (developer() == 0 || LibLogger > LoggerLevels.Info) return
        // region - repeatable code, thanks to Squirrel
        local args = array(vargc + 2)
        args[0] = this
        args[1] = msg

        for(local i = 0; i< vargc; i++) {
            args[i + 2] = vargv[i]
        }
        // endregion

        local msg = macros.format.acall(args)
        printl("• " + msg)
    },

    /*
     * Logs a warning to the console if LibLogger is at most LoggerLevels.Warning.
     * The message is prefixed with the name and line of the calling function.
     * 
     * @param {string} msg - The warning message string containing `{}` placeholders. 
     * @param {...any} vargv - The values for the placeholders, in order.
    */
    warning = function(msg, ...) {
        if (developer() == 0 || LibLogger > LoggerLevels.Warning) return
        local pattern = "► Warning ({} [{}]): " + msg
        // region - repeatable code, thanks to Squirrel
        local info = dev._getInfo()
        local args = array(vargc + 4)
        args[0] = this
        args[1] = pattern
        args[2] = info[0] // func name
        args[3] = info[1] // func line

        for(local i = 0; i< vargc; i++) {
            args[i + 4] = vargv[i]
        }
        // endregion
        printl(macros.format.acall(args))
    },

    /* 
     * Logs an error to the console and plays a warning sound if LibLogger is at most LoggerLevels.Error.
     * The message is prefixed with the name and line of the calling function.
     * 
     * @param {string} msg - The error message string containing `{}` placeholders.
     * @param {...any} vargv - The values for the placeholders, in order.
    */
    error = function(msg, ...) {
        if (developer() == 0 || LibLogger > LoggerLevels.Error) return
        local pattern = "▄▀ *ERROR*: [func = {}; line = {}] | " + msg
        // region - repeatable code, thanks to Squirrel
        local info = dev._getInfo()
        local args = array(vargc + 4)
        args[0] = this
        args[1] = pattern
        args[2] = info[0] // func name
        args[3] = info[1] // func line

        for(local i = 0; i< vargc; i++) {
            args[i + 4] = vargv[i]
        }
        // endregion
        printl(macros.format.acall(args))
        SendToConsole("playvol resource/warning.wav 1")
    },

    _getInfo = function() {
        // 1 is _getInfo, 2 is dev.warning/dev.error, 3 called it. The last level was the script's entry point
        local info = getstackinfos(3)
        if(!info) info = getstackinfos(2)

        local funcName = info.func
        if (funcName == "main" || funcName == "unknown")
            funcName = "file " + info.src
            
        local line = info.line
        return [funcName, line]
    }
}