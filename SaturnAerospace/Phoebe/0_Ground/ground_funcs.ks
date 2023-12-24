// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Ground Funcs
// ------------------------

GLOBAL FUNCTION _DEFINESETTINGS { // Defines Mission Settings
    // _MISSIONSETTINGS
        set ship:name to _MISSIONSETTINGS["Mission Name"].
        global _LAUNCHMOUNT to _MISSIONSETTINGS["Launch Mount"].
        global _VEHICLECONFIG to _MISSIONSETTINGS["Payload Type"].

        IF _MISSIONSETTINGS["Target Vessel"] = false {
            global _VESSELTARGET to "".
        } ELSE {
            global _VESSELTARGET to vessel(_MISSIONSETTINGS["Target Vessel"]).
        }
    
        global _PAYLOADCOUNT to _MISSIONSETTINGS["Payload Count"].
        global _ROLL to _MISSIONSETTINGS["Roll"].
        global _GFORCELIMIT to _MISSIONSETTINGS["G Force Limit"].

        global _APOGEETARGET to _MISSIONSETTINGS["Apogee"] * 1000.
        global _PERIGEETARGET to _MISSIONSETTINGS["Perigee"] * 1000.
        global _INCLINETARGET to _MISSIONSETTINGS["Incline"].

        global _RECOVERY_METHOD to _MISSIONSETTINGS["FORCE RECOVERY"].

    // _COUNTDOWNEVENTS 
        // Count Events
            global _TIME_CREWARMRETRACT to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Crew Arm Retract"]).
            global _TIME_CALYPSOSTARTUP to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Calypso Startup"]).
            global _TIME_PHOEBEHEAVYFUELSTART to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Phoebe Heavy Fueling Start"]).
            global _TIME_PHOEBEFUELSTART to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Phoebe Fueling Start"]).
            global _TIME_INTERNALPOWER to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Internal Power"]).
            global _TIME_STRONGBACKRETRACT to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Strongback Retract"]).
            global _TIME_FUELINGCLOSEOUT to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Fueling Closeout"]).
            global _TIME_PHOEBESTARTUP to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Phoebe Startup"]).
            global _TIME_LASTABORT to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Last Abort Time"]).
            global _TIME_SIDECOREIGNITE to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Side Booster Ignition"]).
            global _TIME_COREIGNITION to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Core Ignition"]).
            global _TIME_WATERDELUGE to 4. // Non Customisable (No Real Need To)

    // _ASCENTSETTINGS
        // First Stage
            global _GRAVITYTURN_STARTSPEED to _ASCENTSETTINGS["FIRST STAGE"]["Gravity Turn Start Speed"].
            global _GRAVITYTURN_ENDANGLE to _ASCENTSETTINGS["FIRST STAGE"]["Gravity Turn End Angle"].
            global _GRAVITYTURN_ENDALTITUDE to _ASCENTSETTINGS["FIRST STAGE"]["Gravity Turn End Altitude"].

        // Second Stage
            if _VEHICLECONFIG = "Phoebe" or _VEHICLECONFIG = "Phoebe Heavy" {
                global _FAIRINGS_ATTACHED to true.
                global _FAIRING_DEPLOYPRESSURE to _ASCENTSETTINGS["SECOND STAGE"]["Payload Fairings"]["Max Dynamic Pressure"].
                global _FAIRING_DEPLOYALTITUDE to _ASCENTSETTINGS["SECOND STAGE"]["Payload Fairings"]["Min Altitude"].
            }

    // Extra General Settings
        GLOBAL _GOFORLAUNCH IS TRUE. // Are We (by default) GO FOR LAUNCH 
        GLOBAL _AZIMUTHCALCULATION is LAZcalc_init(_APOGEETARGET, _INCLINETARGET). // Creates a heading from the Apogee and inclination targets

        // Count Begin
            IF _VEHICLECONFIG = "Calypso Tour" or _VEHICLECONFIG = "Phoebe Heavy" or _VEHICLECONFIG = "Phoebe" { // Logic for no docking code
                IF _COUNTDOWNEVENTS["Begin Countdown (UNIX)"]["UNIX"] > kuniverse:realworldtime {
                    global _BEGINCOUNTTIME to round(_COUNTDOWNEVENTS["Begin Countdown (UNIX)"]["UNIX"] - kuniverse:realworldtime).
                } ELSE {
                    global _BEGINCOUNTTIME to _FORMATLEXICONTIME(_COUNTDOWNEVENTS["Begin Countdown (NS)"]).
                }
            } ELSE IF _VEHICLECONFIG = "Calypso Dock" {
                // Docking Code Here
                GLOBAL _BEGINCOUNTTIME is round(_LAUNCHWINDOW(_VESSELTARGET)).
            }


    // Define Settings Complete
}

GLOBAL FUNCTION _DEFINEPARTS { // Define Vehicle Parts - checks config and assigns correct parts
    // Available Configs

    // Phoebe - 1 Core Cargo Config
    // Phoebe Heavy - 3 Cores Cargo Config
    // Calypso Dock - Docking mission to a station / craft
    // Calypso Tour - Oxford style mission - no docking

    // Default Parts (Ground)
    IF SHIP:STATUS = "PRELAUNCH" and ship:verticalspeed < 0.01 {
        global _GND_CPU to ship:partstagged(_GROUNDTAGS["GROUND STAGE"]["CPU"])[0].
        global _GND_STRONGBACK to ship:partstagged(_GROUNDTAGS["GROUND STAGE"]["STRONGBACK"])[0].
        IF _LAUNCHMOUNT = "KSC 39a" {
            set _GND_TOWER to ship:partstagged(_GROUNDTAGS["GROUND STAGE"]["TOWER"])[0].
            set _GND_BASE to ship:partstagged(_GROUNDTAGS["GROUND STAGE"]["BASE"])[0].
        } ELSE IF _LAUNCHMOUNT = "CCSFS 40" {
            set _GND_WDS to ship:partstagged(_GROUNDTAGS["GROUND STAGE"]["WDS"])[0].
        }
    }

    IF _VEHICLECONFIG = "Phoebe" {
        // Stage 1
            global _S1_CPU to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CPU"])[0].
            global _S1_ENG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["ENGINE"])[0].
            global _S1_TNK to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["TANK"])[0].
            global _S1_DEC to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["DECOUPLER"])[0].
            global _S1_CGT to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CGTs"])[1].
            global _S1_LEG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["LEGS"])[3].
            global _S1_FIN to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FINS"])[3].
            global _S1_FTS to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FTS"])[0].
        
        // Stage 2
            global _S2_CPU to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["CPU"])[0].
            global _S2_ENG to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["ENGINE"])[0].
            global _S2_TNK to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["TANK"])[0].
            global _S2_RCS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["RCS"])[1].
            global _S2_PLF to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["PLF"])[1].
            global _S2_PLS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["PLS"])[0].
            global _S2_FTS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["FTS"])[0].
    } ELSE IF _VEHICLECONFIG = "Phoebe Heavy" {
        // Stage 1
            global _S1_CPU to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CPU"])[0].
            global _S1_ENG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["ENGINE"])[0].
            global _S1_TNK to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["TANK"])[0].
            global _S1_DEC to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["DECOUPLER"])[0].
            global _S1_CGT to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CGTs"])[1].
            global _S1_LEG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["LEGS"])[3].
            global _S1_FIN to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FINS"])[3].
            global _S1_FTS to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FTS"])[0].
        
        // Side Boosters
            global _SB_CPU to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["CPU"])[1].
            global _SB_ENG to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["ENGINE"])[1].
            global _SB_TNK to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["TANK"])[1].
            global _SB_DEC to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["DECOUPLER"])[1].
            global _SB_CGT to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["CGT"])[3].
            global _SB_LEG to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["LEGS"])[7].
            global _SB_FIN to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["FINS"])[7].
            global _SB_NSE to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["NOSE"])[1].
            global _SB_FTS to ship:partstagged(_PHOEBETAGS["SIDE BOOSTERS"]["FTS"])[1].

        // Stage 2
            global _S2_CPU to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["CPU"])[0].
            global _S2_ENG to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["ENGINE"])[0].
            global _S2_TNK to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["TANK"])[0].
            global _S2_RCS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["RCS"])[1].
            global _S2_PLF to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["PLF"])[1].
            global _S2_PLS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["PLS"])[0].
            global _S2_FTS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["FTS"])[0].
    } ELSE IF _VEHICLECONFIG = "Calypso Dock" and ship:status = "PRELAUNCH" {
        // Stage 1
            global _S1_CPU to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CPU"])[0].
            global _S1_ENG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["ENGINE"])[0].
            global _S1_TNK to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["TANK"])[0].
            global _S1_DEC to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["DECOUPLER"])[0].
            global _S1_CGT to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CGTs"])[1].
            global _S1_LEG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["LEGS"])[3].
            global _S1_FIN to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FINS"])[3].
            global _S1_FTS to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FTS"])[0].
        
        // Stage 2
            global _S2_CPU to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["CPU"])[0].
            global _S2_ENG to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["ENGINE"])[0].
            global _S2_TNK to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["TANK"])[0].
            global _S2_RCS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["RCS"])[1].
            global _S2_FTS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["FTS"])[0].
        
        // Calypso
            global _CC_CPU to ship:partstagged(_CALYPSOTAGS["CPU"])[0].
            global _CC_DEC to ship:partstagged(_CALYPSOTAGS["DECOUPLER"])[0].
            global _CC_TRK to ship:partstagged(_CALYPSOTAGS["TRUNK"])[0].
            global _CC_CAP to ship:partstagged(_CALYPSOTAGS["CAPSULE"])[0].
            global _CC_HSH to ship:partstagged(_CALYPSOTAGS["HEATSHIELD"])[0].
            global _CC_MPD to ship:partstagged(_CALYPSOTAGS["MAINS"])[0].
            global _CC_DPD to ship:partstagged(_CALYPSOTAGS["DROGUES"])[0].
            global _CC_DCK to ship:partstagged(_CALYPSOTAGS["APAS"])[0].
    } ELSE IF _VEHICLECONFIG = "Calypso Tour" and ship:status = "PRELAUNCH" {
        // Stage 1
            global _S1_CPU to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CPU"])[0].
            global _S1_ENG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["ENGINE"])[0].
            global _S1_TNK to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["TANK"])[0].
            global _S1_DEC to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["DECOUPLER"])[0].
            global _S1_CGT to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["CGTs"])[1].
            global _S1_LEG to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["LEGS"])[3].
            global _S1_FIN to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FINS"])[3].
            global _S1_FTS to ship:partstagged(_PHOEBETAGS["FIRST STAGE"]["FTS"])[0].
        
        // Stage 2
            global _S2_CPU to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["CPU"])[0].
            global _S2_ENG to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["ENGINE"])[0].
            global _S2_TNK to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["TANK"])[0].
            global _S2_RCS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["RCS"])[1].
            global _S2_FTS to ship:partstagged(_PHOEBETAGS["SECOND STAGE"]["FTS"])[0].
        
        // Calypso
            global _CC_CPU to ship:partstagged(_CALYPSOTAGS["CPU"])[0].
            global _CC_DEC to ship:partstagged(_CALYPSOTAGS["DECOUPLER"])[0].
            global _CC_TRK to ship:partstagged(_CALYPSOTAGS["TRUNK"])[0].
            global _CC_CAP to ship:partstagged(_CALYPSOTAGS["CAPSULE"])[0].
            global _CC_HSH to ship:partstagged(_CALYPSOTAGS["HEATSHIELD"])[0].
            global _CC_MPD to ship:partstagged(_CALYPSOTAGS["MAINS"])[0].
            global _CC_DPD to ship:partstagged(_CALYPSOTAGS["DROGUES"])[0].
    } ELSE IF _VEHICLECONFIG = "Calypso Dock" and ship:status = not "PRELAUNCH" {
        // Calypso
            global _CC_CPU to ship:partstagged(_CALYPSOTAGS["CPU"])[0].
            // global _CC_DEC to ship:partstagged(_CALYPSOTAGS["DECOUPLER"])[0].
            global _CC_TRK to ship:partstagged(_CALYPSOTAGS["TRUNK"])[0].
            global _CC_CAP to ship:partstagged(_CALYPSOTAGS["CAPSULE"])[0].
            global _CC_HSH to ship:partstagged(_CALYPSOTAGS["HEATSHIELD"])[0].
            global _CC_MPD to ship:partstagged(_CALYPSOTAGS["MAINS"])[0].
            global _CC_DPD to ship:partstagged(_CALYPSOTAGS["DROGUES"])[0].
            global _CC_DCK to ship:partstagged(_CALYPSOTAGS["APAS"])[0].
    } ELSE IF _VEHICLECONFIG = "Calypso Tour" and ship:status = not "PRELAUNCH" {
        // Calypso
            global _CC_CPU to ship:partstagged(_CALYPSOTAGS["CPU"])[0].
            // global _CC_DEC to ship:partstagged(_CALYPSOTAGS["DECOUPLER"])[0].
            global _CC_TRK to ship:partstagged(_CALYPSOTAGS["TRUNK"])[0].
            global _CC_CAP to ship:partstagged(_CALYPSOTAGS["CAPSULE"])[0].
            global _CC_HSH to ship:partstagged(_CALYPSOTAGS["HEATSHIELD"])[0].
            global _CC_MPD to ship:partstagged(_CALYPSOTAGS["MAINS"])[0].
            global _CC_DPD to ship:partstagged(_CALYPSOTAGS["DROGUES"])[0].
    }

    // Extra Variables
        IF missionTime < 60 {GLOBAL _SHUTDOWNFUELMARGAIN IS _CHECKRECOVERYMETHOD(_GETVEHICLEFUEL("STAGE 1")).} // Shutdown point for stage 1 ascent (meco)
        IF _VEHICLECONFIG = "Phoebe Heavy" {global _SIDEBOOSTERS_ATTACHED is true. set _SHUTDOWNFUELSIDEBOOSTERS to 4950.} // This sets side boosters attachment state for use in separation
        ELSE {set _SIDEBOOSTERS_ATTACHED to false.}

    // Define Parts Complete
}




// ------------------------
//     Vehicle Control
// ------------------------

GLOBAL FUNCTION _ECU { // Engine Control Unit 
    parameter _STAGE, _ECUACTION.

    IF _STAGE = "STAGE 1" {
        IF _ECUACTION = "Startup" {
            _S1_ENG:getmodule("ModuleTundraEngineSwitch"):doaction("Activate Engine", true). 
        } ELSE IF _ECUACTION = "Shutdown" {
            _S1_ENG:getmodule("ModuleTundraEngineSwitch"):doaction("Shutdown Engine", true). 
        } ELSE IF _ECUACTION = "Next Mode" {
            _S1_ENG:getmodule("ModuleTundraEngineSwitch"):doaction("Next Engine Mode", true). 
        } ELSE IF _ECUACTION = "Previous Mode" {
            _S1_ENG:getmodule("ModuleTundraEngineSwitch"):doaction("Previous Engine Mode", true). 
        }
    } ELSE IF _STAGE = "STAGE 2" {
        IF _ECUACTION = "Startup" {
            _S2_ENG:getmodule("ModuleEnginesFX"):doaction("Activate Engine", true). 
        } ELSE IF _ECUACTION = "Shutdown" {
            _S2_ENG:getmodule("ModuleEnginesFX"):doaction("Shutdown Engine", true). 
        }
    } ELSE IF _STAGE = "SIDE BOOSTERS" {
        IF _ECUACTION = "Startup" {
            FOR P in ship:partstagged("SB_ENG") {
                IF P:MODULES:CONTAINS("ModuleTundraEngineSwitch") { // If the parts contain the module
                    LOCAL M is P:getmodule("ModuleTundraEngineSwitch"). // Get the module
                    FOR A in M:ALLACTIONNAMES() { // For each action in action names
                        IF A:CONTAINS("Activate Engine") {M:DOACTION(A, true).} // If the action names contain decoupling, Starts side booster engines
                    }
                }
            }
        } ELSE IF _ECUACTION = "Shutdown" {
            FOR P in ship:partstagged("SB_ENG") {
                IF P:MODULES:CONTAINS("ModuleTundraEngineSwitch") { // If the parts contain the module
                    LOCAL M is P:getmodule("ModuleTundraEngineSwitch"). // Get the module
                    FOR A in M:ALLACTIONNAMES() { // For each action in action names
                        IF A:CONTAINS("Shutdown Engine") {M:DOACTION(A, true).} // If the action names contain decoupling, Starts side booster engines
                    }
                }
            }
        } ELSE IF _ECUACTION = "Next Mode" {
            FOR P in ship:partstagged("SB_ENG") {
                IF P:MODULES:CONTAINS("ModuleTundraEngineSwitch") { // If the parts contain the module
                    LOCAL M is P:getmodule("ModuleTundraEngineSwitch"). // Get the module
                    FOR A in M:ALLACTIONNAMES() { // For each action in action names
                        IF A:CONTAINS("Next Engine Mode") {M:DOACTION(A, true).} // If the action names contain decoupling, Starts side booster engines
                    }
                }
            }
        } ELSE IF _ECUACTION = "Previous Mode" {
            FOR P in ship:partstagged("SB_ENG") {
                IF P:MODULES:CONTAINS("ModuleTundraEngineSwitch") { // If the parts contain the module
                    LOCAL M is P:getmodule("ModuleTundraEngineSwitch"). // Get the module
                    FOR A in M:ALLACTIONNAMES() { // For each action in action names
                        IF A:CONTAINS("Previous Engine Mode") {M:DOACTION(A, true).} // If the action names contain decoupling, Starts side booster engines
                    }
                }
            }
        }
    } 
}




// ------------------------
//     Countdown 
// ------------------------

GLOBAL FUNCTION _HOLDCHECKER { // Checks for holds & aborts 
    parameter _CURRENTTIME.

    // Manual Hold Procedure
        IF ag9 or NOT _GOFORLAUNCH and _CURRENTTIME >= _TIME_LASTABORT {
            set _HOLDTIME to _CURRENTTIME.
            log "HOLD" to "0:/Data/Phoebe/mission_time.txt".

            IF ag9 {
                ag9 off.
                ag6 off.
                set _TMINUS to _HOLDTIME.

                IF _HOLDTIME < _TIME_LASTABORT {clearScreen. _GROUNDSAFEPROCEDURE(_CURRENTTIME).} 
                ELSE IF _TMINUS >= _TIME_LASTABORT {
                    until ag6 {
                        clearscreen.

                        print "HOLD ACTIVATED" at (10, 10).
                        print "AG6 - Continue @ " + _FORMATSECONDS(_TMINUS) at (10, 11). 
                        print "AG9 - Scrub" at (10, 12).

                        if ag9 {clearscreen. reboot.}
                        if ag10 {clearScreen. _GROUNDSAFEPROCEDURE(_CURRENTTIME).}
                        wait 0.
                    }

                    clearscreen.
                }
            }
        }

    // Automatic Hold Procedure
        IF NOT _GOFORLAUNCH {
            _GROUNDSAFEPROCEDURE(_CURRENTTIME).
        }
}

GLOBAL FUNCTION _COUNTDOWNEVENTSACTION { // All events in countdown
    parameter _CURRENTTIME.

    IF _CURRENTTIME = _TIME_CREWARMRETRACT and _VEHICLECONFIG = "Calypso Dock" or _CURRENTTIME = _TIME_CREWARMRETRACT and _VEHICLECONFIG = "Calypso Tour" {
        _TOWERACTIONS("Toggle Arm").
    } ELSE IF _CURRENTTIME = _TIME_CALYPSOSTARTUP and _VEHICLECONFIG = "Calypso Dock" or _CURRENTTIME = _TIME_CALYPSOSTARTUP and _VEHICLECONFIG = "Calypso Tour" {
        _CALYPSOCOMMANDCORE:SENDMESSAGE("Initialise Calypso"). // Sends a command to begin startup on Calypso & Internal Work
    } ELSE IF _CURRENTTIME = _TIME_PHOEBEHEAVYFUELSTART and _VEHICLECONFIG = "Phoebe Heavy" {
        _STRONGBACKACTIONS("Start Fueling"). // Phoebe Heavy Fueling Procedure takes longer and starts at 35 minutes
    } ELSE IF _CURRENTTIME = _TIME_PHOEBEFUELSTART and _VEHICLECONFIG = "Phoebe" or _CURRENTTIME = _TIME_PHOEBEFUELSTART and _VEHICLECONFIG = "Calypso Dock" or _TIME_PHOEBEFUELSTART and _VEHICLECONFIG = "Calypso Tour" { 
        _STRONGBACKACTIONS("Start Fueling"). // Phoebe / Calypso, starts at 26 minutes
    } ELSE IF _CURRENTTIME = _TIME_INTERNALPOWER {
        _STRONGBACKACTIONS("Stop Generator").
    } ELSE IF _CURRENTTIME = _TIME_STRONGBACKRETRACT {
        _STRONGBACKACTIONS("Retract").
    } ELSE IF _CURRENTTIME = _TIME_FUELINGCLOSEOUT {
        _STRONGBACKACTIONS("Stop Fueling").
        toggle ag5. // Disconnects the fuel lines from the strongback
    } ELSE IF _CURRENTTIME = _TIME_SIDECOREIGNITE and _VEHICLECONFIG = "Phoebe Heavy" { // Heavy on 39a
        _ECU("SIDE BOOSTERS", "Startup").
    } ELSE IF _CURRENTTIME = _TIME_WATERDELUGE and _LAUNCHMOUNT = "KSC 39a" { // Phoebe / Calypso on 39a
        _WATERDELUGE(_LAUNCHMOUNT, "Startup").
    } ELSE IF _CURRENTTIME = _TIME_WATERDELUGE and _LAUNCHMOUNT = "CCSFS 40" { // Phoebe / Calypso on 40
        _WATERDELUGE(_LAUNCHMOUNT, "Startup").
    } ELSE IF _CURRENTTIME = _TIME_COREIGNITION {
        _ECU("STAGE 1", "Startup").
        _ECUTHROTTLE(100).
    } ELSE IF _CURRENTTIME = 0 {
        _STAGE2COMMANDCORE:SENDMESSAGE("Run Stage 2"). // Sends the S1 CPU a command to run
        _STRONGBACKACTIONS("Release"). 
    }
}

GLOBAL FUNCTION _STRONGBACKACTIONS { // Controls for vehicle strongback
    parameter _ACTION.

    IF _LAUNCHMOUNT = "CCSFS 40" {
        IF _ACTION = "Retract" {
            IF _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):hasevent("Open Erector").
            _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):doevent("Open Erector").
        } ELSE IF _ACTION = "Revert" {
            IF _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):hasevent("Close Erector") {
                _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):doevent("Close Erector").
            }
        } ELSE IF _ACTION = "Release" {
            IF _GND_STRONGBACK:getmodule("ModuleTundraDecoupler"):hasaction("Decouple") {
                _GND_STRONGBACK:getmodule("ModuleTundraDecoupler"):doaction("Decouple", true).
            }
        } ELSE IF _ACTION = "Start Fueling" {
            IF _GND_STRONGBACK:getmodulebyindex(10):hasaction("Start Fueling") {
                _GND_STRONGBACK:getmodulebyindex(10):doaction("Start Fueling", true).
            }
        } ELSE IF _ACTION = "Stop Fueling" {
            IF _GND_STRONGBACK:getmodulebyindex(10):hasaction("Stop Fueling") {
                _GND_STRONGBACK:getmodulebyindex(10):doaction("Stop Fueling", true).
            }
        } ELSE IF _ACTION = "Start Generator" {
            IF _GND_STRONGBACK:getmodulebyindex(9):hasaction("Enable Power Generator") {
                _GND_STRONGBACK:getmodulebyindex(9):doaction("Enable Power Generator", true).
            }
        } ELSE IF _ACTION = "Stop Generator" {
           IF _GND_STRONGBACK:getmodulebyindex(9):hasaction("Disable Power Generator") {
                _GND_STRONGBACK:getmodulebyindex(9):doaction("Disable Power Generator", true).
           }
        }
    } ELSE IF _LAUNCHMOUNT = "KSC 39a" {
        IF _ACTION = "Retract" {
            IF _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):hasaction("Toggle") {
                _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):doaction("Toggle", true).
            }
            
        } ELSE IF _ACTION = "Revert" {
            IF _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):hasaction("Toggle") {
                _GND_STRONGBACK:getmodule("ModuleAnimateGeneric"):doaction("Toggle", true).
            }
        } ELSE IF _ACTION = "Release" {
            IF _GND_STRONGBACK:getmodule("LaunchClamp"):hasaction("Release Clamp") {
                _GND_STRONGBACK:getmodule("LaunchClamp"):doaction("Release Clamp", true).
            }
        } ELSE IF _ACTION = "Start Fueling" {
            IF _GND_STRONGBACK:getmodulebyindex(12):hasaction("Start Fueling") {
                _GND_STRONGBACK:getmodulebyindex(12):doaction("Start Fueling", true).
            }
        } ELSE IF _ACTION = "Stop Fueling" {
            IF _GND_STRONGBACK:getmodulebyindex(12):hasaction("Stop Fueling") {
                _GND_STRONGBACK:getmodulebyindex(12):doaction("Stop Fueling", true).
            }
        } ELSE IF _ACTION = "Start Generator" {
            IF _GND_STRONGBACK:getmodulebyindex(11):hasaction("Enable Power Generator") {
                _GND_STRONGBACK:getmodulebyindex(11):doaction("Enable Power Generator", true).
            }
        } ELSE IF _ACTION = "Stop Generator" {
            IF _GND_STRONGBACK:getmodulebyindex(11):hasaction("Disable Power Generator") {
                _GND_STRONGBACK:getmodulebyindex(11):doaction("Disable Power Generator", true).
            }
        }
    } ELSE IF _LAUNCHMOUNT = "Falcon 1.1" {
        IF _ACTION = "Retract" {
            IF _GND_STRONGBACK:getmodule("moduleanimategeneric"):hasaction("Toggle") {
                _GND_STRONGBACK:getmodule("moduleanimategeneric"):doaction("Toggle", true).
            }
        } ELSE IF _ACTION = "Revert" {
            IF _GND_STRONGBACK:getmodule("moduleanimategeneric"):hasaction("Toggle") {
                _GND_STRONGBACK:getmodule("moduleanimategeneric"):doaction("Toggle", true).
            }
        } ELSE IF _ACTION = "Release" {
            IF _GND_STRONGBACK:getmodule("launchclamp"):hasaction("Release Clamp") {
                _GND_STRONGBACK:getmodule("launchclamp"):doaction("Release Clamp", true).
            }
        } 
    }
}

GLOBAL FUNCTION _TOWERACTIONS { // Crew arm actions on 39a/40 crews
    parameter _ACTION.

    IF _ACTION = "Toggle Arm" {
        IF _GND_TOWER:getmodule("ModuleAnimateGeneric"):hasaction("Toggle") { // Checks it has the ability to retract (Phoebe Heavy doesnt have the arm and wont need this)
            _GND_TOWER:getmodule("ModuleAnimateGeneric"):doaction("Toggle", true).
        }
    }
}

GLOBAL FUNCTION _WATERDELUGE { // Water Deluge System on pad 39a
    parameter _PAD, _ACTION.

    IF _PAD = "KSC 39a" {
        IF _ACTION = "Startup" {
            _GND_BASE:getmodule("ModuleEnginesFX"):doaction("Activate Engine", true).
        } ELSE IF _ACTION = "Shutdown" {
            _GND_BASE:getmodule("ModuleEnginesFX"):doaction("Shutdown Engine", true).
        }
    } ELSE IF _PAD = "CCSFS 40" {
        IF _ACTION = "Startup" {
            IF _GND_WDS:getmodule("ModuleEnginesFX"):hasaction("toggle engine") {
                _GND_WDS:getmodule("ModuleEnginesFX"):doaction("toggle engine", true).
            }
        } ELSE IF _ACTION = "Shutdown" {
            IF _GND_WDS:getmodule("ModuleEnginesFX"):hasaction("toggle engine") {
                _GND_WDS:getmodule("ModuleEnginesFX"):doaction("toggle engine", true).
            }
        }
    }
    

           
}

GLOBAL FUNCTION _LAUNCHWINDOW { // Timed launch window for Calypso / Target docking missions
    PARAMETER _TARGET.

    LOCAL _LAT is ship:latitude.
    LOCAL _ECLIPTIC_NORM is vCrs(_TARGET:OBT:VELOCITY:ORBIT, _TARGET:BODY:POSITION - _TARGET:POSITION):NORMALIZED.
    LOCAL _PLANET_NORM is heading(0, _LAT):VECTOR.
    LOCAL _BODYINCLINE is vAng(_PLANET_NORM, _ECLIPTIC_NORM). // Finds the inclination on the variables above
    LOCAL _BETA is arcCos(max(-1, min(1, cos(_BODYINCLINE) * SIN(_LAT) / sin(_BODYINCLINE)))).
    LOCAL _INTERSECT_DIR is vCrs(_PLANET_NORM, _ECLIPTIC_NORM):normalized.
    LOCAL _INTERSECT_POS is -vxcl(_PLANET_NORM, _ECLIPTIC_NORM):normalized.

    LOCAL _LAUNCHTIME_DIR is (_INTERSECT_DIR * sin(_BETA) + _INTERSECT_POS * cos(_BETA)) * cos(_LAT) + sin(_LAT) * _PLANET_NORM.
    LOCAL _LAUNCHTIME is vAng(_LAUNCHTIME_DIR, ship:position - body:position) / 360 * body:rotationperiod.

    IF vCrs(_LAUNCHTIME_DIR, ship:position - body:position) * _PLANET_NORM < 0 {
        set _LAUNCHTIME to body:rotationperiod - _LAUNCHTIME.
    }

    RETURN time:Seconds + _LAUNCHTIME. // Value for countdown
}


// ------------------------
//     Safety (RANGE)
// ------------------------

GLOBAL FUNCTION _GROUNDSAFEPROCEDURE { // For Aborts & Shutdowns this function completes a safety check & shutdown
    parameter _ABORTTIME.

    IF ship:status = "PRELAUNCH" {
        rcs off.
        sas off. 
        _ECU("STAGE1", "Shutdown"). // Engine Shutdown
        _ECUTHROTTLE(0). // Turn Throttle Off
        IF _LAUNCHMOUNT = "KSC 39a" {_WATERDELUGE("Shutdown").}
        print "GROUND SAFE PROCEDURE ACTIVATED!" at (10, 10).
        print "CPU SHUTTING DOWN!" at (10,11).
    
        wait 3.
        IF _ABORTTIME < _TIME_STRONGBACKRETRACT { // If it happens before strongback, the code throws error
            _STRONGBACKACTIONS("Revert"). // Moves strongback to vehicle
        } 
        _STRONGBACKACTIONS("Start Generator"). // Returns power from strongback
        toggle ag7. // Fuel Dump Valve
        wait 3.
        reboot.
    }

    // shutdown.
}

GLOBAL FUNCTION _LAUNCHVALIDITY { // Checks for launch status & any issues with the vehicle
    parameter _CURRENTTIME.

    // Current Variables (Pitch, Fuel etc)
        set _GOFORLAUNCH to TRUE.

        _GETVEHICLEFUEL("STAGE 1"). 
        _GETVEHICLEFUEL("STAGE 2"). 

        // LOCAL _PITCH IS 90 - vectorAngle(ship:up:forevector, ship:facing:forevector).

    // Variable Checker
        IF _CURRENTTIME < _TIME_FUELINGCLOSEOUT and _CURRENTTIME > _TIME_SIDECOREIGNITE { 
            IF _STAGE1LFCURRENT < _STAGE1LFCAPACITY - 20 or _STAGE1OXCURRENT < _STAGE1OXCAPACITY - 20 {
                _GROUNDSAFEPROCEDURE(_CURRENTTIME).
            } ELSE IF _STAGE2LFCURRENT < _STAGE2LFCAPACITY - 10 or _STAGE2OXCURRENT < _STAGE2OXCAPACITY - 10 {
                _GROUNDSAFEPROCEDURE(_CURRENTTIME).
            } 
        } ELSE {donothing.}



        // IF _PITCH < 89 or _PITCH > 91 {set _GOFORLAUNCH to false.}
}

GLOBAL FUNCTION _GETVEHICLEFUEL { // Returns fuel and capacity of vehicle
    parameter _STAGE.

    IF _STAGE = "STAGE 1" {
        FOR res IN _S1_TNK:resources {
            IF res:name = "LiquidFuel" {
                set _STAGE1LFCAPACITY to res:capacity.
                set _STAGE1LFCURRENT to res:amount.
            } ELSE IF res:name = "Oxidizer" {
                set _STAGE1OXCAPACITY to res:capacity.
                set _STAGE1OXCURRENT to res:amount.
            }
        }
    } ELSE IF _STAGE = "STAGE 2" {
        FOR res IN _S2_TNK:resources {
            IF res:name = "LiquidFuel" {
                set _STAGE2LFCAPACITY to res:capacity.
                set _STAGE2LFCURRENT to res:amount.
            } ELSE IF res:name = "Oxidizer" {
                set _STAGE2OXCAPACITY to res:capacity.
                set _STAGE2OXCURRENT to res:amount.
            }
        }
    } ELSE IF _STAGE = "SIDE BOOSTERS" {
        FOR res IN _SB_TNK:resources {
            IF res:name = "LiquidFuel" {
                set _SIDEBOOSTERSLFCAPACITY to res:capacity.
                set _SIDEBOOSTERSLFCURRENT to res:amount.
            } ELSE IF res:name = "Oxidizer" {
                set _SIDEBOOSTERSOXCAPACITY to res:capacity.
                set _SIDEBOOSTERSOXCURRENT to res:amount.
            }
        }
    } ELSE IF _STAGE = "CALYPSO" {
        FOR res IN _CC_CAP:resources {
            IF res:name = "Monopropellant" {
                set _CALYPSOMONOPROPCURRENT to res:amount.
                set _CALYPSOMONOPROPCAPACITY to res:capacity.
            } 
        }
    }
}

GLOBAL FUNCTION _CHECKRECOVERYMETHOD { // Checks fuel from getvehiclefuel and decides recovery method
    parameter _CURRENTPROPELLANT.

    global _ASDS_PROPELLANT is 1850. // Anything Above 600KM Apogee
    global _RTLS_PROPELLANT is 2500. // 600 KM Max RTLS Apogee
    global _EXPD_PROPELLANT is 10. // Expended booster

    IF _RECOVERY_METHOD = "ASDS" {
        return _ASDS_PROPELLANT. 
    } ELSE IF _RECOVERY_METHOD = "RTLS" {
        return _RTLS_PROPELLANT.
    } ELSE IF _RECOVERY_METHOD = "EXPD" { 
        return _EXPD_PROPELLANT.
    } ELSE IF _APOGEETARGET >= 600000 and _PERIGEETARGET < 1200000 and _CURRENTPROPELLANT <= _ASDS_PROPELLANT and _RECOVERY_METHOD = false { // Any orbit above 600km
        return _ASDS_PROPELLANT.
    } ELSE IF _APOGEETARGET < 600000 and _CURRENTPROPELLANT <= _RTLS_PROPELLANT or _VEHICLECONFIG = "Phoebe Heavy" or _VEHICLECONFIG = "Phoebe" and _RECOVERY_METHOD = false { // Any orbit under 600km
        return _RTLS_PROPELLANT.
    } ELSE IF _VEHICLECONFIG = "Calypso Dock" or _VEHICLECONFIG = "Calypso Tour" { // Always ASDS for crew (fuel margin is safe)
        return _ASDS_PROPELLANT.
    } ELSE IF _APOGEETARGET > 1200000 and _RECOVERY_METHOD = false {
        return _EXPD_PROPELLANT.
    }
}

GLOBAL FUNCTION _SENDABORTCALYPSO { // Sends commands to each stage to abort & separates calypso
    parameter _STAGE.

    // STAGE 1 ABORT
        IF _STAGE = "STAGE 1" {
            _CALYPSOCOMMANDCORE:SENDMESSAGE("ABORT ABORT ABORT STAGE 1"). // Ejects Calypso using its own core software
        }
        
    // STAGE 2 ABORT
        IF _STAGE = "STAGE 2" {
            _CALYPSOCOMMANDCORE:SENDMESSAGE("ABORT ABORT ABORT STAGE 2"). // Same as stage 1 just different trajectory
        } 
}

GLOBAL FUNCTION _FLIGHTTERMINATIONSYSTEM { // FTS System (self destruct) NEEDS TO BE SECOND WHEN USING CALYPSO
    parameter _FTS_STAGE.

    IF _FTS_STAGE = "STAGE 1" {
        _S1_FTS:getmodule("TacselfDestruct"):doaction("Detonate Parent!", true). // Stage 1 tank destroys
    } ELSE IF _FTS_STAGE = "STAGE 2" {
        _S2_FTS:getmodule("TacselfDestruct"):doaction("Detonate Parent!", true).
    } ELSE IF _FTS_STAGE = "SIDE BOOSTERS" {
        _SB_FTS:getmodule("TacselfDestruct"):doaction("Detonate Parent!", true).
    }
}




// ------------------------
//     Time Functions
// ------------------------

GLOBAL FUNCTION _FORMATLEXICONTIME { // Convers H M S lexicons into a usable time (seconds)
    parameter time_Unit.

    set _HourVar to time_Unit:h * 3600. // Secs in an hour
    set _MinVar to time_Unit:m * 60. // Secs in a min
    set _SecVar to time_Unit:s * 1. // Secs in a sec

    return _HourVar + _MinVar + _SecVar.
}

GLOBAL FUNCTION _FORMATSECONDS { // Formats seconds into H, M, S
    parameter time_Unit.

    local hour_Zero is "".
    local minute_Zero is "".
    local second_Zero is "".

    local hour_Floor is floor(time_Unit / 3600).
    local minute_Floor is floor((time_Unit - (hour_Floor * 3600)) / 60).
    local second_Floor is floor(time_Unit - (hour_Floor * 3600) - (minute_Floor * 60)).

    if hour_Floor < 10 {set hour_Zero to "0".} else {set hour_Zero to "".}
    if minute_Floor < 10 {set minute_Zero to "0".} else {set minute_Zero to "".}
    if second_Floor < 10 {set second_Zero to "0".} else {set second_Zero to "".}
    
    local time_Unit_Formatted is hour_Zero + hour_Floor + ":" + minute_Zero + minute_Floor + ":" + second_Zero + second_Floor.
    return time_Unit_Formatted.
}