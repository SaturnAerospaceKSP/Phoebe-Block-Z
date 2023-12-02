clearScreen.
print "Waiting For Message - Calypso".

until false {
    wait until not core:messages:empty. // Waits until the core recieves a message
    set _MSGRECIEVED to core:messages:pop. // Assigns variable to message recieved
    set _DECODEDMSG to _MSGRECIEVED:content. // Stores message in a decoded format

    IF _DECODEDMSG = "Initialise Calypso" { // Initialises Calypso prior to launch 
        runOncePath("0:/SaturnAerospace/Phoebe/2_Calypso/calypso_main.ks"). // Runs path of recieved message
    } ELSE IF _DECODEDMSG = "ABORT ABORT ABORT STAGE 1" { // RUN ABORT MODE INSTANTLY
        runOncePath("0:/SaturnAerospace/Phoebe/2_Calypso/Abort/abort_stage1.ks"). // Stage 1 abort code
        _CALYPSOABORT().
    } ELSE IF _DECODEDMSG = "ABORT ABORT ABORT STAGE 2" {
        runOncePath("0:/SaturnAerospace/Phoebe/2_Calypso/Abort/abort_stage2.ks"). // Stage 2 abort code
    }
}