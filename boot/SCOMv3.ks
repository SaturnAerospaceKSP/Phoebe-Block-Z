clearScreen.

until ship:apoapsis > 125000 and ship:periapsis > 125000 {
    print "APO: " + round(ship:apoapsis / 1000, 2) at (1,1).
    print "PER: " + round(ship:periapsis / 1000, 2) at (1,2).
    print "WAITING FOR ORBIT OF 125x125km" at (1,3).

    wait 1.
}

wait 90. // Wait 1 minute 30 to begin operations
runOncePath("0:/SaturnAerospace/SCOMv3.ks").