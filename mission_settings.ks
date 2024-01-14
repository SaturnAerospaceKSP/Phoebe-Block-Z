// Saturn Aerospace 2024
// 
// Made By Julius & Quasy
// Telesto
// 
// ------------------------
//   Mission Settings
// ------------------------

GLOBAL _MISSION_SETTINGS IS lexicon(
    "Mission Name", "Test",
    "Apogee", 100, // Highest point in orbit
    "Perigee", 100, // Lowest point in orbit
    "Inclination", 0, // Inclination
    "SRB Count", 2 // Number of solid rocket boosters 
).

GLOBAL _COUNTDOWNEVENTS IS lexicon(
    "Countdown Begin", lexicon("H", 0, "M", 0, "S", 60), // Countdown Begin (Does not launch at a certain time, primarily used for testing)
    "Countdown Begin (Unix)", lexicon("Unix", 0), // Countdown Begin Unix, (If not using set to 0)

    "Fuel Loading Begin", lexicon("H", 0, "M", 1, "S", 30), //Fueling start time (Currently only in seconds will add HH:MM:SS support later)
    "Fuel Loading Closeout", lexicon("H", 0, "M", 1, "S", 30), // Fueling Closeout time ^^

    "Core Ignition", lexicon("H", 0, "M", 0, "S", 6), // Core Engine Ignition (Currently only in seconds, Will add HH:MM:SS support later on)
    "Booster Ignition", lexicon("H", 0, "M", 0, "S", 2), // Booster Ignition ^^
    "Clamp Release", lexicon("H", 0, "M", 0, "S", 0) // Clamp Release        ^^
).


GLOBAL _PARTTAGS is lexicon( // Rocket kOS tags should be exactly to what is below.
    "GND", lexicon( // Ground Items
    "Core", "GND_CORE",
    "Pad", "GND_PAD"
    ),
    "S1", lexicon( // Stage 1 Items
    "S1 Core", "S1CORE",
    "S1 Tank", "S1TANK",
    "S1 Engine", "S1ENG",
    "S1 Interstage", "S1INTER"
    ),
    "S2", lexicon( // Stage 2 Items
    "S2 Core", "S2CORE",
    "S2 Tank", "S2TANK",
    "S2 Engine", "S2ENG",
    "S2 Payload", "S2PAYL",
    "Fairing", "S2FAIR"
    ),
    "SRB", lexicon( // SRB Items
    "Boost Core", "BCORE",
    "Boost Engine", "BENG",
    "Boost Seperation", "BSEP"
    )
).