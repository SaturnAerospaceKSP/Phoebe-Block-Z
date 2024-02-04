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

        set steeringManager:maxstoppingtime to 0.01. // Smooth & Controlled Movement
        set steeringManager:rollts to 2. // Smooth Roll
        set config:ipu to 2000. // CPU Speed

    // Prepare vehicle
        _DEFINESETTINGS(). // Defines vehicle settings (from ground)
        _DEFINEPARTS(). // Defines part list 


    // Mission Configuration
        lock steering to prograde.
        set _VEHICLECONFIG to "Calypso Dock". // Set this to either "Calypso Dock" or "Calypso Tour" to choose which mission style you would like


    // Flight Style
        wait 15. // Small wait for the shroud
        IF _VEHICLECONFIG = "Calypso Tour" { // Sequence for the tourism version of Calypso
            // Setup
                _CALYPSOCAPSULEACTIONS("TOGGLE SHROUD"). // Open Aerodynamic Shroud
                wait 2.
                IF _CC_CAP:getmodulebyindex(11):hasaction("Enable RCS Thrust") {
                    _CC_CAP:getmodulebyindex(11):doaction("Enable RCS Thrust", true). // Enable Port RCS (Not on weirdly)
                }
                

            // Orbit Correction
                _CATCH_ORBIT().
        } ELSE IF _VEHICLECONFIG = "Calypso Dock" { // Docking Version of calypso (Crew / Cargo)
            // Setup
                IF hasTarget = false {set target to _TARGET_SPACECRAFT.} // Sets a target to avoid issues

                _CALYPSOCAPSULEACTIONS("TOGGLE SHROUD"). 
                wait 5.
                IF _CC_CAP:getmodulebyindex(11):hasaction("Enable RCS Thrust") {
                    _CC_CAP:getmodulebyindex(11):doaction("Enable RCS Thrust", true). // Enable Port RCS (Not on weirdly)
                }

    // Rendezvous
        IF ship:periapsis < _PERIGEETARGET - 100 {
            _CATCH_ORBIT(). // Looks at current orbit & changes orbit to get to the station with fastest time
        }

        _MATCH_ALIGN(). // Matches the alingments of the orbits when at the AN/DN node
        _HOHMAN_RAISE(). // Raises orbit to match that of the target for an intercept
        _HOHMAN_CIRCULARISE(). // When at apogee, circularise to match target

    // Reach Station
        _REDUCE_RELATIVE_VELOCITY(100). // Reduces velocity relative to station 
        _TRANSLATE_TO_STATION(5000, 20, 40). // Now move toward the station 
        _TRANSLATE_TO_STATION(2500, 15, 10). // Now move slower as we get closer
        _TRANSLATE_TO_STATION(170, 8.5, 10). // Finally move to the physics range of the target

    // Dock with station
        global _CALYPSO_DOCKING_PORT is _CC_DCK. // Assign docking port to the variable set on launch
        global _STATION_DOCKING_PORT is target:partstagged("APAS_VAST2")[0]. // Get the station's part for docking [APAS_FRONT] [APAS_BACK]

        _CALYPSO_MOVE_TO_DOCK(50, 2). // Close to 50m at 2m/s
        _CALYPSO_HOLD_POINT(). // Hold at 50m

        LOCK STEERING TO LOOKDIRUP(ship:prograde:forevector, ship:body:position). // Panels Up & point to port

        _CALYPSO_MOVE_TO_DOCK(25, 1). // Close to 25m at 1m/s
        _CALYPSO_HOLD_POINT(). // Hold at 25m
        _CALYPSO_MOVE_TO_DOCK(10, 0.8). // Close to 10m at 0.8m/s
        _CALYPSO_HOLD_POINT(). // Hold at 10m
        _CALYPSO_MOVE_TO_DOCK(0.5, 0.4). // Close to dock with station at 0.4m/s

        set ship:control:neutralize to true.
        wait 4.
        unlock steering.
        unlock throttle.
    }
}














// -----------------------------------
//  ORBITAL CORRECTION BURNS
// -----------------------------------

LOCAL FUNCTION _CATCH_ORBIT { // Checks the current orbit and where the station is to catch it (also boosts periapsis)
    wait 15. // Settling time to move away from the Phoebe Vehicle

    LOCK STEERING TO LOOKDIRUP(ship:retrograde:forevector, ship:body:position). // Locks retrograde with panels up now, rather than down on launch
    
    UNTIL eta:apoapsis < 5 {
        IF ship:apoapsis < _APOGEETARGET {rcs on. set ship:control:fore to -0.5.} // To get to target apogee (has more powerful thrusters as it's facing back)
        ELSE IF ship:apoapsis > _APOGEETARGET + 100 {rcs on. set ship:control:fore to 1.} // If we're too high above apogee (less power thrusters facing back)
        ELSE IF ship:apoapsis > _APOGEETARGET and ship:apoapsis < _APOGEETARGET + 100 {set ship:control:fore to 0. rcs off.} // When at target apogee

        wait 0.
    }

    rcs on.
    set ship:control:fore to -1. // Start burning rearward to raise the periapsis to the intended altitude

    UNTIL ship:periapsis >= _PERIGEETARGET - 500 {
        IF ship:periapsis > body:atm:height {set ship:control:fore to -1.} // Lower thrust for final part of the burn

        wait 0.
    }

    set ship:control:fore to 0. // Periapsis should now be raised 
    rcs off.
} 

LOCAL FUNCTION _MATCH_ALIGN { // Align the AN/DN of the orbit to be 0 or close to that
    wait 30.

    IF _CC_CAP:getmodulebyindex(11):hasaction("Enable RCS Thrust") {
        _CC_CAP:getmodulebyindex(11):doaction("Enable RCS Thrust", true). // Enable Port RCS (Not on weirdly)
    }

    IF abs(AngToRAN()) > abs(AngToRDN()) { // Plane Correction based on angle to ascending / descending nodes
        set _PLANECORRECT TO 1.
    } ELSE {
        set _PLANECORRECT to -1.
    }

    set _ALIGNMENT_NODE to node(time:seconds + _TIMETONODE(), 0, (_NODEPLANECHANGE() * _PLANECORRECT), 0). // Creates a node for aligning the orbit with the target
    add _ALIGNMENT_NODE. // Adds the node to the current craft

    _EXECUTE_NODE(13, true, "REAR"). // This executes the maneuver, 13 = thrust of RCS, true = using rcs, "rear" = facing position
    remove _ALIGNMENT_NODE. // Now remove the node from the list
}

LOCAL FUNCTION _HOHMAN_RAISE { // Raise the orbit to intercept the target
    wait 30. // Settling time from the last maneuver

    set _HOHMAN_RAISE_NODE to node(time:seconds + _PHASEANGLE(), 0, 0, _HOHMANN("RAISE")). // Creates a node for the raise maneuver
    add _HOHMAN_RAISE_NODE. // Adds the node to the craft

    _EXECUTE_NODE(13, true, "FORE"). // This executes the maneuver, 13 = thrust of RCS, true = using rcs, "rear" = facing position
    remove _HOHMAN_RAISE_NODE. // Removes node from list
}

LOCAL FUNCTION _HOHMAN_CIRCULARISE { // Circularise the orbit when at the apogee (close to intercept)
    wait 30. // Settle time for the raise burn

    set _HOHMAN_CIRCULARISE_NODE to node(time:seconds + eta:apoapsis, 0, 0, _HOHMANN("CIRC")). // Creates a node to raise periapsis as craft reaches apogee
    add _HOHMAN_CIRCULARISE_NODE. // Adds the node to the list

    _EXECUTE_NODE(13, true, "REAR"). // This executes the maneuver, 13 = thrust of RCS, true = using rcs, "rear" = facing position
    remove _HOHMAN_CIRCULARISE_NODE. // Remove the node from the list
}










// -----------------------------------
//  STATION TARGETING BURNS
// -----------------------------------

LOCAL FUNCTION _REDUCE_RELATIVE_VELOCITY { // As we approach the target, this will slow the relative velocity
    PARAMETER _THRESHOLD is 0.5.

    wait 30. // Settle time

    lock _RELATIVE_VELOCITY to ship:velocity:orbit - target:velocity:orbit. // Takes the current velocity minus target and finds relative speed

    rcs on. // Enable rcs now
    lock steering to lookDirUp(ship:prograde:forevector, ship:body:position). // Lock rear with panels up

    UNTIL _RELATIVE_VELOCITY:mag < _THRESHOLD {
        print "RELATIVE VEL: " + _RELATIVE_VELOCITY:mag + "   " at (1,1).
        print "THRESHOLD: " + _THRESHOLD at (1,2).

        _RCSTRANSLATE(-1 * _RELATIVE_VELOCITY). // Translate using RCS to reduce relative velocity

        wait 0.
    }

    _RCSTRANSLATE(v(0, 0, 0)). // Cleanup
}

LOCAL FUNCTION _TRANSLATE_TO_STATION { // When relative velocity is at the threshold, the capsule will move toward the target
    PARAMETER _TARGET_DISTANCE, _TARGET_VELOCITY, _THRESHOLD is 0.5.

    wait 30. // Settle Time

    lock _RELATIVE_VELOCITY to ship:velocity:orbit - target:velocity:orbit.
    lock _RENDEZVOUS_VECTOR to target:position - ship:position + (target:retrograde:vector:normalized * _TARGET_DISTANCE).
    lock steering to lookDirUp(ship:prograde:forevector, ship:body:position). // Lock rear with panels up

    set _DOCKING_PID to pidLoop(0.075, 0.00025, 0.05, 0.3, _TARGET_VELOCITY). // PID loop for guidance
    set _DOCKING_PID:setpoint to 0. // Where the PID works to
    lock _DOCKING_PID_OUTPUT to _DOCKING_PID:update(time:seconds, (-1 * _RENDEZVOUS_VECTOR:mag)).

    UNTIL (_RENDEZVOUS_VECTOR:mag < _THRESHOLD) {
        print "RENDEZVOUS VEC: " + _RENDEZVOUS_VECTOR:mag + "          "  at (1,1).

        _RCSTRANSLATE((_RENDEZVOUS_VECTOR:normalized * (_DOCKING_PID_OUTPUT)) - _RELATIVE_VELOCITY). // Translate to the target distance
    }

    _RCSTRANSLATE(v(0, 0, 0)).
}










// -----------------------------------
//  STATION DOCKING BURNS
// -----------------------------------

LOCAL FUNCTION _CALYPSO_MOVE_TO_DOCK { // Move closer to the docking port
    PARAMETER _TARGET_DIST, _TARGET_VELOCITY.    

    lock _RELATIVE_VELOCITY to ship:velocity:orbit - _STATION_DOCKING_PORT:ship:velocity:orbit. // Get relative velocity between crafts
    lock _DOCKING_VECTOR to _STATION_DOCKING_PORT:nodeposition - _CALYPSO_DOCKING_PORT:nodeposition + (_STATION_DOCKING_PORT:portfacing:vector * _TARGET_DIST).

    set _DOCKING_PID to pidLoop(0.1, 0.005, 0.0265, 0.3, _TARGET_VELOCITY). // Controls speed of movein
    set _DOCKING_PID:setpoint to 0.
    lock _DOCKING_PID_OUTPUT to _DOCKING_PID:update(time:seconds, (-1 * _DOCKING_VECTOR:mag)).

    clearScreen.
    until _DOCKING_VECTOR:mag < 0.2 { // Until we reach a margin
        IF ag9 {
            UNTIL ag6 {
                _CALYPSO_HOLD_POINT(). // Holds calypso in place until given command to release and keep moving in 
            }
        }

        _RCSTRANSLATE((_DOCKING_VECTOR:normalized * (_DOCKING_PID_OUTPUT)) - _RELATIVE_VELOCITY). // Moves calypso to the station
        print "DOCKVEC: " + _DOCKING_VECTOR:mag + "         " at (1,1). // Print for seeing how close we are
    }

    _RCSTRANSLATE(v(0, 0, 0)).
}   

LOCAL FUNCTION _CALYPSO_HOLD_POINT { // Hold calypso in the current position from the station
    PARAMETER _HALT_THRESHOLD is 0.2.

    lock _RELATIVE_VELOCITY to ship:velocity:orbit - _STATION_DOCKING_PORT:ship:velocity:orbit.

    UNTIL (_RELATIVE_VELOCITY:mag < _HALT_THRESHOLD) {
        _RCSTRANSLATE(-1 * _RELATIVE_VELOCITY).
    }

    _RCSTRANSLATE(v(0, 0, 0)).
}