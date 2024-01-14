// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
//
// Join Saturn Aerospace - https://discord.gg/3HhPyRdkHu
// 
// ------------------------
//     Mission Settings
// ------------------------

GLOBAL _MISSIONSETTINGS IS LEXICON( // Only change this 
    // vehicle Configuration
        "MISSION NAME", "SCOMv3 M5", // Mission name (vessel name)
        "LAUNCH MOUNT",  "KSC 39a", // [KSC 39a] [CCSFS 40] [Falcon 1.1]
        "PAYLOAD TYPE", "Phoebe Heavy", // [Phoebe] [Phoebe Heavy] [Calypso] 
        "TARGET VESSEL", Moon, // use "None", or set this to the name of a vessel: "Bob" for example
        "TARGET BODY", Moon, // use "None", or body must be it's name: Moon, Mars...

    // Ascent & Payload
        "PAYLOAD COUNT", 12, // How many payloads are required to be separated
        "ROLL", 0, // Phoebe orientation on ascent (recommended not to touch)
        "G FORCE LIMIT", 2.5, // Force limit for ascent [2.5 For Calypso with crew]

    // Orbit Targets
        "APOGEE", 700, // Highest point of orbit (km)
        "PERIGEE", 700, // Lowest point of orbit (km)
        "INCLINE", -28, // Targeted inclination from the Launch Complex (°) [TITAN = 33] [BOB = 45] [SCOM = 0 (28°)]

    // Recovery
        "FORCE RECOVERY", "EXPD" // Can be set to either "ASDS" or "RTLS" or "EXPD" if you want to choose 
).

GLOBAL _COUNTDOWNEVENTS IS LEXICON(
    "BEGIN COUNTDOWN (NS)", LEXICON("H", 0, "M", 0, "S", 20), // Countdown Initiate (NS - Non Specific)
    "BEGIN COUNTDOWN (UNIX)", LEXICON("UNIX", 1705191300), // Countdown Initiate With UNIX Time (0 to ignore) 1705191300

    "CREW ARM RETRACT", LEXICON("H", 0, "M", 45, "S", 0), // Crew Arm Retraction
    "CALYPSO STARTUP", LEXICON("H", 0, "M", 40, "S", 0), // Calypso Capsule Power Up - after this point it will abort with thrusters

    "PHOEBE HEAVY FUELING START", LEXICON("H", 0, "M", 35, "S", 0), // Phoebe Heavy Fuel Start Time (Slightly longer for Phoebe Heavy 3 cores)
    "PHOEBE FUELING START", LEXICON("H", 0, "M", 25, "S", 0), // Phoebe Fuel Start Time (Minimum 21 minutes above Fueling Closeout)

    "INTERNAL POWER", LEXICON("H", 0, "M", 5, "S", 0), // When The Power Generators Shut Down - battery power
    "FUELING CLOSEOUT", LEXICON("H", 0, "M", 4, "S", 20), // Complete Fueling By This Point (Fueling takes around 21 Minutes when using SA config)
    "STRONGBACK RETRACT", LEXICON("H", 0, "M", 4, "S", 15), // When Strongback Retracts
    "PHOEBE STARTUP", LEXICON("H", 0, "M", 1, "S", 0), // Startup Of Phoebe - when the vehicle switches out of ground mode
    
    "LAST ABORT TIME", LEXICON("H", 0, "M", 0, "S", 30), // Last point of abort before scrub
    "SIDE BOOSTER IGNITION", LEXICON("H", 0, "M", 0, "S", 5), // Side Boosters Ignition Time
    "CORE IGNITION", LEXICON("H", 0, "M", 0, "S", 3) // Main Engine Ignition Time
).

GLOBAL _ASCENTSETTINGS IS LEXICON(
    "FIRST STAGE", LEXICON(
        "GRAVITY TURN START SPEED", 50, // Start Speed for Gravity Turn
        "GRAVITY TURN END ANGLE", 10, // End angle for Gravity Turn
        "GRAVITY TURN END ALTITUDE", 45000 // End altitude for Gravity Turn
    ),
    "SECOND STAGE", LEXICON(
        "PAYLOAD FAIRINGS", LEXICON(
            "MAX DYNAMIC PRESSURE", 2.0, // Max pressure of deployment if req are met
            "MIN ALTITUDE", 70000 // Minimum altitude of deployment if req are met
        )
    )
).