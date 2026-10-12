/*+--------------------------------------------------------------------------------+
|                           PCapture Vscripts Library                              |
+----------------------------------------------------------------------------------+
| Author:                                                                          |
|     Animation Alchemist - laVashik ¬_¬                                           |
+----------------------------------------------------------------------------------+ 
|       The Animations module, simplifying the creation of smooth and dynamic      |
|       animations for alpha, color, and object movement in your VScripts.         |
+----------------------------------------------------------------------------------+ */

::animate <- {
    RT = {}
}

::AnimEvent <- class {
    animName = null;
    eventName = null
    delay = 0
    globalDelay = 0
    frameInterval = 0
    maxFrames = 60.0
    autoOptimization = true
    output = null
    entities = []
    easeFunc = null;
    filterCallback = null;
    scope = null;

    /*
     * Constructor for an AnimEvent object.
     *
     * @param {string} name - The animation type, used in the default event name and in log messages.
     * @param {table} table - The animation settings, see the Animation Settings Table in the Animations readme.
     * @param {string|array|ArrayEx|List|CBaseEntity|pcapEntity} ents - The entities to animate, or a targetname; with a trailing `*` (e.g. "door_*") every matching entity is animated.
     * @param {number} time - The duration of the animation in seconds. (optional, default=0)
    */
    constructor(name, table, ents, time = 0) {
        this.animName = name
        local processAsRawEnt = macros.GetFromTable(table, "rawEnt", false)
        
        this.entities = processAsRawEnt ? ents : _GetEntities(ents, name)
        this.delay = time
        
        this.eventName = macros.GetFromTable(table, "eventName", UniqueString(name + "_anim"))
        this.globalDelay = macros.GetFromTable(table, "globalDelay", 0)
        this.output = macros.GetFromTable(table, "output", null)
        this.scope = macros.GetFromTable(table, "scope", null)
        this.easeFunc = macros.GetFromTable(table, "ease", function(t) return t)
        this.filterCallback = macros.GetFromTable(table, "filterCallback", function(a,b,c,d,e) return null)
        this.frameInterval = macros.GetFromTable(table, "frameInterval", FrameTime()).tofloat()
        this.maxFrames = macros.GetFromTable(table, "fps", 60.0).tofloat()
        this.autoOptimization = macros.GetFromTable(table, "optimization", true)

        if(this.frameInterval == 0) throw("frameInterval is not to have 0")

        // A root-table scope would create a circular reference, so null is stored instead.
        if(this.scope == getroottable()) {
            this.scope = null
        }
    } 

    /*
     * Schedules `output` in the animation's event after `delay + globalDelay` seconds, with `scope` as `this`.
     * Does nothing if no output is set.
    */
    function CallOutput() {
        if(this.output)
            ScheduleEvent.Add(this.eventName, this.output, this.delay + this.globalDelay, null, this.scope)
    }

    function _GetEntities(entities, actionName) {
        local type_of = typeof entities;
        if (type_of == "string") {
            local foundEnts = ArrayEx();
            if(entities.find("*") == null) {
                local ent = entLib.FindByName(entities);
                if (!ent) dev.warning(actionName + " AnimEvent: Could not find entity with name '" + entities + "'");
                else foundEnts.append(ent);
            }
            else {
                for(local ent; ent = entLib.FindByName(entities, ent);)
                    foundEnts.append(ent)
                if (foundEnts.len() == 0) dev.warning(actionName + " AnimEvent: Could not find any entities matching name pattern '" + entities + "'");
            }
            return foundEnts;
        }

        if (type_of == "List") {
            entities = entities.toarray()
            type_of = typeof entities;
        }  
        
        if (type_of == "array" || type_of == "ArrayEx") {
            foreach(idx, entity in entities) {
                if (!entity || !entity.IsValid()) {
                    dev.warning(actionName + " AnimEvent: An invalid or null entity was found in the 'entities' list at index " + idx);
                    continue;
                }
                if(typeof entity != "pcapEntity") 
                    entities[idx] = entLib.FromEntity(entity)
            }
            return entities
        }

        if (!entities || !entities.IsValid()) throw("AnimEvent: The provided 'entities' argument is not a valid entity.");

        if (type_of != "pcapEntity")
            return [entLib.FromEntity(entities)]
        
        return [entities]
    } 
}

/*
 * Applies an animation over a specified duration, calculating and setting new values for a property at each frame.
 *
 * All frames are computed up front and scheduled in the `animInfo.eventName` event, one action per entity per frame.
 * `animInfo.delay` is then set to the resulting duration, and the output is scheduled at the end.
 *
 * @param {AnimEvent} animInfo - The AnimEvent object containing the animation settings and entities.
 * @param {function} valueCalculator - A function that calculates the new value for the property at each frame.
 *    This function should take three arguments:
 *        * `step`: The current frame number (starting from 0).
 *        * `transitionFrames`: The number of the last frame, so `step / transitionFrames` goes from 0 to 1.
 *        * `vars`: Optional variables passed through the `vars` parameter.
 * @param {function} propertySetter - A function that sets the new value for the property on each entity.
 *    This function should take two arguments:
 *        * `entity`: The entity to apply the value to.
 *        * `newValue`: The calculated new value for the property.
 * @param {any} vars - Optional variable to pass to the `valueCalculator` function.
 * @param {number} transitionFrames - The number of the last frame, rounded up.
 *    If 0, it's calculated based on `animInfo.delay` and `animInfo.frameInterval`. (default: 0)
*/
animate["applyAnimation"] <- function(animInfo, valueCalculator, propertySetter, vars = null, transitionFrames = 0) {
    if(transitionFrames == 0) {
        if (animInfo.autoOptimization && animInfo.delay / animInfo.frameInterval > animInfo.maxFrames)  
            animInfo.frameInterval = animInfo.delay / animInfo.maxFrames
        
        transitionFrames = animInfo.delay / animInfo.frameInterval;
    }

    transitionFrames = ceil(transitionFrames) 
    local actionsList = List()

    for(local step = 0; step <= transitionFrames; step++) {
        local elapsed = (animInfo.frameInterval * step) + animInfo.globalDelay

        local newValue = valueCalculator(step, transitionFrames, vars)
        
        foreach(ent in animInfo.entities) {
            local action = ScheduleAction(this, propertySetter, elapsed, [ent, newValue])
            actionsList.append(action)
        }
    }

    ScheduleEvent.AddActions(animInfo.eventName, actionsList, true)
    animInfo.delay = animInfo.frameInterval * transitionFrames
    animInfo.CallOutput()

    if(developer() > 0) dev.trace("Created {} animation ({}) for {} actions", animInfo.animName, animInfo.eventName, actionsList.len())
}

/*
 * Applies an animation in real time: after `globalDelay`, each frame is computed and applied when it is due
 * (see `_processRTStep`) instead of being scheduled up front, and `filterCallback` can stop the animation.
 * `animInfo.delay` is set to the animation duration.
 *
 * The arguments are the same as those for `applyAnimation`.
*/
animate["applyRTAnimation"] <- function(animInfo, valueCalculator, propertySetter, vars = null, transitionFrames = 0) {
    if(transitionFrames == 0) {
        if (animInfo.maxFrames * 10 != 600)  
            animInfo.frameInterval = animInfo.delay / animInfo.maxFrames
        
        transitionFrames = animInfo.delay / animInfo.frameInterval;
    }

    ScheduleEvent.Add(
        animInfo.eventName, 
        animate._applyRTAnimation, 
        animInfo.globalDelay, 
        [animInfo, valueCalculator, propertySetter, vars, transitionFrames], 
        this
    )

    animInfo.delay = animInfo.frameInterval * transitionFrames
}

/*
 * Starts a real-time animation scheduled by `applyRTAnimation`: rounds the frame count up and applies
 * frame 0 through `_processRTStep`.
*/
animate["_applyRTAnimation"] <- function(animInfo, valueCalculator, propertySetter, vars, transitionFrames) {
    transitionFrames = ceil(transitionFrames);
    if (developer() > 0) dev.trace("Started {} realtime animation ({})", animInfo.animName, animInfo.eventName);

    animate._processRTStep(0, animInfo, valueCalculator, propertySetter, vars, transitionFrames);
};

/*
 * Applies one frame of a real-time animation and schedules the next one `frameInterval` later
 * in the animation's event. After the last frame it fires the output.
 * Before a frame is applied, `filterCallback(animInfo, newValue, transitionFrames, step, vars)` is called;
 * if it returns true, the animation stops without firing the output.
 *
 * @param {number} step - The frame to apply, starting from 0.
 * @param {AnimEvent} animInfo - The animation.
 * @param {function} valueCalculator - Computes the value of a frame, see `applyAnimation`.
 * @param {function} propertySetter - Applies the value to one entity, see `applyAnimation`.
 * @param {any} vars - Passed to `valueCalculator` and `filterCallback`.
 * @param {number} transitionFrames - The number of the last frame.
*/
animate["_processRTStep"] <- function(step, animInfo, valueCalculator, propertySetter, vars, transitionFrames) {
    // Past the last frame: zero the delays so that CallOutput fires the output now.
    if (step > transitionFrames) {
        animInfo.delay = 0;
        animInfo.globalDelay = 0;
        animInfo.CallOutput();
        return;
    }

    local newValue = valueCalculator(step, transitionFrames, vars);

    if (animInfo.filterCallback(animInfo, newValue, transitionFrames, step, vars)) {
        return;
    }

    foreach(ent in animInfo.entities)
        propertySetter(ent, newValue)

    ScheduleEvent.Add(
        animInfo.eventName,
        animate._processRTStep,
        animInfo.frameInterval,
        [++step, animInfo, valueCalculator, propertySetter, vars, transitionFrames],
        animate
    );
}



IncludeScript("PCapture-LIB/SRC/Animations/alpha")
IncludeScript("PCapture-LIB/SRC/Animations/color")
IncludeScript("PCapture-LIB/SRC/Animations/position")
IncludeScript("PCapture-LIB/SRC/Animations/angles")
