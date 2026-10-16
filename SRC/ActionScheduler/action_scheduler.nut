/*
 * Adds a single action to a scheduled event with the specified name.
 *
 * @param {string|any} eventName - The name of the event to add the action to. If the event does not exist, it is created.
 * @param {string|function|generator} action - The action to execute when the scheduled time arrives: a function, a generator or a string of VScript code.
 * @param {number} timeDelay - The delay in seconds before executing the action.
 * @param {iter|null} args - Optional arguments to pass to the action function, copied.
 * @param {object} scope - The object used as `this` when the action runs. (optional, default is the root table)
*/
ScheduleEvent["Add"] <- function(eventName, action, timeDelay, args = null, scope = null) {
    if (typeof action != "string" && typeof action != "function" && typeof action != "native function" && typeof action != "generator") throw("ScheduleEvent.Add: 'action' must be a function or a string, but got " + typeof action);
    if (typeof timeDelay != "integer" && typeof timeDelay != "float") throw("ScheduleEvent.Add: 'timeDelay' must be a number, but got " + typeof timeDelay);
    local argsType = typeof args;
    if(args && argsType != "array" && argsType != "ArrayEx" && argsType != "List") throw("ScheduleEvent.Add: 'args' must be an array, List, or null, but got " + typeof args)
    // ScheduleAction takes a native array only
    if(argsType == "ArrayEx") args = clone args.arr
    else if(argsType == "List") args = args.toarray().arr
    if(scope == null) scope = getroottable()

    if ( !(eventName in ScheduleEvent.eventsList) ) {
        ScheduleEvent.eventsList[eventName] <- List()
        dev.trace("Created new Event - \"{}\"", eventName)
    }

    local newScheduledEvent = ScheduleAction(scope, action, timeDelay, args)
    local queue = ScheduleEvent.eventsList[eventName]

    // Keep the queue sorted by execution time: ScheduledEventLoop stops at the first action that is not due
    // Walk back from the tail, a new action almost always lands near the end
    local node = queue.lastNode
    while(node != queue.firstNode && node.value.executionTime > newScheduledEvent.executionTime)
        node = node._prevRef
    queue._insertAfterNode(node, newScheduledEvent)
}

/*
 * Adds an action to a scheduled event that will be executed repeatedly at a fixed interval.
 * It repeats until its event is cancelled; intervals in "global" cannot be cancelled.
 *
 * @param {string|any} eventName - The name of the event to add the interval to. If the event does not exist, it is created.
 * @param {string|function|generator} action - The action to execute at each interval.
 * @param {number} interval - The time interval in seconds between executions of the action. Must be greater than 0.
 * @param {number} initialDelay - The initial delay in seconds before the first execution of the action (default is 0).
 * @param {iter|null} args - Optional arguments to pass to the action function, copied.
 * @param {object} scope - The object used as `this` when the action runs (default is the root table).
*/
ScheduleEvent["AddInterval"] <- function(eventName, action, interval, initialDelay = 0, args = null, scope = null) {
    if (typeof action != "string" && typeof action != "function" && typeof action != "native function" && typeof action != "generator") throw("ScheduleEvent.AddInterval: 'action' must be a function or a string, but got " + typeof action);
    if (typeof interval != "integer" && typeof interval != "float") throw("ScheduleEvent.AddInterval: 'interval' must be a number, but got " + typeof interval);
    if (interval <= 0) throw("ScheduleEvent.AddInterval: 'interval' must be a positive number, but got " + interval);
    if (typeof initialDelay != "integer" && typeof initialDelay != "float") throw("ScheduleEvent.AddInterval: 'initialDelay' must be a number, but got " + typeof initialDelay);
    local argsType = typeof args;
    if(args && argsType != "array" && argsType != "ArrayEx" && argsType != "List") throw("ScheduleEvent.AddInterval: 'args' must be an array, List, or null, but got " + typeof args)
    if(argsType == "ArrayEx") args = clone args.arr
    else if(argsType == "List") args = args.toarray().arr
    if(scope == null) scope = getroottable()

    ScheduleEvent.Add(eventName, action, initialDelay, args, scope)
    ScheduleEvent.Add(eventName, ScheduleEvent.AddInterval, initialDelay + interval, [eventName, action, interval, 0, args, scope], scope)
}

/*
 * Adds multiple actions to a scheduled event.
 *
 * An existing event gets the actions appended and is re-sorted by execution time. A new event gets a copy of
 * the container as its queue, sorted unless `noSort`.
 *
 * @param {string|any} eventName - The name of the event to add the actions to. If the event does not exist, it is created.
 * @param {iter} actions - The `ScheduleAction` objects to add to the event.
 * @param {boolean} noSort - Skip sorting when the event is new; the actions must already be sorted by execution time (default is false).
*/
ScheduleEvent["AddActions"] <- function(eventName, actions, noSort = false) { 
    local actionsType = typeof actions;
    if (actionsType != "array" && actionsType != "List" && actionsType != "ArrayEx") throw("ScheduleEvent.AddActions: 'actions' must be an array or a List, but got " + actionsType);
    if (actions.len() > 0) {
        if (typeof actions[0] != "ScheduleAction") {
            dev.warning("ScheduleEvent.AddActions: The 'actions' container does not appear to hold ScheduleAction objects. This might cause errors.");
        }
    }

    if(eventName in ScheduleEvent.eventsList) {
        ScheduleEvent.eventsList[eventName].extend(actions)
        ScheduleEvent.eventsList[eventName].sort()
        if(developer() > 0) dev.trace("Added {} actions to Event \"{}\".", actions.len(), eventName)
        return 
    } 

    // A native array sorts natively, List.sort is a Squirrel merge sort (1.2-1.5x slower, sq 2.2.5)
    // FromArray copies, so the caller's container never becomes the live queue
    local arr = actionsType == "List" ? actions.toarray().arr : actionsType == "ArrayEx" ? actions.arr : actions
    if(!noSort) {
        arr = clone arr
        arr.sort()
    }
    ScheduleEvent.eventsList[eventName] <- List.FromArray(arr)

    if(developer() > 0) dev.trace("Created new Event \"{}\" with {} actions.", eventName, actions.len())
}


/*
 * Cancels a scheduled event with the given name, optionally after a delay. Its pending actions are dropped.
 *
 * @param {string|any} eventName - The name of the event to cancel.
 * @param {number} delay - An optional delay in seconds before canceling the event (default is 0).
 * @throws - If `eventName` is "global" or no event with this name exists.
*/
ScheduleEvent["Cancel"] <- function(eventName, delay = 0) {
    if(eventName == "global")
        throw("The global event cannot be closed!")
    if(!(eventName in ScheduleEvent.eventsList))
        throw("There is no event named " + eventName)
    if(delay > 0)
        return ScheduleEvent.Add("global", ScheduleEvent.TryCancel, delay, [eventName])
    
    ScheduleEvent.eventsList.rawdelete(eventName)
        
    if(developer() > 0) dev.trace("Event \"{}\" closed! Actial events: {}", eventName, macros.GetKeys(ScheduleEvent.eventsList))
}

/*
 * Attempts to cancel a scheduled event with the given name, optionally after a delay.
 * Unlike `ScheduleEvent.Cancel`, a missing event is not an error.
 *
 * @param {string|any} eventName - The name of the event to cancel.
 * @param {number} delay - An optional delay in seconds before attempting to cancel the event (default is 0).
 * @returns {boolean|null} - True if the event was found and canceled, false otherwise. Null if `delay` > 0: the attempt is only scheduled.
 * @throws - If `eventName` is "global".
*/
ScheduleEvent["TryCancel"] <- function(eventName, delay = 0) {
    if(delay > 0) 
        return ScheduleEvent.Add("global", ScheduleEvent.TryCancel, delay, [eventName])
    local isValid = ScheduleEvent.IsValid(eventName) 
    if(isValid) ScheduleEvent.Cancel(eventName)
    return isValid
}

/*
 * Cancels all scheduled events except "global", dropping their pending actions.
*/
ScheduleEvent["CancelAll"] <- function() {
    ScheduleEvent.eventsList = {global = ScheduleEvent.eventsList["global"]}
    dev.trace("Scheduled events have been canceled!")
}

/*
 * Cancels all scheduled events, including "global".
 * "global" also holds the library's own intervals; they are not restarted.
*/
ScheduleEvent["UNSAFE_ClearWithGlobal"] <- function() {
    ScheduleEvent.eventsList = {global = List()}
    dev.trace("All scheduled events have been canceled!")
}


/*
 * Gets the pending actions of a scheduled event.
 *
 * @param {string|any} eventName - The name of the event.
 * @returns {List|null} - The event's queue of ScheduleAction objects (the live List, not a copy), or null if not found.
*/
ScheduleEvent["GetEvent"] <- function(eventName) {
    return eventName in ScheduleEvent.eventsList ? ScheduleEvent.eventsList[eventName] : null
}


/*
 * Checks whether a scheduled event with the given name exists.
 *
 * @param {string|any} eventName - The name of the event.
 * @returns {boolean} - True if the event exists.
*/
ScheduleEvent["IsValid"] <- function(eventName) {
    return eventName in ScheduleEvent.eventsList
}