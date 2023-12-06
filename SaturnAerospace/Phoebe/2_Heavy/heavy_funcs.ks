// Saturn Aerospace 2024
// 
// Made By Quasy & EVE
// Phoebe Block Z
// 
// ------------------------
//     Heavy Funcs
// ------------------------







// ---------------------------
//      Disused Funcs
// ---------------------------

// GLOBAL FUNCTION _CHECKHEAVYFUEL { // Checks for fuel inside Side Boosters for use in gravity turn / separation
//     global _SIDEBOOSTER_RTLSMARGIN to 2475. // RTLS Margin for Side Boosters

//     FOR res IN _SB_TNK:resources { // Checks for resources in Side Boosters
//         IF res:name = "Oxidizer" { // Checks for current oxidizer
//             global _SIDEBOOSTER_OXCURRENT to res:amount. // Returns oxidizer in tank
//             global _SIDEBOOSTER_OXCAPACITY to res:amount. // Returns capacity of tank 
//         }
//     }
// }