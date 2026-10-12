/*
 * Represents a scheduled action.
 *
 * One entry of an event queue in ScheduleEvent.eventsList; `_cmp` orders entries by execution time.
*/
::ScheduleAction <- class {
    // The object used as `this` when the action runs.
    scope = null;
    // The function, generator or VScript code string to execute.
    action = null;
    // The game time (Time()) at which the action is due.
    executionTime = null;
    // Optional arguments to pass to the action function.
    args = null;

    /*
     * Constructor for a ScheduleAction object.
     *
     * @param {object} scope - The object used as `this` when the action runs.
     * @param {string|function|generator} action - The function or generator to run, or a string of VScript code.
     * @param {number} delay - The delay in seconds; the action is due at Time() + delay.
     * @param {array|null} args - Optional arguments to pass to the action function.
    */
    constructor(scope, action, delay, args = null) {
        this.scope = scope
        this.action = action
        this.executionTime = delay + Time()

        if(args != null && typeof args != "array") throw("arguments must be an array, but got " + typeof args)
        this.args = args
    }

    /*
     * Executes the scheduled action with `scope` as `this`.
     *
     * If the action is a string, it is compiled into a function on the first run and replaces `action`.
     * If arguments are provided, they are passed to the action function.
     *
     * @returns {any} - The result of the action function.
    */
    function run() {
        if(type(this.action) == "string")
            this.action = compilestring(action)

        if(this.args == null) {
            return this.action.call(scope)
        }

        local actionArgs = [this.scope]
        actionArgs.extend(this.args)
        return this.action.acall(actionArgs)
    }

    /*
     * Resumes a generator action once and schedules the next resume.
     *
     * The yielded number is the pause in seconds before the next resume; 0 or less waits one frame.
     * A bare `yield` (null) or the end of the generator stops it. If the event no longer exists,
     * the generator is dropped with a developer warning.
     *
     * @param {generator} generator - The generator to resume.
     * @param {string|any} eventName - The event the generator is added to again.
    */
    function processGenerator(generator, eventName) {
        if(generator.getstatus() == "dead") return
        local delay = resume generator
        if(delay == null) return

        try {delay = delay.tofloat()}
        catch(err) {throw "Invalid value for sleep. " + err}
        if (delay <= 0.0) delay = FrameTime()

        if(eventName in ScheduleEvent.eventsList) {
            ScheduleEvent.Add(eventName, generator, delay, null, this.scope)
        } else {
            dev.warning("Generator pause will not take effect as the event '{}' no longer exists in the schedule.", eventName)
        }
    }

    /*
     * Describes the action for error output.
     *
     * @returns {string} - The scope, action and execution time, one per line.
    */
    function GetInfo() return "[Scope] " + scope + "\n[Action] " + this.action + "\n[executionTime] " + executionTime
    function _typeof() return "ScheduleAction"
    function _tostring() return "ScheduleAction: (" + this.executionTime + ")"
    function _cmp(other) {
        if (this.executionTime > other.executionTime) return 1;
        else if (this.executionTime < other.executionTime) return -1;
        return 0;
    }
}