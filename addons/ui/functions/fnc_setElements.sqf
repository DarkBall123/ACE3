#include "..\script_component.hpp"
/*
 * Author: Jonpas
 * Sets basic visible elements of the UI using showHUD setter.
 *
 * Arguments:
 * 0: Show Hint <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [false] call ace_ui_fnc_setElements
 *
 * Public: No
 */

params [["_showHint", false]];

{
    [_x, missionNamespace getVariable (format [QGVAR(%1), _x]), false, !GVAR(allowSelectiveUI)] call FUNC(setAdvancedElement);
} forEach (keys GVAR(configCache));

if (isArray (missionConfigFile >> "showHUD")) exitWith {
    if (_showHint) then {
        [LSTRING(Disabled)] call EFUNC(common,displayTextStructured);
    };
};

private _showInfo = GVAR(soldierVehicleWeaponInfo) || {
    ACE_player call CBA_fnc_canUseWeapon
    && {currentWeapon ACE_player isKindOf ["Binocular", configFile >> "CfgWeapons"]}
};

["ui", [
    true,
    _showInfo,
    GVAR(vehicleRadar),
    GVAR(vehicleCompass),
    true,
    GVAR(commandMenu),
    GVAR(groupBar),
    true,
    true,
    true
]] call EFUNC(common,showHud);
