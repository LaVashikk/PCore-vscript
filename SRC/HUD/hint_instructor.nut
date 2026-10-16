/*
 * Instructor hints through env_instructor_hint, built with chained calls:
 * HUD.HintInstructor("Press E").SetIcon("icon_tip").AttachTo(button).Enable()
 *
 * A HintInstructor holds only its settings. Every Enable/Disable makes a one-shot env_instructor_hint
 * and removes it right away: the server sends the hint and forgets it, the client keeps it on its own.
 *
 * What the engine does with it:
 * - Every HintInstructor has its own hint: different ones are shown at the same time, a new Enable of the same one replaces it.
 * - While any game_text is on screen (HUD.ScreenText), hints are paused. The hold time only runs while the hint is visible.
 * All methods return the HintInstructor itself, so calls chain
*/
HUD["HintInstructor"] <- class {
    // Unique: the targetname of the one-shot entities and the hint_replace_key. EndHint finds the hint by this name
    name = null;
    message = "";
    // The text the activator of Enable(player) sees instead of `message`
    activatorMessage = "";
    holdtime = 5;
    iconOnScreen = "icon_tip";
    iconOffScreen = "icon_tip";
    color = "255 255 255";
    bind = "";
    // 1: on the HUD; 0: at `target`
    onHud = 1;
    target = "";
    range = 0;
    pulse = 0;
    alphaPulse = 0;
    shake = 0;

    /*
     * Creates an instructor hint, shown on the HUD by default. Nothing is shown until Enable.
     *
     * @param {string} message - The hint text.
    */
    constructor(message) {
        this.name = UniqueString("pcap_hint")
        this.SetText(message)
    }

    /*
     * Shows the hint, replacing the one this HintInstructor showed before.
     *
     * @param {CBaseEntity|pcapEntity} player - Show it to this player only (coop). With SetActivatorText, everyone sees it
     * and this player sees the activator text. (optional, default: all players)
    */
    function Enable(player = null) {
        local ent = entLib.CreateByClassname("env_instructor_hint", {
            targetname = this.name,
            hint_replace_key = this.name,
            hint_caption = this.message,
            hint_activator_caption = this.activatorMessage,
            hint_static = this.onHud,
            hint_allow_nodraw_target = this.onHud,
            hint_target = this.target,
            hint_color = this.color,
            hint_icon_onscreen = this.bind != "" ? "use_binding" : this.iconOnScreen,
            hint_icon_offscreen = this.iconOffScreen,
            hint_binding = this.bind,
            // 0 persists until Disable
            hint_timeout = this.holdtime,
            hint_forcecaption = 1,
            hint_nooffscreen = 0,
            hint_range = this.range,
            hint_pulseoption = this.pulse,
            hint_alphaoption = this.alphaPulse,
            hint_shakeoption = this.shake,
            // With an activator text everyone sees the hint, the player sees that text
            hint_local_player_only = player && this.activatorMessage == "" ? 1 : 0
        })
        EntFireByHandle(ent, "ShowHint", "", 0, player)
        EntFireByHandle(ent, "Kill")
        return this
    }

    /*
     * Hides the hint.
    */
    function Disable() {
        // Any entity with the hint's name can stop it
        local ent = entLib.CreateByClassname("env_instructor_hint", {targetname = this.name})
        EntFireByHandle(ent, "EndHint")
        EntFireByHandle(ent, "Kill")
        return this
    }

    /*
     * Sets the hint text. Shown on the next Enable.
     *
     * @param {string} message - The text.
    */
    function SetText(message) {
        if(typeof message != "string") throw("HUD.HintInstructor.SetText: 'message' must be a string, but got " + typeof message)
        this.message = message
        return this
    }

    /*
     * Sets the text the player passed to Enable(player) sees, while the others see SetText's: "Press the button" and
     * "Wait for your partner" in one hint. "" (the default) shows Enable(player)'s hint to that player only.
     *
     * @param {string} message - The activator's text.
    */
    function SetActivatorText(message) {
        if(typeof message != "string") throw("HUD.HintInstructor.SetActivatorText: 'message' must be a string, but got " + typeof message)
        this.activatorMessage = message
        return this
    }

    /*
     * Shows a key binding with the hint, e.g. "+use". The on-screen icon becomes the binding while it is set.
     *
     * @param {string} bind - The binding, or "" to go back to the icon.
    */
    function SetBind(bind) {
        if(typeof bind != "string") throw("HUD.HintInstructor.SetBind: 'bind' must be a string, but got " + typeof bind)
        this.bind = bind
        return this
    }

    /*
     * Shows the hint on the HUD (the default).
    */
    function ShowOnHud() {
        this.onHud = 1
        this.target = ""
        return this
    }

    /*
     * Shows the hint at an entity, following it. hint_target works by name, so an unnamed entity gets a unique one.
     * The target is looked up on each Enable: if it is gone by then, the hint has nothing to follow.
     *
     * @param {CBaseEntity|pcapEntity|string} ent - The entity, or its targetname.
    */
    function AttachTo(ent) {
        if(typeof ent == "string") {
            this.target = ent
        }
        else {
            local target = entLib.FromEntity(ent)
            if(!target || !target.IsValid()) throw("HUD.HintInstructor.AttachTo: 'ent' is not a valid entity")
            if(target.GetName() == "") target.SetUniqueName("hint_target")
            this.target = target.GetName()
        }
        this.onHud = 0
        return this
    }

    /*
     * Sets the text color.
     *
     * @param {Vector|string} color - The color, Vector(255, 0, 0) or "255 0 0".
    */
    function SetColor(color) {
        this.color = HUD._ColorString(color, "HUD.HintInstructor.SetColor")
        return this
    }

    /*
     * Sets the icon, both on screen and off screen (default "icon_tip").
     *
     * @param {string} icon - The icon name.
    */
    function SetIcon(icon) {
        if(typeof icon != "string") throw("HUD.HintInstructor.SetIcon: 'icon' must be a string, but got " + typeof icon)
        this.iconOnScreen = icon
        this.iconOffScreen = icon
        return this
    }

    /*
     * Sets the icon shown while the hint is on screen.
     *
     * @param {string} icon - The icon name.
    */
    function SetIconOnScreen(icon) {
        if(typeof icon != "string") throw("HUD.HintInstructor.SetIconOnScreen: 'icon' must be a string, but got " + typeof icon)
        this.iconOnScreen = icon
        return this
    }

    /*
     * Sets the icon shown at the screen edge while the hint's target is off screen.
     *
     * @param {string} icon - The icon name.
    */
    function SetIconOffScreen(icon) {
        if(typeof icon != "string") throw("HUD.HintInstructor.SetIconOffScreen: 'icon' must be a string, but got " + typeof icon)
        this.iconOffScreen = icon
        return this
    }

    /*
     * Sets how long the hint stays visible, in seconds (default 5). 0 keeps it until Disable.
     *
     * @param {number} time - The hold time.
    */
    function SetHoldTime(time) {
        if(typeof time != "integer" && typeof time != "float") throw("HUD.HintInstructor.SetHoldTime: 'time' must be a number, but got " + typeof time)
        this.holdtime = time
        return this
    }

    /*
     * Sets the distance from the target at which the hint is visible, 0 for any distance.
     *
     * @param {number} distance - The distance in units.
    */
    function SetDistance(distance) {
        if(typeof distance != "integer" && typeof distance != "float") throw("HUD.HintInstructor.SetDistance: 'distance' must be a number, but got " + typeof distance)
        this.range = distance
        return this
    }

    /*
     * Sets the hint_pulseoption, hint_alphaoption and hint_shakeoption keyvalues.
     *
     * @param {number} sizePulsing - The size pulsing option.
     * @param {number} alphaPulsing - The alpha pulsing option.
     * @param {number} shaking - The shaking option.
    */
    function SetEffects(sizePulsing, alphaPulsing, shaking) {
        if(typeof sizePulsing != "integer" && typeof sizePulsing != "float") throw("HUD.HintInstructor.SetEffects: 'sizePulsing' must be a number, but got " + typeof sizePulsing)
        if(typeof alphaPulsing != "integer" && typeof alphaPulsing != "float") throw("HUD.HintInstructor.SetEffects: 'alphaPulsing' must be a number, but got " + typeof alphaPulsing)
        if(typeof shaking != "integer" && typeof shaking != "float") throw("HUD.HintInstructor.SetEffects: 'shaking' must be a number, but got " + typeof shaking)
        this.pulse = sizePulsing
        this.alphaPulse = alphaPulsing
        this.shake = shaking
        return this
    }
}
