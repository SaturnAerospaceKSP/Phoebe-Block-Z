// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
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
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe//Recovery/recovery_funcs.ks"). // Recovery Based Functions
    runOncePath("0:/SaturnAerospace/Libraries/lazcalc.ks"). // Azimuth Calculations

    set steeringManager:maxstoppingtime to 10. // Max Vehicle Turning Speed
    set steeringManager:rollts to 30. // Max Roll Speed
    set config:ipu to 2000. // CPU speed

    set _ASDS_MARGIN to 2000. // LOX needed for Autonomous Spaceport Droneship

    set _ASDS_REENTRYSTART to -775. // (verticalspeed)
    set _ASDS_REENTRYSTOP to -225. // (verticalspeed)
    set _RTLS_REENTRYSTART to -750. // (verticalspeed)
    set _RTLS_REENTRYSTOP to -475. // (verticalspeed)
    set _BOOSTER_ALTOFFSET to 30.70. // Vehicle Height (alt radar)
    set _ERRORSCALING to 1. // Error Scale for guidance (declare point)
    set _MAXAOA to 0. // Max Angle Of Attack for guidance (declare point)
    set _DISTANCETOIMPACT to 99999. // Distance From Impact Point (declare point)
    set _STEERDIRECTION to 90. // Base Steering Direction (declare point)
    set _ADJUSTPITCHVAL to 5. // Pitch Value 
    set _ADJUSTLATOFFSET to 0. // Latitudinal Offset
    set _ADJUSTLNGOFFSET to 0. // Longitudinal Offset

    _DEFINESETTINGS(). // Defines mission settings and configuration
    _DEFINEPARTS(). // Defines all vehicle parts based on configuration setting 

    _CHECKRECOVERYMETHOD(_GETVEHICLEFUEL("STAGE 1")). // Gets fuel for function

    IF _STAGE1OXCURRENT <= _ASDS_MARGIN {wait 5. set _RECOVERYMETHOD to "ASDS". _ASDS_SEQUENCE().} // ASDS Sequence
    ELSE {wait 5. set _RECOVERYMETHOD to "RTLS". _RTLS_SEQUENCE().} // RTLS Sequence
}

GLOBAL FUNCTION _DECIDELANDINGTARGET {
    parameter _LANDINGMETHOD.

    IF _LANDINGMETHOD = "ASDS" {
        set _FINAL_LANDING_TARGET to vessel("- Droneship PEUFED"):geoposition. 
    } ELSE IF _LANDINGMETHOD = "RTLS" {
        set _FINAL_LANDING_TARGET to latlng(28.2141268970927, -80.30495738722). // KSC1
    }

    // KSC 1 - [28.2140920160773, -80.3049028987299]
    // KSC 2 - [28.2152200476183, -80.3108388947316]
    // KSC 3 - [28.2176038174504, -80.3070629919739]

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
    rcs on. // Turns on RCS thrusters
    _STEER_HEADING(_FINAL_LANDING_TARGET:heading, 90, _ROLL).
    wait 5.
    _STEER_HEADING(_FINAL_LANDING_TARGET:heading, 60, _ROLL).
    wait 5.
    _STEER_HEADING(_FINAL_LANDING_TARGET:heading, 30, _ROLL).
    wait 5.
    _STEER_HEADING(_FINAL_LANDING_TARGET:heading, 0, _ROLL). // Flip complete now
    wait 5.

    rcs off. // Disable RCS as engines ignite
    _ECU("STAGE 1", "STARTUP"). // Startup Engines for boostback
    _ECU("STAGE 1", "Next Mode"). // Switches to 3 engines
    _ECUTHROTTLE(100). // 100% Throttle (Boostback Startup)
    
    UNTIL _DISTANCETOIMPACT < 650 {
        _STEERTOLANDINGZONE(_ADJUSTPITCHVAL, _ADJUSTLATOFFSET, _ADJUSTLNGOFFSET).

        IF _DISTANCETOIMPACT < 10000 {_ECUTHROTTLE(50).} // 50% Throttle 
        ELSE {_ECUTHROTTLE(100).} // 100% Throttle
    }

    IF _DISTANCETOIMPACT < 750 {
        _ECUTHROTTLE(0). // 0% Throttle (Boostback Shutdown)
        _ECU("STAGE 1", "Shutdown").
        wait 1. // Settle Time
    }
}

GLOBAL FUNCTION _COASTPHASE {
    set steeringManager:maxstoppingtime to 1. // Slow Turning 
    rcs on. // Turns RCS on for maneuvering
    _STEER_DIRECT(up). // Steers up during coast 

    UNTIL SHIP:verticalSpeed < -50 {wait 0.} // Waits until descending

    _DEPLOYGRIDFINS(). // Deploys grid fins    
    _STEER_DIRECT(srfRetrograde). // Points retrograde (surface)
}

GLOBAL FUNCTION _REENTRYBURN {
    IF _RECOVERYMETHOD = "ASDS" {
        UNTIL ship:verticalSpeed <= _ASDS_REENTRYSTART {_STEER_DIRECT(srfRetrograde). wait 0.}

        
        set _MAXAOA to -3. // Inverted AOA on entry burn
        _ECU("STAGE 1", "Next Mode"). // 3 Engines for ASDS

        _ECU("STAGE 1", "Startup"). // Enable Engines
        _ECU("STAGE 1", "Next Mode"). // Single Engine Startup
        _ECUTHROTTLE(10). // 10% Throttle
        rcs off.

        _ECU("STAGE 1", "Previous Mode"). // Back to 3 engines (realistic)
        _ECUTHROTTLE(100). // 100% Throttle
        _S1_TNK:getmodule("ModuleTundraSoot"):doaction("Toggle Soot", true).

        UNTIL ship:verticalSpeed >= _ASDS_REENTRYSTOP {lock steering to _STEERTOLZ(). wait 0.}

        _ECUTHROTTLE(0).
        set _ERRORSCALING to 1.2. // // Increases scaling of guidance
    } ELSE IF _RECOVERYMETHOD = "RTLS" {
        UNTIL ship:verticalSpeed <= _RTLS_REENTRYSTART {_STEER_DIRECT(srfRetrograde). wait 0.}

        lock steering to srfRetrograde.
        _ECU("STAGE 1", "Startup"). // Enable Engines Entryburn start
        _ECU("STAGE 1", "Next Mode"). // Single Engine Startup
        _ECUTHROTTLE(10). // 10% Throttle
        rcs off.

        _ECU("STAGE 1", "Previous Mode"). // Back to 3 engines (realistic)
        _ECUTHROTTLE(100). // 100% Throttle
        _S1_TNK:getmodule("ModuleTundraSoot"):doaction("Toggle Soot", true).

        UNTIL ship:verticalSpeed >= _RTLS_REENTRYSTOP {wait 0.}

        _ECUTHROTTLE(0). // 0% Throttle
        set _ERRORSCALING to 1.2. // Increases scaling of guidance
    }
}

GLOBAL FUNCTION _ATMOSPHERICGUIDANCE {
    set steeringManager:maxstoppingtime to 10. // Better Control
    set steeringManager:rollts to 5. // Roll Speed

    UNTIL ship:altitude <= 2500 {
        IF ship:altitude > 25000 {set _MAXAOA to 30.}
        IF ship:altitude < 25000 {set _MAXAOA to 25.}
        IF ship:altitude < 20000 {set _MAXAOA to 20.}
        IF ship:altitude < 15000 {set _MAXAOA to 15.}
        IF ship:altitude < 10000 {set _MAXAOA to 10.}
        IF ship:altitude < 5000 {set _MAXAOA to 7.5.}

        _STEER_DIRECT(_STEERTOLZ()).
    }
}

GLOBAL FUNCTION _LANDINGBURNRTLS {
    lock _TRUERADAR to alt:radar - _BOOSTER_ALTOFFSET + 2.9. // Higher alt on ship for ASDS
    lock _GRAVITY to constant:g * body:mass / body:radius ^ 2.
    lock _MAXDECELERATION to (ship:availablethrust / ship:mass) - _GRAVITY.
    lock _STOPDISTANCE to ship:verticalSpeed ^ 2 / (2 * _MAXDECELERATION).
    lock _BURNTHROTTLE to _STOPDISTANCE / _TRUERADAR.

    // Landing Burn Start
        UNTIL _TRUERADAR <= (_STOPDISTANCE - _BOOSTER_ALTOFFSET + 300) {lock steering to _STEERTOLZ(). print _TRUERADAR at (10, 13). wait 0.} // Wait until suicide burn altitude#
        lock steering to _STEERTOLZ().
        lock throttle to (_BURNTHROTTLE + 0.2). // Start Suicide Burn
        set _MAXAOA to -5. // Inverted AOA for landing burn
        set _ERRORSCALING to 0.8. // Slower Guidance
        

    // Landing Gear
        IF addons:tr:hasimpact {
            WHEN alt:radar < 400 then {set _MAXAOA to -1.5.}
            WHEN alt:radar < 200 then {_DEPLOYLANDINGLEGS(). set _MAXAOA to -0.75.}
        } 

    // One Engine Switch
        UNTIL ship:verticalspeed >= -40 {wait 0.}
        _ECU("STAGE 1", "Next Mode").
        set _MAXAOA to -1.
        lock throttle to (_BURNTHROTTLE + 0.3).

    // Final Landing Sector
        IF _TRUERADAR < 80 {lock steering to up. set _MAXAOA to 0.}
        UNTIL ship:verticalspeed >= -0.01 {wait 0.}
        _ECUTHROTTLE(0). // 0% Throttle

    // Shutdown
        _ECUTHROTTLE(0). // Shutdown engines when landed
        _ECU("STAGE 1", "Shutdown"). // Engine off
}

GLOBAL FUNCTION _LANDINGBURNASDS {
    lock _TRUERADAR to alt:radar - _BOOSTER_ALTOFFSET + 2.9. // Higher alt on ship for ASDS
    lock _GRAVITY to constant:g * body:mass / body:radius ^ 2.
    lock _MAXDECELERATION to (ship:availablethrust / ship:mass) - _GRAVITY.
    lock _STOPDISTANCE to ship:verticalSpeed ^ 2 / (2 * _MAXDECELERATION).
    lock _BURNTHROTTLE to _STOPDISTANCE / _TRUERADAR.

    // Landing Burn Start
        UNTIL _TRUERADAR <= (_STOPDISTANCE - _BOOSTER_ALTOFFSET + 300) {lock steering to _STEERTOLZ(). print _TRUERADAR at (10, 13). wait 0.} // Wait until suicide burn altitude#
        lock steering to _STEERTOLZ().
        lock throttle to (_BURNTHROTTLE + 0.2). // Start Suicide Burn
        set _MAXAOA to -7. // Inverted AOA for landing burn
        set _ERRORSCALING to 0.8. // Slower Guidance
        

    // Landing Gear
        IF addons:tr:hasimpact {
            WHEN alt:radar < 400 then {set _MAXAOA to -1.5.}
            WHEN alt:radar < 200 then {_DEPLOYLANDINGLEGS(). set _MAXAOA to -0.75.}
        } 

    // One Engine Switch
        UNTIL ship:verticalspeed >= -35 {wait 0.}
        _ECU("STAGE 1", "Next Mode").
        set _MAXAOA to -0.5.
        lock throttle to (_BURNTHROTTLE + 0.4).

    // Final Landing Sector
        IF _TRUERADAR < 80 {lock steering to up. set _MAXAOA to 0.}
        UNTIL ship:verticalspeed >= -0.01 {wait 0.}
        _ECUTHROTTLE(0). // 0% Throttle

    // Shutdown
        _ECUTHROTTLE(0). // Shutdown engines when landed
        _ECU("STAGE 1", "Shutdown"). // Engine off
}
