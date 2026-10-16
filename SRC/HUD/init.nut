/*+--------------------------------------------------------------------------------+
|                           PCapture Vscripts Library                              |
+----------------------------------------------------------------------------------+
| Author:                                                                          |
|     Interface Illusionist - laVashik :|                                          |
+----------------------------------------------------------------------------------+
|    The HUD module, providing tools to craft immersive and informative on-screen  | 
|    elements like text displays and interactive hints.                            |
+----------------------------------------------------------------------------------+ */ 

::HUD <- {}

// "R G B" from a Vector or a string, for the HUD color keyvalues. This function is not part of the public API
HUD["_ColorString"] <- function(color, caller) {
    if(typeof color == "Vector") return macros.VecToStr(color)
    if(typeof color == "string") return color
    throw(caller + ": 'color' must be a Vector or a string, but got " + typeof color)
}

IncludeScript("PCapture-LIB/SRC/HUD/game_text")
IncludeScript("PCapture-LIB/SRC/HUD/hint_instructor")