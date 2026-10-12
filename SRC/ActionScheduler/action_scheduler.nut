/*
 * Adds a single action to a scheduled event with the specified name.
 *
 * @param {string|any} eventName - The name of the event to add the action to. If the event does not exist, it is created.
 * @param {string|function|generator} action - The action to execute when the scheduled time arrives: a function, a generator or a string of VScript code.
 * @param {number} timeDelay - The delay in seconds before executing the action.
 * @param {array|null} args - An optional array of arguments to pass to the action function.
 * @param {object} scope - The object used as `this` when the action runs (default is the root table).
*/
ScheduleEvent["Add"] <- function(eventName, action, timeDelay, args = null, scope = this) {
    if (typeof action != "string" && typeof action != "function" && typeof action != "native function" && typeof action != "generator") throw("ScheduleEvent.Add: 'action' must be a function or a string, but got " + typeof action);
    if (typeof timeDelay != "integer" && typeof timeDelay != "float") throw("ScheduleEvent.Add: 'timeDelay' must be a number, but got " + typeof timeDelay);
    local argsType = typeof args;
    if(args && argsType != "array" && argsType != "ArrayEx" && argsType != "List") throw("ScheduleEvent.Add: 'args' must be an array, List, or null, but got " + typeof args)

    if ( !(eventName in ScheduleEvent.eventsList) ) {
        ScheduleEvent.eventsList[eventName] <- List()
        dev.trace("Created new Event - \"{}\"", eventName)
    }

    local newScheduledEvent = ScheduleAction(scope, action, timeDelay, args)
    local currentActionList = ScheduleEvent.eventsList[eventName]

    // Keep the queue sorted by execution time: ScheduledEventLoop stops at the first action that is not due.
    if(currentActionList.len() == 0 || currentActionList.top() <= newScheduledEvent) {
        currentActionList.append(newScheduledEvent)
        return
    } 
    
    local low = 0
    local high = currentActionList.len() - 1
    local mid

    local tempActionArr = currentActionList.toarray()
    while (low <= high) {
        mid = (low + high) / 2
        if (tempActionArr[mid] < newScheduledEvent) {
            low = mid + 1
        }
        else if (tempActionArr[mid] > newScheduledEvent) {
            high = mid - 1
        }
        else {
            low = mid
            break
        }
    }
    
    currentActionList.insert(low, newScheduledEvent)
}

/*
 * Adds an action to a scheduled event that will be executed repeatedly at a fixed interval.
 * It repeats until its event is cancelled; intervals in "global" cannot be cancelled.
 *
 * @param {string|any} eventName - The name of the event to add the interval to. If the event does not exist, it is created.
 * @param {string|function|generator} action - The action to execute at each interval.
 * @param {number} interval - The time interval in seconds between executions of the action. Must be greater than 0.
 * @param {number} initialDelay - The initial delay in seconds before the first execution of the action (default is 0).
 * @param {array|null} args - An optional array of arguments to pass to the action function.
 * @param {object} scope - The object used as `this` when the action runs (default is the root table).
*/
ScheduleEvent["AddInterval"] <- function(eventName, action, interval, initialDelay = 0, args = null, scope = this) {
    if (typeof action != "string" && typeof action != "function" && typeof action != "native function" && typeof action != "generator") throw("ScheduleEvent.AddInterval: 'action' must be a function or a string, but got " + typeof action);
    if (typeof interval != "integer" && typeof interval != "float") throw("ScheduleEvent.AddInterval: 'interval' must be a number, but got " + typeof interval);
    if (interval <= 0) throw("ScheduleEvent.AddInterval: 'interval' must be a positive number, but got " + interval);
    if (typeof initialDelay != "integer" && typeof initialDelay != "float") throw("ScheduleEvent.AddInterval: 'initialDelay' must be a number, but got " + typeof initialDelay);
    local argsType = typeof args;
    if(args && argsType != "array" && argsType != "ArrayEx" && argsType != "List") throw("ScheduleEvent.AddInterval: 'args' must be an array, List, or null, but got " + typeof args)


    ScheduleEvent.Add(eventName, action, initialDelay, args, scope)
    ScheduleEvent.Add(eventName, ScheduleEvent.AddInterval, initialDelay + interval, [eventName, action, interval, 0, args, scope], scope)
}

/*
 * Adds multiple actions to a scheduled event.
 *
 * An existing event gets the actions appended and is re-sorted by execution time. For a new event, the container
 * is sorted in place (unless `noSort`) and becomes the event's queue: a List is used as is, other containers are copied into a List.
 *
 * @param {string|any} eventName - The name of the event to add the actions to. If the event does not exist, it is created.
 * @param {array|ArrayEx|List} actions - The `ScheduleAction` objects to add to the event.
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

    if(!noSort) actions.sort()

    if(typeof actions == "List") {
        ScheduleEvent.eventsList[eventName] <- actions
    } else {
        ScheduleEvent.eventsList[eventName] <- List.FromArray(actions)
    }

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
        return ScheduleEvent.Add("global", format("ScheduleEvent.Cancel(\"%s\")", eventName), delay)
    
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