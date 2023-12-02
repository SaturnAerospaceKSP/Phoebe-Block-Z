until ag8 {
    clearscreen.
    print "Waiting For Ag8" at (0,0).
    print round(ship:altitude / 1000, 2) + "          " at (0,1).
}
print "Stage Separation".
rcs on.

wait 3.
runOncePath("0:/ZArchive/PBX2/flight/landing/rec_Decision.ks").