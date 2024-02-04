// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Flight Funcs
// ------------------------

GLOBAL FUNCTION _RCSCU { // RCS Control Unit
    parameter _DIR is "NO CHANGE", _STAGE is "STAGE 2", _TOGGLE is "none".  
    // revison 2 simplifies the code and toggles RCS based on what we want, rather than assuming it is either on or off
    // under revision 0 and revision 1 potentially if you didnt know what state RCS was in, you could do what you arent intending to, i.e turning it off when you want it on]
    // Also revision 2 allows for the _TOGGLE state to be set directly

    IF _STAGE = "STAGE 1" { // set me an example
        local _rcsSetValue is 0.
        IF _DIR = "FORE" {
            set _rcsSetValue to 1. // can only be from -1 to 1, not to a max of 5
        } ELSE IF _DIR = "REAR" {
            set _rcsSetValue to -1.
        }
        IF NOT(_TOGGLE = "NONE") {
            _S1_CGT:getmodule("ModuleRCSFX"):setfield("RCS", _TOGGLE = "on").
        }
        IF NOT(_DIR = "NO CHANGE") {
            set ship:control:fore to _rcsSetValue.
        }
        
    } ELSE IF _STAGE = "STAGE 2" {
        local _rcsSetValue is 0.
        IF _DIR = "FORE" {
            set _rcsSetValue to 1. // can only be from -1 to 1, not to a max of 5
        } ELSE IF _DIR = "REAR" {
            set _rcsSetValue to -1.
        }
        IF NOT(_TOGGLE = "NONE") {
            _S2_RCS:getmodule("ModuleRCSFX"):setfield("RCS", _TOGGLE = "on").
        }
        IF NOT(_DIR = "NO CHANGE") {
            set ship:control:fore to _rcsSetValue.
        }
    } ELSE IF _STAGE = "SIDE BOOSTERS" {
        local _rcsSetValue is 0.
        IF _DIR = "FORE" {
            set _rcsSetValue to 1. // can only be from -1 to 1, not to a max of 5
        } ELSE IF _DIR = "REAR" {
            set _rcsSetValue to -1.
        }
        IF NOT(_TOGGLE = "NONE") {
            _SB_CGT:getmodule("ModuleRCSFX"):setfield("RCS", _TOGGLE = "on").
        }
        IF NOT(_DIR = "NO CHANGE") {
            set ship:control:fore to _rcsSetValue.
        }
    } ELSE IF _STAGE = "CALYPSO" {
        // IF _DIR = "FORE" and _TOGGLE = "on" {
        //     __CGT:getmodule("ModuleRCSFX"):doaction("toggle rcs thrust", true).
        //     set ship:control:fore to 5.
        // } ELSE IF _DIR = "REAR" and _TOGGLE = "on" {
        //     _S1_CGT:getmodule("ModuleRCSFX"):doaction("toggle rcs thrust", true).
        //     set ship:control:fore to -5.
        // } ELSE IF _DIR = "FORE" and _TOGGLE = "off" {
        //     _S1_CGT:getmodule("ModuleRCSFX"):doaction("toggle rcs thrust", true).
        //     set ship:control:fore to 0.
        // } ELSE IF _DIR = "REAR" and _TOGGLE = "off" {
        //     _S1_CGT:getmodule("ModuleRCSFX"):doaction("toggle rcs thrust", true).
        //     set ship:control:fore to 0.
        // }

        // Calypso RCS having multiple modules causing issues?
        // Read through dragon methods, could be of use
    }

}

GLOBAL FUNCTION _DEPLOYSIDEBOOSTERS { // Separates side boosters 
    FOR P in ship:partstagged("SB_DEC") {
            IF P:MODULES:CONTAINS("ModuleTundraAnchoredDecoupler") { // If the parts contain the module
                LOCAL M is P:getmodule("ModuleTundraAnchoredDecoupler"). // Get the module
                FOR A in M:ALLACTIONNAMES() { // For each action in action names
                    if A:CONTAINS("Decouple") {M:DOACTION(A, true). set _SIDEBOOSTERS_ATTACHED to false.} // If the action names contain decoupling, decouple side boosters
                }
            }
        }
}

GLOBAL FUNCTION _DEPLOYFAIRINGS { // Deploys Vehicle Payload Fairings when able
    IF ship:altitude >= _FAIRING_DEPLOYALTITUDE and ship:dynamicpressure <= _FAIRING_DEPLOYPRESSURE and _FAIRINGS_ATTACHED { // Checks to see the current parameters
        FOR P in ship:partstagged("S2_PLF") {
            IF P:MODULES:CONTAINS("ModuleDecouple") { // If the parts contain the module
                LOCAL M is P:getmodule("ModuleDecouple"). // Get the module
                FOR A in M:ALLACTIONNAMES() { // For each action in action names
                    if A:CONTAINS("Decouple") {M:DOACTION(A, true). set _FAIRINGS_ATTACHED to false.} // If the action names contain decoupling, decouple fairings
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
    IF _FAIRINGS_ATTACHED = false and _PAYLOADCOUNT = 1 {
        _S2_PLS:getmodule("ModuleDecouple"):doaction("Decouple", true).
    } ELSE IF _FAIRINGS_ATTACHED = false and _PAYLOADCOUNT > 1 {
        set _PAYLOADSDEPLOYED to 0.

        toggle ag8. // Can be toggled for further stage activation
        until _PAYLOADSDEPLOYED = _PAYLOADCOUNT {
            stage. // Separates 

            wait 5. // 4 Seconds between each separation
            set _PAYLOADSDEPLOYED to _PAYLOADSDEPLOYED + 1. /// Quasy Quasy Quasy if you see this the code is still a copy
        }
    } ELSE {
        wait until _FAIRINGS_ATTACHED = false.
    }
} 

GLOBAL FUNCTION _ORBITSHUTDOWNPROCEDURE { // Shuts down unneccesary things and deorbits S2 if applicable
    
}

GLOBAL FUNCTION _LAUNCH_AZIMUTH { // From KSLib
    PARAMETER _TARGET_INCLINE, _ORBIT_ALT, _RAW is false, _AUTOSWITCH is false.

    LOCAL _SHIP_LAT is ship:latitude.
    LOCAL _RAW_HEAD IS 0. // Azimuth without auto switch

    IF ABS(_TARGET_INCLINE) < abs(_SHIP_LAT) {set _TARGET_INCLINE TO _SHIP_LAT.}
    IF (_TARGET_INCLINE > 180) {set _TARGET_INCLINE to -360 + _TARGET_INCLINE.}
    IF (_TARGET_INCLINE < -180) {set _TARGET_INCLINE to 360 + _TARGET_INCLINE.}
    IF hasTarget {SET _AUTOSWITCH to true.}

    LOCAL _HEAD IS arcSin(max(min(cos(_TARGET_INCLINE) / cos(_SHIP_LAT), 1), -1)).
    set _RAW_HEAD to _HEAD.

    IF _AUTOSWITCH {
        IF _NODE_SIGN_TARGET() > 0 {set _HEAD to 180 - _HEAD.}
    } ELSE IF (_TARGET_INCLINE < 0) {set _HEAD to 180 - _HEAD.}

    LOCAL _EQ_VEL is (2 * constant:pi * body:radius) / body:rotationperiod.
    local _V_ORBIT is sqrt(body:mu / (_ORBIT_ALT + body:radius)).
    LOCAL _V_ROT_X is _V_ORBIT * sin(_HEAD) - (_EQ_VEL * cos(_SHIP_LAT)).
    LOCAL _V_ROT_Y is _V_ORBIT * cos(_HEAD).
    
    SET _HEAD TO 90 - arcTan2(_V_ROT_Y, _V_ROT_X).

    IF _RAW {return mod(_RAW_HEAD + 360, 360).}
    ELSE {return mod(_HEAD + 360, 360).}
}

LOCAL FUNCTION _NODE_SIGN_TARGET { // approaching AN or DN
	if (hasTarget) {
		local joinVec is vcrs(_ORBIT_BINORMAL(), _TARGET_BINORMAL()):normalized.
		local signVec is vcrs(-body:position:normalized, joinVec):normalized.
		local sign is vdot(_ORBIT_BINORMAL(), signVec).

		if (sign > 0) { return 1. }
		else { return -1. }
	} 
	else { return 1. }
}

function _ORBIT_TANGENT { // ship velocity
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}

LOCAL FUNCTION _ORBIT_BINORMAL { // ship binormal
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, _ORBIT_TANGENT(ves)):normalized.
}

LOCAL FUNCTION _TARGET_BINORMAL { // target binormal
    parameter ves is target.

    return vcrs((ves:position - ves:body:position):normalized, _ORBIT_TANGENT(ves)):normalized.
}

GLOBAL FUNCTION _INCLINE_MANAGER { // Copied from raizspace code on the shuttle to correct inclination
    parameter maxDeviation.
	
	set incDiff to SHIP:ORBIT:INCLINATION - _INCLINETARGET.

	if incDiff > 0.05 {
		if _PROGRADE_HEAD < 90 AND _INCLINE_CORRECTION < maxDeviation{
			set _INCLINE_CORRECTION to _INCLINE_CORRECTION + (maxDeviation/100).
		}
		if _PROGRADE_HEAD > 90 AND _INCLINE_CORRECTION > -maxDeviation{
			set _INCLINE_CORRECTION to _INCLINE_CORRECTION - (maxDeviation/100).
		}
	}
	if incDiff < -0.05{
		if _PROGRADE_HEAD < 90 AND _INCLINE_CORRECTION > -maxDeviation{
			set _INCLINE_CORRECTION to _INCLINE_CORRECTION - (maxDeviation/100).
		}
		if _PROGRADE_HEAD > 90 AND _INCLINE_CORRECTION < maxDeviation{
			set _INCLINE_CORRECTION to _INCLINE_CORRECTION + (maxDeviation/100).
		}
	}
	
	if incDiff < 0.05 AND incDiff > -0.05{
		if _INCLINE_CORRECTION > 0{
			set _INCLINE_CORRECTION to _INCLINE_CORRECTION - (maxDeviation/100).
		}
		
		if _INCLINE_CORRECTION < 0{
			set _INCLINE_CORRECTION to _INCLINE_CORRECTION + (maxDeviation/100).
		}
	}	
}

GLOBAL FUNCTION _HEADING_OF_VECTOR {
    PARAMETER VECT.

    LOCAL EAST IS VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR).

    LOCAL TRIG_X IS VDOT(SHIP:NORTH:VECTOR, VECT).
    LOCAL TRIG_Y IS VDOT(EAST, VECT).

    LOCAL RESULT IS ARCTAN2(TRIG_Y, TRIG_X).

    IF RESULT < 0 {RETURN 360 + RESULT.} ELSE {RETURN RESULT.}
}





// ---------------------------
//     Guidance Functions
// ---------------------------

GLOBAL FUNCTION _HEADINGANDPITCHCONTROL {
    parameter _STAGE.

    IF _STAGE = "STAGE 1" { // GRAVITY TURN
        set _HEADING_CONTROL to _LAUNCH_AZIMUTH(_INCLINETARGET, _APOGEETARGET). // Heading Azimuth to stay on correct inclination
        set _PITCH_CONTROL to max(_GRAVITYTURN_ENDANGLE, 90 * (1 - ship:altitude / _GRAVITYTURN_ENDALTITUDE)). // Pitchover, meets end angle at end altitude
    } ELSE IF _STAGE = "STAGE 2" { // OPEN / CLOSED / TERMINAL GUIDANCE
        IF _APOGEETARGET > body:atm:height + 20000 {
            set _APOAPSISOFFSET to ship:apoapsis - body:atm:height. // Works on guidance from the Start of earth's space border
        } ELSE {
            set _APOAPSISOFFSET to ship:apoapsis - _APOGEETARGET. // Use the apogee for insertion altitude
        }

        set _HALVEDETA to 15 - eta:apoapsis. 

        set _HEADING_CONTROL to _LAUNCH_AZIMUTH(_INCLINETARGET, _APOGEETARGET). // Heading Azimuth to stay on correct inclination
        set _PITCH_CONTROL to (_HALVEDETA * 2) + ((_APOAPSISOFFSET / 5000) * 10). // Controls vehicle pitch to finish on target

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

GLOBAL FUNCTION _ORBITALVELOCITY {
    parameter r1 is apoapsis, r2 is periapsis, r3 is altitude.
    
    set r1 to r1+body:radius.
    set r2 to r2+body:radius.
    set r3 to r3+body:radius.

    local _a is (r1+r2)/2. // _SEMIMAJORAXIS
    local __V is (body:mu * ((2 / (r3)) - (1/_a))) ^ 0.5.
    return __V.
}