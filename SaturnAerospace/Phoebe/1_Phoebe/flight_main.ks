// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Flight Main
// ------------------------

clearScreen.
GLOBAL _STEER_TARGET IS ship:facing. // global steering parameter
GLOBAL _THROTTLE_TARGET IS 0. // global throttle parameter
_CPUINIT(). // Second Phase - Initialises vehicle on startup

GLOBAL FUNCTION _CPUINIT {
    runOncePath("0:/SaturnAerospace/Phoebe/mission_Settings.ks"). // Mission Settings
    runOncePath("0:/SaturnAerospace/Phoebe/partlist.ks"). // Part List
    runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks"). // Ground Based Functions
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/flight_funcs.ks"). // Flight Based Functions
    runOncePath("0:/SaturnAerospace/Libraries/LAZCALC.ks"). // Azimuth Calculations For Gravity Turn

    set steeringManager:maxstoppingtime to 1. // Max Vehicle Turning Speed
    set steeringManager:rollts to 5. // Max Roll Speed
    set config:ipu to 2000. // CPU speed
    set kuniverse:defaultloaddistance:flying:unload to 30000. // Unload distance increased for flying objects

    _DEFINESETTINGS(). // Defines mission settings and configuration
    _DEFINEPARTS(). // Defines all vehicle parts based on configuration setting 
    _GETVEHICLEFUEL("STAGE 1"). // Gets the first stage fuel for the gravity turn logic & shutdown
    _GETVEHICLEFUEL("STAGE 2"). // Gets the second stage fuel for later validation 

    GLOBAL _STAGE1COMMANDCORE is _S1_CPU:getmodule("kOSProcessor"):connection. // Used to send messages to Stage 1
    IF _VEHICLECONFIG = "Calypso Dock" or _VEHICLECONFIG = "Calypso Tour" {
        GLOBAL _CALYPSOCOMMANDCORE is _CC_CPU:getmodule("kOSProcessor"):connection. // Connects directly to Calypso for preparation
    } ELSE IF _VEHICLECONFIG = "Phoebe Heavy" {
        GLOBAL _SIDEBOOSTERCOMMANDCORE is _SB_CPU:getmodule("kOSProcessor"):connection. // Side Cores CPU
    }

    _PHOEBEFLIGHTMAIN().
}

GLOBAL FUNCTION _PHOEBEFLIGHTMAIN {
    IF _VEHICLECONFIG = "Phoebe" {
        _PHASE1_TOWERCLEAR().
        _PHASE1_BOOSTERGUIDANCE().
        _PHASE1_STAGESEPARATION().

        _PHASE2_VEHICLEGUIDANCE().
        _PHASE2_ORBITINSERTIONBURN().
        _PHASE2_ORBITOPS_CLEANUP().
    } ELSE IF _VEHICLECONFIG = "Phoebe Heavy" {
        _PHASE1_TOWERCLEAR().
        _PHASE1_BOOSTERGUIDANCE().
        _PHASE1_STAGESEPARATION().

        _PHASE2_VEHICLEGUIDANCE().
        _PHASE2_ORBITINSERTIONBURN().
        _PHASE2_ORBITOPS_CLEANUP().
    } ELSE IF _VEHICLECONFIG = "Calypso Dock" { // This config uses calypso and has no orbit insertion due to calypso doing that on its own
        _PHASE1_TOWERCLEAR().
        _PHASE1_BOOSTERGUIDANCE().
        _PHASE1_STAGESEPARATION().

        _PHASE2_VEHICLEGUIDANCE().
        _PHASE2_ORBITOPS_CLEANUP().
    } ELSE IF _VEHICLECONFIG = "Calypso Tour" { // This config uses calypso and doesnt need orbital insertion as this handles it itself
        _PHASE1_TOWERCLEAR().
        _PHASE1_BOOSTERGUIDANCE().
        _PHASE1_STAGESEPARATION().

        _PHASE2_VEHICLEGUIDANCE().
        _PHASE2_ORBITOPS_CLEANUP().
    }
}





// ---------------------------------
//         STAGE 1 
// ---------------------------------

GLOBAL FUNCTION _PHASE1_TOWERCLEAR { // Liftoff - gravity turn start speed
    // local _VEHICLEUP is facing. // Sets the current facing to a variable

    lock steering to _STEER_TARGET. // Steers up from the pad
    _ECUTHROTTLE(95). // 95% Throttle

    UNTIL ship:verticalSpeed >= _GRAVITYTURN_STARTSPEED {
        wait 0.
    }
}

GLOBAL FUNCTION _PHASE1_BOOSTERGUIDANCE { // Guidance - Gravity Turn & Fuel Checks
    local _G_FORCE_LIMIT is _GFORCELIMIT * 10. // Will allow for Max G Throttling 
    local _CURRENTPITCH is 90. // Start Angle for gravity turn 
    _CHECKRECOVERYMETHOD(_STAGE1OXCURRENT).

    UNTIL _CURRENTPITCH = _GRAVITYTURN_ENDANGLE or _STAGE1OXCURRENT <= _SHUTDOWNFUELMARGAIN + 400 { // Gravity Turn Logic Here
        local _THROTTLE_CONTROL is (_G_FORCE_LIMIT * ship:mass / (ship:maxThrust + 0.1) * 100). // Allows vehicle to maintain the G-Force target throughout gravity turn
        _HEADINGANDPITCHCONTROL("STAGE 1"). // Controls Heading & Pitch throughout gravity turn
        _GETVEHICLEFUEL("STAGE 1"). // Grabs fuel every tick
        IF _VEHICLECONFIG = "Phoebe Heavy" {_GETVEHICLEFUEL("SIDE BOOSTERS").} // Side Booster fuel

        // Calypso Abort
            IF ag4 {
                _ECU("STAGE 1", "Shutdown").
                _ECU("STAGE 2", "Shutdown").

                IF _VEHICLECONFIG = "Calypso Dock" or _VEHICLECONFIG = "Calypso Tour"{
                    _SENDABORTCALYPSO("STAGE 1"). // Tells Calypso to eject
                }
                
                _FLIGHTTERMINATIONSYSTEM("STAGE 1"). // Sends FTS command to stage 1
                _FLIGHTTERMINATIONSYSTEM("STAGE 2"). // Sends FTS command to stage 2
            }

        // Phoebe Heavy Separation
            IF _SIDEBOOSTERS_ATTACHED and _SIDEBOOSTERSOXCURRENT < _SHUTDOWNFUELSIDEBOOSTERS + 100 {
                set _S1_ENG:thrustlimit to 60. // Limits center core thrust for separation

                _ECU("SIDE BOOSTERS", "SHUTDOWN"). // Shutdown Side Core Engines
                wait 0.5.

                // FOR CPU in SHIP:partstagged("SB_CPU") {
                //     IF CPU:hasmodule("kOSProcessor") {
                //         CPU:SENDMESSAGE("Initialise Side Core Recovery"). // Sends command to side boosters to begin their flight
                //     }
                // }
                
                toggle ag8. // Temporary Fix
                wait 0.1.
                _DEPLOYSIDEBOOSTERS(). // Separates boosters

                wait 1. // Waits a second to throttle back up
                set _S1_ENG:thrustlimit to 100. // Full Throttle

                set _SIDEBOOSTERS_ATTACHED to false. // Sets side boosters to separated state to prevent double sep
            }

        // Throttle & Steering
            _STEER_HEADING(_HEADING_CONTROL, _PITCH_CONTROL, _ROLL).
            _ECUTHROTTLE(_THROTTLE_CONTROL). 
    }
}

GLOBAL FUNCTION _PHASE1_STAGESEPARATION { // Separation - Stage 1 & 2 separate and begin own flights
    // Engine Shutdown
        set _CURRENTFACE to facing. // Facing Vector to point to (stable heading)
        _STEER_DIRECT(_CURRENTFACE). // Locks steering (we cant lock it to facing as it would not be stable)

        UNTIL _STAGE1OXCURRENT <= _SHUTDOWNFUELMARGAIN + 10 {_GETVEHICLEFUEL("STAGE 1"). wait 0.} // Stable Time For Steering

        _ECU("STAGE 1", "Shutdown"). // Shutdown
        _ECUTHROTTLE(0). // 0% Throttle (Main Engine Cutoff)
        _STAGE1COMMANDCORE:SENDMESSAGE("Initialise Recovery"). // Sends the command to S1's core to begin recovery (BEFORE SEP)

        rcs on. // Turn On RCS ports
        wait 2.5. // Settle Time

    // Separation & Core Messages
        _S1_DEC:getmodule("ModuleTundraDecoupler"):doaction("Decouple", true). // Decouples Stage 1 
        _RCSCU("FORE", "STAGE 2", "ON"). // Ullage begin

        wait 3. // Settle Time

    // Stage 2 Engine Start
        _ECU("STAGE 2", "Startup").
        _ECUTHROTTLE(10). // 10% Throttle (TEATEB)
        _RCSCU("FORE", "STAGE 2", "OFF"). // Ullage Complete
        rcs off.

        wait 1.5. // Time To Make Space From Booster
        _ECUTHROTTLE(100). // 100% Throttle (SES-1)

        wait 2. // Final Settle Time
}







// ---------------------------------
//         STAGE 2
// ---------------------------------

GLOBAL FUNCTION _PHASE2_VEHICLEGUIDANCE {
    local _G_FORCE_LIMIT is _GFORCELIMIT * 10. // Will allow for Max G Throttling 
    set steeringManager:maxstoppingtime to 0.1. // Slower Turning
    set steeringManager:rollts to 20. // Slower Rolling

    UNTIL ship:apoapsis >= body:atm:height - 3000 {_STEER_DIRECT(srfPrograde).} // Waits to start guidance while prograde

    UNTIL ship:apoapsis >= _APOGEETARGET - 1500 and ship:periapsis > body:atm:height { // Apogee must be at the target, periapsis above 0 and ship not descending
        local _THROTTLE_CONTROL is (_G_FORCE_LIMIT * ship:mass / (ship:maxThrust + 0.1) * 100).
        _HEADINGANDPITCHCONTROL("STAGE 2"). // Controls pitch and heading
       
        // Fairings Deploy (NOT ON CALYPSO)
            IF _VEHICLECONFIG = "Phoebe" or _VEHICLECONFIG = "Phoebe Heavy" {_DEPLOYFAIRINGS().} // Checks for alt & pressure for fairings

        // Steering Maximums
            IF _PITCH_CONTROL < -7.5 {set _PITCH_CONTROL to -7.5.}
            IF _PITCH_CONTROL > 15 {set _PITCH_CONTROL to 15.}
            IF ship:apoapsis < body:atm:height and _PITCH_CONTROL < -2 {set _PITCH_CONTROL to -2.}
            IF ship:apoapsis > body:atm:height and ship:periapsis > 0 {set _PITCH_CONTROL to 0.}
        
        // Loop Break Scenarios
            IF ship:apoapsis >= _APOGEETARGET and ship:periapsis >= body:atm:height - 10000 {break.}

        // Calypso Abort
            IF ag4 {
                _ECU("STAGE 2", "Shutdown").

                IF _VEHICLECONFIG = "Calypso Dock" or _VEHICLECONFIG = "Calypso Tour"{
                    _SENDABORTCALYPSO("STAGE 2"). // Tells Calypso to eject
                }
                
                _FLIGHTTERMINATIONSYSTEM("STAGE 2"). // Sends FTS command to stage 2
            }

        // Throttle & Steering
            _STEER_HEADING(_HEADING_CONTROL, _PITCH_CONTROL, _ROLL). // Steer Phoebe

            IF ship:apoapsis <= _APOGEETARGET - 20000 {_ECUTHROTTLE(100).} // Initial Throttle at full power
            IF ship:apoapsis >= _APOGEETARGET - 20000 and ship:periapsis >= _PERIGEETARGET - 100000 {_ECUTHROTTLE(40).} // Final Slower Throttle
    }

    _ECUTHROTTLE(0). // 0% Throttle (SECO)
    
    UNTIL ship:apoapsis >= _APOGEETARGET {
        IF ship:apoapsis < _APOGEETARGET {rcs on. set ship:control:fore to 0.5.}
        ELSE {set ship:control:fore to 0. rcs off.}

        IF _VEHICLECONFIG = "Phoebe" or _VEHICLECONFIG = "Phoebe Heavy" {_DEPLOYFAIRINGS().}
        wait 0.
    }

    wait 5.
}

GLOBAL FUNCTION _PHASE2_ORBITINSERTIONBURN {
    LOCAL _TARGETVEL is _ORBITALVELOCITYPERIGEE(_APOGEETARGET, _PERIGEETARGET).
    local _CURRENTVEL is _ORBITALVELOCITYAPOGEE(ship:apoapsis, ship:periapsis).
    local _VELTOGO is _TARGETVEL - _CURRENTVEL. // Maths finding difference of velocity 
    local _MAXACCELERATION is ship:maxthrust / ship:mass. // Max Vehicle Acceleration
    local _REQUIREDBURNDURATION is _VELTOGO / _MAXACCELERATION. // Required Burn for orbit

    UNTIL eta:apoapsis - 1 <= (_REQUIREDBURNDURATION / 2) {
        _STEER_DIRECT(prograde).
        
        IF ship:apoapsis < _APOGEETARGET {rcs on. _RCSCU("FORE", "STAGE 2", "ON").} 
        ELSE {_RCSCU("FORE", "STAGE 2", "OFF"). rcs off.}    
        }

    _ECUTHROTTLE(70). // 100% Throttle (SES-2)

    UNTIL ship:periapsis >= (_PERIGEETARGET - 0.3) {
        wait 0.

        if ship:periapsis >= _PERIGEETARGET - 10000 {_ECUTHROTTLE(40).}
    }

    _ECUTHROTTLE(0). // 0% Throttle (SECO-2)
    wait 5.
}

GLOBAL FUNCTION _PHASE2_ORBITOPS_CLEANUP {
    IF _VEHICLECONFIG = "Phoebe" or _VEHICLECONFIG = "Phoebe Heavy" {
        wait 30. // Time to prepare for separation
        _PAYLOADSEPARATION(). // Deploys payload / payloads
        _ORBITSHUTDOWNPROCEDURE().
    } ELSE IF _VEHICLECONFIG = "Calypso Dock" or _VEHICLECONFIG = "Calypso Tour" { 
        _CALYPSOCOMMANDCORE:SENDMESSAGE("Initialise Calypso"). // Sends a message to Calypso to begin its orbital operations
        _DEPLOYCALYPSO(). // Deploys calypso separating from stage 2
    }
}