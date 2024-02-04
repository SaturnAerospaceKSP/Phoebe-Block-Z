// SCOMv3 Software 
// TO BE USED ON SCOM ONLY
// Made By Quasy


_SCOM_INIT().


// --------------------
//  OPERATIONS
// --------------------

LOCAL FUNCTION _SCOM_INIT {
    clearScreen.

    rcs on.
    set steeringManager:maxstoppingtime to 0.001. // Slow Steering

    LOCK STEERING TO UP. // Lock up so that the panels orient easier

    _DEFINE_PARTS().

    wait 60. // Wait a minute for deployment 

    _BIGANTENNA:getmodule("ModuleDeployableAntenna"):doaction("Toggle Panels", true).
    _SMALLANTENNA:getmodule("ModuleDeployableAntenna"):doaction("Toggle Antenna", true).
    _PANEL:getmodule("KopernicusSolarPanel"):doaction("Toggle Panels", true).
    _DISH:getmodule("ModuleDeployableAntenna"):doaction("Toggle Panels", true).

    wait 30.
    set SHIP:name to "SCOMv3".
}








// -----------------------
//  FUNCTIONS
// -----------------------

LOCAL FUNCTION _DEFINE_PARTS {
    SET _BUS TO ship:partstagged("SCOM")[0].
    SET _BIGANTENNA TO ship:partstagged("SCOM_ANTENNA")[0].
    SET _SMALLANTENNA TO ship:partstagged("SCOM_LONGANTENNA")[0].
    SET _PANEL to ship:partstagged("SCOM_PANEL")[0].
    SET _DISH to ship:partstagged("SCOM_DISH")[0].
}