#include "..\script_component.hpp"
/*
 * Author: DarkBall123
 * Checks if a terrain trench can be placed.
 *
 * Arguments:
 * 0: Heightmap vertices <ARRAY>
 * 1: Terrain cell size <NUMBER>
 *
 * Return Value:
 * Can place <BOOL>
 *
 * Example:
 * [[[1000, 1000]], 7.5] call ace_trenches_fnc_canPlaceTerrainTrench
 *
 * Public: No
 */

params ["_vertices", "_cellSize"];

if (_cellSize <= 0 || {_vertices isEqualTo []}) exitWith {false};

private _invalidVertex = _vertices findIf {
    _x params ["_vertexX", "_vertexY"];

    _vertexX < _cellSize
    || {_vertexY < _cellSize}
    || {_vertexX > worldSize - _cellSize}
    || {_vertexY > worldSize - _cellSize}
};
if (_invalidVertex != -1) exitWith {false};

true
