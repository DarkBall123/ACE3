#include "..\script_component.hpp"
/*
 * Author: DarkBall123
 * Creates a terrain trench on the server.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Trench class <STRING>
 * 2: Position <ARRAY>
 * 3: Direction <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ACE_player, "ACE_envelope_small", [1000, 1000, 0], 0] call ace_trenches_fnc_createTerrainTrench
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_trenchClass", "", [""]],
    ["_position", [], [[]]],
    ["_direction", 0, [0]]
];

if (!isServer || {isNull _unit} || {!alive _unit} || {count _position < 2}) exitWith {};

private _trenchConfig = configFile >> "CfgVehicles" >> _trenchClass;
private _terrainProperties = configProperties [
    _trenchConfig,
    QUOTE(configName _x in [ARR_2(QQGVAR(terrainClass),QQGVAR(terrainVertexCount))]),
    false
];
private _terrainClass = getText (_trenchConfig >> QGVAR(terrainClass));
private _vertexCount = getNumber (_trenchConfig >> QGVAR(terrainVertexCount));
private _terrainConfig = configFile >> "CfgVehicles" >> _terrainClass;

private _fnc_failure = {
    [QGVAR(terrainTrenchCreated), [_unit, objNull], [_unit]] call CBA_fnc_targetEvent;
};

if (
    !(_unit call FUNC(canDigTrench))
    || {count _terrainProperties != 2}
    || {!isClass _terrainConfig}
    || {!(_vertexCount in [1, 2])}
) exitWith {
    call _fnc_failure;
};

getTerrainInfo params ["", "", "_cellSize"];
([_position, _direction, _vertexCount, _cellSize] call FUNC(getTerrainTrenchData)) params [
    "_vertices",
    "_center",
    "_terrainDirection"
];

if (
    _unit distance2D _center > _cellSize + TRENCH_ACTION_DISTANCE
    || {!([_vertices, _cellSize] call FUNC(canPlaceTerrainTrench))}
) exitWith {
    call _fnc_failure;
};

private _terrainHeights = _vertices apply {
    [_x select 0, _x select 1, getTerrainHeightASL _x]
};

private _trench = createVehicle [_terrainClass, [0, 0, 0], [], 0, "CAN_COLLIDE"];
_trench enableSimulationGlobal false;
private _surfaceNormal = surfaceNormal _center;
private _right = [sin _terrainDirection, cos _terrainDirection, 0] vectorCrossProduct _surfaceNormal;
private _forward = _surfaceNormal vectorCrossProduct _right;
private _vecDirAndUp = [_forward, _surfaceNormal];

_trench setPosASL _center;
_trench setVectorDirAndUp _vecDirAndUp;
_trench setVariable [QGVAR(progress), 0, true];
_trench setVariable [QGVAR(digging), false, true];
_trench setVariable [QGVAR(placeData), [_center, _vecDirAndUp], true];
_trench setVariable [QGVAR(terrainVertices), _vertices, true];
_trench setVariable [QGVAR(terrainHeights), _terrainHeights, true];

[QGVAR(placed), [_unit, _trench]] call CBA_fnc_globalEvent;
[QGVAR(terrainTrenchCreated), [_unit, _trench], [_unit]] call CBA_fnc_targetEvent;
