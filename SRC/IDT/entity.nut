/*
 * Wrapper around an entity handle, which is kept in `CBaseEntity`.
 * Get instances through entLib (FromEntity, Create*, Find*): it keeps one cached wrapper per entity.
*/
::pcapEntity <- class {
    CBaseEntity = null;

    /*
     * Wraps an entity and stores the wrapper as `selfEx` in the entity's script scope.
     * Use entLib.FromEntity instead of calling it directly: it returns the cached wrapper.
     *
     * @param {CBaseEntity|pcapEntity} entity - The entity to wrap. A pcapEntity is unwrapped first.
    */
    constructor(entity) { 
        if (!entity || !entity.IsValid()) throw("pcapEntity: invalid entity");
        if(typeof entity == "pcapEntity")
            entity = entity.CBaseEntity

        this.CBaseEntity = entity
        EntitiesScopes[this.CBaseEntity] <- {}
        entity.ValidateScriptScope()
        entity.GetScriptScope().selfEx <- this // todo: no docs about it
    }

    /*
     * Sets the angles of the entity from a Vector.
     *
     * @param {Vector} angles - Pitch, yaw and roll.
    */
    function SetAngles2(angles) {
        this.CBaseEntity.SetAngles(angles.x, angles.y, angles.z)
    }


    // Destroys the entity. 
    function Destroy(fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.Destroy, fireDelay, null, this)
        
        if(!this.CBaseEntity || !this.CBaseEntity.IsValid()) return
        this.CBaseEntity.Destroy()
        this.CBaseEntity = null
    }


    /*
     * Kills the entity through the "Kill" input.
     * Does nothing if the entity is already invalid.
     *
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function Kill(fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.Kill, fireDelay, null, this)

        if(!this.CBaseEntity || !this.CBaseEntity.IsValid()) return
        EntFireByHandle(this.CBaseEntity, "kill")
        this.CBaseEntity = null
    }


    /*
     * Dissolves the entity through the shared env_entity_dissolver (`dissolver`).
     * Once it has run, IsValid() returns false. The dissolver finds its target by targetname, so an entity
     * without one, or with one shared by other entities, is renamed to a unique one first.
     *
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function Dissolve(fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.Dissolve, fireDelay, null, this)

        if(!dissolver || !dissolver.IsValid()) throw("The entity 'dissolver' is missing, the Dissolve method will not work.")
        if(this.GetName() == "")
            this.SetUniqueName("targetname")
        for(local entity; entity = Entities.FindByName(entity, this.GetName()); ) if(!macros.IsEqual(this, entity)) {
            this.SetUniqueName()
            break
        }

        dissolver.SetKeyValue("target", this.GetName())
        EntFireByHandle(dissolver, "dissolve")

        this.SetUserData("Dissolved", true)
    }


    /*
     * Checks whether the entity still exists and has not been killed, destroyed or dissolved through this wrapper.
     *
     * @returns {bool|null} - True if the entity is valid. False otherwise, or null after Kill or Destroy.
    */
    function IsValid() {
        return this.CBaseEntity && this.CBaseEntity.IsValid() && !this.GetUserData("Dissolved")
    }


    /*
     * Checks whether the entity is a player (classname "player").
     *
     * @returns {bool} - True if the entity is a player, false otherwise.
    */
    function IsPlayer() {
        return this.CBaseEntity.GetClassname() == "player"
    }

    /*
     * Gets the eye position of a player. For any other entity, returns GetCenter().
     *
     * @returns {Vector} - The position in world coordinates.
    */
     function EyePosition() {
        if(this.IsPlayer()) return this.CBaseEntity.EyePosition()
        return this.GetCenter()
    }

    /*
     * Gets the view angles of a player. For any other entity, returns GetAngles().
     *
     * @returns {Vector} - Pitch, yaw and roll.
    */
    function EyeAngles() {
        if(this.IsPlayer()) return this.GetUserData("Eye").GetAngles()
        return this.GetAngles()
    }

    /*
     * Gets the direction a player is looking in. For any other entity, returns GetForwardVector().
     *
     * @returns {Vector} - The unit forward vector.
    */
    function EyeForwardVector() {
        if(this.IsPlayer()) return this.GetUserData("Eye").GetForwardVector()
        return this.GetForwardVector()
    }

    /*
     * Sets a keyvalue of the entity and stores the value as user data, where GetKeyValue(key) reads it.
     *
     * @param {string} key - The key of the key-value pair.
     * @param {int|float|Vector|string} value - The value of the key-value pair.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetKeyValue(key, value, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetKeyValue, fireDelay, [key, value], this)

        this.SetUserData(key, value)

        switch (typeof value) {
            case "integer":
                return this.CBaseEntity.__KeyValueFromInt(key, value);
            case "float":
                return this.CBaseEntity.__KeyValueFromFloat(key, value);
            case "Vector":
                return this.CBaseEntity.__KeyValueFromVector(key, value);
            case "string":
                return this.CBaseEntity.__KeyValueFromString(key, value);
        }
        
        return this.CBaseEntity.__KeyValueFromString(key, value.tostring());
    }


    /*
     * Connects an output of the entity to an input of a target entity.
     *
     * @param {string} outputName - The name of the output to connect.
     * @param {string|CBaseEntity|pcapEntity} target - The targetname, or an entity, which is referenced by its current targetname.
     * @param {string} input - The name of the input on the target entity to connect to.
     * @param {string} param - An optional parameter override for the input. (default: "")
     * @param {number} delay - An optional delay in seconds before triggering the input. (default: 0)
     * @param {number} fires - The number of times the output should fire before becoming inactive. -1 indicates unlimited fires. (default: -1)
    */
     function AddOutput(outputName, target, input, param = "", delay = 0, fires = -1) {
        if(typeof target == "instance" || typeof target == "pcapEntity")
            target = target.GetName()
        this.SetKeyValue(outputName, target + "\x001B" + input + "\x001B" + param + "\x001B" + delay + "\x001B" + fires)
    }

    /*
     * Connects an output of the entity to a script function.
     * A function is called by its name through a "RunScriptCode" output on the entity, so the name must resolve
     * from the entity's script scope or the root table. Anonymous functions and functions compiled from a string
     * are stored in the root table under a unique name first.
     * A string is taken as a function name and connected through the native ConnectOutput; delay and fires don't apply to it.
     *
     * @param {string} outputName - The name of the output to connect.
     * @param {function|string} script - The function to call, or the name of a function in the entity's script scope.
     * @param {number} delay - An optional delay in seconds before the call. (default: 0)
     * @param {number} fires - The number of times the output should fire before becoming inactive. -1 indicates unlimited fires. (default: -1)
    */
    function ConnectOutputEx(outputName, script, delay = 0, fires = -1) {
        if(typeof script == "function") {
            local funcName = script.getinfos().name
            local src = script.getinfos().src
            // If scripts is an anonymous function, assign it a unique name and add it to the root scope
            if(!funcName || src == "unnamedbuffer") { 
                funcName = UniqueString("OutputFunc")
                getroottable()[funcName] <- script
            }
            script = funcName + "()"
        } else {
            return this.ConnectOutput(outputName, script)
        }

        this.AddOutput(outputName, "!self", "RunScriptCode", script, delay, fires)
    }

    /*
     * Hooks an input of the entity: the closure runs before the input is processed and must return true
     * to let it through, or false to block it.
     *
     * @param {string} inputName - The name of the input to hook.
     * @param {function} closure - The function to call when the entity receives the input.
    */
    function SetInputHook(inputName, closure) {
        if(this.ValidateScriptScope() == false) return
        this.GetScriptScope()["Input" + inputName] <- closure
        // The engine looks the hook up by the input name as it was fired, and inputs are case-insensitive,
        // so the lowercase spelling is hooked too.
        this.GetScriptScope()["Input" + inputName.tolower()] <- closure
    }

    /*
     * Plays a sound on the entity through the native EmitSound.
     *
     * @param {string} soundName - The name of the sound to play.
     * @param {number} fireDelay - An optional delay in seconds before playing the sound. (default: 0)
     * @param {string} eventName - The name of the event to schedule the sound playback under. (default: "global")
    */
    function EmitSound(soundName, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.EmitSound, fireDelay, [soundName], this)

        this.CBaseEntity.EmitSound(soundName)
    }

    /*
     * Plays a sound on the entity with volume control and optional looping. StopSoundEx stops it.
     * Calling it again while the sound is still playing only changes its volume.
     *
     * @param {string} soundName - The name of the sound to play.
     * @param {number} volume - The volume of the sound (0-10). (default: 10)
     * @param {boolean} looped - Whether to replay the sound each time it ends. (default: false)
     * @param {number} fireDelay - An optional delay in seconds before playing the sound. (default: 0)
     * @param {string} eventName - The name of the event to schedule the sound playback under. (default: "global")
    */
    function EmitSoundEx(soundName, volume = 10, looped = false, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.EmitSoundEx, fireDelay, [soundName], this)
        
        // If the sound is still playing, only move its emitter to apply the new volume.
        local soundEnt = this.GetUserData(soundName)
        if(soundEnt && soundEnt.IsValid()) 
            return soundEnt.SetAbsOrigin(this.GetOrigin() + Vector(0, 0, 3000 - volume * 300))
        
        // SO FKING CURSED WORKAROUND EVER!
        local soundEnt = entLib.CreateProp("prop_physics", Vector(), ALWAYS_PRECACHED_MODEL)
        soundEnt.SetAbsOrigin(this.GetOrigin() + Vector(0, 0, 3000 - volume * 300))
        soundEnt.SetParent(this)
        soundEnt.SetKeyValue("rendermode", 5)
        soundEnt.SetAlpha(0)

        local soundTime = macros.GetSoundDuration(soundName)
        this.SetUserData(soundName, soundEnt)
        soundEnt.EmitSound(soundName)
        
        if(!looped) return soundEnt.Destroy(soundTime)
        ScheduleEvent.AddInterval(soundEnt, soundEnt.EmitSound, soundTime, soundTime, [soundName], soundEnt)
    }

    /*
     * Stops a sound started with EmitSoundEx and removes its emitter. Does nothing if the sound is not playing.
     *
     * @param {string} soundName - The name of the sound to stop.
     * @param {number} fireDelay - An optional delay in seconds before stopping the sound. (default: 0)
     * @param {string} eventName - The name of the event to schedule the sound stop under. (default: "global")
    */
    function StopSoundEx(soundName, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0) {
            return ScheduleEvent.Add(eventName, this.StopSoundEx, fireDelay, [soundName], this)
        }

        local soundEnt = this.GetUserData(soundName)
        if(!soundEnt || !soundEnt.IsValid()) return

        ScheduleEvent.TryCancel(soundEnt)
        soundEnt.SetOrigin(Vector(0, 0, 10000))
        soundEnt.Destroy(0.04)
    }


    /*
     * Sets the targetname of the entity.
     *
     * @param {string} name - The targetname to be set.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetName(name, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetName, fireDelay, [name], this)
        
        this.SetKeyValue("targetname", name)
    }

    /*
     * Sets a unique targetname that starts with the given prefix.
     *
     * @param {string} prefix - The prefix to be used for the unique targetname. (default: "pcapEnt")
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetUniqueName(prefix = "pcapEnt", fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetUniqueName, fireDelay, [prefix], this)
        
        this.SetKeyValue("targetname", UniqueString(prefix))
    }


    /*
     * Parents the entity through the "SetParent" input, which finds the parent by targetname.
     * An entity passed as the parent is referenced by its targetname: if it has none, or shares it with
     * other entities, it is renamed to a unique one first.
     *
     * @param {string|CBaseEntity|pcapEntity} parentEnt - The parent entity object or its targetname.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetParent(parentEnt, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetParent, fireDelay, [parentEnt], this)
        
        if(typeof parentEnt != "string") {
            local Pent = entLib.FromEntity(parentEnt)
            local hasUniqueName = true
            if(Pent.GetName() == "") 
                Pent.SetUniqueName("parent")
            for(local entity; entity = Entities.FindByName(entity, Pent.GetName()); ) if(!macros.IsEqual(Pent, entity)) {
                Pent.SetUniqueName("parent")
                break
            }
            parentEnt = Pent.GetName()
        }
        
        EntFireByHandle(this.CBaseEntity, "SetParent", parentEnt)            
    }

    /*
     * Gets the direct children of the entity, without grandchildren.
     *
     * @returns {List} - The children as pcapEntity objects.
    */
    function GetChildren() {
        local childrenList = List()

        local child = this.CBaseEntity.FirstMoveChild(); 
        while(child) {
            childrenList.append(entLib.FromEntity(child));
            child = child.NextMovePeer();
        }

        return childrenList;
    }

    /*
     * Gets all descendants of the entity (children, grandchildren, and so on) in depth-first order.
     *
     * @returns {List} - The descendants as pcapEntity objects.
    */
    function GetAllChildrenRecursively() {
        local descendantsList = List();
        _findDescendantsRecursive(this.CBaseEntity, descendantsList);

        return descendantsList;
    }


    /*
     * Sets the solid type of the entity through the "SetSolidtype" input.
     *
     * @param {number} solidType - The solid type (SOLID_* constants).
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetCollision(solidType, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetCollision, fireDelay, [solidType], this)
        
        EntFireByHandle(this.CBaseEntity, "SetSolidtype", solidType.tostring()) 
        this.SetUserData("Solidtype", solidType)
    }


    /*
     * Sets the collision group of the entity through the "CollisionGroup" keyvalue.
     *
     * @param {number} collisionGroup - The collision group (COLLISION_GROUP_* constants).
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetCollisionGroup(collisionGroup, fireDelay = 0, eventName = "global") {
        this.SetKeyValue("CollisionGroup", collisionGroup, fireDelay, eventName)
    }
    

    /*
     * Starts playing the specified animation through the "SetAnimation" input.
     *
     * @param {string} animationName - The name of the animation to play.
     * @param {number} fireDelay - Delay in seconds before starting the animation. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetAnimation(animationName, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetAnimation, fireDelay, [animationName], this)
        
        EntFireByHandle(this.CBaseEntity, "SetAnimation", animationName)
        this.SetUserData("animation", animationName)
    }


    /*
     * Sets the alpha (opacity) of the entity. It has no visible effect while "rendermode" is 0 (Normal).
     *
     * @param {number} opacity - The alpha value (0-255). It is truncated to an integer and clamped to that range.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetAlpha(opacity, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetAlpha, fireDelay, [opacity], this)
        
        // The "Alpha" input clamps, the keyvalue path doesn't: out-of-range values would wrap around.
        local alpha = math.clamp(opacity.tointeger(), 0, 255)
        this.__KeyValueFromInt("renderamt", alpha)
        this.SetUserData("alpha", alpha)
    }


    /*
     * Sets the color of the entity.
     *
     * @param {string|Vector} colorValue - The color value as a string (e.g., "255 0 0") or a Vector.
     * @param {number} fireDelay - Delay in seconds before applying.
    */
    function SetColor(colorValue, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetColor, fireDelay, [colorValue], this)
        
        if(typeof colorValue == "Vector") 
            colorValue = macros.VecToStr(colorValue)

        EntFireByHandle(this.CBaseEntity, "Color", colorValue)
        this.SetUserData("color", colorValue)
    }


    /*
     * Sets the skin of the entity through the "skin" input.
     *
     * @param {number} skin - The skin number.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetSkin(skin, fireDelay = 0, eventName = "global") { 
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetSkin, fireDelay, [skin], this)
        
        EntFireByHandle(this.CBaseEntity, "skin", skin.tointeger().tostring())
        this.SetUserData("skin", skin)
    }


    /*
     * Sets whether the entity is drawn, through the "EnableDraw" / "DisableDraw" inputs.
     *
     * @param {boolean} isEnabled - True to enable drawing, false to disable.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetDrawEnabled(isEnabled, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetDrawEnabled, fireDelay, [isEnabled], this)
        
        local action = isEnabled ? "EnableDraw" : "DisableDraw"
        EntFireByHandle(this.CBaseEntity, action)
        this.SetUserData("IsDraw", isEnabled)
    }

    /*
     * Sends the entity its "Disable" input and makes TracePlus ignore it (SetTraceIgnore(true)).
     *
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function Disable(fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.Disable, fireDelay, null, this)
        
        EntFireByHandle(this.CBaseEntity, "Disable")
        this.SetTraceIgnore(true)
    }

    /*
     * Sends the entity its "Enable" input and makes TracePlus hit it again (SetTraceIgnore(false)).
     *
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function Enable(fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.Enable, fireDelay, null, this)
        
        EntFireByHandle(this.CBaseEntity, "Enable")
        this.SetTraceIgnore(false)
    }

    /*
     * Checks if the entity is set to be drawn.
     * 
     * @returns {boolean} - True if the entity is set to be drawn, false otherwise.
    */
    function IsDrawEnabled() {
        return this.GetUserData("IsDraw")
    }

    /*
     * Sets whether TracePlus bbox traces ignore the entity.
     *
     * @param {boolean} isEnabled - True to ignore the entity during traces, false otherwise.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetTraceIgnore(isEnabled, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetTraceIgnore, fireDelay, [isEnabled], this)
        
        this.SetUserData("TracePlusIgnore", isEnabled)
        TracePlusIgnoreEnts[this.CBaseEntity] <- isEnabled
    }

    /*
     * Checks whether TracePlus bbox traces ignore the entity.
     *
     * @returns {bool|null} - The value last passed to SetTraceIgnore, or null if it was never called.
    */
    function IsTraceIgnored() {
        return this.GetUserData("TracePlusIgnore")
    }

    /*
     * Sets the spawnflags of the entity through SetKeyValue, so GetSpawnflags returns them.
     *
     * @param {number} flag - The spawnflags value to set.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetSpawnflags(flag, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetSpawnflags, fireDelay, [flag], this)
        
        this.SetKeyValue("SpawnFlags", flag)
    }


    /*
     * Sets the scale of the entity's model. Also sets its body group to 0.
     *
     * @param {number} scaleValue - The scale value.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetModelScale(scaleValue, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetModelScale, fireDelay, [scaleValue], this)
        
        this.__KeyValueFromFloat("ModelScale", scaleValue.tofloat())
        this.SetUserData("ModelScale", scaleValue)
        // hack for entity inner state update
        EntFireByHandle(this.CBaseEntity, "SetBodyGroup", "1"); EntFireByHandle(this.CBaseEntity, "SetBodyGroup", "0", 0.02)
    }

    /*
     * Gets the model scale set with SetModelScale.
     *
     * @returns {number} - The scale, or 1 if SetModelScale was never called.
    */
    function GetModelScale() {
        local res = this.GetUserData("ModelScale")
        return res ? res : 1
    }


    /*
     * Moves the entity so that its center (GetCenter) is at the given world position.
     * It moves through the native SetAbsOrigin, so clients interpolate the move.
     *
     * @param {Vector} vector - The desired absolute center vector in world coordinates.
    */
    function SetAbsCenter(vector) {
        local offset = this.CBaseEntity.GetCenter() - this.CBaseEntity.GetOrigin()
        this.CBaseEntity.SetAbsOrigin( vector - offset )
    }

    /*
     * Teleports the entity so that its center (GetCenter) is at the given position.
     * Like SetOrigin, the position is relative to the parent for a parented entity.
     *
     * @param {Vector} vector - The center position.
    */
    function SetCenter(vector) {
        local offset = this.CBaseEntity.GetCenter() - this.CBaseEntity.GetOrigin()
        this.CBaseEntity.SetOrigin( vector - offset )
    }

    /*
     * Adds the response context "name:value" to the entity through the "AddContext" input,
     * and stores the value as user data under name.
     *
     * @param {string} name - The name of the context value.
     * @param {any} value - The value to set.
     * @param {number} fireDelay - Delay in seconds before applying. (default: 0)
     * @param {string} eventName - The name of the event to schedule the delayed call under. (default: "global")
    */
    function SetContext(name, value, fireDelay = 0, eventName = "global") {
        if(fireDelay != 0)
            return ScheduleEvent.Add(eventName, this.SetContext, fireDelay, [name, value], this)
        
        EntFireByHandle(this.CBaseEntity, "AddContext", (name + ":" + value))
        this.SetUserData(name, value)
    }
    
    /*
     * Stores an arbitrary value associated with the entity. Names are case-insensitive and share one
     * namespace with SetKeyValue keys and the library's own entries ("alpha", "color", "eye", "dissolved", ...).
     *
     * @param {string} name - The name of the value.
     * @param {any} value - The value to store.
    */
    function SetUserData(name, value) {
        EntitiesScopes[this.CBaseEntity][name.tolower()] <- value
    }

    /*
     * Gets a value stored with SetUserData or SetKeyValue. The name is case-insensitive.
     *
     * @param {string} name - The name of the value to get.
     * @returns {any} - The stored value, or null if not found.
    */
    function GetUserData(name) {
        name = name.tolower()
        if(name in EntitiesScopes[this.CBaseEntity])
            return EntitiesScopes[this.CBaseEntity][name]
        return null
    }

    /*
     * Calculates the local coordinates (position and angles) of this entity relative to its move parent.
     * If the entity has no parent, its world coordinates are returned.
     *
     * @returns {table} - The local coordinates: { pos = <Vector>, ang = <Vector> }.
    */
    function GetLocalCoords() {
        local pParent = this.CBaseEntity.GetMoveParent();
        if (!pParent) {
            // If there's no parent, local coordinates are equal to world coordinates.
            return { pos = this.GetOrigin(), ang = this.GetAngles() };
        }

        local childWorldPos = this.GetOrigin();
        local parentWorldPos = pParent.GetOrigin();

        local childWorldAng = this.GetAngles();
        local parentWorldAng = pParent.GetAngles();

        // Calculate the offset vector in world coordinates
        local worldOffset = childWorldPos - parentWorldPos;

        // "Unrotate" the world offset vector by the parent's angles to get the local position
        local localPos = math.vector.unrotate(worldOffset, parentWorldAng);
        local localAng = childWorldAng - parentWorldAng;

        return { pos = localPos, ang = localAng };
    }

    /*
     * Teleports the entity to a world position, so clients don't interpolate the move.
     * For a parented entity the position is converted to the parent's space. Parenting to an attachment
     * is not taken into account: SetAbsOriginNative handles it, but interpolates.
     *
     * @param {Vector} desiredAbsVec - The desired absolute position in world coordinates.
    */
    function SetAbsOrigin(desiredAbsVec) {
        local pParent = this.CBaseEntity.GetMoveParent()

        // The native SetOrigin teleports in the parent's space, which is world space when there is no parent.
        if (!pParent) {
            return this.CBaseEntity.SetOrigin(desiredAbsVec)
        }

        local parentWorldPos = pParent.GetOrigin()
        local parentWorldAng = pParent.GetAngles()

        local worldOffsetVector = desiredAbsVec - parentWorldPos

        local localPos = math.vector.unrotate(worldOffsetVector, parentWorldAng)

        this.SetOrigin(localPos)
    }

    /*
     * Sets the entity's absolute origin using the native engine method.
     * Unlike the custom SetAbsOrigin, this method handles attachment parents correctly.
     * However, it causes client-side interpolation (visual sliding) when moving the entity.
     *
     * @param {Vector} desiredAbsVec - The desired absolute position in world coordinates.
    */
    function SetAbsOriginNative(desiredAbsVec) {
        this.CBaseEntity.SetAbsOrigin(desiredAbsVec)
    }

    /*
     * Checks whether the entity's bounding box is a cube (all sides have equal length).
     *
     * @returns {boolean} - True if the bounding box is a cube, false otherwise.
    */
    function IsSquareBbox() {
        local mins = this.GetBoundingMins();
        local maxs = this.GetBoundingMaxs();
        
        local sizeX = abs(maxs.x - mins.x)
        local sizeY = abs(maxs.y - mins.y)
        local sizeZ = abs(maxs.z - mins.z)

        return sizeX == sizeY && sizeY == sizeZ;
    }

    /*
     * Gets the center of the entity's bounds (GetBoundingMins, GetBoundingMaxs), relative to its origin.
     *
     * @returns {Vector} - The center of the bounds.
    */
    function GetBoundingCenter() {
        return (this.CBaseEntity.GetBoundingMaxs() - this.CBaseEntity.GetBoundingMins()) * 0.5
    }

    /*
     * Gets the axis-aligned box that encloses the entity's rotated bounds, relative to its origin (see CreateAABB).
     *
     * @returns {table} - {min, center, max}: the min corner, the center and the max corner of the box.
    */
    function GetAABB() {
        return {
            min = this.CreateAABB(0),
            center = this.CreateAABB(4),
            max = this.CreateAABB(7)
        }
    }

    /* 
     * Gets the index of the entity.
     *
     * @returns {int} - The index of the entity.
    */
    function GetIndex() {
        return this.CBaseEntity.entindex()
    }


    /*
     * Gets a keyvalue stored through SetKeyValue (or any user data under that name).
     * For "model", "health" and "targetname" it falls back to the entity's current value if none was stored.
     *
     * @param {string} key - The key of the key-value pair.
     * @returns {any} - The value, or null if none was stored and the key has no fallback.
    */
    function GetKeyValue(key) {
        local value = this.GetUserData(key)
        if(value != null)
            return value

        switch(key) {
            case "model":
                return this.GetModelName()
                break
            case "health":
                return this.GetHealth()
                break
            case "targetname":
                return this.GetName()
                break
        }

        return null
    }


    /*
     * Gets the spawnflags set through SetSpawnflags or SetKeyValue.
     *
     * @returns {int|null} - The spawnflags value, or null if they were not set that way.
    */
    function GetSpawnflags() {
        return this.GetUserData("spawnflags")
    }


    /*
     * Gets the alpha (opacity) set with SetAlpha.
     *
     * @returns {int} - The alpha value, or 255 if SetAlpha was never called.
    */
    function GetAlpha() {
        local alpha = this.GetUserData("alpha")
        return alpha != null ? alpha : 255
    }


    /*
     * Gets the color set with SetColor.
     *
     * @returns {string} - The color as "R G B", or "255 255 255" if SetColor was never called.
    */
    function GetColor() {
        local color = this.GetUserData("color")
        return color ? color : "255 255 255"
    }


    /*
     * Gets the skin set with SetSkin.
     *
     * @returns {number} - The skin number, or 0 if SetSkin was never called.
    */
    function GetSkin() {
        local skin = this.GetUserData("skin")
        return skin ? skin : 0
    }


    /*
     * Gets the prefix of the entity name: everything up to and including the last "-" ("a-b-" for "a-b-c").
     *
     * @returns {string} - The prefix of the entity name.
    */
    function GetNamePrefix() {
        return macros.GetPrefix(this.GetName())
    }


    /*
     * Gets the postfix of the entity name: everything from the first "-" on ("-b-c" for "a-b-c").
     *
     * @returns {string} - The postfix of the entity name.
    */
    function GetNamePostfix() {
        return macros.GetPostfix(this.GetName())
    }

    /*
     * Gets the partner of a portal: the linked partner of a linked_portal_door, or for a prop_portal
     * the other portal of its pair (see FindPartnerForPropPortal).
     *
     * @returns {pcapEntity|null} - The partner entity, or null if no partner is found.
    */
    function GetPartnerInstance() {
        if(this.CBaseEntity instanceof CLinkedPortalDoor)
            return entLib.FromEntity(this.CBaseEntity.GetPartnerInstance())
        return FindPartnerForPropPortal(this)
    }


    /*
     * Gets a point of the axis-aligned box that encloses the entity's rotated bounds (GetBBoxPoints).
     *
     * @param {number} stat - 0 for the min corner, 7 for the max corner, 4 for the center.
     * @returns {Vector} - The point, relative to the entity's origin.
    */
    function CreateAABB(stat) { 
        local angles = this.GetAngles()
        if(stat == 4) 
            angles = Vector(45, 45, 45)

        local all_vertex = this.GetBBoxPoints()
        local x = array(8)
        local y = array(8)
        local z = array(8)

        foreach(idx, vec in all_vertex) {
            x[idx] = vec.x
            y[idx] = vec.y
            z[idx] = vec.z
        }

        x.sort(); y.sort(); z.sort()
 
        local result
        if(stat == 4) { // centered
            result = ( Vector(x[7], y[7], z[7]) - Vector(x[0], y[0], z[0]) ) * 0.5
        } 
        else {
            result = Vector(x[stat], y[stat], z[stat])
        }
        
        return result
    }

    /*
     * Gets the 8 corners of the entity's bounds rotated by its angles, relative to its origin (add GetOrigin()
     * for world positions). The corner names below use the entity's local axes: +X front, +Y left, +Z top.
     *
     * @returns {array} - The 8 corners as Vectors.
    */
    function GetBBoxPoints() {
        local max = this.GetBoundingMaxs();
        local min = this.GetBoundingMins();
        local angles = this.GetAngles()
    
        local getVertex = macros.GetVertex
        return [
            getVertex(max, min, min, angles), // 0 - Front-Right-Bottom
            getVertex(max, max, min, angles), // 1 - Front-Left-Bottom
            getVertex(min, max, min, angles), // 2 - Back-Left-Bottom
            getVertex(min, min, min, angles), // 3 - Back-Right-Bottom
            getVertex(min, min, max, angles), // 4 - Back-Right-Top
            getVertex(min, max, max, angles), // 5 - Back-Left-Top
            getVertex(max, max, max, angles), // 6 - Front-Left-Top
            getVertex(max, min, max, angles), // 7 - Front-Right-Top
        ]
    }

    /*
     * Gets the faces of the rotated box from GetBBoxPoints as 12 triangles, two per face, relative to the entity's origin.
     *
     * @returns {array} - 12 tables {origin, vertices}: vertices holds the triangle's 3 corners, origin its centroid.
    */
    function GetBBoxFaces() {
        local vertices = this.GetBBoxPoints()
        local getTriangle = macros.GetTriangle
        return [
            /* Right face triangles */
            getTriangle(vertices[0], vertices[3], vertices[4]), // Face 0: Front-Right-Bottom, Back-Right-Bottom, Back-Right-Top
            getTriangle(vertices[0], vertices[4], vertices[7]), // Face 1: Front-Right-Bottom, Back-Right-Top, Front-Right-Top

            /* Left face triangles */
            getTriangle(vertices[1], vertices[2], vertices[5]), // Face 2: Front-Left-Bottom, Back-Left-Bottom, Back-Left-Top
            getTriangle(vertices[1], vertices[5], vertices[6]), // Face 3: Front-Left-Bottom, Back-Left-Top, Front-Left-Top

            /* Back face triangles */
            getTriangle(vertices[3], vertices[2], vertices[5]), // Face 4: Back-Right-Bottom, Back-Left-Bottom, Back-Left-Top
            getTriangle(vertices[3], vertices[5], vertices[4]), // Face 5: Back-Right-Bottom, Back-Left-Top, Back-Right-Top

            /* Front face triangles */
            getTriangle(vertices[0], vertices[1], vertices[6]), // Face 6: Front-Right-Bottom, Front-Left-Bottom, Front-Left-Top
            getTriangle(vertices[0], vertices[6], vertices[7]), // Face 7: Front-Right-Bottom, Front-Left-Top, Front-Right-Top

            /* Bottom face triangles */
            getTriangle(vertices[0], vertices[1], vertices[2]), // Face 8: Front-Right-Bottom, Front-Left-Bottom, Back-Left-Bottom
            getTriangle(vertices[0], vertices[2], vertices[3]), // Face 9: Front-Right-Bottom, Back-Left-Bottom, Back-Right-Bottom

            /* Top face triangles */
            getTriangle(vertices[7], vertices[6], vertices[5]), // Face 10: Front-Right-Top, Front-Left-Top, Back-Left-Top
            getTriangle(vertices[7], vertices[5], vertices[4])  // Face 11: Front-Right-Top, Back-Left-Top, Back-Right-Top
        ]
    }

    /*
     * Checks if this entity is equal to another entity based on their entity indices.
     *
     * @param {pcapEntity|CBaseEntity} other - The other entity to compare.
     * @returns {boolean} - True if the entities are equal, false otherwise.
    */
    function IsEqual(other) return this.entindex() == other.entindex()

    /*
     * Converts the entity object to a string.
     *
     * @returns {string} - The string representation of the entity.
    */
    function _tostring() return "pcapEntity: " + this.CBaseEntity + ""

    /*
     * Returns the type of the entity object.
     *
     * @returns {string} - The type of the entity object.
    */
    function _typeof() return "pcapEntity"
}

/*
 * Appends all descendants of an entity to resultList as pcapEntity objects, depth-first.
 * Internal helper of pcapEntity.GetAllChildrenRecursively.
 *
 * @param {CBaseEntity} pCurrentParent - The entity to search for children of.
 * @param {List} resultList - The list to append found children to.
*/
::_findDescendantsRecursive <- function(pCurrentParent, resultList) {
    local child = pCurrentParent.FirstMoveChild();

    while (child) {
        resultList.append(entLib.FromEntity(child));
        _findDescendantsRecursive(child, resultList);
        child = child.NextMovePeer();
    }
}

// Passthroughs to the native CBaseEntity methods.
function pcapEntity::ConnectOutput(output, funcName) this.CBaseEntity.ConnectOutput(output, funcName)
function pcapEntity::DisconnectOutput(output, funcName) this.CBaseEntity.DisconnectOutput(output, funcName)
function pcapEntity::PrecacheSoundScript(sound_name) this.CBaseEntity.PrecacheSoundScript(sound_name)
function pcapEntity::IsSequenceFinished() return this.CBaseEntity.IsSequenceFinished()
function pcapEntity::SpawnEntity() this.CBaseEntity.SpawnEntity()

function pcapEntity::GetAngles() return this.CBaseEntity.GetAngles()
function pcapEntity::GetAngularVelocity() return this.CBaseEntity.GetAngularVelocity()
function pcapEntity::GetBoundingMaxs() return this.CBaseEntity.GetBoundingMaxs()
function pcapEntity::GetBoundingMins() return this.CBaseEntity.GetBoundingMins()
function pcapEntity::GetCenter() return this.CBaseEntity.GetCenter()
function pcapEntity::GetClassname() return this.CBaseEntity.GetClassname()
function pcapEntity::GetForwardVector() return this.CBaseEntity.GetForwardVector()
function pcapEntity::GetHealth() return this.CBaseEntity.GetHealth()
function pcapEntity::GetLeftVector() return this.CBaseEntity.GetLeftVector()
function pcapEntity::GetMaxHealth() return this.CBaseEntity.GetMaxHealth()
function pcapEntity::GetModelKeyValues() return this.CBaseEntity.GetModelKeyValues()
function pcapEntity::GetModelName() return this.CBaseEntity.GetModelName()
function pcapEntity::GetName() return this.CBaseEntity.GetName()
function pcapEntity::GetOrigin() return this.CBaseEntity.GetOrigin()
function pcapEntity::GetScriptId() return this.CBaseEntity.GetScriptId()
function pcapEntity::GetUpVector() return this.CBaseEntity.GetUpVector()
function pcapEntity::GetPartnername() return this.CBaseEntity.GetPartnername()
function pcapEntity::ValidateScriptScope() return this.CBaseEntity.ValidateScriptScope()
function pcapEntity::GetScriptScope() return this.CBaseEntity.GetScriptScope()
function pcapEntity::entindex() return this.CBaseEntity.entindex()

function pcapEntity::SetForwardVector(vector) this.CBaseEntity.SetForwardVector(vector)
function pcapEntity::SetHealth(health) this.CBaseEntity.SetHealth(health)
function pcapEntity::SetMaxHealth(health) this.CBaseEntity.SetMaxHealth(health)
function pcapEntity::SetModel(model_name) this.CBaseEntity.SetModel(model_name)
function pcapEntity::SetOrigin(vector) this.CBaseEntity.SetOrigin(vector)
function pcapEntity::SetAngles(x, y, z) this.CBaseEntity.SetAngles(x, y, z)
function pcapEntity::SetVelocity(vector) this.CBaseEntity.SetVelocity(vector)
function pcapEntity::SetBBox(mins, maxs) this.CBaseEntity.SetSize(mins, maxs)
function pcapEntity::SetSize(mins, maxs) this.CBaseEntity.SetSize(mins, maxs)

// KeyValues manipulation
function pcapEntity::__KeyValueFromInt(key, value) return this.CBaseEntity.__KeyValueFromInt(key, value)
function pcapEntity::__KeyValueFromFloat(key, value) return this.CBaseEntity.__KeyValueFromFloat(key, value)
function pcapEntity::__KeyValueFromString(key, value) return this.CBaseEntity.__KeyValueFromString(key, value)
function pcapEntity::__KeyValueFromVector(key, value) return this.CBaseEntity.__KeyValueFromVector(key, value)

// Hierarchy & Movement relations. Entities passed in and returned are raw CBaseEntity handles, not pcapEntity.
function pcapEntity::FirstMoveChild() return this.CBaseEntity.FirstMoveChild()
function pcapEntity::GetMoveParent() return this.CBaseEntity.GetMoveParent()
function pcapEntity::GetRootMoveParent() return this.CBaseEntity.GetRootMoveParent()
function pcapEntity::NextMovePeer() return this.CBaseEntity.NextMovePeer()
function pcapEntity::GetOwner() return this.CBaseEntity.GetOwner()
function pcapEntity::SetOwner(ent) this.CBaseEntity.SetOwner(ent)

// State & Game
function pcapEntity::GetPreTemplateName() return this.CBaseEntity.GetPreTemplateName()
function pcapEntity::GetTeam() return this.CBaseEntity.GetTeam()
function pcapEntity::SetTeam(team) this.CBaseEntity.SetTeam(team)
function pcapEntity::GetSoundDuration(soundName, actorModel = "") return this.CBaseEntity.GetSoundDuration(soundName, actorModel)

// Transform & Velocity
function pcapEntity::GetVelocity() return this.CBaseEntity.GetVelocity()
function pcapEntity::SetAngularVelocity(pitch, yaw, roll) this.CBaseEntity.SetAngularVelocity(pitch, yaw, roll)