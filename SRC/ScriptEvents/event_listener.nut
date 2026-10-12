/*
 * Triggers and looks up VGameEvent objects by name.
*/
::EventListener <- {
    /*
     * Triggers the VGameEvent with the given name (see VGameEvent.Trigger). An unknown name only prints a developer warning.
     *
     * @param {string} eventName - The name of the event to trigger.
     * @param {any} ... - Optional arguments passed to each action.
     * @returns {boolean|null} - True if the actions ran; null if the event is unknown, has no actions, has no triggers left or its filter rejected the args.
    */
    function Notify(eventName, ...) {
        if((eventName in AllScriptEvents) == false)
            return dev.warning("Unknown VGameEvent {" + eventName + "}")

        local varg = array(vargc)
        for(local i = 0; i< vargc; i++) {
            varg[i] = vargv[i]
        }

        return AllScriptEvents[eventName].Trigger(varg)
        
    }
    
    /* 
     * Gets a VGameEvent object by name. 
     * 
     * @param {string} eventName - The name of the event to retrieve. 
     * @returns {VGameEvent|null} - The VGameEvent object, or null if the event is not found. 
    */
    function GetEvent(eventName) {
        return eventName in AllScriptEvents ? AllScriptEvents[eventName] : null
    }
}