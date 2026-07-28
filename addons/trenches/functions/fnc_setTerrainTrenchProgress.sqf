#include "..\script_component.hpp"
/*
 * Author: DarkBall123
 * Sets terrain trench progress on the server.
 *
 * Arguments:
 * 0: Trench <OBJECT>
 * 1: Progress <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [trench, 0.5] call ace_trenches_fnc_setTerrainTrenchProgress
 *
 * Public: No
 */

params [
    ["_trench", objNull, [objNull]],
    ["_progress", 0, [0]]
];

if (!isServer || {isNull _trench} || {!(_trench isKindOf "ACE_TerrainTrench_Base")}) exitWith {};

private _terrainHeights = _trench getVariable [QGVAR(terrainHeights), []];
private _depth = getNumber (configOf _trench >> QGVAR(terrainDepth));
if (_terrainHeights isEqualTo [] || {_depth <= 0}) exitWith {};

_progress = 0 max (_progress min 1);
private _terrainData = _terrainHeights apply {
    [_x select 0, _x select 1, (_x select 2) - _depth * _progress]
};

TRACE_3("set terrain trench progress",_trench,_progress,_terrainData);
setTerrainHeight [_terrainData, false];
_trench setVariable [QGVAR(progress), _progress, true];
