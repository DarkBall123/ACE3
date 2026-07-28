#include "..\script_component.hpp"
/*
 * Author: DarkBall123
 * Checks if a terrain trench can be placed.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Heightmap vertices <ARRAY>
 * 2: Terrain cell size <NUMBER>
 *
 * Return Value:
 * Can place <BOOL>
 *
 * Example:
 * [ACE_player, [[1000, 1000]], 7.5] call ace_trenches_fnc_canPlaceTerrainTrench
 *
 * Public: No
 */

params ["_unit", "_vertices", "_cellSize"];

if (
    _cellSize < TERRAIN_CELL_SIZE_MIN
    || {_cellSize > TERRAIN_CELL_SIZE_MAX}
    || {_vertices isEqualTo []}
) exitWith {false};

private _invalidVertex = _vertices findIf {
    private _vertex = _x;
    _vertex params ["_vertexX", "_vertexY"];

    _vertexX < _cellSize
    || {_vertexY < _cellSize}
    || {_vertexX > worldSize - _cellSize}
    || {_vertexY > worldSize - _cellSize}
    || {surfaceIsWater _vertex}
    || {isOnRoad _vertex}
    || {!([_vertex] call EFUNC(common,canDig))}
    || {nearestTerrainObjects [_vertex, [], _cellSize, false, true] isNotEqualTo []}
    || {
        ((nearestObjects [_vertex, ["All"], _cellSize, true]) findIf {
            _x != _unit
            && {!(_x isKindOf "Man")}
            && {!(_x isKindOf "Logic")}
            && {!(_x isKindOf "ACE_LogicDummy")}
            && {!(_x isKindOf "WeaponHolder")}
        }) != -1
    }
};
if (_invalidVertex != -1) exitWith {false};

private _terrainTrenches = nearestObjects [
    _vertices select 0,
    ["ACE_TerrainTrench_Base"],
    2 * _cellSize,
    true
];

(_terrainTrenches findIf {
    (_vertices arrayIntersect (_x getVariable [QGVAR(terrainVertices), []])) isNotEqualTo []
}) == -1
