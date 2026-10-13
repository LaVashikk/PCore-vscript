/*
 * Settings for bbox traces (TracePlus.Bbox, TracePlus.PortalBbox): class and model filters, custom filter
 * functions and analyzer options. Create instances with TracePlus.Settings.new().
*/
TracePlus["Settings"] <- class {
    id = null; // todo: dont used!
    ignoreAllClasses = false; 
    
    // Entity classnames to ignore during traces. An entry matches every classname that contains it; "*" ignores all classes.
    ignoreClasses = ArrayEx("viewmodel", "weapon_", "beam", "light",
        "trigger_", "phys_", "env_", "point_", "info_", "vgui_", "logic_",
        "clone", "prop_portal", "portal_base2D", "func_clip", "func_instance",
        "func_portal_detector", "func_noportal_volume", "func_portal_bumper",
        "func_areaportalwindow", "path_track", "npc_bullseye", "move_rope", "keyframe_rope",
        "worldspawn", "soundent", "player_manager", "bodyque", "ai_network", "generic_actor"
    );
    // Entity classnames that are hit even if they match ignoreClasses; matched the same way.
    priorityClasses = ArrayEx();
    // Entity model names to ignore during traces. An entry matches every model name that contains it.
    ignoredModels = ArrayEx();
    // Undocumented, you normally never need to change it! A trace starting inside one of these is hit right at the start
    // instead of skipping it: a cube stuck in a portal contains the start of the cast that comes out of that portal
    hitInsideClasses = ArrayEx("prop_weighted_cube", "prop_monster_box", "npc_portal_turret_floor", "prop_physics");


    // A custom function to determine if a ray should hit an entity, see SetCollisionFilter.
    shouldRayHitEntity = null;
    // A custom function to determine if an entity should be ignored during a trace, see SetIgnoreFilter.
    shouldIgnoreEntity = null;

    // classname / model name -> ignored, filled by the analyzer. The lists only change through Set*/Append*, which drop these
    classCache = null;
    modelCache = null;

    /*
     * Creates settings with the default lists. Use TracePlus.Settings.new() instead.
    */
    constructor() {
        // Class members are shared by every instance, so each one gets its own lists
        this.ignoreClasses = this.ignoreClasses.Clone()
        this.priorityClasses = this.priorityClasses.Clone()
        this.ignoredModels = this.ignoredModels.Clone()
        this.classCache = {}
        this.modelCache = {}
    }

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

        // A copy, so changing the caller's array later can't get past the caches
        this.ignoreClasses = ArrayEx.FromArray(ignoreClassesArray).Clone()
        this.ignoreAllClasses = this.ignoreClasses.contains("*")
        this.classCache = {}

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

        this.priorityClasses = ArrayEx.FromArray(priorityClassesArray).Clone()
        this.classCache = {}
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

        this.ignoredModels = ArrayEx.FromArray(ignoredModelsArray).Clone()
        this.modelCache = {}
        return this
    }

    /*
     * Appends an entity classname to the list of ignored classes.
     *
     * @param {string} className - The classname to append.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function AppendIgnoredClass(className) {
        if(typeof className != "string") throw("TracePlus.Settings.AppendIgnoredClass: Invalid argument type. Expected a 'string', but got " + typeof className)

        this.ignoreClasses.append(className)
        if(className == "*") this.ignoreAllClasses = true // todo: this can be invalidated if something modify ignoreClasses not from methods
        this.classCache = {}

        return this
    }

    /*
     * Appends an entity classname to the list of priority classes.
     *
     * @param {string} className - The classname to append.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function AppendPriorityClasses(className) {
        if(typeof className != "string") throw("TracePlus.Settings.AppendPriorityClasses: Invalid argument type. Expected a 'string', but got " + typeof className)

        this.priorityClasses.append(className)
        this.classCache = {}
        return this
    }

    /*
     * Appends an entity model name to the list of ignored models.
     *
     * @param {string} modelName - The model name to append.
     * @returns {TraceSettings} - This settings object, for chaining.
    */
    function AppendIgnoredModel(modelName) {
        if(typeof modelName != "string") throw("TracePlus.Settings.AppendIgnoredModel: Invalid argument type. Expected a 'string', but got " + typeof modelName)

        this.ignoredModels.append(modelName)
        this.modelCache = {}
        return this
    }

    /*
     * Gets a copy of the list of entity classnames to ignore during traces. Change the list with Set/Append.
     *
     * @returns {ArrayEx} - A copy of the ignored classnames.
    */
    function GetIgnoreClasses() {
        return this.ignoreClasses.Clone()
    }

    /*
     * Gets a copy of the list of entity classnames to prioritize during traces. Change the list with Set/Append.
     *
     * @returns {ArrayEx} - A copy of the priority classnames.
    */
    function GetPriorityClasses() {
        return this.priorityClasses.Clone()
    }

    /*
     * Gets a copy of the list of entity model names to ignore during traces. Change the list with Set/Append.
     *
     * @returns {ArrayEx} - A copy of the ignored model names.
    */
    function GetIgnoredModels() {
        return this.ignoredModels.Clone()
    }

    /*
     * Checks a classname against the class lists: it is ignored if it matches ignoreClasses (or "*" is there)
     * and no priority class. Cached per classname until the class lists change.
    */
    function _isClassIgnored(classname) {
        if(classname in this.classCache) return this.classCache[classname]

        local ignored = (this.ignoreAllClasses || _matchesAny(this.ignoreClasses, classname)) && !_matchesAny(this.priorityClasses, classname)
        this.classCache[classname] <- ignored
        return ignored
    }

    /*
     * Checks a model name against ignoredModels. An empty model name is never ignored.
     * Cached per model name until the model list changes.
    */
    function _isModelIgnored(modelname) {
        if(modelname == "") return false
        if(modelname in this.modelCache) return this.modelCache[modelname]

        local ignored = _matchesAny(this.ignoredModels, modelname)
        this.modelCache[modelname] <- ignored
        return ignored
    }

    // See hitInsideClasses. Not cached: it only runs for entities the trace starts inside of
    function _isHitInside(classname) {
        return _matchesAny(this.hitInsideClasses, classname)
    }

    // True if `name` contains one of the masks
    function _matchesAny(list, name) {
        foreach(mask in list.arr)
            if(name.find(mask) != null) return true
        return false
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
     * Creates a copy of these settings. The class and model lists are copied, the filter functions are shared.
     *
     * @returns {TraceSettings} - The copy.
    */
    function Clone() {
        return clone this
    }

    // Squirrel calls it on the fresh shallow copy, which still shares the lists and caches with `original`
    function _cloned(original) {
        this.ignoreClasses = original.ignoreClasses.Clone()
        this.priorityClasses = original.priorityClasses.Clone()
        this.ignoredModels = original.ignoredModels.Clone()
        this.classCache = {}
        this.modelCache = {}
    }

    function _typeof() return "TraceSettings"
}