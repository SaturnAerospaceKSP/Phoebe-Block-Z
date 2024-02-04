// Saturn Aerospace 2024
// 
// Made By Quasy & EVE, using suicide code from https://gist.github.com/HerrCraziDev/468a832395a427a3283a6b1b2b54a469
// Phoebe Block Z
// 
// ------------------------
//     Recovery Main
// ------------------------

clearScreen.
_CPUINIT(). // Final Phase (Stage 1) - Vehicle Recovery (ASDS/RTLS)

GLOBAL FUNCTION _CPUINIT {
    runOncePath("0:/SaturnAerospace/Phoebe/mission_Settings.ks"). // Mission Settings
    runOncePath("0:/SaturnAerospace/Phoebe/partlist.ks"). // Part List
    runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks"). // Ground Based Functions
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/flight_funcs.ks"). // Flight Based Functions
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/Recovery/recovery_funcs.ks"). // Recovery Based Functions
    runOncePath("0:/SaturnAerospace/Libraries/lazcalc.ks"). // Azimuth Calculations

    set steeringManager:maxstoppingtime to 10. // Max Vehicle Turning Speed
    set steeringManager:rollts to 30. // Max Roll Speed
    set config:ipu to 400. // CPU speed

    set _ASDS_MARGIN to 2000. // LOX needed for Autonomous Spaceport Droneship

    set _SINGLE_ENGINE_LANDING to false. // Are we using 1 or 3 engines, false is 3
    set _ASDS_REENTRYSTART to -635. // (verticalspeed) - Set to 635 as default
    set _ASDS_REENTRYSTOP to -250. // (verticalspeed) - Set to 250 as default
    set _RTLS_REENTRYSTART to -650. // (verticalspeed) - Set to 650 as default
    set _RTLS_REENTRYSTOP to -450. // (verticalspeed) - Set to 450 as default
    set _BOOSTER_ALTOFFSET to 30.70. // Vehicle Height (alt radar)
    set _ERRORSCALING to 1. // Error Scale for guidance (declare point)
    set _MAXAOA to 0. // Max Angle Of Attack for guidance (declare point)
    set _DISTANCETOIMPACT to 99999. // Distance From Impact Point (declare point)
    set _STEERDIRECTION to 90. // Base Steering Direction (declare point)
    set _ADJUSTPITCHVAL to 5. // Pitch Value 
    set _ADJUSTLATOFFSET to 0. // Latitudinal Offset
    set _ADJUSTLNGOFFSET to 0. // Longitudinal Offset

    _DEFINESETTINGS(). // Defines mission settings and configuration
    set _S1_TNK to ship:partstagged("S1_TANK")[0].
    set _S1_ENG to ship:partstagged("S1_ENG")[0].
    set _S1_DEC to ship:partstagged("S1_DEC")[0].

    _CHECKRECOVERYMETHOD(_GETVEHICLEFUEL("STAGE 1")). // Gets fuel for function

    lock steering to facing. // locks straight 
    wait 0.5. // waits  a few seconds till s2 is clear

    IF _STAGE1OXCURRENT <= _ASDS_MARGIN {wait 3. set _RECOVERYMETHOD to "ASDS". _ASDS_SEQUENCE().} // ASDS Sequence
    ELSE {wait 3. set _RECOVERYMETHOD to "RTLS". _RTLS_SEQUENCE().} // RTLS Sequence
}






// Landing Zone Targets

GLOBAL FUNCTION _DECIDELANDINGTARGET { // THIS IS THE FUNCTION FOR CHOOSING LANDING ZONE
    parameter _LANDINGMETHOD.

    IF _LANDINGMETHOD = "ASDS" {
        set _FINAL_LANDING_TARGET to vessel("- Droneship PEUFED"):geoposition.
    } ELSE IF _LANDINGMETHOD = "RTLS" {
        set _FINAL_LANDING_TARGET to latlng(28.2165624440971, -80.3052356387165).
    }

    // KSC 1 - [28.2165624440971, -80.3052356387165]
    // KSC 2 - [28.219352252803, -80.3099196801356]
    // KSC 3 - [28.2231410218699, -80.3097318080028]
    // SOLOMON PAD 1 - [-8.67308977890146, 160.914975191284]
    // SOLOMON PAD 2 - [-8.66878860969399, 160.911720767519]

}





// ------------------------------------
//       Sequence Functions
// ------------------------------------

GLOBAL FUNCTION _ASDS_SEQUENCE {
    _DECIDELANDINGTARGET("ASDS"). // Decides the landing target for the recovery

    _COASTPHASE(). // Coast between MECO & Entry
    _REENTRYBURN(). // Burn to reduce velocity & heating
    _ATMOSPHERICGUIDANCE(). // AOA Changer
    _LANDINGBURNASDS(). // Landing On LZ
}

GLOBAL FUNCTION _RTLS_SEQUENCE {
    _DECIDELANDINGTARGET("RTLS"). // Decides the landing target for the recovery

    _BOOSTBACKBURN(). // Boosts back towards LZ
    _COASTPHASE(). // Coast between boostback & entry
    _REENTRYBURN(). // Burn to reduce velocity & heating
    _ATMOSPHERICGUIDANCE(). // AOA Changer
    _LANDINGBURNRTLS(). // Landing On LZ
}




// ------------------------------------
//       RECOVERY Functions
// ------------------------------------

GLOBAL FUNCTION _BOOSTBACKBURN {
    rcs on.

    set _CURRENTPITCH to round(90 - vAng(ship:up:forevector, ship:facing:forevector)).
    
    IF ship:facing:roll > -10 and ship:facing:roll < 10 {
        SET SHIP:CONTROL:PITCH TO +1.
    } ELSE {
        SET SHIP:CONTROL:PITCH TO -1.
    }
    
    UNTIL _CURRENTPITCH > 80 { // Until we point up
        print round(_CURRENTPITCH) + "    " at (1, 1).
        set _CURRENTPITCH to round(90 - vAng(ship:up:forevector, ship:facing:forevector)).
    }

    IF ship:facing:roll > -10 and ship:facing:roll < 10 {
        SET SHIP:CONTROL:PITCH TO +0.3.
    } ELSE {
        SET SHIP:CONTROL:PITCH TO -0.3.
    }

    // Boostback Engine Startup
        _ECU("STAGE 1", "STARTUP"). // Startup Engines for boostback
        _ECU("STAGE 1", "Next Mode"). // Switches to 3 engines
        LOCK THROTTLE TO 1. // 100% Throttle (Boostback Startup) 
    
    UNTIL _CURRENTPITCH < 30 { // Engines now on and we start going down to lowerlmao pitch
        IF _CURRENTPITCH < 29 { // Slow down steering authority
            set steeringManager:maxstoppingtime to 0.5.
        }

        print round(_CURRENTPITCH) + "    " at (1, 1).
        set _CURRENTPITCH to round(90 - vAng(ship:up:forevector, ship:facing:forevector)).
    }

    // Now Pointing Back To LZ
        set ship:control:pitch to 0. // Stop flipping
        rcs off. // Disable RCS as engines are ignited
    
    UNTIL _DISTANCETOIMPACT < 700 {
        _STEERTOLANDINGZONE(_ADJUSTPITCHVAL, _ADJUSTLATOFFSET, _ADJUSTLNGOFFSET).

        IF _DISTANCETOIMPACT < 10000 {LOCK THROTTLE TO 0.5.} // 50% Throttle 
        ELSE {LOCK THROTTLE TO 1.} // 100% Throttle
    }

    UNTIL _DISTANCETOIMPACT > 2500 { // Waits a little longer for the boostback to go beyond the pad (reentry will fix this)
        _STEERTOLANDINGZONE(_ADJUSTPITCHVAL, _ADJUSTLATOFFSET, _ADJUSTLNGOFFSET).
    }

    SET _FACE_STILL to facing.
    LOCK STEERING TO _FACE_STILL.

    UNTIL _DISTANCETOIMPACT > 4500 {
        set _OVSHTLATLNG to latlng(_FINAL_LANDING_TARGET:lat, _FINAL_LANDING_TARGET:lng). // Sets overshooting distances
        SET _DISTANCETOIMPACT to _CALCDISTANCE(_OVSHTLATLNG, addons:tr:impactpos). // Distance to impact updates
        
        wait 0.
    }

    LOCK THROTTLE TO 0. // 0% Throttle (Boostback Shutdown)
    _ECU("STAGE 1", "Shutdown").
    wait 1. // Settle Time
}



GLOBAL FUNCTION _COASTPHASE {
    set steeringManager:maxstoppingtime to 1. // Slow Turning 
    rcs on. // Turns RCS on for maneuvering
    LOCK STEERING TO up. // Steers up during coast 

    set steeringManager:torqueepsilonmax to 0.04.
    set steeringManager:torqueepsilonmin to 0.02. 

    UNTIL SHIP:verticalSpeed < -100 {wait 0.} // Waits until descending

    _DEPLOYGRIDFINS(). // Deploys grid fins    
    LOCK STEERING TO srfRetrograde. // Points retrograde (surface)
}



GLOBAL FUNCTION _REENTRYBURN {
    IF _RECOVERYMETHOD = "ASDS" {
        UNTIL ship:verticalSpeed <= _ASDS_REENTRYSTART {LOCK STEERING TO srfRetrograde. wait 0.01.}

        LOCK STEERING TO _STEERTOLZ().
        set _MAXAOA to -6. // Inverted AOA on entry burn
        _ECU("STAGE 1", "Next Mode"). // 3 Engines for ASDS
        _ECU("STAGE 1", "Next Mode"). // Single Engine Startup

        _ECU("STAGE 1", "Startup"). // Enable Engines
        LOCK THROTTLE TO 0.1. // 10% Throttle
        rcs off.
        wait 0.5.

        _ECU("STAGE 1", "Previous Mode"). // Back to 3 engines (realistic)
        LOCK THROTTLE TO 1. // 100% Throttle
        _S1_TNK:getmodule("ModuleTundraSoot"):doaction("Toggle Soot", true).
        _S1_DEC:getmodule("ModuleTundraSoot"):doaction("Toggle Soot", true).

        UNTIL ship:verticalSpeed >= _ASDS_REENTRYSTOP {wait 0.1.}

        LOCK THROTTLE TO 0.
        IF _SINGLE_ENGINE_LANDING {_ECU("STAGE 1", "Next Mode").} // Single Engine Startup
        set _ERRORSCALING to 1.4. // // Increases scaling of guidance
    } ELSE IF _RECOVERYMETHOD = "RTLS" {
        UNTIL ship:verticalSpeed <= _RTLS_REENTRYSTART {LOCK STEERING TO srfRetrograde. wait 0.01.}

        // lock steering to _STEERTOLZ().
        // set _MAXAOA to -3. // Inverted AOA on entry burn
        _ECU("STAGE 1", "Startup"). // Enable Engines Entryburn start
        _ECU("STAGE 1", "Next Mode"). // Single Engine Startup
        LOCK THROTTLE TO 0.1. // 10% Throttle
        rcs off.

        _ECU("STAGE 1", "Previous Mode"). // Back to 3 engines (realistic)
        LOCK THROTTLE TO 1. // 100% Throttle
        _S1_TNK:getmodule("ModuleTundraSoot"):doaction("Toggle Soot", true).
        _S1_DEC:getmodule("ModuleTundraSoot"):doaction("Toggle Soot", true).

        UNTIL ship:verticalSpeed >= _RTLS_REENTRYSTOP {wait 0.1.}

        LOCK THROTTLE TO 0. // 0% Throttle
        IF _SINGLE_ENGINE_LANDING {_ECU("STAGE 1", "Next Mode").} // Single Engine Startup
        set _ERRORSCALING to 1.4. // Increases scaling of guidance
    }
}



GLOBAL FUNCTION _ATMOSPHERICGUIDANCE {
    set steeringManager:torqueepsilonmin to 0.0002. // Less RCS Spasms
    set steeringManager:torqueepsilonmax to 0.001.
    set steeringManager:maxstoppingtime to 10. // Better Control
    set steeringManager:rollts to 10. // Roll Speed

    rcs on.
    LOCK STEERING TO _STEERTOLZ().

    UNTIL ship:altitude <= 5000 {
        IF ship:altitude > 20000 {set _MAXAOA to 20.}
        IF ship:altitude < 20000 {set _MAXAOA to 17.}
        IF ship:altitude < 15000 {set _MAXAOA to 15.}
        IF ship:altitude < 11000 {set _MAXAOA to 12.} // At this point the wind increases on KWP so we need to increase AOA to combat the wind
        IF ship:altitude < 9000 {set _MAXAOA to 8.}
        IF ship:altitude < 6000 {set _MAXAOA to 4.}
    }

    clearScreen.
    // SET _MAXAOA to 40. // Higher AOA here as winds are strongest around 10km and this will be before landing
}









GLOBAL FUNCTION _LANDINGBURNASDS {
    set _ERRORSCALING to 1.

    lock _TRUERADAR to alt:radar - _BOOSTER_ALTOFFSET + 2.9. // Higher alt on ship for ASDS
    lock _GRAVITY to constant:g * body:mass / body:radius ^ 2.
    lock _MAXDECELERATION to (ship:availablethrust / ship:mass) - _GRAVITY.
    lock _STOPDISTANCE to ship:verticalSpeed ^ 2 / (2 * _MAXDECELERATION).
    lock _BURNTHROTTLE to _STOPDISTANCE / _TRUERADAR.

    // Landing Burn Start
        UNTIL _TRUERADAR <= _STOPDISTANCE - _BOOSTER_ALTOFFSET - 25 {
            lock steering to _STEERTOLZ(). 
            set _MAXAOA to 10.

            print _TRUERADAR at (10, 13).
            wait 0.
        } // Wait until suicide burn altitude

        rcs off.
        lock steering to _STEERTOLZ().
        lock throttle to 1. // Start Suicide Burn
        set _MAXAOA to -3. // Inverted AOA for landing burn

    // Landing Gear
        IF addons:tr:hasimpact {
            WHEN alt:radar < 400 then {set _MAXAOA to -1.}
            WHEN alt:radar < 200 then {_DEPLOYLANDINGLEGS().} //set _MAXAOA to -0.75.}
        } 

    // One Engine Switch

        UNTIL ship:verticalSpeed > -65 {
            set _FINAL_LANDING_TARGET to vessel("- Droneship PEUFED"):geoposition.

            wait 0.
        }

        set _MAXAOA to -2.
        lock throttle to (_BURNTHROTTLE + 0.4).

        UNTIL ship:verticalspeed > -45 {
            set _FINAL_LANDING_TARGET to vessel("- Droneship PEUFED"):geoposition.

            wait 0.05.  
        }

        IF _SINGLE_ENGINE_LANDING = FALSE {_ECU("STAGE 1", "NEXT MODE").}
        set steeringManager:rollts to 10. // Limit roll to stop spasm
        // set steeringManager:rollcontrolanglerange to 1. // Stop rolling unneccessarily 
        set _MAXAOA to -1.25.
        lock throttle to (_BURNTHROTTLE + 0.35).

    // Touchdown Waiting Section
        UNTIL ship:verticalspeed >= -0.01 {
            set _FINAL_LANDING_TARGET to vessel("- Droneship PEUFED"):geoposition.

            IF ship:verticalspeed > -50 and ship:velocity:surface:mag < 2.5 {LOCK STEERING TO HEADING(_FINAL_LANDING_TARGET:heading, 89.5).}

            ELSE IF ship:verticalspeed > -20 and ship:velocity:surface:mag > 4 {
                UNTIL ship:velocity:surface:mag < 4 {
                    LOCK STEERING TO srfRetrograde. 
                } 

                LOCK STEERING TO HEADING(90, 90).
            } 

            wait 0.05.
        }

    // Shutdown
        LOCK THROTTLE TO 0. // Shutdown engines when landed
        _ECU("STAGE 1", "Shutdown"). // Engine off

        wait 10.
        shutdown.
}






GLOBAL FUNCTION _LANDINGBURNRTLS {
    lock _TRUERADAR to alt:radar - _BOOSTER_ALTOFFSET + 2.9. // Higher alt on ship for ASDS
    lock _GRAVITY to constant:g * body:mass / body:radius ^ 2.
    lock _MAXDECELERATION to (ship:availablethrust / ship:mass) - _GRAVITY.
    lock _STOPDISTANCE to ship:verticalSpeed ^ 2 / (2 * _MAXDECELERATION).
    lock _BURNTHROTTLE to _STOPDISTANCE / _TRUERADAR.

    // Landing Burn Start
        UNTIL _TRUERADAR <= _STOPDISTANCE - _BOOSTER_ALTOFFSET + 400 {
            lock steering to _STEERTOLZ(). 
            set _MAXAOA to 30.

            print _TRUERADAR at (10, 13).
            wait 0.
        } // Wait until suicide burn altitude

        rcs off.
        lock steering to _STEERTOLZ().
        lock throttle to (_BURNTHROTTLE + 0.15). // Start Suicide Burn
        set _MAXAOA to -6. // Inverted AOA for landing burn
        set _ERRORSCALING to 1.15. // Slower Guidance
        

    // Landing Gear
        IF addons:tr:hasimpact {
            WHEN alt:radar < 400 then {set _MAXAOA to -1.}
            WHEN alt:radar < 200 then {_DEPLOYLANDINGLEGS().} //set _MAXAOA to -0.75.}
        } 

    // One Engine Switch
        UNTIL ship:verticalspeed > -45 {wait 0.05.}

        IF _SINGLE_ENGINE_LANDING = FALSE {_ECU("STAGE 1", "NEXT MODE").}
        set steeringManager:rollts to 10. // Limit roll to stop spasm
        // set steeringManager:rollcontrolanglerange to 1. // Stop rolling unneccessarily 
        set _MAXAOA to -2.
        set _ERRORSCALING to 1.
        lock throttle to (_BURNTHROTTLE + 0.3).

    // Touchdown Waiting Section
        UNTIL ship:verticalspeed >= -0.01 {
            IF ship:verticalspeed > -50 and ship:velocity:surface:mag < 2.5 {LOCK STEERING TO HEADING(_FINAL_LANDING_TARGET:heading, 89.5).}

            ELSE IF ship:verticalspeed > -50 and ship:velocity:surface:mag > 2.5 {
                UNTIL ship:velocity:surface:mag < 2.5 {
                    LOCK STEERING TO srfRetrograde. 
                } 

                LOCK STEERING TO HEADING(90, 90).
            } 

            wait 0.05.
        }

    // Shutdown
        LOCK THROTTLE TO 0. // Shutdown engines when landed
        _ECU("STAGE 1", "Shutdown"). // Engine off

        wait 10.
        shutdown.
}

















// GLOBAL FUNCTION _LANDINGBURNRTLS { 
//     // SUICIDE BURN PORTION
//         UNTIL SHIP:STATUS = "LANDED" and ship:verticalspeed > 0.1 { // Ensure the vehicle is landed before exiting the loop
//         // UPDATE
//             SET _IMPACT_DIST TO addons:tr:impactpos:distance. // Distance until ship hits ground

//             SET _GRAVITY TO CONSTANT:G * BODY:MASS / BODY:RADIUS ^ 2. // Gravity (M/S^2)
//             SET _MAX_DECEL TO (SHIP:AVAILABLETHRUST / SHIP:MASS) - _GRAVITY. // Maximum deceleration possible (m/s^2)
//             SET _STOP_DIST TO SHIP:VELOCITY:SURFACE:SQRMAGNITUDE / (2 * _MAX_DECEL). // The distance the burn requires
//             SET _HOVERSLAM_THROTTLE TO _STOP_DIST /  _IMPACT_DIST. // Throttle required for perfect hoverslam

//             SET _SHIP_VELOCITY TO ship:velocity:surface:mag. // Vessel's total velocity
//             SET _IMPACT_TIME TO _IMPACT_DIST / abs(_SHIP_VELOCITY). // Time until ship hits ground
//             SET _SINGLE_ENGINE TO FALSE. // Three Engine Start?

//         // LOGIC
//             IF _IMPACT_DIST <= _STOP_DIST + 100 { // Checking if we are under the hoverslam start point
//                 // THROTTLE
//                     LOCK THROTTLE TO (_HOVERSLAM_THROTTLE + 0.2). // Landing Burn Start
//             }

//             // STEERING
//                 IF SHIP:VERTICALSPEED >= -75 {SET _MAXAOA to -3.5.}
//                 IF SHIP:VERTICALSPEED >= -50 {SET _MAXAOA to -2.5. LOCK THROTTLE TO (_HOVERSLAM_THROTTLE + 0.3).}
//                 IF SHIP:VERTICALSPEED >= -25 {SET _MAXAOA to -1.5.}
//             // FUNCTIONS
//                 IF ALT:RADAR < 100 {_DEPLOYLANDINGLEGS().}
//                 IF SHIP:VERTICALSPEED > -40 and _SINGLE_ENGINE = false {_ECU("STAGE 1", "NEXT MODE"). SET _SINGLE_ENGINE TO TRUE.}
//                 WHEN ALT:RADAR < 100 and _SHIP_VELOCITY > 3 THEN {LOCK STEERING TO HEADING(_HEADING_OF_VECTOR(RETROGRADE:VECTOR), 93).}


//     // TELEMETRY READOUTS
//         PRINT "SRF VEL:  " + ROUND(_SHIP_VELOCITY, 4) + " m/s          " at (0, terminal:height - 11).
//         PRINT "HOR VEL:  " + ROUND(SHIP:groundspeed, 4) + " m/s          " at (0, terminal:height - 10).
//         PRINT "VERT VEL: " + ROUND(SHIP:verticalspeed, 4) + " m/s          " at (0, terminal:height - 9).
//         PRINT "DESC RTE: " + ROUND(abs(ship:verticalspeed / ship:groundspeed), 2) + "          " at (0, terminal:height - 8).
//         PRINT "───────────────────────────────────────" at (0, terminal:height - 7).
//         PRINT "IMPACT TIME: T+" + ROUND(_IMPACT_TIME, 3) + " s          " at (0, terminal:height - 6).
//         PRINT "IMPACT DIST:   " + ROUND(_IMPACT_DIST, 2) + " m          " at (0, terminal:height - 5).
//         PRINT "MAX DECEL:     " + ROUND(_MAX_DECEL, 5) + " m/s          " at (0, terminal:height - 4).
//         PRINT "S. BURN DIST:  " + ROUND(_STOP_DIST, 2) + " m          " at (0, terminal:height - 3).
//         PRINT "───────────────────────────────────────" at (0, terminal:height - 2).
//         PRINT "THROTTLE: " + ROUND(_HOVERSLAM_THROTTLE * 100, 2) + " %          " at (0, terminal:height - 1).


//     // SPEED 
//         wait 0.01.
//     }

//     // SHUTDOWN
//     LOCK THROTTLE TO 0.
//     LOCK STEERING TO UP.
// }

