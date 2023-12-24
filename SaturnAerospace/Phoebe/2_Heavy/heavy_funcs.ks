// Saturn Aerospace 2024
// 
// Made By Quasy & EVE, including software from Marcus House (hey hey)
// Phoebe Block Z
// 
// ------------------------
//     Heavy Funcs
// ------------------------

GLOBAL FUNCTION _SETUPVARIABLES {
    // Landing Zones
        set _BOOSTER1_LZ to latlng(28.2140920160773, -80.3049028987299).
        set _BOOSTER2_LZ to latlng(28.2152200476183, -80.3108388947316).
        set _LANDINGBURN_ALT to 1900.

    // Booster Offset
        set _BOOSTER1_RDROFFSET to 24.5.
        set _BOOSTER2_RDROFFSET to 24.5. // Offset on altitude for the booster
        set _BOOSTER_ADJUSTPITCH to 10. // Adjust Pitch 
        set _BOOSTER_ADJUSTLAT to 0. // Latitude offset 
        set _BOOSTER_ADJUSTLNG to -0.25. // Sets overshooting distance

    // Variables
        set steeringManager:maxstoppingtime to 5. // Turn Speed
        set steeringManager:rollts to 5. // Roll Speed
        set _BOOSTER_LANDMODE to true. // Landing? 
        set _LOOPING to true. // Looping for functions
        set _STEERINGDIR to 90. // Initial Steering Direction
        set _GEODIST to 1. // Baseline Variable
        set _ERRORSCALING to 1. // Error Correction amount (higher = more corrections)
        set _AOA to 0. // Angle Of Attack Limit

    // Suicide
        set _G to constant:g * body:mass / body:radius ^ 2.
        set _DISTMARGIN to 1300.
        set _MAXVERTACC to ship:availablethrust / ship:mass - _G.
        set _VERTACC to _SPROJ(ship:sensors:acc, up:vector).
        set _DRAGACC to _G + _VERTACC.
        set _SUICIDE_BURNDISTANCE to (ship:verticalspeed ^ 2 / (2 * (_MAXVERTACC + _DRAGACC / 2))) + _DISTMARGIN.
        set _IMPACTDIST to 1.
}

GLOBAL FUNCTION _SET_TRUERADAR { // Sets true radar (altitude - booster offset) for landing 
    IF _ISBOOSTER("B1") {
        lock _TRUERADAR to alt:radar - _BOOSTER1_RDROFFSET.
    } ELSE IF _ISBOOSTER("B2") {
        lock _TRUERADAR to alt:radar - _BOOSTER2_RDROFFSET.
    }
}

GLOBAL FUNCTION _GET_SUICIDEBURN_THROTTLE { // Variables for suicide burn
    lock _G to constant:g * body:mass / body:radius ^ 2.
    lock _MAX_DECEL to (ship:availablethrust / ship:mass) - _G.
    lock _STOP_DISTANCE to (ship:verticalspeed ^ 2 / (2 * _MAX_DECEL)).

    return _STOP_DISTANCE / _TRUERADAR.
}

GLOBAL FUNCTION _BOOSTER_STEERTOLZ {
    parameter _PITCH is 0, _OVSHTLAT is 0, _OVSHTLNG is 0.

    set _OVSHTLATLNG to latlng(_BOOSTER1_LZ:lat + _OVSHTLAT, _BOOSTER1_LZ:lng + _OVSHTLNG).

    set _TARGETDIRECTION to _GEODIR(addons:tr:impactpos, _OVSHTLATLNG).
    set _IMPACTDIST to _CALCDISTANCE(_OVSHTLATLNG, addons:tr:impactpos).

    set _STEERINGDIR to _TARGETDIRECTION - 180.
    print _IMPACTDIST at (10, 10).

    lock steering to heading(_STEERINGDIR, _PITCH).
}

GLOBAL FUNCTION _SET_HOVERPIDLOOPS {

	SET bodyRadius TO 1700. //note Kerbin is around 1700
	
	//Controls altitude by changing climbPID setpoint
	SET hoverPID TO PIDLOOP(1, 0.01, 0.0, -50, 50). 
	//Controls vertical speed
	SET climbPID TO PIDLOOP(0.1, 0.3, 0.005, 0, 1). 
	//Controls horizontal speed by tilting rocket
	SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20).
	SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20). 
	 //controls horizontal position by changing velPID setpoints
	SET eastPosPID TO PIDLOOP(bodyRadius, 0, 100, -40,40).
	SET northPosPID TO PIDLOOP(bodyRadius, 0, 100, -40,40).

}

GLOBAL FUNCTION _SPROJ {
    parameter a, b.

    IF b:mag = 0 {print "SPROJ: DIVIDE BY 0, Returning 1" at (10,11). return 1.}
    return vDot(a,b) * (1/b:mag).
}

GLOBAL FUNCTION _C_VELOCITY {
    local _VELOCITY_SURF is ship:velocity:surface.
    local _E_VECTOR is vCrs(up:vector, north:vector).
    local _E_COMPEN is _SPROJ(velocity, _E_VECTOR).
    local _N_COMPEN is _SPROJ(_VELOCITY_SURF, north:vector).
    local _U_COMPEN is _SPROJ(_VELOCITY_SURF, up:vector).

    return V(_E_COMPEN, _U_COMPEN, _N_COMPEN).
}

GLOBAL FUNCTION _HOVER_STEERINGUPDATE {
    parameter reverse.

    set _CVEL_LAST to _C_VELOCITY().
    set eastVelPID:setpoint to eastPosPID:update(time:seconds, ship:geoposition:lng).
    set northVelPID:SETPOINT TO northPosPID:UPDATE(TIME:SECONDS,SHIP:GEOPOSITION:LAT).
	local eastVelPIDOut IS eastVelPID:UPDATE(TIME:SECONDS, _CVEL_LAST:X).
	LOCAL northVelPIDOut IS northVelPID:UPDATE(TIME:SECONDS, _CVEL_LAST:Z).
	LOCAL eastPlusNorth is MAX(ABS(eastVelPIDOut), ABS(northVelPIDOut)).
	SET steeringPitch TO 90 - eastPlusNorth.

	LOCAL steeringDirNonNorm IS ARCTAN2(eastVelPID:OUTPUT, northVelPID:OUTPUT). //might be negative

	IF steeringDirNonNorm >= 0 {
		SET steeringDir TO steeringDirNonNorm.
	} ELSE {
		SET steeringDir TO 360 + steeringDirNonNorm.
	}
	IF reverse="Gridfin" {
		SET steeringDir TO steeringDir - 180.
		IF steeringDir < 0 {
			SET steeringDir TO 360 + steeringDir.
	}
	}
	ELSE IF reverse="Engine"{
		Print "0" at (1,1).
	}

	LOCK STEERING TO HEADING(steeringDir,steeringPitch).
}

GLOBAL FUNCTION _GRIDFIN_STEER {
    if(_GEODIST > 100){
		_SET_HOVERMAXSTEERANGLE(20).
		_SET_HOVERMAXSTEERSPEED(200). //booster will start reducing it's horizontal with limit of 200m/s
	} ELSE IF _GEODIST < 100 and _GEODIST > 25{
		_SET_HOVERMAXSTEERANGLE(16).
		_SET_HOVERMAXSTEERSPEED(150). //booster will start reducing it's horizontal with limit of 200m/s
	} ELSE {
		_SET_HOVERMAXSTEERANGLE(12.5).
		_SET_HOVERMAXSTEERSPEED(100).
	}
	
	
	_HOVER_STEERINGUPDATE("Gridfin"). //will automatically steer the vessel towards the target.
}

GLOBAL FUNCTION _ISBOOSTER { // Sets a booster to a tag and helps select booster
    PARAMETER _BOOSTERSELECT.

    set _BOOSTERTAG to ship:partstagged(_BOOSTERSELECT).

    IF _BOOSTERTAG:LENGTH > 0 {
        return true.
    } ELSE {return false.}
}










// ----------------------
//  Other Functions
// ----------------------

GLOBAL FUNCTION _SET_HOVERTARGET {
    parameter lat, lng.

    set eastPosPID:setpoint to lng.
    set northPosPID:setpoint to lat.
}

GLOBAL FUNCTION _SET_HOVERALTITUDE {
    parameter _A.

    set hoverPID:setpoint to _A.
}

GLOBAL FUNCTION _COPY_VESSELHEADING {
    parameter _VESSEL.

    return vessel(_VESSEL):facing:vector.
}

GLOBAL FUNCTION _SET_HOVERDESCENTSPEED {
    parameter _A.

    set hoverPID:maxoutput to _A.
    set hoverPID:minoutput to -1 * _A.

    set climbPID:setpointg to hoverPID:update(time:seconds, ship:altitude). // Control descent with throttle
    set _THROTT to climbPID:update(time:seconds, ship:verticalspeed).
}

GLOBAL FUNCTION _SET_HOVERMAXSTEERANGLE {
    parameter _A.
    
    set eastVelPID:maxoutput to _A.
    set eastVelPID:minoutput to -1 * _A.

    set northVelPID:maxoutput to _A.
    set northVelPID:minoutput to -1 * _A.
}

GLOBAL FUNCTION _SET_HOVERMAXSTEERSPEED {
    parameter _A.

    set eastVelPID:maxoutput to _A.
    set eastVelPID:minoutput to -1 * _A.

    set northVelPID:maxoutput to _A.
    set northVelPID:minoutput to -1 * _A.
}

GLOBAL FUNCTION _UPDATE_VARS {
    set _DISTMARGIN to 1300.
    set _MAXVERTACC to ship:availablethrust / ship:mass - _G.
    set _VERTACC to _SPROJ(ship:sensors:acc, up:vector).
    set _DRAGACC to _G + _VERTACC.
    set _SUICIDE_BURNDISTANCE to (ship:verticalspeed ^ 2 / (2 * (_MAXVERTACC + _DRAGACC / 2))) + _DISTMARGIN.
}

GLOBAL FUNCTION _SET_THROTTLESENSITIVITY {
    parameter _A.
    
    set climbPID:kp to _A.
}

GLOBAL FUNCTION _DIST_TO_TARGET {
    parameter _TARG.

    return _CALCDISTANCE(_TARG, addons:tr:impactpos).
}

GLOBAL FUNCTION _UPDATE_MAXACCEL {
    set _G to constant:g * body:mass / body:radius ^ 2.
    set _MAXACCEL to ship:availablethrust / ship:mass - _G.
}

GLOBAL FUNCTION _GET_PHASEANGLETARGET {
    parameter _TGTBODY.

    set _SHIPVEL to ship:velocity:orbit.
    set _TGTPOS to _TGTBODY:orbit:position.

    return vAng(_SHIPVEL, _TGTPOS).
}

GLOBAL FUNCTION _SOOTTEXTURE {
    FOR P in ship:partstagged("SB_TNK") {
            IF P:MODULES:CONTAINS("ModuleTundraSoot") { // If the parts contain the module
                LOCAL M is P:getmodule("ModuleTundraSoot"). // Get the module
                FOR A in M:ALLACTIONNAMES() { // For each action in action names
                    IF A:CONTAINS("Toggle Soot") {M:DOACTION(A, true).} // If the action names contain decoupling, decouple fairings
                }
            } 
        } 
}









// -------------------
//  COMMUNICATIONS
// -------------------

GLOBAL FUNCTION _PROCESS_COMMCOMMANDS {
    WHEN not ship:messages:empty then {
        set _MSGRECIEVED to ship:messages:pop.

        set _CMD to _MSGRECIEVED:content[0].
        set _VAL to _MSGRECIEVED:content[1].

        IF (_CMD = "THROTTLE") {
            set _THROTT to _VAL.
        }

        IF (_CMD = "DONE") {
            set _DONE to _VAL.
        }
    }
}

GLOBAL FUNCTION _SEND_VESSELMESSAGE {
    parameter _V, MSG.

    set _C to _V:connection.
    _C:SENDMESSAGE(MSG).
}












// -------------------------------
//  Copied Functions
// -------------------------------

function getVectorRadialin{
	SET normalVec TO getVectorNormal().
	return vcrs(ship:velocity:orbit,normalVec).
}
function getVectorRadialout{
	SET normalVec TO getVectorNormal().
	return -1*vcrs(ship:velocity:orbit,normalVec).
}
function getVectorNormal{
	return vcrs(ship:velocity:orbit,-body:position).
}
function getVectorAntinormal{
	return -1*vcrs(ship:velocity:orbit,-body:position).
}
function getVectorSurfaceRetrograde{
	return -1*ship:velocity:surface.
}
function getVectorSurfacePrograde{
	return ship:velocity:surface.
}
function getOrbitLongitude{
	return MOD(OBT:LAN + OBT:ARGUMENTOFPERIAPSIS + OBT:TRUEANOMALY, 360).
}
function getBodyAscendingnodeLongitude{
	return SHIP:ORBIT:LONGITUDEOFASCENDINGNODE.
}
function getBodyDescendingnodeLongitude{
	return SHIP:ORBIT:LONGITUDEOFASCENDINGNODE+180.
}

function runstep {
	parameter stepName.
	parameter stepFunction.
	if(step=false){
		SET step TO stepName.
	}
	if(step=stepName){
		UNTIL step = false {
			//setLandingTarget(). //just keep landing target up to date depending on ship name.
			//updateVars().
		//	updateReadouts().
			
			//debugDrawUpdate().
			processCommCommands().
			
			stepFunction:call(). //call main step function
			wait 0.1.
		}
	}
}


// ---------------------------
//      Disused Funcs
// ---------------------------

// GLOBAL FUNCTION _CHECKHEAVYFUEL { // Checks for fuel inside Side Boosters for use in gravity turn / separation
//     global _SIDEBOOSTER_RTLSMARGIN to 2475. // RTLS Margin for Side Boosters

//     FOR res IN _SB_TNK:resources { // Checks for resources in Side Boosters
//         IF res:name = "Oxidizer" { // Checks for current oxidizer
//             global _SIDEBOOSTER_OXCURRENT to res:amount. // Returns oxidizer in tank
//             global _SIDEBOOSTER_OXCAPACITY to res:amount. // Returns capacity of tank 
//         }
//     }
// }