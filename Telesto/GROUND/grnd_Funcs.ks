// Saturn Aerospace 2024
// 
// Made By Julius & Quasy
//       Telesto
// 
// ------------------------
//    Ground Functions
// ------------------------


global function _DEFINEPARAMETERS {
    // _MISSION_SETTINGS

    global _MISSIONNAME to _MISSION_SETTINGS["Mission Name"].
    global _APOGTARGET to _MISSION_SETTINGS["Apogee"] * 1000.
    global _PERITARGET to _MISSION_SETTINGS["Perigee"] * 1000.
    global _INCTARGET to _MISSION_SETTINGS["Inclination"].
    global _SRBCOUNT to _MISSION_SETTINGS["SRB Count"].

    // _COUNTDOWNEVENTS

    
    // global _BEGINCOUNTDOWN to _COUNTDOWNEVENTS["Countdown Begin"].
    global _FUELBEGIN to _COUNTDOWNEVENTS["Fuel Loading Begin"].
    global _FUELCLOSEOUT to _COUNTDOWNEVENTS["Fuel Loading Closeout"].
    global _COREIGNITE to _COUNTDOWNEVENTS["Core Ignition"].
    global _BOOSTIGNITE to _COUNTDOWNEVENTS["Booster Ignition"].
    global _CLAMPRELEASE to _COUNTDOWNEVENTS["Clamp Release"].

    // // _PARTTAGS
    // IF SHIP:STATUS = "PRELAUNCH" and ship:verticalspeed < 0.01 {
    //     global _GNDCORE to ship:partstagged(_PARTTAGS["GND"]["Core"])[0].
    //     global _GNDPAD to ship:partstagged(_PARTTAGS["GND"]["Pad"])[0].
    // }

    // // S1
    // global _S1TANK to ship:partstagged(_PARTTAGS["S1"]["S1 Tank"])[0].
    // global _S1ENG to ship:partstagged(_PARTTAGS["S1"]["S1 Engine"])[0].
    // global _S1INTER to ship:partstagged(_PARTTAGS["S1"]["S1 Interstage"])[0].

    // // S2
    // global _S2TANK to ship:partstagged(_PARTTAGS["S2"]["S2 Tank"])[0].
    // global _S2ENG to ship:partstagged(_PARTTAGS["S2"]["S2 Engine"])[0].
    // global _S2PAYL to ship:partstagged(_PARTTAGS["S2"]["S2 Payload"])[0].
    // global _S2FAIR to ship:partstagged(_PARTTAGS["S2"]["Fairing"])[1].

    // // SRB
    // global _BOOSTCORE to ship:partstagged(_PARTTAGS["SRB"]["Boost Core"])[_SRBCOUNT].
    // global _BOOSTENG to ship:partstagged(_PARTTAGS["SRB"]["Boost Engine"])[_SRBCOUNT].
    // global _BOOSTSEP to ship:partstagged(_PARTTAGS["SRB"]["Boost Seperation"])[_SRBCOUNT].

    if _COUNTDOWNEVENTS["Countdown Begin (Unix)"]["Unix"] > kuniverse:realworldtime {
        global _BEGINCOUNTDOWN to round(_COUNTDOWNEVENTS["Countdown Begin (Unix)"]["Unix"]) - kuniverse:realworldtime.
    } else if _COUNTDOWNEVENTS["Countdown Begin (Unix)"]["Unix"] < kuniverse:realworldtime {
        global _BEGINCOUNTDOWN to _FORMATLEXICONTOSECOND(_COUNTDOWNEVENTS["Countdown Begin"]).
    }
}


global function _FORMATSECONDS { // Formats seconds into H, M, S
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

GLOBAL FUNCTION _FORMATLEXICONTOSECOND { 
    parameter time_Unit.

    set _HourVar to time_Unit:H * 3600. 
    set _MinVar to time_Unit:M * 60. 
    set _SecVar to time_Unit:S * 1. 

    return _HourVar + _MinVar + _SecVar.
}

global function _Veh_Throt {
    parameter throt.

    lock throttle to throt.
}

global function _Veh_Steer {
    parameter dir.

    lock steering to dir.
}

global function _CHECKFORHOLD {
    parameter _TMINUSCLOCK.

    if ag9 {
        ag9 off.
        ag6 off.
        set _TMINUSCLOCK to _TMINUSCLOCK.

        until ag6 {
            clearscreen.
            print "- ! HOLDING COUNTDOWN ! -" at (2,0).
            print "AG9 - Abort Countdown" at (2,1).
            print "AG6 - Continue Countdown at: " + _FORMATSECONDS(_TMINUSCLOCK) at (2,2).

            if ag9 {ag9 off. reboot.}
            wait 0.
        }
        clearscreen.
    }
}