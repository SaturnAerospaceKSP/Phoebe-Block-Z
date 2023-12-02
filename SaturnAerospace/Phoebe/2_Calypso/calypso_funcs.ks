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




// -------------------------------
//        Calypso Control
// -------------------------------

GLOBAL FUNCTION _CALYPSOMOTORTHROTTLE {
    parameter _VALUE.

    lock throttle to _VALUE / 100.
}

GLOBAL FUNCTION _CALYPSOCAPSULEACTIONS {
    parameter _ACTION.

    IF _ACTION = "TOGGLE Shroud" {
        _CC_CAP:getmodule("ModuleAnimateGeneric"):doaction("Toggle Shroud", true).
    } ELSE IF _ACTION = "ABORT ABORT ABORT" {
        _CC_CAP:getmodule("ModuleEnginesFX"):doaction("Activate Engine", true).
    } ELSE IF _ACTION = "ABORT SHUTDOWN" {
        _CC_CAP:getmodule("ModuleEnginesFX"):doaction("Shutdown Engine", true).
    }
}