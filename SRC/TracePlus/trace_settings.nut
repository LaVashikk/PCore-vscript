/*
 * Settings for bbox traces (TracePlus.Bbox, TracePlus.PortalBbox), built with chained calls:
 * TracePlus.Settings().IgnoreClasses("func_").ExceptClasses("func_brush")
 *
 * An entity is checked in this order, the first match decides:
 * 1. The ignore filter returns true: ignored.
 * 2. The hit filter returns true: hit.
 * 3. The classname matches IgnoreClasses and not ExceptClasses: ignored.
 * 4. The model name matches IgnoreModels: ignored.
 * 5. Otherwise: hit.
 *
 * A mask matches every name that contains it. "*" alone ignores all classes, a "*" at the ends of a longer mask is dropped.
 * All methods but the getters return the settings themselves, so calls chain
*/
TracePlus["Settings"] <- class {
    // Classname masks to ignore during traces
    ignoredClasses = ArrayEx("viewmodel", "weapon_", "beam", "light",
        "trigger_", "phys_", "env_", "point_", "info_", "vgui_", "logic_",
        "clone", "prop_portal", "portal_base2D", "func_clip", "func_instance",
        "func_portal_detector", "func_noportal_volume", "func_portal_bumper",
        "func_areaportalwindow", "path_track", "npc_bullseye", "move_rope", "keyframe_rope",
        "worldspawn", "soundent", "player_manager", "bodyque", "ai_network", "generic_actor"
    );
    // Classname masks that are hit even if they match ignoredClasses: the other side of the same rule
    exceptedClasses = ArrayEx();
    // Model name masks to ignore during traces
    ignoredModels = ArrayEx();
    // "*" is in ignoredClasses, no find over the list needed
    ignoreAllClasses = false;
    // Undocumented, you normally never need to change it! A trace starting inside one of these is hit right at the start
    // instead of skipping it: a cube stuck in a portal contains the start of the cast that comes out of that portal
    hitInsideClasses = ArrayEx("prop_weighted_cube", "prop_monster_box", "npc_portal_turret_floor", "prop_physics");

    // See SetIgnoreFilter and SetHitFilter
    ignoreFilter = null;
    hitFilter = null;

    // classname / model name -> ignored, filled by the analyzer. The lists only change through the methods, which drop these
    classCache = null;
    modelCache = null;

    /*
     * Creates settings with the default ignored classes.
    */
    constructor() {
        // Class members are shared by every instance, so each one gets its own lists
        this.ignoredClasses = this.ignoredClasses.Clone()
        this.exceptedClasses = this.exceptedClasses.Clone()
        this.ignoredModels = this.ignoredModels.Clone()
        this.classCache = {}
        this.modelCache = {}
    }


    /*
     * Adds classname masks to ignore. Takes any number of strings, arrays and ArrayEx of strings.
     * "*" ignores every class, see IgnoreAllClasses.
    */
    function IgnoreClasses(...) {
        for(local i = 0; i < vargc; i++)
            _addMasks(this.ignoredClasses, vargv[i], "IgnoreClasses")
        this.ignoreAllClasses = this.ignoredClasses.contains("*")
        this.classCache = {}
        return this
    }

    /*
     * Adds classname masks to hit even if IgnoreClasses matches them: IgnoreClasses("func_").ExceptClasses("func_brush").
     * Only works against the ignored classes, an ignored model or the ignore filter still wins.
     * Takes any number of strings, arrays and ArrayEx of strings.
    */
    function ExceptClasses(...) {
        for(local i = 0; i < vargc; i++)
            _addMasks(this.exceptedClasses, vargv[i], "ExceptClasses")
        this.classCache = {}
        return this
    }

    /*
     * Ignores every class, so only ExceptClasses (and the hit filter) let entities through.
    */
    function IgnoreAllClasses() { // todo: maybe make it toggable?
        return this.IgnoreClasses("*")
    }

    /*
     * Removes all ignored classes, the defaults too (triggers, env_, info_, prop_portal...).
     * To hit just a few of them, ExceptClasses is usually what you want.
    */
    function ClearIgnoredClasses() {
        this.ignoredClasses = ArrayEx()
        this.ignoreAllClasses = false
        this.classCache = {}
        return this
    }

    /*
     * Removes all excepted classes.
    */
    function ClearExceptedClasses() {
        this.exceptedClasses = ArrayEx()
        this.classCache = {}
        return this
    }

    /*
     * Adds model name masks to ignore. Takes any number of strings, arrays and ArrayEx of strings.
    */
    function IgnoreModels(...) {
        for(local i = 0; i < vargc; i++)
            _addMasks(this.ignoredModels, vargv[i], "IgnoreModels")
        this.modelCache = {}
        return this
    }

    /*
     * Removes all ignored models.
    */
    function ClearIgnoredModels() {
        this.ignoredModels = ArrayEx()
        this.modelCache = {}
        return this
    }

    /*
     * Sets the ignore filter. It is called with the candidate entity (pcapEntity): true ignores it, whatever the rest
     * of the settings says. null removes the filter.
    */
    function SetIgnoreFilter(filterFunction) {
        this.ignoreFilter = filterFunction
        return this
    }

    /*
     * Sets the hit filter. It is called with the candidate entity (pcapEntity): true hits it even if the ignored
     * classes or models match it, false leaves it to them. The ignore filter goes first. null removes the filter.
     * With a hit filter, ignored classes can no longer be skipped early, so the trace costs more.
    */
    function SetHitFilter(filterFunction) {
        this.hitFilter = filterFunction
        return this
    }

    /*
     * Gets a copy of the ignored classname masks.
     *
     * @returns {ArrayEx} - A copy of the list.
    */
    function GetIgnoredClasses() {
        return this.ignoredClasses.Clone()
    }

    /*
     * Gets a copy of the excepted classname masks.
     *
     * @returns {ArrayEx} - A copy of the list.
    */
    function GetExceptedClasses() {
        return this.exceptedClasses.Clone()
    }

    /*
     * Gets a copy of the ignored model name masks.
     *
     * @returns {ArrayEx} - A copy of the list.
    */
    function GetIgnoredModels() {
        return this.ignoredModels.Clone()
    }

    /*
     * Gets the ignore filter function, or null.
    */
    function GetIgnoreFilter() {
        return this.ignoreFilter
    }

    /*
     * Gets the hit filter function, or null.
    */
    function GetHitFilter() {
        return this.hitFilter
    }

    /*
     * Creates a copy of these settings. The lists are copied, the filter functions are shared.
    */
    function Clone() {
        return clone this
    }

    function _cloned(original) {
        this.ignoredClasses = original.ignoredClasses.Clone()
        this.exceptedClasses = original.exceptedClasses.Clone()
        this.ignoredModels = original.ignoredModels.Clone()
        this.classCache = {}
        this.modelCache = {}
    }

    // Appends one argument of the mask methods: a string, or an array/ArrayEx of them
    function _addMasks(list, arg, caller) {
        local type = typeof arg
        if(type == "string") {
            list.append(_normalizeMask(arg, caller))
            return
        }
        if(type != "array" && type != "ArrayEx") throw("TracePlus.Settings." + caller + ": expected strings, arrays or ArrayEx, but got " + type)

        foreach(mask in (type == "ArrayEx" ? arg.arr : arg)) {
            if(typeof mask != "string") throw("TracePlus.Settings." + caller + ": expected string masks, but got " + typeof mask)
            list.append(_normalizeMask(mask, caller))
        }
    }

    // Masks are substrings, so "prop_*" would never match anything: the stars at the ends go. "*" alone stays, it's the ignore-all marker
    function _normalizeMask(mask, caller) {
        if(mask.len() < 2) return mask

        local s = 0
        local e = mask.len()
        while(s < e && mask[s] == '*') s++
        while(e > s && mask[e - 1] == '*') e--
        
        local trimmed = mask.slice(s, e)
        if(trimmed.find("*") != null) throw("TracePlus.Settings." + caller + ": \"*\" only works at the ends of a mask, got \"" + mask + "\"")
        if(trimmed == "") return "*"

        return trimmed
    }

    /*
     * Checks a classname against the class lists: it is ignored if it matches ignoredClasses (or "*" is there)
     * and no excepted class. Cached per classname until the class lists change.
    */
    function _isClassIgnored(classname) {
        if(classname in this.classCache) return this.classCache[classname]

        local ignored = (this.ignoreAllClasses || _matchesAny(this.ignoredClasses, classname)) && !_matchesAny(this.exceptedClasses, classname)
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

    function _typeof() return "TraceSettings"
}
