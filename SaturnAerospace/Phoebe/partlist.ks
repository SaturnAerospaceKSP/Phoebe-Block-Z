// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Partlist 
// ------------------------

GLOBAL _GROUNDTAGS IS LEXICON(
    "GROUND STAGE", LEXICON(
        "CPU", "GND_CPU",
        "STRONGBACK", "GND_TE",
        "TOWER", "GND_TOWER",
        "BASE", "GND_BASE", 
        "WDS", "GND_WDS"
    )
).

GLOBAL _PHOEBETAGS IS LEXICON(
    "FIRST STAGE", LEXICON(
        "CPU", "S1_CPU", 
        "ENGINE", "S1_ENG",
        "TANK", "S1_TANK",
        "DECOUPLER", "S1_DEC",
        "CGTs", "S1_CGT",
        "LEGS", "S1_LEG",
        "FINS", "S1_FIN",
        
        "FTS", "S1_FTS"
    ),

    "SECOND STAGE", LEXICON(
        "CPU", "S2_CPU",
        "ENGINE", "S2_ENG",
        "TANK", "S2_TANK",
        "RCS", "S2_RCS",
        "PLF", "S2_PLF",
        "PLS", "S2_PLS",

        "FTS", "S2_FTS"
    ),

    "SIDE BOOSTERS", LEXICON(
        "CPU", "SB_CPU",
        "ENGINE", "SB_ENG",
        "TANK", "SB_TANK",
        "DECOUPLER", "SB_DEC",
        "CGT", "SB_CGT",
        "LEGS", "SB_LEG",
        "FINS", "SB_FIN",
        "NOSE", "SB_NOSE",

        "FTS", "SB_FTS"
    )
).

GLOBAL _CALYPSOTAGS IS LEXICON(
    "CPU", "CC_CPU",
    "DECOUPLER", "CC_DEC",
    "TRUNK", "CC_TRUNK",
    "CAPSULE", "CC_CAPSULE",
    "HEATSHIELD", "CC_HEATSHIELD",
    "MAINS", "CC_MAINS",
    "DROGUES", "CC_DROGUES",
    "APAS", "CC_APAS"
).