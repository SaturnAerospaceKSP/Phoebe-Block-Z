clearScreen.
print "Waiting For Message - Calypso".

until false {
    wait until not core:messages:empty. // Waits until the core recieves a message
    set _MSGRECIEVED to core:messages:pop. // Assigns variable to message recieved
    set _DECODEDMSG to _MSGRECIEVED:content. // Stores message in a decoded format

    IF _DECODEDMSG = "Initialise Calypso" { // Initialises Calypso prior to launch 
        runOncePath("0:/SaturnAerospace/Phoebe/2_Calypso/calypso_main.ks"). // Runs path of recieved message
    } ELSE IF _DECODEDMSG = "ABORT ABORT ABORT" { // RUN ABORT MODE INSTANTLY
        runOncePath("0:/SaturnAerospace/Phoebe/2_Calypso/calypso_funcs.ks"). // Grabs functions for calypso abort
        _CALYPSOABORT().
    } 
}