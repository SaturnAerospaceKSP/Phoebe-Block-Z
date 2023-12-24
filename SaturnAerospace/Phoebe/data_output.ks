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
    IF exists("0:/Data/Phoebe/mission_Time.txt") { // Checks if mission time exists
        deletePath("0:/Data/Phoebe/mission_Time.txt").
        log "N/A" to "0:/Data/Phoebe/mission_Time.txt".
    }

    IF exists("0:/Data/Phoebe/vehicle_Speed.txt") { // Checks if vehicle speed text file exists
        deletePath("0:/Data/Phoebe/vehicle_Speed.txt").
        log "N/A" to "0:/Data/Phoebe/vehicle_Speed.txt".
    } 

    IF exists("0:/Data/Phoebe/vehicle_Alt.txt") { // Checks if vehicle altitude file exists
        deletePath("0:/Data/Phoebe/vehicle_Alt.txt").
        log "N/A" to "0:/Data/Phoebe/vehicle_Alt.txt".
    }

    IF exists("0:/Data/Phoebe/stage1_propellant.txt") { // Checks if Stage 1 Data exists
        deletePath("0:/Data/Phoebe/stage1_propellant.txt").
        log "N/A" to "0:/Data/Phoebe/stage1_propellant.txt".
    }

    IF exists("0:/Data/Phoebe/stage2_propellant.txt") { // Checks if Stage 2 Data exists
        deletePath("0:/Data/Phoebe/stage2_propellant.txt").
        log "N/A" to "0:/Data/Phoebe/stage2_propellant.txt".
    }
}

GLOBAL FUNCTION _DATALOGGING {
    log floor(ship:airspeed * 3.6) to  "0:/Data/Phoebe/vehicle_Speed.txt". // Speed in km/h
    log floor(ship:altitude / 1000, 1) to "0:/Data/Phoebe/vehicle_alt.txt". // Altitude in km
    _GETVEHICLEFUEL("STAGE 1").
    _GETVEHICLEFUEL("STAGE 2").
    IF _VEHICLECONFIG = "Phoebe Heavy" {_GETVEHICLEFUEL("SIDE BOOSTERS").}

    set STAGE1_PROPELLANT to _STAGE1LFCURRENT + _STAGE1OXCURRENT.
    set STAGE1_CAPACITY to _STAGE1LFCAPACITY + _STAGE1OXCAPACITY.

    set STAGE2_PROPELLANT to _STAGE2LFCURRENT + _STAGE2OXCURRENT.
    set STAGE2_CAPACITY to _STAGE2LFCAPACITY + _STAGE2OXCAPACITY.

    IF _VEHICLECONFIG = "Phoebe Heavy" {
        set SIDEBOOSTER_PROPELLANT to _SIDEBOOSTERSLFCURRENT + _SIDEBOOSTERSOXCURRENT. 
        set SIDEBOOSTER_CAPACITY to _SIDEBOOSTERSLFCAPACITY + _SIDEBOOSTERSOXCAPACITY.
    }

    IF _VEHICLECONFIG = "Phoebe" or _VEHICLECONFIG = "Calypso Dock" or _VEHICLECONFIG = "Calypso Tour" {
        log round((STAGE1_PROPELLANT / STAGE1_CAPACITY) * 100, 1) + "%" to "0:/Data/Phoebe/stage1_propellant.txt". // Logs the Liquid Fuel for Stream
    } ELSE IF _VEHICLECONFIG = "Phoebe Heavy" {
        log round(((STAGE1_PROPELLANT + SIDEBOOSTER_PROPELLANT) / (STAGE1_CAPACITY + SIDEBOOSTER_CAPACITY)) * 100, 1) + "%" to "0:/Data/stage1_propellant.txt".
    }

    log round((STAGE2_PROPELLANT / STAGE2_CAPACITY) * 100, 1) + "%" to "0:/Data/Phoebe/stage2_propellant.txt". // Logs the Oxidizer for Stream

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

        if ship:altitude < body:atm:height {print "| MACH: " + round(sqrt(2 / 1.4 * ship:q / body:atm:altitudepressure(altitude)), 3) + " (MACH)   " at (0,10).}
        else {print "| AIRSPEED: " + round(airspeed, 3) + " (M/S)   " at (0,10).}

        print "| ALTITUDE: " + round(ship:altitude / 1000, 1) + " (KM)   " at (0,11).
        print "| THROTTLE: " + round(throttle * 100, 3) + " (%)   " at (0,12).
        print "| PITCH: " + round(90 - vectorAngle(ship:up:forevector, ship:facing:forevector), 3) + " (Deg)   " at (0,13).
        print "|───[TIMINGS]───────────────────────" at (0,14).
        print "| ETA APOGEE: " + _FORMATSECONDS(eta:apoapsis) + " (s)   "at (0,15).
        print "| ETA PERIGEE: " + _FORMATSECONDS(eta:periapsis) + " (s)   " at (0,16).
        print "|───[POSITION]──────────────────────" at (0,17).
        print "| LNG COORDS: " + round(longitude, 3) + "   " at (0,18).
        print "| LAT COORDS: " + round(latitude, 3) + "   " at (0,19).
        print "|───────────────────────────────────" at (0,20).
        
        if missionTime > 0 {
            log "T+" + _FORMATSECONDS(missionTime) to "0:/Data/Phoebe/mission_Time.txt". // Logs T+ time
        }
 // 39x17
    wait 0.15. 
}

GLOBAL FUNCTION _DATAFLIGHT {
    
}