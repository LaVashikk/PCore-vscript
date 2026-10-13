/*
 * Settings for bbox traces (TracePlus.Bbox, TracePlus.PortalBbox): class and model filters, custom filter
 * functions and analyzer options. Create instances with TracePlus.Settings.new().
*/
TracePlus["Settings"] <- class {
    id = null;
    ignoreAllClasses = false; // TODO: start using this optimization!!!!
    
    // Entity classnames to ignore during traces. An entry matches every classname that contains it; "*" ignores all classes.
    // todo: remove edict-less ents from here!
    ignoreClasses = ArrayEx("viewmodel", "weapon_", "beam", "light",
        "trigger_", "phys_", "env_", "point_", "info_", "vgui_", "logic_",
        "clone", "prop_portal", "portal_base2D", "func_clip", "func_instance",
        "func_portal_detector", 
        "worldspawn", "soundent", "player_manager", "bodyque", "ai_network"
    );
    // Entity classnames that are hit even if they match ignoreClasses; matched the same way.
    priorityClasses = ArrayEx();
    // Entity model names to ignore during traces. An entry matches every model name that contains it.
    ignoredModels = ArrayEx();


    // A custom function to determine if a ray should hit an entity, see SetCollisionFilter.
    shouldRayHitEntity = null;
    // A custom function to determine if an entity should be ignored during a trace, see SetIgnoreFilter.
    shouldIgnoreEntity = null;

    /*
     * Creates a new TraceSettings object with default values or from a table of settings.
     *
     * Keys: ignoreClasses, priorityClasses, ignoredModels (array or ArrayEx), shouldRayHitEntity, shouldIgnoreEntity
     * (functions). A given list replaces the default one; to extend the default
     * ignored classes, use AppendIgnoredClass instead.
     *
     * @param {table} settingsTable - A table containing settings to override the defaults. (optional)
     * @returns {TraceSettings} - A new TraceSettings object.
    */
    function new(settingsTable = {}) {
        local result = TracePlus.Settings()
        result.id = UniqueString("TracePlus")

        result.SetIgnoredClasses(macros.GetFromTable(settingsTable, "ignoreClasses", TracePlus.Settings.ignoreClasses))
        result.SetPriorityClasses(macros.GetFromTable(settingsTable, "priorityClasses", TracePlus.Settings.priorityClasses))
        result.SetIgnoredModels(macros.GetFromTable(settingsTable, "ignoredModels", TracePlus.Settings.ignoredModels))
        
        result.SetCollisionFilter(macros.GetFromTable(settingsTable, "shouldRayHitEntity", null))
        result.SetIgnoreFilter(macros.GetFromTable(settingsTable, "shouldIgnoreEntity", null))
        
        return result
    }


    /*
     * Sets the list of entity classnames to ignore during traces.
     *
     * @param {array|ArrayEx} ignoreClassesArray - An array or ArrayEx containing entity classnames to ignore.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function SetIgnoredClasses(ignoreClassesArray) {
        if(typeof ignoreClassesArray != "array" && typeof ignoreClassesArray != "ArrayEx") throw("TracePlus.Settings.SetIgnoredClasses: Invalid argument type. Expected an 'array' or 'ArrayEx', but got " + typeof ignoreClassesArray)

        this.ignoreClasses = ArrayEx.FromArray(ignoreClassesArray)
        this.ignoreAllClasses = this.ignoreClasses && this.ignoreClasses.contains("*")
        
        return this
    }

    /*
     * Sets the list of entity classnames to prioritize during traces.
     *
     * @param {array|ArrayEx} priorityClassesArray - An array or ArrayEx containing entity classnames to prioritize.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function SetPriorityClasses(priorityClassesArray) {
        if(typeof priorityClassesArray != "array" && typeof priorityClassesArray != "ArrayEx") throw("TracePlus.Settings.SetPriorityClasses: Invalid argument type. Expected an 'array' or 'ArrayEx', but got " + typeof priorityClassesArray)

        this.priorityClasses = ArrayEx.FromArray(priorityClassesArray)
        return this
    }

    /*
     * Sets the list of entity model names to ignore during traces.
     *
     * @param {array|ArrayEx} ignoredModelsArray - An array or ArrayEx containing entity model names to ignore.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function SetIgnoredModels(ignoredModelsArray) {
        if(typeof ignoredModelsArray != "array" && typeof ignoredModelsArray != "ArrayEx") throw("TracePlus.Settings.SetIgnoredModels: Invalid argument type. Expected an 'array' or 'ArrayEx', but got " + typeof ignoredModelsArray)

        this.ignoredModels = ArrayEx.FromArray(ignoredModelsArray)
        return this
    }

    /*
     * Appends an entity classname to the list of ignored classes. A list still shared with the defaults is copied first.
     *
     * @param {string} className - The classname to append.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function AppendIgnoredClass(className) {
        if(typeof className != "string") throw("TracePlus.Settings.AppendIgnoredClass: Invalid argument type. Expected a 'string', but got " + typeof className)

        // CoW Mechanism
        if(this.ignoreClasses == TracePlus.Settings.ignoreClasses)
            this.ignoreClasses = this.ignoreClasses.Clone()
        
        this.ignoreClasses.append(className)
        this.ignoreAllClasses = this.ignoreClasses && this.ignoreClasses.contains("*")
        
        return this
    }

    /*
     * Appends an entity classname to the list of priority classes. A list still shared with the defaults is copied first.
     *
     * @param {string} className - The classname to append.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function AppendPriorityClasses(className) {
        if(typeof className != "string") throw("TracePlus.Settings.AppendPriorityClasses: Invalid argument type. Expected a 'string', but got " + typeof className)

        // CoW Mechanism
        if(this.priorityClasses == TracePlus.Settings.priorityClasses)
            this.priorityClasses = this.priorityClasses.Clone()
        
        this.priorityClasses.append(className)
        return this
    }

    /*
     * Appends an entity model name to the list of ignored models. A list still shared with the defaults is copied first.
     *
     * @param {string} modelName - The model name to append.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function AppendIgnoredModel(modelName) {
        if(typeof modelName != "string") throw("TracePlus.Settings.AppendIgnoredModel: Invalid argument type. Expected a 'string', but got " + typeof modelName)

        // CoW Mechanism
        if(this.ignoredModels == TracePlus.Settings.ignoredModels)
            this.ignoredModels = this.ignoredModels.Clone()

        this.ignoredModels.append(modelName)
        return this
    }

    /* 
     * Gets the list of entity classnames to ignore during traces. 
     *
     * @returns {ArrayEx} - An ArrayEx containing the ignored classnames. 
    */
    function GetIgnoreClasses() {
        return this.ignoreClasses
    }

    /*
     * Gets the list of entity classnames to prioritize during traces. 
     *
     * @returns {ArrayEx} - An ArrayEx containing the priority classnames. 
    */
    function GetPriorityClasses() {
        return this.priorityClasses
    }

    /*
     * Gets the list of entity model names to ignore during traces. 
     *
     * @returns {ArrayEx} - An ArrayEx containing the ignored model names. 
    */
    function GetIgnoredModels() {
        return this.ignoredModels
    }

    /*
     * Sets a custom function to determine if a ray should hit an entity.
     * It is called with the candidate entity (a CBaseEntity); returning true lets the ray hit it
     * regardless of the ignored classes and models. The ignore filter is checked first.
     *
     * @param {function|null} filterFunction - The filter function to set, or null to remove it.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function SetCollisionFilter(filterFunction) { // aka. SetHitFilter
        this.shouldRayHitEntity = filterFunction
        return this
    }

    /*
     * Sets a custom function to determine if an entity should be ignored during a trace.
     * It is called with the candidate entity (a CBaseEntity); returning true makes the trace ignore it.
     *
     * @param {function|null} filterFunction - The filter function to set, or null to remove it.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function SetIgnoreFilter(filterFunction) {
        this.shouldIgnoreEntity = filterFunction
        return this
    }

    /*
     * Gets the custom collision filter function. 
     *
     * @returns {function|null} - The collision filter function, or null if not set. 
    */
    function GetCollisionFilter() {
        return this.shouldRayHitEntity
    }

    /*
     * Gets the custom ignore filter function. 
     *
     * @returns {function|null} - The ignore filter function, or null if not set. 
    */
    function GetIgnoreFilter() {
        return this.shouldIgnoreEntity
    }

    /*
     * Applies the custom collision filter function to an entity.
     *
     * @param {CBaseEntity} entity - The entity to check, passed to the filter as is.
     * @returns {boolean} - The result of the filter, or false if no filter is set.
    */
    function ApplyCollisionFilter(entity) {
        return this.shouldRayHitEntity ? this.shouldRayHitEntity(entity) : false
    }

    /*
     * Applies the custom ignore filter function to an entity.
     *
     * @param {CBaseEntity} entity - The entity to check, passed to the filter as is.
     * @returns {boolean} - The result of the filter, or false if no filter is set.
    */
    function ApplyIgnoreFilter(entity) {
        return this.shouldIgnoreEntity ? this.shouldIgnoreEntity(entity) : false
    }

    /*
     * Adds an entity to an ignoreEntities value: null gives the entity itself, an array or ArrayEx
     * gets it appended in place, and a single entity is returned as a new array [newEnt, ignoreEntities].
     *
     * @param {array|ArrayEx|CBaseEntity|pcapEntity|null} ignoreEntities - The current entities to ignore.
     * @param {CBaseEntity|pcapEntity} newEnt - The entity to add.
     * @returns {array|ArrayEx|CBaseEntity|pcapEntity} - The updated value: `newEnt`, the same array, or a new array.
    */
    function UpdateIgnoreEntities(ignoreEntities, newEnt) {
        if (ignoreEntities) {
            if (typeof ignoreEntities == "array" || typeof ignoreEntities == "ArrayEx") {
                ignoreEntities.append(newEnt)
            }
            else {
                ignoreEntities = [newEnt, ignoreEntities]
            }
        }
        else {
            ignoreEntities = newEnt
        }

        return ignoreEntities
    }

    /*
     * Creates a copy of these settings. The class and model lists are copied, the filter functions are shared.
     *
     * @returns {TraceSettings} - The copy.
    */
    function Clone() {
        local set = TracePlus.Settings()
            .SetIgnoredClasses(this.ignoreClasses.Clone())
            .SetPriorityClasses(this.priorityClasses.Clone())
            .SetIgnoredModels(this.ignoredModels.Clone())
            .SetCollisionFilter(this.shouldRayHitEntity)
            .SetIgnoreFilter(this.shouldIgnoreEntity)
        set.id = this.id
        return set
    }

    function _typeof() return "TraceSettings"
    function _cloned() return this.Clone()
}