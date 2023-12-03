// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Data Output
// ------------------------

CD("0:/SaturnAerospace/Phoebe/"). // Changes default directory for file use
runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks"). // Required for conversion funcs
_DATAOUTPUTCHECKER().

wait 1.
clearScreen.

until false {
    _DATALOGGING(). // Logs data for eternity
    _DATAFLIGHT(). // Logs to a folder for each flight
} 

GLOBAL FUNCTION _DATAOUTPUTCHECKER {
    IF exists("0:/Data/vehicle_Speed.txt") { // Checks if vehicle speed text file exists
        deletePath("0:/Data/vehicle_Speed.txt").
        log "N/A" to "0:/Data/vehicle_Speed.txt".
    } 

    IF exists("0:/Data/vehicle_Alt.txt") { // Checks if vehicle altitude file exists
        deletePath("0:/Data/vehicle_Alt.txt").
        log "N/A" to "0:/Data/vehicle_Alt.txt".
    }
}

GLOBAL FUNCTION _DATALOGGING {
    log floor(ship:airspeed * 3.6) to  "0:/Data/vehicle_Speed.txt". // Speed in km/h
    log floor(ship:altitude / 1000, 1) to "0:/Data/vehicle_alt.txt". // Altitude in km

    // Telemetry Screen
        print "|───[SATURN AEROSPACE - 2024 PBZ]───" at (0,0).
        print "| MISSION: " + shipName at (0, 1). 
        print "|───[ORBIT]─────────────────────────" at (0,2).
        print "| APOGEE: " + round(apoapsis / 1000, 1) + " (KM)   " at (0,3).
        print "| PERIGEE: " + round(periapsis / 1000, 1) + " (KM)   " at (0,4). 
        print "| INCLINE: " + round(orbit:inclination, 1) + " (Deg)   " at (0,5).
        print "|───[VEHICLE]───────────────────────" at (0,6).
        print "| MASS: " + round(ship:mass, 1) + " (T)   " at (0,7).
        print "| THRUST: " + round(ship:availablethrust, 1) + " (KN)   " at (0,8).
        print "| ALTITUDE: " + round(ship:altitude / 1000, 1) + " (KM)   " at (0,9).
        print "| THROTTLE: " + round(throttle * 100, 3) + " (%)   " at (0,10).
        print "| PITCH: " + round(90 - vectorAngle(ship:up:forevector, ship:facing:forevector), 3) + " (Deg)   " at (0,11).
        print "|───[TIMINGS]───────────────────────" at (0,12).
        print "| ETA APOGEE: " + _FORMATSECONDS(eta:apoapsis) + " (s)   "at (0,13).
        print "| ETA PERIGEE: " + _FORMATSECONDS(eta:periapsis) + " (s)   " at (0,14).
        print "|───[POSITION]──────────────────────" at (0,15).
        print "| LNG COORDS: " + round(longitude, 3) + "   " at (0,16).
        print "| LAT COORDS: " + round(latitude, 3) + "   " at (0,17).
        print "|───────────────────────────────────" at (0,18).
        
 // 39x17
    wait 0.15. 
}

GLOBAL FUNCTION _DATAFLIGHT {
    
}