#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

GVAR(entrenchingTools) = keys (uiNamespace getVariable QGVAR(entrenchingTools));

if (isServer) then {
    addMissionEventHandler ["Loaded", {
        [{
            {
                [_x, _x getVariable [QGVAR(progress), 0]] call FUNC(setTerrainTrenchProgress);
            } forEach allMissionObjects "ACE_TerrainTrench_Base";
        }] call CBA_fnc_execNextFrame;
    }];
};

ADDON = true;
