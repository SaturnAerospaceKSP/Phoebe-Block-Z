// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Data Output
// ------------------------

CD("0:/SaturnAerospace/Phoebe/"). // Changes default directory for file use
runOncePath("0:/SaturnAerospace/Phoebe/mission_settings.ks"). // Prerequisite for scripts
runOncePath("0:/SaturnAerospace/Phoebe/partlist.ks"). // Prerequisite for scripts
runOncePath("0:/SaturnAerospace/Libraries/LAZCALC.ks"). // Azimuth Library
runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_funcs.ks"). // Required for conversion funcs
_DEFINESETTINGS(). // Defines settings for vehicle
_DEFINEPARTS(). // Defines parts for the vehicle
_DATAOUTPUTCHECKER(). // Checks for files & deletes if the file exists

wait 1.
clearScreen.

until false {
    _DATALOGGING(). // Logs data for eternity
    _DATAFLIGHT(). // Logs to a folder for each flight
} 

GLOBAL FUNCTION _DATAOUTPUTCHECKER {
    IF exists("0:/Data/mission_Time.txt") { // Checks if mission time exists
        deletePath("0:/Data/mission_Time.txt").
        log "N/A" to "0:/Data/mission_Time.txt".
    }

    IF exists("0:/Data/vehicle_Speed.txt") { // Checks if vehicle speed text file exists
        deletePath("0:/Data/vehicle_Speed.txt").
        log "N/A" to "0:/Data/vehicle_Speed.txt".
    } 

    IF exists("0:/Data/vehicle_Alt.txt") { // Checks if vehicle altitude file exists
        deletePath("0:/Data/vehicle_Alt.txt").
        log "N/A" to "0:/Data/vehicle_Alt.txt".
    }

    IF exists("0:/Data/vehicle_LF.txt") { // Checks if LiquidFuel Data exists
        deletePath("0:/Data/vehicle_LF.txt").
        log "N/A" to "0:/Data/vehicle_LF.txt".
    }

    IF exists("0:/Data/vehicle_OX.txt") { // Checks if Oxidizer Data exists
        deletePath("0:/Data/vehicle_OX.txt").
        log "N/A" to "0:/Data/vehicle_OX.txt".
    }
}

GLOBAL FUNCTION _DATALOGGING {
    log floor(ship:airspeed * 3.6) to  "0:/Data/vehicle_Speed.txt". // Speed in km/h
    log floor(ship:altitude / 1000, 1) to "0:/Data/vehicle_alt.txt". // Altitude in km
    _GETVEHICLEFUEL("STAGE 1").
    _GETVEHICLEFUEL("STAGE 2").

    IF ship:status = "PRELAUNCH" {
        set vehicle_TOTAL_LF to _STAGE1LFCURRENT + _STAGE2LFCURRENT. // Stage 1 & 2 Liquid Fuel Current
        set vehicle_CAPAC_LF to _STAGE1LFCAPACITY + _STAGE2LFCAPACITY. // Stage 1 & 2 Liquid Fuel Capacity

        set vehicle_TOTAL_OX to _STAGE1OXCURRENT + _STAGE2OXCURRENT. // Stage 1 & 2 Oxidizer Current
        set vehicle_CAPAC_OX to _STAGE1OXCAPACITY + _STAGE2OXCAPACITY. // Stage 1 & 2 Oxidizer Capacity

        log round((vehicle_TOTAL_LF / vehicle_CAPAC_LF) * 100, 1) to "0:/Data/vehicle_LF.txt". // Logs the Liquid Fuel for Stream
        log round((vehicle_TOTAL_OX / vehicle_CAPAC_OX) * 100, 1) to "0:/Data/vehicle_OX.txt". // Logs the Oxidizer for Stream
    }

    // Telemetry Screen
        print "|───[SATURN AEROSPACE - 2024 PBZ]───" at (0,0).
        print "| MISSION: " + shipName at (0,1). 
        print "| M.E.T: " + _FORMATSECONDS(missionTime) at (0,2).
        print "|───[ORBIT]─────────────────────────" at (0,3).
        print "| APOGEE: " + round(apoapsis / 1000, 1) + " (KM)   " at (0,4).
        print "| PERIGEE: " + round(periapsis / 1000, 1) + " (KM)   " at (0,5). 
        print "| INCLINE: " + round(orbit:inclination, 1) + " (Deg)   " at (0,6).
        print "|───[VEHICLE]───────────────────────" at (0,7).
        print "| MASS: " + round(ship:mass, 1) + " (T)   " at (0,8).
        print "| THRUST: " + round(ship:availablethrust, 1) + " (KN)   " at (0,9).
        print "| ALTITUDE: " + round(ship:altitude / 1000, 1) + " (KM)   " at (0,10).
        print "| THROTTLE: " + round(throttle * 100, 3) + " (%)   " at (0,11).
        print "| PITCH: " + round(90 - vectorAngle(ship:up:forevector, ship:facing:forevector), 3) + " (Deg)   " at (0,12).
        print "|───[TIMINGS]───────────────────────" at (0,13).
        print "| ETA APOGEE: " + _FORMATSECONDS(eta:apoapsis) + " (s)   "at (0,14).
        print "| ETA PERIGEE: " + _FORMATSECONDS(eta:periapsis) + " (s)   " at (0,15).
        print "|───[POSITION]──────────────────────" at (0,16).
        print "| LNG COORDS: " + round(longitude, 3) + "   " at (0,17).
        print "| LAT COORDS: " + round(latitude, 3) + "   " at (0,18).
        print "|───────────────────────────────────" at (0,19).
        
 // 39x17
    wait 0.15. 
}

GLOBAL FUNCTION _DATAFLIGHT {
    
}