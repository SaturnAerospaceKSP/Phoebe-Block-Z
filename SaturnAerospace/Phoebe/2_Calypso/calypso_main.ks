// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Calypso Main
// ------------------------

clearScreen.
_CPUINIT().

GLOBAL FUNCTION _CPUINIT {
    // Place files required here
    runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks").
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/flight_funcs.ks").
    runOncePath("0:/SaturnAerospace/Phoebe/2_Calypso/calypso_funcs.ks").

    set config:ipu to 2000. // CPU Speed

    _DEFINESETTINGS(). // Defines vehicle settings (from ground)
    _DEFINEPARTS(). // Defines part list 

}
