clearScreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
print "Waiting For AG6 To Be Pressed..." at (2, 10).
set terminal:width to 40.
set terminal:height to 12.

wait until ag6.
runOncePath("0:/SaturnAerospace/Phoebe/0_Ground/ground_main.ks").