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

private _grassCutters = (_trench getVariable [QGVAR(grassCutters), []]) select {!isNull _x};
getTerrainInfo params ["", "", "_cellSize"];
private _cutterScale = _cellSize / 3.75;

if (_progress > 0 && {_grassCutters isEqualTo []}) then {
    private _terrainCells = [];
    {
        _x params ["_vertexX", "_vertexY"];
        _terrainCells pushBackUnique [_vertexX - _cellSize, _vertexY - _cellSize];
        _terrainCells pushBackUnique [_vertexX, _vertexY - _cellSize];
        _terrainCells pushBackUnique [_vertexX - _cellSize, _vertexY];
        _terrainCells pushBackUnique [_vertexX, _vertexY];
    } forEach _terrainHeights;

    {
        _x params ["_cellX", "_cellY"];
        private _cutterPos = [
            _cellX + _cellSize / 2,
            _cellY + _cellSize / 2,
            0
        ];
        _cutterPos set [2, getTerrainHeightASL _cutterPos];

        private _grassCutter = createSimpleObject ["Land_ClutterCutter_medium_F", _cutterPos];
        _grassCutter setVectorUp (surfaceNormal _cutterPos);
        _grassCutter setObjectScale _cutterScale;
        _grassCutters pushBack _grassCutter;
    } forEach _terrainCells;

    _trench setVariable [QGVAR(grassCutters), _grassCutters];
};

{
    private _cutterPos = getPosASL _x;
    _cutterPos set [2, getTerrainHeightASL _cutterPos];
    _x setPosASL _cutterPos;
    _x setVectorUp (surfaceNormal _cutterPos);
    _x setObjectScale _cutterScale;
} forEach _grassCutters;
