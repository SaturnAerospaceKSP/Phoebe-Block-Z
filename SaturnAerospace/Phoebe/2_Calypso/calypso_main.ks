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
    runOncePath("0:/SaturnAerospace/Phoebe/mission_Settings.ks").
    runOncePath("0:/SaturnAerospace/Phoebe/partlist.ks").
    runOncePath("0:/SaturnAerospace/Libraries/LAZCALC.ks").
    runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks").
    runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/flight_funcs.ks").
    runOncePath("0:/SaturnAerospace/Phoebe/2_Calypso/calypso_funcs.ks").

    set steeringManager:maxstoppingtime to 0.1. // Smooth & Controlled Movement
    set steeringManager:rollts to 2. // Smooth Roll
    set config:ipu to 2000. // CPU Speed

    _DEFINESETTINGS(). // Defines vehicle settings (from ground)
    _DEFINEPARTS(). // Defines part list 

    IF _VEHICLECONFIG = "Calypso Tour" { // Sequence for the tourism version of Calypso
        // Setup
            _CALYPSOCAPSULEACTIONS("TOGGLE SHROUD").

        // Rendezvous
            _CATCH_ORBIT().
            // _MATCH_ALIGN(). // Matches the alingments of the orbits when at the AN/DN node
    } ELSE IF _VEHICLECONFIG = "Calypso Dock" { // Docking Version of calypso (Crew / Cargo)
        // Setup
            _CALYPSOCAPSULEACTIONS("TOGGLE SHROUD"). 

        // Rendezvous
            _CATCH_ORBIT(). // Looks at current orbit & changes orbit to get to the station with fastest time
            // _MATCH_ALIGN(). // Matches the alingments of the orbits when at the AN/DN node

    }
}


// --------------------------------------------------------------------------

LOCAL FUNCTION _CATCH_ORBIT { // Checks the current orbit and where the station is to catch it (also boosts periapsis)
    lock steering to LOOKDIRUP(ship:retrograde:forevector, -ship:body:position). // Locks retrograde with panels down
    
    until eta:apoapsis < 15 {
        if ship:apoapsis < _APOGEETARGET {rcs on. set ship:control:fore to -1.}
        else {set ship:control:fore to 0. rcs off.}

        wait 0.
    }
} 

LOCAL FUNCTION _MATCH_ALIGN { // Align the AN/DN of the orbit to be 0 or close to that

}