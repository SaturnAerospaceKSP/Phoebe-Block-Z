clearScreen.
print "Waiting For Message - S1".

until false {
    wait until not core:messages:empty. // Waits until the core recieves a message
    set _MSGRECIEVED to core:messages:pop. // Assigns variable to message recieved
    set _DECODEDMSG to _MSGRECIEVED:content. // Stores message in a decoded format

    if _DECODEDMSG = "Initialise Recovery" {    
        runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/Recovery/recovery_main.ks"). // Runs path of recieved message
    } 
}