
if(!("RunTests" in getroottable())) IncludeScript("PCapture-Lib/Tests/test_exec")

scriptEventsTests <- {
    function vGameEventCreationTest() {
        local gameEvent = VGameEvent("testEvent");
        return assert(gameEvent.eventName == "testEvent");
    },

    function vGameEventAddActionTest() {
        local gameEvent = VGameEvent("testEventWithAction");
        local actionFunc = function() {};
        gameEvent.AddAction(actionFunc);
        return assert(gameEvent.actions.len() == 1);
    },

    function vGameEventClearActionsTest() {
        local gameEvent = VGameEvent("testEventClearActions");
        gameEvent.AddAction(function() {});
        gameEvent.ClearActions();
        return assert(gameEvent.actions.len() == 0);
    },

    function vGameEventSetFilterTest() {
        local gameEvent = VGameEvent("testEventWithFilter");
        local filterFunc = function() { return true; };
        gameEvent.SetFilter(filterFunc);
        return assert(gameEvent.filterFunction == filterFunc);
    },

    function eventListenerNotifyTest() {
        local eventName = "listenerNotifyTestEvent";
        local eventTriggered = [false]; // wrapper
        local gameEvent = VGameEvent(eventName);
        gameEvent.AddAction(function(eventTriggered) { 
            eventTriggered[0] = true;
        });
        EventListener.Notify(eventName, eventTriggered);
        return assert(eventTriggered[0] == true);
    },

    function vGameEventForceTriggerTest() {
        local eventName = "forceTriggerTestEvent";
        local eventTriggered = [false]; // wrapper
        local gameEvent = VGameEvent(eventName);
        gameEvent.AddAction(function(eventTriggered) {
            eventTriggered[0] = true; 
        });
        gameEvent.ForceTrigger([eventTriggered]);
        return assert(eventTriggered[0] == true);
    },

    function eventListenerGetEventTest() {
        local eventName = "getEventTestEvent";
        local gameEvent = VGameEvent(eventName);
        local retrievedEvent = EventListener.GetEvent(eventName);
        return assert(retrievedEvent == gameEvent);
    },

    function vGameEventTriggerCountLimitTest() {
        local eventName = "triggerCountLimitEvent";
        local triggerCount = 2;
        local counter = [0]; // wrapper
        local gameEvent = VGameEvent(eventName, triggerCount);
        gameEvent.AddAction(function(counter) {
            counter[0]++;
        });

        EventListener.Notify(eventName, counter);
        EventListener.Notify(eventName, counter);
        EventListener.Notify(eventName, counter); // Triggered more times than allowed

        return assert(counter[0] == triggerCount); // Check if event triggered only twice
    },

    function vGameEventFilterFunctionTest() {
        local eventName = "filterFunctionEvent";
        local eventTriggered = [0]; // wrapper
        local gameEvent = VGameEvent(eventName);
        gameEvent.SetFilter(function(args) {
            return args[1] == "allowed"; // Filter to only allow triggers with "allowed" argument
        });
        gameEvent.AddAction(function(eventTriggered, _) {
            eventTriggered[0] += 1;
        });

        EventListener.Notify(eventName, eventTriggered, "denied"); // Should not trigger due to filter
        EventListener.Notify(eventName, eventTriggered, "allowed"); // Should trigger

        return assert(eventTriggered[0] == 1); // Check if event was triggered only when filter allowed
    },

    function eventListenerNotifyUnknownEventTest() {
        local result = EventListener.Notify("unknownEvent"); // Notify an event that does not exist
        return assert(result == null); // Should return null for unknown event
    },

    function vGameEventTriggerWithoutArgsTest() {
        local counter = [0]; // wrapper
        local gameEvent = VGameEvent("triggerWithoutArgsEvent");
        gameEvent.AddAction(function() : (counter) {
            counter[0]++;
        });
        gameEvent.Trigger();
        gameEvent.Trigger();
        return assert(counter[0] == 2);
    },

    function vGameEventArgsNotMutatedTest() {
        local args = ["data"];
        local gameEvent = VGameEvent("argsNotMutatedEvent");
        gameEvent.AddAction(function(data) {});
        gameEvent.Trigger(args);
        gameEvent.ForceTrigger(args);
        return assert(args.len() == 1);
    },
};

// Run all tests
RunTests("ScriptEvents", scriptEventsTests);