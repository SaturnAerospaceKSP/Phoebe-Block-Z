clearScreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
print "Waiting For AG6 To Be Pressed..." at (10, 10).
set terminal:width to 40.
set terminal:height to 12.

wait until ag6.
runOncePath("0:/SaturnAerospace/Telesto/GROUND/grnd_main.ks").