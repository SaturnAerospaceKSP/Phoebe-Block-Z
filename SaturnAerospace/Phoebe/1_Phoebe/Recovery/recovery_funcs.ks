// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Recovery Funcs
// ------------------------

GLOBAL FUNCTION _DEPLOYGRIDFINS {
    FOR P in ship:partstagged("S1_FIN") {
            IF P:MODULES:CONTAINS("ModuleAnimateGeneric") { // If the parts contain the module
                LOCAL M is P:getmodule("ModuleAnimateGeneric"). // Get the module
                FOR A in M:ALLACTIONNAMES() { // For each action in action names
                    IF A:CONTAINS("Toggle Fins") {M:DOACTION(A, true).} // If the action names contain decoupling, decouple fairings
                }
            }
        } 
}

GLOBAL FUNCTION _DEPLOYLANDINGLEGS {
    FOR P in ship:partstagged("S1_LEG") {
            IF P:MODULES:CONTAINS("ModuleWheelDeployment") { // If the parts contain the module
                LOCAL M is P:getmodule("ModuleWheelDeployment"). // Get the module
                FOR A in M:ALLACTIONNAMES() { // For each action in action names
                    IF A:CONTAINS("Extend") {M:DOACTION(A, true).} // If the action names contain decoupling, decouple fairings
                }
            } 
        } 
}




// ------------------
// Guidance Logic
// ------------------

GLOBAL FUNCTION _STEERTOLANDINGZONE {
    parameter _PITCH IS 1, _OVSHTLATMOD is 0, _OVSHTLNGMOD is 0.

    set _OVSHTLATLNG to latlng(_FINAL_LANDING_TARGET:lat + _OVSHTLATMOD, _FINAL_LANDING_TARGET:lng + _OVSHTLNGMOD). // Sets overshooting distances
    set _TGTDIRECTION to _GEODIR(addons:tr:impactpos, _OVSHTLATLNG). // Set direction based on overshooting
    set _DISTANCETOIMPACT to _CALCDISTANCE(_OVSHTLATLNG, addons:tr:impactpos). // Distance to impact updates
    set _STEERDIRECTION to _TGTDIRECTION - 180. // Direction changer

    print "DIST TO IMPACT: " + _DISTANCETOIMPACT at (10, 10). 

    LOCK STEERING TO HEADING(_STEERDIRECTION, _PITCH, _ROLL).
}

GLOBAL FUNCTION _GEODIR {
    parameter geo1, geo2.

    return arcTan2(geo1:lng - geo2:lng, geo1:lat - geo2:lat).
}

GLOBAL FUNCTION _CALCDISTANCE {
    parameter geo1, geo2.

    return (geo1:position - geo2:position):mag.
}

GLOBAL FUNCTION _GETIMPACT {
    IF addons:tr:hasimpact {
        return addons:tr:impactpos.
        // return ship:position + (ship:velocity:surface:mag * addons:tr:timetillimpact - 3).
    }

    return ship:geoPosition.
}

GLOBAL FUNCTION _POSITIONERROR {
    return _GETIMPACT():position - _FINAL_LANDING_TARGET:position.
}

GLOBAL FUNCTION _STEERTOLZ {
    local _ERRORVECTOR is _POSITIONERROR().
    local _VELOCITYVECTOR is -ship:velocity:surface.
    local _RESULT is _VELOCITYVECTOR + _ERRORVECTOR * _ERRORSCALING.

    if vAng(_RESULT, _VELOCITYVECTOR) > _MAXAOA {
        set _RESULT to _VELOCITYVECTOR:normalized + tan(_MAXAOA) * _ERRORVECTOR:normalized.
    }

    return lookDirUp(_RESULT, facing:topvector).
}
