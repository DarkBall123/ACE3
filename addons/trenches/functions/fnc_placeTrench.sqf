#include "..\script_component.hpp"
/*
 * Author: Garth 'L-H' de Wet, Ruthberg, edited by commy2 for better MP and eventual AI support, esteldunedain
 * Starts the place process for trench.
 *
 * Arguments:
 * 0: unit <OBJECT>
 * 1: Trench class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ACE_player, "ACE_envelope_small"] call ace_trenches_fnc_placeTrench
 *
 * Public: No
 */

#define PREVIEW_DEPTH 1
#define PREVIEW_HEIGHT 0.1
#define PREVIEW_ICON_SIZE 1.25
#define PREVIEW_LINE_WIDTH 6
#define PREVIEW_ICON "\a3\ui_f\data\IGUI\Cfg\Cursors\select_target_ca.paa"
#define PREVIEW_DEPTH_COLOR [1, 0.2, 0, 1]
#define PREVIEW_SURFACE_COLOR [0, 0.8, 1, 1]

params ["_unit", "_trenchClass"];

//Load trench data
private _noGeoModel = getText (configFile >> "CfgVehicles" >> _trenchClass >> QGVAR(noGeoClass));
if(_noGeoModel == "") then {_noGeoModel = _trenchClass;};

GVAR(trenchClass) = _trenchClass;
GVAR(trenchPlacementData) = getArray (configFile >> "CfgVehicles" >> _trenchClass >> QGVAR(placementData));
TRACE_1("",GVAR(trenchPlacementData));

// prevent the placing unit from running
[_unit, "forceWalk", QUOTE(ADDON), true] call EFUNC(common,statusEffect_set);
[_unit, "blockThrow", QUOTE(ADDON), true] call EFUNC(common,statusEffect_set);

// create the trench
private _trench = createVehicle [_noGeoModel, [0, 0, 0], [], 0, "NONE"];

GVAR(trench) = _trench;

// prevent collisions with trench
[QEGVAR(common,enableSimulationGlobal), [_trench, false]] call CBA_fnc_serverEvent;

GVAR(digDirection) = 0;

getTerrainInfo params ["", "", "_cellSize"];

// pfh that runs while the dig is in progress
GVAR(digPFH) = [{
    (_this select 0) params ["_unit", "_trench", "_cellSize"];

    // Cancel if the helper object is gone
    if (isNull _trench) exitWith {
        [_unit] call FUNC(placeCancel);
    };

    // Cancel if the place is no longer suitable
    if !([_unit] call FUNC(canDigTrench)) exitWith {
        [_unit] call FUNC(placeCancel);
    };

    // Update trench position
    GVAR(trenchPlacementData) params ["_dx", "_dy", "_offset"];
    private _basePos = eyePos _unit vectorAdd ([sin getDir _unit, +cos getDir _unit, 0] vectorMultiply 1.0);

    private _angle = (GVAR(digDirection) + getDir _unit);

    // _v1 forward from the player, _v2 to the right, _v3 points away from the ground
    private _v3 = surfaceNormal _basePos;
    private _v2 = [sin _angle, +cos _angle, 0] vectorCrossProduct _v3;
    private _v1 = _v3 vectorCrossProduct _v2;

    // Stick the trench to the ground
    _basePos set [2, getTerrainHeightASL _basePos];
    private _minzoffset = 0;
    private _terrainVertices = [];
    for [{private _ix = -_dx/2},{_ix <= _dx/2},{_ix = _ix + _dx/3}] do {
        for [{private _iy = -_dy/2},{_iy <= _dy/2},{_iy = _iy + _dy/3}] do {
            private _pos = _basePos vectorAdd (_v2 vectorMultiply _ix)
                                    vectorAdd (_v1 vectorMultiply _iy);
            _minzoffset = _minzoffset min ((getTerrainHeightASL _pos) - (_pos select 2));
            _terrainVertices pushBackUnique ((_pos select [0, 2]) apply {_cellSize * round (_x / _cellSize)});
            #ifdef DEBUG_MODE_FULL
                _pos set [2, getTerrainHeightASL _pos];
                private _pos2 = +_pos;
                _pos2 set [2, getTerrainHeightASL _pos + 1];
                drawLine3D [ASLToAGL _pos, ASLToAGL _pos2, [1,1,0,1]];
            #endif
        };
    };

    // A changed heightmap vertex affects the four surrounding terrain cells
    private _terrainCells = [];
    {
        _x params ["_vertexX", "_vertexY"];
        _terrainCells pushBackUnique [_vertexX - _cellSize, _vertexY - _cellSize];
        _terrainCells pushBackUnique [_vertexX, _vertexY - _cellSize];
        _terrainCells pushBackUnique [_vertexX - _cellSize, _vertexY];
        _terrainCells pushBackUnique [_vertexX, _vertexY];
    } forEach _terrainVertices;

    {
        _x params ["_cellX", "_cellY"];
        private _bottomLeftChanged = [_cellX, _cellY] in _terrainVertices;
        private _topLeftChanged = [_cellX, _cellY + _cellSize] in _terrainVertices;
        private _bottomRightChanged = [_cellX + _cellSize, _cellY] in _terrainVertices;
        private _topRightChanged = [_cellX + _cellSize, _cellY + _cellSize] in _terrainVertices;

        private _bottomLeft = [_cellX, _cellY, PREVIEW_HEIGHT];
        private _topLeft = [_cellX, _cellY + _cellSize, PREVIEW_HEIGHT];
        private _bottomRight = [_cellX + _cellSize, _cellY, PREVIEW_HEIGHT];
        private _topRight = [_cellX + _cellSize, _cellY + _cellSize, PREVIEW_HEIGHT];

        if (_bottomLeftChanged) then {
            _bottomLeft set [2, PREVIEW_HEIGHT + PREVIEW_DEPTH];
        };
        if (_topLeftChanged) then {
            _topLeft set [2, PREVIEW_HEIGHT + PREVIEW_DEPTH];
        };
        if (_bottomRightChanged) then {
            _bottomRight set [2, PREVIEW_HEIGHT + PREVIEW_DEPTH];
        };
        if (_topRightChanged) then {
            _topRight set [2, PREVIEW_HEIGHT + PREVIEW_DEPTH];
        };

        if (_bottomLeftChanged || {_topLeftChanged} || {_bottomRightChanged}) then {
            drawLine3D [_bottomLeft, _topLeft, PREVIEW_SURFACE_COLOR, PREVIEW_LINE_WIDTH];
            drawLine3D [_bottomLeft, _bottomRight, PREVIEW_SURFACE_COLOR, PREVIEW_LINE_WIDTH];
            drawLine3D [_topLeft, _bottomRight, PREVIEW_SURFACE_COLOR, PREVIEW_LINE_WIDTH];
        };
        if (_topLeftChanged || {_topRightChanged} || {_bottomRightChanged}) then {
            drawLine3D [_topLeft, _topRight, PREVIEW_SURFACE_COLOR, PREVIEW_LINE_WIDTH];
            drawLine3D [_topRight, _bottomRight, PREVIEW_SURFACE_COLOR, PREVIEW_LINE_WIDTH];
            drawLine3D [_topLeft, _bottomRight, PREVIEW_SURFACE_COLOR, PREVIEW_LINE_WIDTH];
        };
    } forEach _terrainCells;

    {
        private _surface = _x + [PREVIEW_HEIGHT];
        private _depth = _x + [PREVIEW_HEIGHT + PREVIEW_DEPTH];
        drawLine3D [_surface, _depth, PREVIEW_DEPTH_COLOR, PREVIEW_LINE_WIDTH];
        drawIcon3D [
            PREVIEW_ICON,
            PREVIEW_DEPTH_COLOR,
            _depth,
            PREVIEW_ICON_SIZE,
            PREVIEW_ICON_SIZE,
            0,
            format ["-%1 m", PREVIEW_DEPTH toFixed 2],
            2,
            0.05,
            "RobotoCondensedBold"
        ];
    } forEach _terrainVertices;

    _basePos set [2, (_basePos select 2) + _minzoffset + _offset];
    TRACE_2("",_minzoffset,_offset);
    _trench setPosASL _basePos;
    _trench setVectorDirAndUp [_v1, _v3];
    GVAR(trenchPos) = _basePos;

}, 0, [_unit, _trench, _cellSize]] call CBA_fnc_addPerFrameHandler;

// add mouse button action and hint
[localize LSTRING(ConfirmDig), localize LSTRING(CancelDig), localize LSTRING(ScrollAction)] call EFUNC(interaction,showMouseHint);

_unit setVariable [QGVAR(Dig), [
    _unit, "DefaultAction",
    {GVAR(digPFH) != -1},
    {[_this select 1] call FUNC(placeConfirm)}
] call EFUNC(common,addActionEventHandler)];

_unit setVariable [QGVAR(isPlacing), true, true];
