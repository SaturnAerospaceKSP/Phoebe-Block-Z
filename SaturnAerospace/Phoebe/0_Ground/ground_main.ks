// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Ground Main 
// ------------------------

clearScreen.
_CPUINIT(). // First Phase - Initialise the cpu for ground operations

GLOBAL FUNCTION _CPUINIT { // Initialisation of the ground CPU & preparation for flight
    runOncePath("0:/SaturnAerospace/Phoebe/mission_Settings.ks"). // Mission Settings
    runOncePath("0:/SaturnAerospace/Phoebe/partlist.ks"). // Part List
    runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks"). // Ground Functions
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/flight_funcs.ks"). // Flight Functions
    //runOncePath("0:/SaturnAerospace/Libraries/LAZCALC.ks"). // Azimuth Calculations
    
    ag6 off. // Abort Trigger
    ag9 off. // Abort Trigger 
    set config:ipu to 2000.

    _DEFINESETTINGS(). // Defines mission settings and configuration
    _DEFINEPARTS(). // Defines all vehicle parts based on configuration setting 
    IF _BODYTARGET {_DEFINEPLANET().} // Only if we have a target

    _STRONGBACKACTIONS("Start Generator"). // Starts power feed to Phoebe

    IF _BEGINCOUNTTIME < _TIME_PHOEBEFUELSTART {_STRONGBACKACTIONS("Start Fueling").} // Starts fueling of Phoebe (Stage 1, then Stage 2)
    
    GLOBAL _STAGE2COMMANDCORE is _S2_CPU:getmodule("kOSProcessor"):connection. // Used to send messages to Stage 2 (Main CPU)
    IF _VEHICLECONFIG = "Calypso" {
        GLOBAL _CALYPSOCOMMANDCORE is _CC_CPU:getmodule("kOSProcessor"):connection. // Connects directly to Calypso for preparation
    }

    _COUNTDOWNSEQUENCE(_BEGINCOUNTTIME). // Finally, the countdown sequence is run to go through the count
}

GLOBAL FUNCTION _COUNTDOWNSEQUENCE { // Primary Countdown Function
    parameter _TIMETOSTART.
    set _TMINUSCLOCK to _TIMETOSTART. // Assigns function parameter to a variable to be used

    until missionTime = 1 { // For non rendezvous timed launches
        IF _VESSELTARGET = false { // "" is a replacement for false due to kos string oddness
            _HOLDCHECKER(_TMINUSCLOCK). // Continuously Checks for a automatic / manual hold
            _LAUNCHVALIDITY(_TMINUSCLOCK). // Repeatedly looks for issues with vehicle and informs MCC
            _COUNTDOWNEVENTSACTION(_TMINUSCLOCK). // Events for the countdown

            // Stream
                print "T-" + _FORMATSECONDS(_TMINUSCLOCK) + "       " at (1,0). // Prints to the terminal

                IF missionTime < 1 {
                    log "T-" + _FORMATSECONDS(_TMINUSCLOCK) to "0:/Data/Phoebe/mission_Time.txt". // Log T Minus to OBS
                }

            // Countdown Logic
                IF _TMINUSCLOCK > kuniverse:realworldtime { // IF the unix time is in the future, it will use that rather than a normal countdown
                    set _TMINUSCLOCK to _TMINUSCLOCK - kuniverse:realworldtime.
                } ELSE IF _TMINUSCLOCK = 0 or _TMINUSCLOCK < kuniverse:realworldtime {
                    set _TMINUSCLOCK to _TMINUSCLOCK - 0.5. // Counts down the clock
                } ELSE IF _TMINUSCLOCK < 0 {
                    break.
                }

            wait 0.5. 
        } ELSE IF _VESSELTARGET = true{ // For Timed T-0  |  "" is a replacement for false due to kos string oddness
            _HOLDCHECKER(_TMINUSCLOCK). // Continuously Checks for a automatic / manual hold
            _LAUNCHVALIDITY(_TMINUSCLOCK). // Repeatedly looks for issues with vehicle and informs MCC
            _COUNTDOWNEVENTSACTION(_TMINUSCLOCK). // Events for the countdown

            // Stream
                print "T- " + _FORMATSECONDS(_TMINUSCLOCK) + "       " at (1,0).

                IF missionTime < 1 {
                    log "T-" + _FORMATSECONDS(_TMINUSCLOCK) to "0:/Data/Phoebe/mission_Time.txt".
                }

            // Countdown Logic
                set _TMINUSCLOCK to round(_LAUNCHWINDOW(_TARGET_SPACECRAFT) - time:seconds).

            wait 0.5.
        }

    }

    shutdown. // Shuts down ground CPU so that it is not using any power on pad / prevents issues
}
