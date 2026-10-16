/*
 * On-screen text through game_text, built with chained calls:
 * HUD.ScreenText("Hello", 0.5, 0.4).SetHoldTime(2).Enable()
 *
 * A ScreenText holds only its settings. The library owns one game_text per channel and fills it on Enable,
 * so a ScreenText costs no entity: create as many as you like.
 *
 * What the engine does with it:
 * - There are 6 channels, 0 to 5. A new text on a channel replaces the one shown there, whoever sent it.
 * - Channels 2 and 3 use the chapter title fonts (InGameChapterSubtitle, InGameChapterTitle).
 * - While any game_text is on screen, instructor hints (HUD.HintInstructor) are paused.
 * - A text longer than 511 characters is cut.
 * All methods return the ScreenText itself, so calls chain
*/
HUD["ScreenText"] <- class {
    message = "";
    // -1 centers the text on that axis
    x = -1;
    y = -1;
    channel = 2;
    color = "170 170 170";
    color2 = "0 0 0";
    effect = 0;
    fadein = 0;
    fadeout = 0;
    fxtime = 0;
    holdtime = 10;

    /*
     * Creates a screen text. Nothing is shown until Enable.
     *
     * @param {string} message - The text.
     * @param {number} x - Horizontal position, 0 (left) to 1 (right), -1 to center. (optional, default -1)
     * @param {number} y - Vertical position, 0 (top) to 1 (bottom), -1 to center. (optional, default -1)
    */
    constructor(message, x = -1, y = -1) {
        this.SetText(message)
        this.SetPos(x, y)
    }

    /*
     * Shows the text on its channel, for the hold time.
     *
     * @param {CBaseEntity|pcapEntity} player - Show it to this player only (coop). (optional, default: all players)
    */
    function Enable(player = null) {
        local ent = HUD._ChannelText(this.channel)
        ent.__KeyValueFromString("message", this.message)
        ent.__KeyValueFromFloat("x", this.x)
        ent.__KeyValueFromFloat("y", this.y)
        ent.__KeyValueFromString("color", this.color)
        ent.__KeyValueFromString("color2", this.color2)
        ent.__KeyValueFromInt("effect", this.effect)
        ent.__KeyValueFromFloat("fadein", this.fadein)
        ent.__KeyValueFromFloat("fadeout", this.fadeout)
        ent.__KeyValueFromFloat("fxtime", this.fxtime)
        ent.__KeyValueFromFloat("holdtime", this.holdtime)
        HUD._DisplayChannelText(this.channel, ent, player)
        return this
    }

    /*
     * Hides whatever its channel shows, by putting an empty text there.
     * The empty text still pauses instructor hints for a few frames.
     *
     * @param {CBaseEntity|pcapEntity} player - Hide it for this player only (coop). (optional, default: all players)
    */
    function Disable(player = null) {
        local ent = HUD._ChannelText(this.channel)
        ent.__KeyValueFromString("message", "")
        ent.__KeyValueFromFloat("fadein", 0)
        ent.__KeyValueFromFloat("fadeout", 0)
        ent.__KeyValueFromFloat("holdtime", 0.01)
        HUD._DisplayChannelText(this.channel, ent, player)
        return this
    }

    /*
     * Sets the text. Shown on the next Enable.
     *
     * @param {string} message - The text.
    */
    function SetText(message) {
        if(typeof message != "string") throw("HUD.ScreenText.SetText: 'message' must be a string, but got " + typeof message)
        this.message = message
        return this
    }

    /*
     * Sets the position: 0 to 1 on each axis from the top left corner, -1 to center on that axis.
     *
     * @param {number} x - Horizontal position.
     * @param {number} y - Vertical position.
    */
    function SetPos(x, y) {
        if(typeof x != "integer" && typeof x != "float") throw("HUD.ScreenText.SetPos: 'x' must be a number, but got " + typeof x)
        if(typeof y != "integer" && typeof y != "float") throw("HUD.ScreenText.SetPos: 'y' must be a number, but got " + typeof y)
        this.x = x
        this.y = y
        return this
    }

    /*
     * Sets the channel, 0 to 5 (default 2). Texts on the same channel replace each other.
     *
     * @param {integer} channel - The channel.
    */
    function SetChannel(channel) {
        if(typeof channel != "integer" || channel < 0 || channel > 5) throw("HUD.ScreenText.SetChannel: 'channel' must be an integer from 0 to 5, but got " + channel)
        this.channel = channel
        return this
    }

    /*
     * Sets the text color.
     *
     * @param {Vector|string} color - The color, Vector(255, 0, 0) or "255 0 0".
    */
    function SetColor(color) {
        this.color = HUD._ColorString(color, "HUD.ScreenText.SetColor")
        return this
    }

    /*
     * Sets the second color, used by some effects (see SetEffect).
     *
     * @param {Vector|string} color - The color, Vector(255, 0, 0) or "255 0 0".
    */
    function SetColor2(color) {
        this.color2 = HUD._ColorString(color, "HUD.ScreenText.SetColor2")
        return this
    }

    /*
     * Sets the effect, the game_text `effect` keyvalue (Hammer lists 0 fade in/out, 1 credits, 2 scan out).
     *
     * @param {integer} effect - The effect.
    */
    function SetEffect(effect) {
        if(typeof effect != "integer" && typeof effect != "float") throw("HUD.ScreenText.SetEffect: 'effect' must be a number, but got " + typeof effect)
        this.effect = effect
        return this
    }

    /*
     * Sets the fade in time in seconds.
     *
     * @param {number} time - The fade in time.
    */
    function SetFadeIn(time) {
        if(typeof time != "integer" && typeof time != "float") throw("HUD.ScreenText.SetFadeIn: 'time' must be a number, but got " + typeof time)
        this.fadein = time
        return this
    }

    /*
     * Sets the fade out time in seconds.
     *
     * @param {number} time - The fade out time.
    */
    function SetFadeOut(time) {
        if(typeof time != "integer" && typeof time != "float") throw("HUD.ScreenText.SetFadeOut: 'time' must be a number, but got " + typeof time)
        this.fadeout = time
        return this
    }

    /*
     * Sets how long the text stays, in seconds (default 10).
     *
     * @param {number} time - The hold time.
    */
    function SetHoldTime(time) {
        if(typeof time != "integer" && typeof time != "float") throw("HUD.ScreenText.SetHoldTime: 'time' must be a number, but got " + typeof time)
        this.holdtime = time
        return this
    }

    /*
     * Sets the game_text `fxtime` keyvalue, used by the effects (see SetEffect).
     *
     * @param {number} time - The effect time in seconds.
    */
    function SetFXTime(time) {
        if(typeof time != "integer" && typeof time != "float") throw("HUD.ScreenText.SetFXTime: 'time' must be a number, but got " + typeof time)
        this.fxtime = time
        return this
    }
}


// channel -> its game_text, created on first use
HUD["_channelTexts"] <- array(6)

// This function is not part of the public API
HUD["_ChannelText"] <- function(channel) {
    local ent = HUD._channelTexts[channel]
    if(ent && ent.IsValid()) return ent

    ent = entLib.CreateByClassname("game_text", {channel = channel}).CBaseEntity
    HUD._channelTexts[channel] = ent
    return ent
}

// channel -> [time, player] of the last Display queued there
HUD["_lastDisplay"] <- array(6)

// "All players" for everyone. One player: the flag off and the player as the activator, game_text sends it to the activator only
HUD["_DisplayChannelText"] <- function(channel, ent, player) {
    ent.__KeyValueFromInt("spawnflags", player ? 0 : 1)

    // Display reads the keyvalues when it fires, so a second one in the same tick only repeats the first
    // And it isn't free: 20 in one tick on one channel lost the text of ANOTHER channel (in game, 5 were fine)
    local now = Time()
    local last = HUD._lastDisplay[channel]
    if(last && last[0] == now && last[1] == player) return
    HUD._lastDisplay[channel] = [now, player]

    EntFireByHandle(ent, "Display", "", 0, player)
}
