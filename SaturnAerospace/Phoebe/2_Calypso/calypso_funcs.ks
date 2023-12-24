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

GLOBAL FUNCTION _GET_DISTANCE { // Distance to desired craft
    PARAMETER _TARGETCRAFT.

    return _TARGETCRAFT:position:mag - ship:position:mag. // Distance between us & the station
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
    IF _ACTION = "TOGGLE SHROUD" {
        _CC_CAP:getmodule("ModuleAnimateGeneric"):doaction("Toggle Shroud", true).
    } ELSE IF _ACTION = "ABORT ABORT ABORT" {
        _CC_CAP:getmodule("ModuleEnginesFX"):doaction("Activate Engine", true).
    } ELSE IF _ACTION = "ABORT SHUTDOWN" {
        _CC_CAP:getmodule("ModuleEnginesFX"):doaction("Shutdown Engine", true).
    }
}