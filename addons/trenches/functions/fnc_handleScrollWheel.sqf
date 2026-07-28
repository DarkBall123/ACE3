#include "..\script_component.hpp"
/*
 * Author: Garth 'L-H' de Wet, Ruthberg
 * Handles sandbag rotation
 *
 * Arguments:
 * 0: scroll amount <NUMBER>
 *
 * Return Value:
 * handled <BOOL>
 *
 * Example:
 * [1.2] call ace_trenches_fnc_handleScrollWheel
 *
 * Public: No
 */

if (GVAR(digPFH) == -1) exitWith {false};

params ["_scroll"];

GVAR(digDirection) = if (GVAR(terrainPlacement)) then {
    (
        GVAR(digDirection)
        + ([-TERRAIN_DIRECTION_STEP, TERRAIN_DIRECTION_STEP] select (_scroll > 0))
        + 4 * TERRAIN_DIRECTION_STEP
    ) mod (4 * TERRAIN_DIRECTION_STEP)
} else {
    GVAR(digDirection) + (_scroll * 5)
};

true
