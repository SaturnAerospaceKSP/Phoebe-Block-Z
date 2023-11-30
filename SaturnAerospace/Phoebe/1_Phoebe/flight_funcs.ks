// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Flight Funcs
// ------------------------

GLOBAL FUNCTION _STEER_HEADING { // Replaces default heading steer
    parameter _HEAD, _PITCH, _ROLLPOINT is 0.

    lock steering to heading(_HEAD, _PITCH, _ROLLPOINT).
}

GLOBAL FUNCTION _STEER_DIRECT { // Replaces directional steer
    parameter _DIRECT.

    lock steering to _DIRECT.
}

GLOBAL FUNCTION _RCSCU { // RCS Control Unit
    parameter _DIR, _STAGE, _TOGGLE.

    FOR S1 in ship:partstagged(_S1_CGT) {
        if S1:Modules:CONTAINS("ModuleRCSFX") {
            local M is S1:Getmodule("ModuleRCSFX").
            for A in M:ALLACTIONNAMES()
                IF A:CONTAINS("toggle rcs thrust")
                IF _STAGE = "STAGE 1" {
                    IF _DIR = "FORE" and _TOGGLE = "ON" {
                        M:doaction(a, true).
                        set ship:control:fore to 5.
                    } ELSE IF _DIR = "REAR" and _TOGGLE = "ON" {
                        M:doaction(a, true).
                        set ship:control:fore to -5.
                    } ELSE IF _DIR = "FORE" or "REAR" and _TOGGLE = "OFF" {
                        M:doaction(a, true).
                        set ship:control:fore to 0.
                    }  
                } 
        }
    } 
    FOR S2 IN SHIP:PARTSTAGGED(_S2_RCS) {
        IF S2:MODULES:CONTAINS("ModuleRCSFX") {
            LOCAL M IS S2:GETMODULE("ModuleRCSFX").
            FOR A IN M:ALLACTIONNAMES()
            IF A:CONTAINS("toggle rcs thrust")
                IF _STAGE = "STAGE 2" {
                    IF _DIR = "FORE" and _TOGGLE = "ON" {
                        M:doaction(a, true).
                        set ship:control:fore to 5.
                    } ELSE IF _DIR = "REAR" and _TOGGLE = "ON" {
                        M:doaction(a, true).
                        set ship:control:fore to -5.
                    } ELSE IF _DIR = "FORE" or "REAR" and _TOGGLE = "OFF" {
                        M:doaction(a, true).
                        set ship:control:fore to 0.
                    }  
                } 
        }
    }
    FOR SB IN SHIP:PARTSTAGGED(_SB_CGT) {
        IF SB:MODULES:CONTAINS("ModuleRCSFX") {
            LOCAL M IS SB:GETMODULE("ModuleRCSFX").
            FOR A IN M:ALLACTIONNAMES()
            IF A:CONTAINS("toggle rcs thrust")
                IF _STAGE = "SIDE BOOSTERS" {
                    IF _DIR = "FORE" and _TOGGLE = "ON" {
                        M:doaction(a, true).
                        set ship:control:fore to 5.
                    } ELSE IF _DIR = "REAR" and _TOGGLE = "ON" {
                        M:doaction(a, true).
                        set ship:control:fore to -5.
                    } ELSE IF _DIR = "FORE" or "REAR" and _TOGGLE = "OFF" {
                        M:doaction(a, true).
                        set ship:control:fore to 0.
                    }  
                } 
        }
    }
    
}

GLOBAL FUNCTION _ECUTHROTTLE { // Replaces default throttle
    parameter _TGT.

    lock throttle to _TGT / 100.
}

GLOBAL FUNCTION _DEPLOYFAIRINGS { // Deploys Vehicle Payload Fairings when able
    IF ship:altitude >= _FAIRING_DEPLOYALTITUDE and ship:dynamicpressure <= _FAIRING_DEPLOYPRESSURE and _FAIRINGS_ATTACHED { // Checks to see the current parameters
        FOR P in ship:partstagged("S2_PLF") {
            IF P:MODULES:CONTAINS("ModuleDecouple") { // If the parts contain the module
                LOCAL M is P:getmodule("ModuleDecouple"). // Get the module
                FOR A in M:ALLACTIONNAMES() { // For each action in action names
                    if A:CONTAINS("Decouple") {M:DOACTION(A, true).} // If the action names contain decoupling, decouple fairings
                }
            }
        }
    }
}

GLOBAL FUNCTION _DEPLOYCALYPSO { // Separates Calypso from the Second Stage
    wait 5. // Adds separation for vehicle to settle
    _CC_DEC:getmodule("ModuleDecouple"):doaction("Decouple", true). // Separation

}

GLOBAL FUNCTION _PAYLOADSEPARATION { // Deploys payload(s) into orbit after flight

} 

GLOBAL FUNCTION _ORBITSHUTDOWNPROCEDURE { // Shuts down unneccesary things and deorbits S2 if applicable
    
}



// ---------------------------
//     Guidance Functions
// ---------------------------

GLOBAL FUNCTION _HEADINGANDPITCHCONTROL {
    parameter _STAGE.

    IF _STAGE = "STAGE 1" { // GRAVITY TURN
        GLOBAL _HEADING_CONTROL is LAZcalc(_AZIMUTHCALCULATION). // Heading Azimuth to stay on correct inclination
        GLOBAL _PITCH_CONTROL is max(_GRAVITYTURN_ENDANGLE, 90 * (1 - ship:altitude / _GRAVITYTURN_ENDALTITUDE)). // Pitchover, meets end angle at end altitude
    } ELSE IF _STAGE = "STAGE 2" { // OPEN / CLOSED / TERMINAL GUIDANCE
        GLOBAL _APOAPSISOFFSET is ship:apoapsis - body:atm:height. // Works on guidance from the Target Apoapsis
        GLOBAL _HALVEDETA is 15 - eta:apoapsis. 

        GLOBAL _HEADING_CONTROL is LAZcalc(_AZIMUTHCALCULATION). // Azimuth like stage 1 for correct incline
        GLOBAL _PITCH_CONTROL is (_HALVEDETA * 2) + ((_APOAPSISOFFSET / 5000) * 10). // Controls vehicle pitch to finish on target

        print "HEAD TGT: " + _HEADING_CONTROL at (10, 10).
        print "PITCH TGT: " + _PITCH_CONTROL at (10, 11).
    }
}

GLOBAL FUNCTION _ORBITALVELOCITYPERIGEE {
    parameter _APOGEE, _PERIGEE.

    local _SEMIMAJORAXIS is body:radius + (_APOGEE + _PERIGEE) / 2.
    local _V is (body:mu * ((2 / (_PERIGEE)) - (1 / _SEMIMAJORAXIS))) ^ 0.5.

    return _V.
}

GLOBAL FUNCTION _ORBITALVELOCITYAPOGEE {
    parameter _APOGEE, _PERIGEE.

    local _SEMIMAJORAXIS is body:radius + (_APOGEE + _PERIGEE) / 2.
    local _V is (body:mu * ((2 / (_APOGEE)) - (1 / _SEMIMAJORAXIS))) ^ 0.5.

    return _V.
}
