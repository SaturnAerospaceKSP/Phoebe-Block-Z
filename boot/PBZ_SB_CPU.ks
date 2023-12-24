clearScreen.
print "Waiting For Message - SB".

// until ag8 {
//     wait until not core:messages:empty. // Waits until the core recieves a message
//     set _MSGRECIEVED to core:messages:pop. // Assigns variable to message recieved
//     set _DECODEDMSG to _MSGRECIEVED:content. // Stores message in a decoded format

//     if _DECODEDMSG = "Initialise Side Core Recovery" {    
//         runOncePath("0:/SaturnAerospace/Phoebe/2_Heavy/heavy_main.ks"). // Runs path of recieved message
//     } 
// }

wait until ag8.
runOncePath("0:/SaturnAerospace/Phoebe/2_Heavy/heavy_main.ks"). // Runs path of recieved message