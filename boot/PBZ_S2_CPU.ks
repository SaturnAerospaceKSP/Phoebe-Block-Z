clearScreen.
print "Waiting For Message - S2".

until false {
    wait until not core:messages:empty. // Waits until the core recieves a message
    set _MSGRECIEVED to core:messages:pop. // Assigns variable to message recieved
    set _DECODEDMSG to _MSGRECIEVED:content. // Stores message in a decoded format

    IF _DECODEDMSG = "Run Stage 2" {
        lock throttle to 1. // Sets throttle to prevent shutdown
        runOncePath("0:/SaturnAerospace/Phoebe/1_Phoebe/flight_main.ks"). // Runs path of recieved message
    } ELSE IF _DECODEDMSG = "Run Static Fire" {
        
    }
}