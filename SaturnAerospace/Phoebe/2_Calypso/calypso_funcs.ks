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









// -----------------------
//        LIB GNC
// -----------------------

GLOBAL FUNCTION _EXECUTE_NODE { // Executes any node created by kOS or the user (not only used by Calypso )
    PARAMETER _MAXTHRUST is ship:maxthrust, _ISRCS is false, _CTRLFACE is "REAR", _NODETOL is 1.5. // Either Fore Or Top for CTRL Face

    set ship:control:neutralize to true.
    rcs off.

    // Maneuver Timing and Prep
        lock _NORMVEC to vCrs(ship:prograde:vector, body:position).
        lock steering to lookDirUp(ship:retrograde:vector, _NORMVEC).

        local _BURNCOMPLETE is false.
        local _NODETOLERANCE is _NODETOL.
        local _NEXTNODE is nextnode. 
        local _MAXACCEL is _MAXTHRUST / ship:mass.
        local _BURNTIME is _NEXTNODE:deltav:mag / _MAXACCEL.

        IF (_ISRCS = true) {rcs on.}
        ELSE {RCS OFF.}

        lock _NV to _NEXTNODE:deltav:normalized. // Make sure it'll update the parameter by locking
        
        IF (_CTRLFACE = "FORE") {
            lock steering to lookDirUp(_NV, _NORMVEC).
        } ELSE {
            lock steering to lookDirUp(-_NEXTNODE:deltav, _NORMVEC).
        }
        


    // Maneuver Execution Code
        until nextnode:eta <= (_BURNTIME / 2) {
            print "ETA NODE: " + nextNode:eta + "    "  at (1,1).
            print "BURN TIME: " +  _BURNTIME / 2 + "   " at (1,2).

            wait 0.
        }

        until _BURNCOMPLETE {
            set _MAXACCEL to _MAXTHRUST / ship:mass.

            print _NEXTNODE:deltav:mag + "     " at (1,1).

            IF (_ISRCS = true) {
                _RCSTRANSLATE(_NV). // For RCS (Calypso Mainly)
            } ELSE {
                lock throttle to min(_NEXTNODE:deltav:mag / _MAXACCEL, 1). // For engines
            }


            IF (_NEXTNODE:deltav:mag < _NODETOLERANCE) { // If we are within the limit of the node tolerance, stop the burn
                set ship:control:neutralize to true. // Rcs stop
                lock throttle to 0. // For Engines
                set _BURNCOMPLETE to true. // Stop the loop
            }

            wait 0.
        }



    // Cleanup Section
        rcs off.
        
        lock steering to lookDirUp(ship:retrograde:vector, _NORMVEC).
        wait 5.
}

GLOBAL FUNCTION _RCSTRANSLATE { // Translating using RCS Thrusters
    parameter _TARGVECTOR.
    
    IF _TARGVECTOR:mag > 1 {set _TARGVECTOR to _TARGVECTOR:normalized.}

    // Nullify the redundant contorls
        set ship:control:fore to (_TARGVECTOR * ship:facing:forevector). // This should be minus because we point rearward
        set ship:control:starboard to (_TARGVECTOR * ship:facing:starvector).
        set ship:control:top to (_TARGVECTOR * ship:facing:topvector).

        wait 0.
}

FUNCTION OrbitTangent {
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}

FUNCTION OrbitBinormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, OrbitTangent(ves)):normalized.
}

FUNCTION TargetBinormal {
    parameter ves is target.

    return vcrs((ves:position - ves:body:position):normalized, OrbitTangent(ves)):normalized.
}

FUNCTION AngToRAN {
    parameter OrbitBinormal is OrbitBinormal().
    parameter TargetBinormal is TargetBinormal().

    local joinVector is RelativeNodalVector(OrbitBinormal, TargetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(OrbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

FUNCTION AngToRDN {
    parameter OrbitBinormal is OrbitBinormal().
    parameter TargetBinormal is TargetBinormal().

    local joinVector is -RelativeNodalVector(OrbitBinormal, TargetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(OrbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

FUNCTION RelativeNodalVector {
    parameter OrbitBinormal is OrbitBinormal().
    parameter TargetBinormal is TargetBinormal().

    return vcrs(OrbitBinormal, TargetBinormal):normalized.
}

FUNCTION _TIMETONODE {
	local TA0 is ship:orbit:trueanomaly. 
	local ANTA is mod(360 + TA0 + AngToRAN(), 360).	// TA is True Anomaly
	local DNTA is mod(ANTA + 180, 360).

	// 1 is AN, 2 is DN
	local ecc is ship:orbit:eccentricity.
	local SMA is ship:orbit:semimajoraxis.

	local t0 is time:seconds.
	local MA0 is mod(mod(t0 - ship:orbit:epoch, ship:orbit:period) / ship:orbit:period * 360 + ship:orbit:meananomalyatepoch, 360).

	local EA1 is mod(360 + arctan2(sqrt(1 - ecc^2) * sin(ANTA), ecc + cos(ANTA)), 360).
	local MA1 is EA1 - ecc * constant:radtodeg * sin(EA1).
	local t1 is mod(360 + MA1 - MA0, 360) / sqrt(ship:body:mu / SMA^3) / constant:radtodeg + t0.

	local EA2 is mod(360 + arctan2(sqrt(1 - ecc^2) * sin(DNTA), ecc + cos(DNTA)), 360).
	local MA2 is EA2 - ecc * constant:radtodeg * sin(EA2).
	local t2 is mod(360 + MA2 - MA0, 360) / sqrt(ship:body:mu / SMA^3) / constant:radtodeg + t0.

	return min(t2 - t0, t1 - t0).
}

FUNCTION _NODEPLANECHANGE {
	local TA0 is ship:orbit:trueanomaly. 
	local ANTA is mod(360 + TA0 + AngToRAN(), 360).	// TA is True Anomaly
	local DNTA is mod(ANTA + 180, 360).

	local SMA is ship:orbit:semimajoraxis.
	local ecc is ship:orbit:eccentricity.

	local rad1 is SMA * (1 - ecc * cos(ANTA)).
	local rad2 is SMA * (1 - ecc * cos(DNTA)).

	local Vv1 is sqrt(ship:body:mu * ((2 / rad1) - (1 / SMA))).
	local Vv2 is sqrt(ship:body:mu * ((2 / rad2) - (1 / SMA))).

	local angChange1 is (2 * Vv1 * sin(Trig() / 2)).
	local angChange2 is (2 * Vv2 * sin(Trig() / 2)).

	return min(angChange1, angChange2).
}

FUNCTION _HOHMANN {
	parameter burn.

	if (burn = "raise") {
		local targetSMA is ((target:altitude + ship:altitude + (ship:body:radius * 2)) / 2).
		local targetVel is sqrt(ship:body:mu * (2 / (ship:body:radius + ship:altitude) - (1 / targetSMA))).
    	local currentVel is sqrt(ship:body:mu * (2 / (ship:body:radius + ship:altitude) - (1 / ship:orbit:semimajoraxis))).
	
		return (targetVel - currentVel). 
	}
	else if (burn = "circ") {
		local targetVel is sqrt(ship:body:mu / (ship:orbit:body:radius + ship:orbit:apoapsis)).
    	local currentVel is sqrt(ship:body:mu * ((2 / (ship:body:radius + ship:orbit:apoapsis) - (1 / ship:orbit:semimajoraxis)))).
    	
		return (targetVel - currentVel).
	}		
}

FUNCTION _PHASEANGLE {
	local transferSMA is (target:orbit:semimajoraxis + ship:orbit:semimajoraxis) / 2.
	local transferTime is (2 * constant:pi * sqrt(transferSMA^3 / ship:body:mu)) / 2.
	local transferAng is 180 - ((transferTime / target:orbit:period) * 360).

	local univRef is ship:orbit:lan + ship:orbit:argumentofperiapsis + ship:orbit:trueanomaly.
	local compareAng is target:orbit:lan + target:orbit:argumentofperiapsis + target:orbit:trueanomaly.
	local phaseAng is (compareAng - univRef) - 360 * floor((compareAng - univRef) / 360).
	
    local DegPerSec is  (360 / ship:orbit:period) - (360 / target:orbit:period).
    local angDiff is transferAng - phaseAng.

    local t is angDiff / DegPerSec.

	return abs(t).
}

FUNCTION Trig {
	parameter res is "angChange".	// add parameters as much as you can squeeze out in this trigonometry relations

    local i1 is ship:orbit:inclination.
    local i2 is target:orbit:inclination.
    local o1 is ship:orbit:lan.
    local o2 is target:orbit:lan.

    local a1 is sin(i1) * cos(o1).
    local a2 is sin(i1) * sin(o1).
    local a3 is cos(i1).

    local b1 is sin(i2) * cos(o2).
    local b2 is sin(i2) * sin(o2).
    local b3 is cos(i2).

	local angChange is arccos((a1 * b1) + (a2 * b2) + (a3 * b3)).

	if (res = "angChange") { return angChange. }
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