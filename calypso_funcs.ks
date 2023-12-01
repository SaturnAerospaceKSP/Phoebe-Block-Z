// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Calypso Funcs
// ------------------------

GLOBAL FUNCTION _CALYPSOABORT {
    _CALYPSOCAPSULEACTIONS("ABORT ABORT ABORT"). // Sends abort motors to ON
    
}

// ------------------------
//    Random Variables
// ------------------------
local _SHROUD_OPEN is false.

// -------------------------------
//        Calypso Control
// -------------------------------

GLOBAL FUNCTION _CALYPSOMOTORTHROTTLE {
    parameter _VALUE.

    lock throttle to _VALUE / 100.
}

GLOBAL FUNCTION _CALYPSOCAPSULEACTIONS { // Calypso Actions
    parameter _ACTION.
    IF _ACTION = "TOGGLE Shroud" {
        _CC_CAP:getmodule("ModuleAnimateGeneric"):doaction("Toggle Shroud", true).
        set _SHROUD_OPEN to true.
        _CC_CAP:GETMODULEBYINDEX(12):DOACTION("toggle rcs thrust", true).
    } ELSE IF _ACTION = "ABORT ABORT ABORT" {
        _CC_CAP:getmodule("ModuleEnginesFX"):doaction("Activate Engine", true).
        _CALYPSOMOTORTHROTTLE(100).
    } ELSE IF _ACTION = "ABORT SHUTDOWN" {
        _CC_CAP:getmodule("ModuleEnginesFX"):doaction("Shutdown Engine", true).
        _CALYPSOMOTORTHROTTLE(0).
    }
}

GLOBAL FUNCTION _CALYPSORCS { // Calypso RCS Control Unit
    parameter _DIR, _TOGGLE.
    local _ENABLED IS FALSE.

        FOR CC IN SHIP:PARTSTAGGED("CC_CAPSULE") {
        IF CC:MODULES:CONTAINS("ModuleRCSFX") {
            LOCAL M IS CC:GETMODULE("ModuleRCSFX").
            FOR A IN M:ALLACTIONNAMES()
            IF A:CONTAINS("toggle rcs thrust")
                IF _DIR = "FORE" and _TOGGLE = "ON" and _SHROUD_OPEN = true {
                    if _ENABLED = false {
                        M:doaction(a, true).
                        set ship:control:fore to 5.
                        set _ENABLED to true.
                    } ELSE IF _ENABLED = true {
                        set ship:control:fore to 5.
                        set _ENABLED to true.
                    }
                } ELSE IF _DIR = "REAR" and _TOGGLE = "ON" {
                    if _ENABLED = false {
                        M:doaction(a, true).
                        set ship:control:fore to -5.
                        set _ENABLED to true.
                    } ELSE IF _ENABLED = true {
                        set ship:control:fore to -5.
                        set _ENABLED to true.
                    }
                } ELSE IF _DIR = "PORT" and _TOGGLE = "ON" {
                    if _ENABLED = false {
                        M:doaction(a, true).
                        set ship:control:starboard to -5.
                        set _ENABLED to true.
                    } ELSE IF _ENABLED = true {
                        set ship:control:starboard to -5.
                        set _ENABLED to true.
                    }
                } ELSE IF _DIR = "STARBOARD" and _TOGGLE = "ON" {
                    if _ENABLED = false {
                        M:doaction(a, true).
                        set ship:control:starboard to 5.
                        set _ENABLED to true.
                    } ELSE IF _ENABLED = true {
                        set ship:control:starboard to 5.
                        set _ENABLED to true.
                    }
                } ELSE IF _DIR = "PITCH UP" and _TOGGLE = "ON" {
                    if _ENABLED = false {
                        M:doaction(a, true).
                        set ship:control:top to -5.
                        set _ENABLED to true.
                    } ELSE IF _ENABLED = true {
                        set ship:control:top to -5.
                        set _ENABLED to true.
                    }
                } ELSE IF _DIR = "PITCH DOWN" and _TOGGLE = "ON" {
                    if _ENABLED = false {
                        M:doaction(a, true).
                        set ship:control:top to 5.
                        set _ENABLED to true.
                    } ELSE IF _ENABLED = true {
                        set ship:control:top to 5.
                        set _ENABLED to true.
                    }                    
                } ELSE IF _DIR = "FORE" or "REAR" or "PORT" or "STARBOARD" or "PITCH UP" or "PITCH DOWN" and _TOGGLE = "OFF" {
                    if _ENABLED = false {
                        set ship:control:fore to 0.
                        set ship:control:top to 0.
                        set ship:control:starboard to 0.
                        set _ENABLED to false.
                    } ELSE IF _ENABLED = true {
                        M:DOACTION(a, true).
                        set ship:control:fore to 0.
                        set ship:control:top to 0.
                        set ship:control:starboard to 0.
                        set _ENABLED to false.
                    }
                }  
        }
    }
}
