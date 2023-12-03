clearScreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
print "Waiting For AG6 To Be Pressed..." at (10, 10).

wait until ag6.
core:part:getmodule("kOSProcessor"):doevent("Close Terminal").
runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_main.ks").