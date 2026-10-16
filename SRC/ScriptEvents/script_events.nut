/*
 * A global event bus: scripts subscribe to an event by its name and emit it by its name, nothing to create beforehand.
 *
 * ScriptEvents.On("cube_dissolved", function(cube) { ... })
 * ScriptEvents.Emit("cube_dissolved", cube)
 *
 * Actions get the emitted arguments, `this` is the scope given to On/Once (the root table by default).
 * An error in an action isn't caught: it stops the remaining actions and points to its own line
*/
::ScriptEvents <- {
    // event name -> its subscriptions in the order they were added. A name without subscriptions is deleted
    _events = {},
    // subscription id -> subscription, for Off
    _subs = {},
    _lastId = 0,

    /*
     * Subscribes an action to an event.
     *
     * @param {string} eventName - The name of the event.
     * @param {function} action - Called with the emitted arguments.
     * @param {object} scope - `this` for the action. (optional, default is the root table)
     * @returns {integer} - The subscription id, for Off.
    */
    function On(eventName, action, scope = null) {
        return this._subscribe(eventName, action, scope, false, "On")
    }

    /*
     * Subscribes an action to the next emit of an event only: it unsubscribes right before it runs.
     *
     * @param {string} eventName - The name of the event.
     * @param {function} action - Called with the emitted arguments.
     * @param {object} scope - `this` for the action. (optional, default is the root table)
     * @returns {integer} - The subscription id, for Off.
    */
    function Once(eventName, action, scope = null) {
        return this._subscribe(eventName, action, scope, true, "Once")
    }

    /*
     * Removes a subscription.
     *
     * @param {integer} id - The id returned by On or Once.
     * @returns {boolean} - True if it was subscribed, false if it was removed before
    */
    function Off(id) {
        if(!(id in this._subs)) return false
        this._unsubscribe(this._subs[id])
        return true
    }

    /*
     * Emits an event: runs its actions with the given arguments, in the order they were subscribed.
     * An action subscribed during the emit runs from the next emit on, an action removed during it doesn't run.
     *
     * @param {string} eventName - The name of the event.
     * @param {any} ... - Arguments passed to each action.
     * @returns {boolean} - True if any action ran, false if nothing is subscribed to the event.
    */
    function Emit(eventName, ...) {
        if(typeof eventName != "string") throw("ScriptEvents.Emit: the event name must be a string, but got " + typeof eventName)
        if(!(eventName in this._events)) {
            dev.trace("ScriptEvents: nothing is subscribed to {}", eventName)
            return false
        }

        // args[0] is `this` of the action
        local args = array(vargc + 1)
        for(local i = 0; i < vargc; i++)
            args[i + 1] = vargv[i]

        local ran = false
        // A copy: Once and Off from inside an action change the list
        foreach(sub in clone this._events[eventName]) {
            if(!sub.active) continue
            if(sub.once) this._unsubscribe(sub)

            args[0] = sub.scope
            sub.action.acall(args)
            ran = true
        }

        return ran
    }


    function _subscribe(eventName, action, scope, once, caller) {
        if(typeof eventName != "string") throw("ScriptEvents." + caller + ": the event name must be a string, but got " + typeof eventName)
        if(typeof action != "function" && typeof action != "native function") throw("ScriptEvents." + caller + ": the action must be a function, but got " + typeof action)

        this._lastId += 1
        local sub = {
            id = this._lastId,
            eventName = eventName,
            action = action,
            scope = scope != null ? scope : getroottable(),
            once = once,
            active = true
        }

        if(!(eventName in this._events)) this._events[eventName] <- []
        this._events[eventName].append(sub)
        this._subs[sub.id] <- sub

        return sub.id
    }

    // `active` stops a running Emit from calling it, its copy of the list still has it
    function _unsubscribe(sub) {
        sub.active = false
        delete this._subs[sub.id]

        local list = this._events[sub.eventName]
        foreach(i, s in list) {
            if(s == sub) {
                list.remove(i)
                break
            }
        }

        if(list.len() == 0) delete this._events[sub.eventName]
    }
}
