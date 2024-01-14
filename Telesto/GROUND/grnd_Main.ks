// Saturn Aerospace 2024
// 
// Made By Julius & Quasy
//       Telesto
// 
// ------------------------
//      Ground Main
// ------------------------
clearscreen.
_GRNDINIT().

global function _GRNDINIT {
    runoncepath("0:/SaturnAerospace/Telesto/mission_settings").
    runoncepath("0:/SaturnAerospace/Telesto/GROUND/grnd_Funcs").

    ag6 off.
    ag9 off.
    _DEFINEPARAMETERS().
    _COUNTDOWN_TMINUS(_BEGINCOUNTDOWN).



}



global function _COUNTDOWN_TMINUS {
    parameter _TMINUSCLOCK.

    until missionTime = 1 {
        _CHECKFORHOLD(_TMINUSCLOCK).
        if _TMINUSCLOCK > kuniverse:realworldtime {
            set _TMINUSCLOCK to _TMINUSCLOCK - kuniverse:realworldTime.
        } else if _TMINUSCLOCK = 0 or _TMINUSCLOCK < kuniverse:realworldtime {
            set _TMINUSCLOCK to _TMINUSCLOCK - 1. // Counts down the clock
        }

        print "T-" + _FORMATSECONDS(_TMINUSCLOCK) + "      " at (1,0).
        log "T-" + _FORMATSECONDS(_TMINUSCLOCK) to "0:Data/Telesto/mission_Time.txt".
    
        wait 1.
    }
}


