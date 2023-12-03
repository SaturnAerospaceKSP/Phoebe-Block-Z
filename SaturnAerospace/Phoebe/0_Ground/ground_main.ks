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
    runOncePath("0:/SaturnAerospace/Libraries/LAZCALC.ks"). // Azimuth Calculations
    
    ag6 off. // Abort Trigger
    ag9 off. // Abort Trigger 
    set config:ipu to 2000.

    _DEFINESETTINGS(). // Defines mission settings and configuration
    _DEFINEPARTS(). // Defines all vehicle parts based on configuration setting 
    _STRONGBACKACTIONS("Start Generator"). // Starts power feed to Phoebe
    _STRONGBACKACTIONS("Start Fueling"). // Starts fueling of Phoebe (Stage 1, then Stage 2)
    
    GLOBAL _STAGE2COMMANDCORE is _S2_CPU:getmodule("kOSProcessor"):connection. // Used to send messages to Stage 2 (Main CPU)
    IF _VEHICLECONFIG = "Calypso Dock" or _VEHICLECONFIG = "Calypso Tour" {
        GLOBAL _CALYPSOCOMMANDCORE is _CC_CPU:getmodule("kOSProcessor"):connection. // Connects directly to Calypso for preparation
    }

    _COUNTDOWNSEQUENCE(_BEGINCOUNTTIME). // Finally, the countdown sequence is run to go through the count
}

GLOBAL FUNCTION _COUNTDOWNSEQUENCE { // Primary Countdown Function
    parameter _TIMETOSTART.
    set _TMINUSCLOCK to _TIMETOSTART.

    until missionTime = 1 {
        _HOLDCHECKER(_TMINUSCLOCK). // Continuously Checks for a automatic / manual hold
        _LAUNCHVALIDITY(_TMINUSCLOCK). // Repeatedly looks for issues with vehicle and informs MCC

        _COUNTDOWNEVENTSACTION(_TMINUSCLOCK). // Events for the countdown

        print "T-" + _FORMATSECONDS(_TMINUSCLOCK) + "       " at (1,0). // Prints to the terminal
        log "T-" + _FORMATSECONDS(_TMINUSCLOCK) to "0:/Data/mission_Time.txt". // Log T Minus to OBS

        IF _BEGINCOUNTTIME > kuniverse:realworldtime { // IF the unix time is in the future, it will use that rather than a normal countdown
            set _TMINUSCLOCK to _BEGINCOUNTTIME - kuniverse:realworldtime.
        } ELSE {
            set _TMINUSCLOCK to _TMINUSCLOCK - 1. // Counts down the clock
        }

        GLOBAL _INTERCOMMUNICATIONS_TMINUS is _TMINUSCLOCK.
        wait 1. 
    }
}
