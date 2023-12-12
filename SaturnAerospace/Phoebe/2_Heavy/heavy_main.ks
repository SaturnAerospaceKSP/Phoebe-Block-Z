// Saturn Aerospace 2024
// 
// Made By Quasy & EVE, including software from Marcus House (hey hey)
// Phoebe Block Z
// 
// ------------------------
//     Heavy Main
// ------------------------

clearScreen.
wait 2.
_CPUINIT(). // Initialises CPU & Preparation

GLOBAL FUNCTION _CPUINIT {
    runOncePath("0:/SaturnAerospace/Phoebe/mission_Settings.ks"). // Mission Settings
    runOncePath("0:/SaturnAerospace/Phoebe/partlist.ks"). // Part List
    runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks"). // Ground Based Functions
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/flight_funcs.ks"). // Flight Based Functions
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/Recovery/recovery_funcs.ks"). // Recovery Based Functions
    runOncePath("0:/SaturnAerospace/Phoebe/2_Heavy/heavy_funcs.ks"). // Heavy Functions
    runOncePath("0:/SaturnAerospace/Libraries/lazcalc.ks"). // Azimuth Calculations

    set steeringManager:maxstoppingtime to 1. // Max Vehicle Turning Speed
    set steeringManager:rollts to 30. // Max Roll Speed
    set config:ipu to 2000. // CPU speed

    // _GETVEHICLEFUEL("SIDE BOOSTERS"). // Gets side booster fuel
    _SETUPVARIABLES(). // Grabs variables for Phoebe Heavy Recovery

    _BOOSTER_SEPARATION(). // Separation of boosters and craft assignment
    _SET_TRUERADAR(). // Sets offset for boosters
    _SIDEBOOSTERRECOVERY(). // Run Script
}


// -----------------------
//      Main Section
// -----------------------

GLOBAL FUNCTION _SIDEBOOSTERRECOVERY {
    wait 2.

    set _THROTT to 0.
    lock throttle to _THROTT.

    UNTIL not _LOOPING {
        IF _ISBOOSTER("B1") {
            _BOOSTER_1().
            _BOOSTBACK_B1().
            _ENTRYBURN().
            _GLIDE().
            _THREE_ENG_LANDING().
            _SINGLE_LANDING().

            // Shutdown on land
            set _THROTT to 0.
            lock steering to up.
            
            rcs off.
            wait 10.
            shutdown.
        } ELSE IF _ISBOOSTER("B2") {
            _BOOSTER_2().
            _ENTRYBURN().
            _GLIDE().
            _THREE_ENG_LANDING().
            _SINGLE_LANDING().

            // Shutdown on land
            set _THROTT to 0.
            lock steering to up.
            
            rcs off.
            wait 10.
            shutdown.
        }

        when throttle = 0 then { // Steering Settings for 0 throttle
            set steeringManager:maxstoppingtime to 1.
            set steeringManager:pitchpid:kd to 2.
            set steeringManager:yawpid:kd to 2.
            preserve.
        }

        when throttle > 0 then { // Steering Settings for burns
            set steeringManager:maxstoppingtime to 5.
            set steeringManager:pitchpid:kd to 1.
            set steeringManager:yawpid:kd to 1.
            preserve.
        }

        _PROCESS_COMMCOMMANDS(). // Processes Communications from dominant booster
        wait 0.1.
    }
    
}

// --------------------------
//  Sequence Functions
// --------------------------

GLOBAL FUNCTION _BOOSTER_SEPARATION {
    IF _ISBOOSTER("B1") {
        set _LANDING_TGT to _BOOSTER1_LZ.
        set _THROTT to 0.
        set ship:name to "Booster 1".

        kuniverse:forcesetactivevessel(SHIP).
        
        _ECU("SIDE BOOSTERS", "STARTUP"). // Enables engines
        _ECU("SIDE BOOSTERS", "NEXT MODE"). // 3 Engine Burn
    } ELSE IF _ISBOOSTER("B2") {
        set _LANDING_TGT to _BOOSTER2_LZ.
        set _THROTT to 0.
        set ship:name to "Booster 2".
    }
}

GLOBAL FUNCTION _BOOSTER_1 {
    set _COMM_TARGETVESSEL to vessel("Booster 2").
    _BOOSTER_STEERTOLZ(_BOOSTER_ADJUSTPITCH, _BOOSTER_ADJUSTLAT, _BOOSTER_ADJUSTLNG).

    wait 5.
    set _THROTT to 1.
}

GLOBAL FUNCTION _BOOSTER_2 {
    until _DONE = 0 {
        _PROCESS_COMMCOMMANDS().

        lock steering to _COPY_VESSELHEADING("Booster 1").
        lock throttle to _THROTT.
    }
}

GLOBAL FUNCTION _BOOSTBACK_B1 {
    UNTIL _IMPACTDIST < 500 {
        _BOOSTER_STEERTOLZ(_BOOSTER_ADJUSTPITCH, _BOOSTER_ADJUSTLAT, _BOOSTER_ADJUSTLNG).

        IF (_IMPACTDIST < 20000) {
            set _THROTT to 0.5.
            _SEND_VESSELMESSAGE(_COMM_TARGETVESSEL, list("THROTTLE", _THROTT)).
        } ELSE {
            set _THROTT to 1.

            IF _ISBOOSTER("B1") {
                _SEND_VESSELMESSAGE(_COMM_TARGETVESSEL, list("THROTTLE", _THROTT)).
            }
        }
    }

    IF _IMPACTDIST < 580 {_SEND_VESSELMESSAGE(_COMM_TARGETVESSEL, list("THROTTLE", 0)).}

    IF _IMPACTDIST < 500 {
        set _THROTT to 0.
        wait 1.

        IF _ISBOOSTER("B1") {
            IF _BOOSTER_LANDMODE {
                _SEND_VESSELMESSAGE(_COMM_TARGETVESSEL, list("DONE", 0)).
                kuniverse:forcesetactivevessel(_COMM_TARGETVESSEL).

                wait 2.
            }
        }
    }
}

GLOBAL FUNCTION _ENTRYBURN {
    rcs on.
    set _THROTT to 0.
    lock steering to up.

    set steeringManager:torqueepsilonmax to 0.04. // Steering fixes for rcs bug
    set steeringManager:torqueepsilonmin to 0.008. 

    UNTIL ship:verticalspeed < 100 {wait 0.}

    brakes on.
    lock steering to srfRetrograde.

    UNTIL alt:radar < 40000 {wait 0.}

    // Entry Burn Begin
    set _THROTT to 1.
    _SOOTTEXTURE().

    until ship:verticalSpeed > -300 {
        _SET_HOVERPIDLOOPS().
        _SET_HOVERTARGET(_BOOSTER1_LZ:lat, _BOOSTER1_LZ:lng).
    }

    // Entry Burn Stop
    set _THROTT to 0.
}

GLOBAL FUNCTION _GLIDE {
    until alt:radar < _LANDINGBURN_ALT {
        IF _ISBOOSTER("B1") {
            _SET_HOVERPIDLOOPS().
            _SET_HOVERTARGET(_BOOSTER1_LZ:lat, _BOOSTER1_LZ:lng).
            set _GEODIST to _CALCDISTANCE(_BOOSTER1_LZ, ship:geoposition).
        } ELSE IF _ISBOOSTER("B2") {
            _SET_HOVERPIDLOOPS().
            _SET_HOVERTARGET(_BOOSTER2_LZ:lat, _BOOSTER2_LZ:lng).
            set _GEODIST to _CALCDISTANCE(_BOOSTER2_LZ, ship:geoposition).
        }

        print _GEODIST.

        _GRIDFIN_STEER().
    }
}

GLOBAL FUNCTION _THREE_ENG_LANDING {
    _UPDATE_VARS().
    
    _SET_HOVERMAXSTEERANGLE(12).
    _SET_HOVERMAXSTEERSPEED(4).
    _HOVER_STEERINGUPDATE("Engine").

    set _THROTT to 1.

    until ship:verticalSpeed > -90 {
        wait 0.
    }

    _ECU("SIDE BOOSTERS", "NEXT MODE").
}

GLOBAL FUNCTION _SINGLE_LANDING {
    until ship:status = "LANDED" {
        set _MINLANDVEL to 0.
        _UPDATE_VARS().
        _SET_HOVERMAXSTEERANGLE(5).
        _SET_HOVERMAXSTEERSPEED(2).

        set _MAXDESCENTSPEED to 50.
        set _THROTT to _GET_SUICIDEBURN_THROTTLE() + 0.05.

        IF alt:radar < 250 {gear on.}

        IF ship:altitude < 210 {_SET_HOVERDESCENTSPEED(20).}
        ELSE {_SET_HOVERDESCENTSPEED(_MAXDESCENTSPEED).}

        IF alt:radar < 80 {lock steering to up.}

        _HOVER_STEERINGUPDATE("Engine").

    }
}