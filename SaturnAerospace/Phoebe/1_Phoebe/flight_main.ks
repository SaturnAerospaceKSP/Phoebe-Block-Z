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
    runOncePath("0:/SaturnAerospace/Libraries/rsvp/main.ks"). // Interplanetary launch library

    set steeringManager:maxstoppingtime to 5. // Max Vehicle Turning Speed
    set steeringManager:rollts to 10. // Max Roll Speed
    set config:ipu to 2000. // CPU speed
    set kuniverse:defaultloaddistance:flying:unload to 30000. // Unload distance increased for flying objects

    _DEFINESETTINGS(). // Defines mission settings and configuration
    _DEFINEPARTS(). // Defines all vehicle parts based on configuration setting 
    _GETVEHICLEFUEL("STAGE 1"). // Gets the first stage fuel for the gravity turn logic & shutdown
    _GETVEHICLEFUEL("STAGE 2"). // Gets the second stage fuel for later validation 

    GLOBAL _STAGE1COMMANDCORE is _S1_CPU:getmodule("kOSProcessor"):connection. // Used to send messages to Stage 1
    IF _VEHICLECONFIG = "Calypso" {
        GLOBAL _CALYPSOCOMMANDCORE is _CC_CPU:getmodule("kOSProcessor"):connection. // Connects directly to Calypso for preparation
    } ELSE IF _VEHICLECONFIG = "Phoebe Heavy" {
        GLOBAL _SIDEBOOSTERCOMMANDCORE is _SB_CPU:getmodule("kOSProcessor"):connection. // Side Cores CPU
    }

    _PHOEBEFLIGHTMAIN().
}

GLOBAL FUNCTION _PHOEBEFLIGHTMAIN {
    IF _VEHICLECONFIG = "Phoebe" or _VEHICLECONFIG = "Phoebe Heavy" { // Phoebe & Phoebe Heavy follow the same sequence (Boosterguidance handles separation)
        _PHASE1_TOWERCLEAR().
        _PHASE1_BOOSTERGUIDANCE().
        _PHASE1_STAGESEPARATION().

        _PHASE2_VEHICLEGUIDANCE().
        _PHASE2_ORBITINSERTIONBURN().

        IF _BODYTARGET {_INTERPLANETARY_SEQUENCE().} 

        _PHASE2_ORBITOPS_CLEANUP().
    } ELSE IF _VEHICLECONFIG = "Calypso" { // This config uses calypso and has no orbit insertion due to calypso doing that on its own
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
    SET _STAGE_1_CONTROL TO TRUE.
    SET _STAGE_2_CONTROL TO FALSE. 

    lock steering to _STEER_TARGET. // Steers up from the pad
    _ECUTHROTTLE(100). // 100% Throttle

    UNTIL ship:verticalSpeed >= _GRAVITYTURN_STARTSPEED {
        IF missionTime > 2 and ship:verticalspeed < 1 { // This is checking if Phoebe has cleared the pad
            _STRONGBACKACTIONS("Release"). // Releases as a failsafe for the pad 
        }

        wait 0.5.
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

                IF _VEHICLECONFIG = "Calypso" {
                    _SENDABORTCALYPSO("STAGE 1"). // Tells Calypso to eject
                }
                
                wait 1.
                _FLIGHTTERMINATIONSYSTEM("STAGE 1"). // Sends FTS command to stage 1
                _FLIGHTTERMINATIONSYSTEM("STAGE 2"). // Sends FTS command to stage 2
            }

        // Phoebe Heavy Separation
            IF _SIDEBOOSTERS_ATTACHED and _SIDEBOOSTERSOXCURRENT < _SHUTDOWNFUELSIDEBOOSTERS + 100 {
                set _S1_ENG:thrustlimit to 60. // Limits center core thrust for separation

                _ECU("SIDE BOOSTERS", "SHUTDOWN"). // Shutdown Side Core Engines
                wait 0.5.
                
                toggle ag8. // Temporary Fix for triggering the side core kos script
                wait 0.5. // Slight wait for the settling
                _DEPLOYSIDEBOOSTERS(). // Separates boosters

                wait 1. // Waits a second to throttle back up
                set _S1_ENG:thrustlimit to 100. // Full Throttle

                set _SIDEBOOSTERS_ATTACHED to false. // Sets side boosters to separated state to prevent double sep
            }     


            // Steering & Throttle
                _STEER_HEADING(_HEADING_CONTROL, _PITCH_CONTROL, _ROLL). // Steer outside of the loop and change vars inside
                _ECUTHROTTLE(_THROTTLE_CONTROL). // Throttle outside the loop
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
        set _SEP_FACING to ship:facing.
        _STEER_DIRECT(_SEP_FACING). // Steer straight
        _RCSCU("FORE", "STAGE 2", "ON"). // Ullage begin

        wait 1. // Settle Time

    // Stage 2 Engine Start
        _ECU("STAGE 2", "Startup").
        _ECUTHROTTLE(10). // 10% Throttle (TEATEB)
        rcs off.

        wait 3.5. // Time To Make Space From Booster
        _ECUTHROTTLE(100). // 100% Throttle (SES-1)
        _RCSCU("FORE", "STAGE 2", "OFF"). // Ullage Complete

        wait 2. // Final Settle Time
        SET _STAGE_1_CONTROL TO FALSE.
        SET _STAGE_2_CONTROL TO TRUE.
}














// ---------------------------------
//         STAGE 2
// ---------------------------------

GLOBAL FUNCTION _PHASE2_VEHICLEGUIDANCE {
    local _G_FORCE_LIMIT is _GFORCELIMIT * 10. // Will allow for Max G Throttling 
    set steeringManager:maxstoppingtime to 0.5. // Slower Turning
    set steeringManager:rollts to 20. // Slower Rolling

    UNTIL ship:apoapsis >= body:atm:height - 4000 {_STEER_DIRECT(_SEP_FACING).} // Waits to start guidance while prograde

    UNTIL ship:apoapsis >= _APOGEETARGET - 2500 and ship:periapsis > body:atm:height - 1000 { // Apogee must be at the target, periapsis above 0 and ship not descending
        local _THROTTLE_CONTROL is (_G_FORCE_LIMIT * ship:mass / (ship:maxThrust + 0.1) * 100).
        _HEADINGANDPITCHCONTROL("STAGE 2"). // Controls pitch and heading
       
        // Fairings Deploy (NOT ON CALYPSO)
            IF _VEHICLECONFIG = "Phoebe" or _VEHICLECONFIG = "Phoebe Heavy" {_DEPLOYFAIRINGS().} // Checks for alt & pressure for fairings

        // Steering Maximums
            IF _PITCH_CONTROL < -7.5 {set _PITCH_CONTROL to -7.5.}
            IF _PITCH_CONTROL > 10 {set _PITCH_CONTROL to 10.}
            IF ship:apoapsis < body:atm:height and _PITCH_CONTROL < -1 {set _PITCH_CONTROL to -1.}
            IF ship:apoapsis > body:atm:height and ship:periapsis > 0 {set _PITCH_CONTROL to 0.}
            IF ship:verticalspeed < 0 and alt:radar < body:atm:height {set _PITCH_CONTROL to -ship:verticalspeed.}
        
        // Loop Break Scenarios
            IF ship:apoapsis >= _APOGEETARGET + 1500 and ship:periapsis >= body:atm:height - 25000 {break.}

        // Calypso Abort
            IF ag4 {
                _ECU("STAGE 2", "Shutdown").

                IF _VEHICLECONFIG = "Calypso" {
                    _SENDABORTCALYPSO("STAGE 2"). // Tells Calypso to eject
                }

                wait 1.
                _FLIGHTTERMINATIONSYSTEM("STAGE 2"). // Sends FTS command to stage 2
            }

        // Throttle & Steering
            _STEER_HEADING(_HEADING_CONTROL, _PITCH_CONTROL, _ROLL). // Steer Phoebe

            IF ship:apoapsis <= _APOGEETARGET - 20000 {_ECUTHROTTLE(_THROTTLE_CONTROL).} // Initial Throttle at full power
            IF ship:apoapsis >= _APOGEETARGET - 20000 and ship:periapsis >= _PERIGEETARGET - 100000 {_ECUTHROTTLE(_THROTTLE_CONTROL - 40).} // Final Slower Throttle

        
        wait 0.01. // Wait Command to reduce lag
    }


    _ECUTHROTTLE(0). // 0% Throttle (SECO)
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
        
        IF ship:apoapsis < _APOGEETARGET + 10 {rcs on. set ship:control:fore to 1.} 
        ELSE IF ship:apoapsis >= _APOGEETARGET + 50 {rcs on. set ship:control:fore to -1.}    
        ELSE IF ship:apoapsis >= _APOGEETARGET + 10 and ship:apoapsis < _APOGEETARGET + 50 {set ship:control:fore to 0. rcs off.}
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
        _ORBITSHUTDOWNPROCEDURE(). // Cleanup the vehicle and shutdown CPU's
    } ELSE IF _VEHICLECONFIG = "Calypso" { 
        _CALYPSOCOMMANDCORE:SENDMESSAGE("Initialise Calypso"). // Sends a message to Calypso to begin its orbital operations
        _DEPLOYCALYPSO(). // Deploys calypso separating from stage 2
        _ORBITSHUTDOWNPROCEDURE(). // Shut down S2 in orbit
    }
}













// ---------------------------------
//         INTERPLANETARY
// ---------------------------------

GLOBAL FUNCTION _INTERPLANETARY_SEQUENCE { // Sequence for flying to other planets, using the RSVP public library
    set config:ipu to 2000. // Fast CPU
    _STEER_DIRECT(PROGRADE).

    _MANEUVER_TO_TARGET(). // Burn to be on course to target planet
    _SOI_CAPTURE(). // Capture SOI with stage 2 and bring periapsis to intended position
    _TUNE_ORBIT_TARGET_BODY(). // Fix up the orbit of the vehicle when in the correct orbit of the target

}

LOCAL FUNCTION _MANEUVER_TO_TARGET {
    GLOBAL _TRANSFER_OPTIONS IS LEXICON( // Option Config - https://github.com/maneatingape/rsvp
        "create_maneuver_nodes", "both", // Will we create a node
        "verbose", true, // Do we print to the CPU
        "search_interval", 500, // Processes of searching (higher = faster)
        "search_duration", 20000, // Duration of search
        "final_orbit_periapsis", 175000 // Final Periapsis for the maneuver
    ). 

    RSVP:GOTO(_INTER_PLANAR_TARGET, _TRANSFER_OPTIONS). // Now make a node

    // Library for calypso used for this (has execute node func)
        runOncePath("0:/SaturnAerospace/Phoebe/2_calypso/calypso_funcs.ks").

    // Execute the first node to get to the target
        _EXECUTE_NODE(ship:availablethrust, false, "FORE").
        remove nextNode. // Clear node from the list and focus on next one (now this section is complete)

        _STEER_DIRECT(RETROGRADE).
}

LOCAL FUNCTION _SOI_CAPTURE {
    wait 10.

    _EXECUTE_NODE(ship:availablethrust, false, "FORE"). // Execute final node
    remove nextNode. // Clear node from que

    clearscreen.
    ag6 off.
    print "WAIT FOR AG6" at (5,5).

    wait until ag6. // wait for further validation from user
}

LOCAL FUNCTION _TUNE_ORBIT_TARGET_BODY {

}