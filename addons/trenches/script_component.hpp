#define COMPONENT trenches
#define COMPONENT_BEAUTIFIED Trenches
#include "\z\ace\addons\main\script_mod.hpp"

#define TERRAIN_CELL_SIZE_MIN 1
#define TERRAIN_CELL_SIZE_MAX 10
#define TERRAIN_DIRECTION_STEP 90
#define TRENCH_ACTION_DISTANCE 3

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_TRENCHES
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_TRENCHES
    #define DEBUG_SETTINGS DEBUG_SETTINGS_TRENCHES
#endif

#include "\z\ace\addons\main\script_macros.hpp"
