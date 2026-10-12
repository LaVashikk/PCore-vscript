/*
 * Represents a custom "game event".
 *
 * Triggering the event runs its actions, subject to an optional filter and a trigger count.
 * Every event is registered in AllScriptEvents under its name, where EventListener finds it.
*/
::VGameEvent <- class {
    // The name of the event.  
    eventName = null; 
    // The number of times the event can be triggered before it becomes inactive (-1 for unlimited triggers). 
    triggerCount = null; 
    // List of action functions, run in the order they were added.
    actions = null; 
    // A filter function to check conditions before triggering the event.  
    filterFunction = null; 

    /*
     * Constructor for a VGameEvent object. Registers it in AllScriptEvents, replacing an event with the same name.
     *
     * @param {string} eventName - The name of the event.
     * @param {number} triggerCount - The number of times the event can be triggered (-1 for unlimited). (optional, default=-1)
     * @param {function|null} actionsList - A single action to add. (optional)
    */
    constructor(eventName, triggerCount = -1, actionsList = null) {
        this.eventName = eventName
        this.triggerCount = triggerCount
        this.actions = List()
        
        if(actionsList) this.actions.append(actionsList)
        
        AllScriptEvents[eventName] <- this
    }

    // Adds an action.
    function AddAction(actionFunction) null

    // Removes all actions.
    function ClearActions() null

    // Sets the filter that decides whether Trigger runs the actions.
    function SetFilter(filterFunc) null
    
    // Runs the actions if the trigger count and the filter allow it.
    function Trigger(args = null) null

    // Runs the actions, ignoring the filter and the trigger count.
    function ForceTrigger(args = null) null
}



/*
 * Adds an action. Actions run in the order they were added, with the event as `this`
 * and the trigger args as their parameters.
 *
 * @param {function} actionFunction - The action to add.
*/
function VGameEvent::AddAction(actionFunction) {
    this.actions.append(actionFunction)
}

/*
 * Removes all actions.
*/
function VGameEvent::ClearActions() {
    this.actions.clear()
}

/*
 * Sets the filter function for the event.
 *
 * Trigger calls the filter with the trigger args array as its only parameter (the event is `this`)
 * and runs the actions only if it returns true. ForceTrigger ignores it.
 *
 * @param {function|null} filterFunc - The filter, or null to remove it.
*/
function VGameEvent::SetFilter(filterFunc) {
    this.filterFunction = filterFunc
}


/*
 * Triggers the event if the trigger count allows and the filter function (if set) returns true.
 * A successful trigger decrements a positive trigger count. An event without actions does nothing.
 *
 * @param {array|null} args - Arguments passed to each action. (optional)
 * @returns {boolean|null} - True if the actions ran, null otherwise.
*/
function VGameEvent::Trigger(args = null) {
    if(this.actions.len() == 0) {
        dev.trace("Attempt to run {}, which has no actions", this.eventName)
        return
    }
    if(args == null) args = []
    if(typeof args != "array") throw("VGameEvent::Trigger ("+this.eventName+"): Invalid argument type. Expected an 'array', but got " + typeof args + " [" + args + "]")

    if (this.triggerCount != 0 && (this.filterFunction == null || this.filterFunction(args))) {
        if (this.triggerCount > 0) {
            // Decrement the trigger count if it is not unlimited
            this.triggerCount-- 
        }

        return this.ForceTrigger(args)
    }
}


/*
 * Forces the event to trigger, ignoring the filter function and trigger count.
 *
 * Each action is called with the event as `this` and the elements of `args` as its parameters.
 * An error in an action stops the remaining actions and is rethrown with the event name.
 *
 * @param {array|null} args - Arguments passed to each action. (optional)
 * @returns {boolean} - Always true.
*/
function VGameEvent::ForceTrigger(args = null) {
    if(args == null) args = []
    if(typeof args != "array") throw("VGameEvent::ForceTrigger ("+this.eventName+"): Invalid argument type. Expected an 'array', but got " + typeof args + " [" + args + "]")

    // Built separately so the caller's `args` stays untouched between triggers.
    local callArgs = [this]
    callArgs.extend(args)
    foreach(action in this.actions.iter()) {
        try {
            action.acall(callArgs)
        } catch(err) {
            throw("VGameEvent Error: " + this.eventName + " has accured: " + err )
        }
    }
    dev.trace("VScript Event Fired - " + this.eventName)
    return true // todo: what ._.
}