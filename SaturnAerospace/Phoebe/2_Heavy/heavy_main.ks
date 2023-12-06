// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Heavy Main
// ------------------------

clearScreen.
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

    _DEFINESETTINGS(). // Defines mission settings and configuration
    _DEFINEPARTS(). // Defines all vehicle parts based on configuration setting 
    _GETVEHICLEFUEL("STAGE 1"). // Gets the first stage fuel for the gravity turn logic & shutdown
    _GETVEHICLEFUEL("STAGE 2"). // Gets the second stage fuel for later validation 
    _GETVEHICLEFUEL("SIDE BOOSTERS"). // Gets side booster fuel

    _SIDEBOOSTERRECOVERY(). // Run Script
}


// -----------------------
//      Wait Section
// -----------------------

GLOBAL FUNCTION _SIDEBOOSTERRECOVERY {
    wait until _SIDEBOOSTERS_ATTACHED = false.
    print "Yo" at (10,10).
}