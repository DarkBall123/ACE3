#include "..\script_component.hpp"
/*
 * Author: DarkBall123
 * Gets heightmap vertices for a terrain trench.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Direction <NUMBER>
 * 2: Vertex count <NUMBER>
 * 3: Terrain cell size <NUMBER>
 *
 * Return Value:
 * Vertices, center position ASL and direction <ARRAY>
 *
 * Example:
 * [[1000, 1000, 0], 90, 2, 7.5] call ace_trenches_fnc_getTerrainTrenchData
 *
 * Public: No
 */

params ["_position", "_direction", "_vertexCount", "_cellSize"];

_direction = (
    (TERRAIN_DIRECTION_STEP * round (_direction / TERRAIN_DIRECTION_STEP))
    + 4 * TERRAIN_DIRECTION_STEP
) mod (4 * TERRAIN_DIRECTION_STEP);

private _vertices = [];
_position params ["_positionX", "_positionY"];

if (_vertexCount == 1) then {
    _vertices pushBack [
        _cellSize * round (_positionX / _cellSize),
        _cellSize * round (_positionY / _cellSize)
    ];
} else {
    if (_direction in [90, 270]) then {
        private _startX = _cellSize * floor (_positionX / _cellSize);
        private _vertexY = _cellSize * round (_positionY / _cellSize);
        _vertices pushBack [_startX, _vertexY];
        _vertices pushBack [_startX + _cellSize, _vertexY];
    } else {
        private _vertexX = _cellSize * round (_positionX / _cellSize);
        private _startY = _cellSize * floor (_positionY / _cellSize);
        _vertices pushBack [_vertexX, _startY];
        _vertices pushBack [_vertexX, _startY + _cellSize];
    };
};

private _center = [0, 0, 0];
{
    _center = _center vectorAdd [_x select 0, _x select 1, getTerrainHeightASL _x];
} forEach _vertices;
_center = _center vectorMultiply (1 / count _vertices);

[_vertices, _center, _direction]
