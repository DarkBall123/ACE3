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

#define PREVIEW_HEIGHT 0.1
#define PREVIEW_ICON_SIZE 0.5
#define PREVIEW_ICON "\a3\ui_f\data\map\markers\military\dot_CA.paa"
#define PREVIEW_VALID_COLOR [1, 1, 1, 0.9]
#define PREVIEW_INVALID_COLOR [1, 0.15, 0.15, 0.95]
#define VALIDATION_INTERVAL 0.5

params ["_unit", "_trenchClass"];

private _trenchConfig = configFile >> "CfgVehicles" >> _trenchClass;
GVAR(trenchClass) = _trenchClass;
GVAR(trenchPlacementData) = getArray (_trenchConfig >> QGVAR(placementData));
TRACE_1("",GVAR(trenchPlacementData));

private _terrainProperties = configProperties [
    _trenchConfig,
    QUOTE(configName _x in [ARR_2(QQGVAR(terrainClass),QQGVAR(terrainVertexCount))]),
    false
];
private _terrainClass = getText (_trenchConfig >> QGVAR(terrainClass));
private _terrainConfig = configFile >> "CfgVehicles" >> _terrainClass;
private _terrainVertexCount = getNumber (_trenchConfig >> QGVAR(terrainVertexCount));
private _terrainDepth = getNumber (_terrainConfig >> QGVAR(terrainDepth));
GVAR(terrainPlacement) = count _terrainProperties == 2
    && {isClass _terrainConfig}
    && {_terrainVertexCount in [1, 2]}
    && {_terrainDepth > 0};
GVAR(trenchPlacementValid) = false;
if (!GVAR(terrainPlacement)) then {
    _terrainVertexCount = 0;
};

// prevent the placing unit from running
[_unit, "forceWalk", QUOTE(ADDON), true] call EFUNC(common,statusEffect_set);
[_unit, "blockThrow", QUOTE(ADDON), true] call EFUNC(common,statusEffect_set);

private _trench = objNull;
if (!GVAR(terrainPlacement)) then {
    private _noGeoModel = getText (_trenchConfig >> QGVAR(noGeoClass));
    if (_noGeoModel == "") then {
        _noGeoModel = _trenchClass;
    };
    _trench = createVehicle [_noGeoModel, [0, 0, 0], [], 0, "NONE"];
    [QEGVAR(common,enableSimulationGlobal), [_trench, false]] call CBA_fnc_serverEvent;
};
GVAR(trench) = _trench;

getTerrainInfo params ["", "", "_cellSize"];
GVAR(digDirection) = if (GVAR(terrainPlacement)) then {
    (
        TERRAIN_DIRECTION_STEP * round (getDir _unit / TERRAIN_DIRECTION_STEP)
    ) mod (4 * TERRAIN_DIRECTION_STEP)
} else {
    0
};

// pfh that runs while the dig is in progress
GVAR(digPFH) = [{
    (_this select 0) params [
        "_unit",
        "_trench",
        "_terrainVertexCount",
        "_terrainDepth",
        "_cellSize",
        "_lastVertices",
        "_nextValidation"
    ];

    // Cancel if the place is no longer suitable
    if !([_unit] call FUNC(canDigTrench)) exitWith {
        [_unit] call FUNC(placeCancel);
    };

    private _basePos = eyePos _unit vectorAdd ([sin getDir _unit, +cos getDir _unit, 0] vectorMultiply 1.0);

    if (_terrainVertexCount > 0) exitWith {
        ([_basePos, GVAR(digDirection), _terrainVertexCount, _cellSize] call FUNC(getTerrainTrenchData)) params [
            "_terrainVertices",
            "_terrainCenter",
            "_terrainDirection"
        ];

        if (_terrainVertices isNotEqualTo _lastVertices || {CBA_missionTime >= _nextValidation}) then {
            GVAR(trenchPlacementValid) = [_unit, _terrainVertices, _cellSize] call FUNC(canPlaceTerrainTrench);
            (_this select 0) set [5, _terrainVertices];
            (_this select 0) set [6, CBA_missionTime + VALIDATION_INTERVAL];
        };

        GVAR(trenchPos) = _terrainCenter;
        GVAR(digDirection) = _terrainDirection;

        private _color = [PREVIEW_INVALID_COLOR, PREVIEW_VALID_COLOR] select GVAR(trenchPlacementValid);
        {
            drawIcon3D [
                PREVIEW_ICON,
                _color,
                _x + [PREVIEW_HEIGHT],
                PREVIEW_ICON_SIZE,
                PREVIEW_ICON_SIZE,
                0,
                format ["-%1 m", _terrainDepth toFixed 2],
                2,
                0.035,
                "RobotoCondensed"
            ];
        } forEach _terrainVertices;
    };

    // Cancel if the helper object is gone
    if (isNull _trench) exitWith {
        [_unit] call FUNC(placeCancel);
    };

    // Update trench position
    GVAR(trenchPlacementData) params ["_dx", "_dy", "_offset"];
    private _angle = (GVAR(digDirection) + getDir _unit);

    // _v1 forward from the player, _v2 to the right, _v3 points away from the ground
    private _v3 = surfaceNormal _basePos;
    private _v2 = [sin _angle, +cos _angle, 0] vectorCrossProduct _v3;
    private _v1 = _v3 vectorCrossProduct _v2;

    // Stick the trench to the ground
    _basePos set [2, getTerrainHeightASL _basePos];
    private _minzoffset = 0;
    for [{private _ix = -_dx/2},{_ix <= _dx/2},{_ix = _ix + _dx/3}] do {
        for [{private _iy = -_dy/2},{_iy <= _dy/2},{_iy = _iy + _dy/3}] do {
            private _pos = _basePos vectorAdd (_v2 vectorMultiply _ix)
                                    vectorAdd (_v1 vectorMultiply _iy);
            _minzoffset = _minzoffset min ((getTerrainHeightASL _pos) - (_pos select 2));
            #ifdef DEBUG_MODE_FULL
                _pos set [2, getTerrainHeightASL _pos];
                private _pos2 = +_pos;
                _pos2 set [2, getTerrainHeightASL _pos + 1];
                drawLine3D [ASLToAGL _pos, ASLToAGL _pos2, [1,1,0,1]];
            #endif
        };
    };
    _basePos set [2, (_basePos select 2) + _minzoffset + _offset];
    TRACE_2("",_minzoffset,_offset);
    _trench setPosASL _basePos;
    _trench setVectorDirAndUp [_v1, _v3];
    GVAR(trenchPos) = _basePos;

}, 0, [_unit, _trench, _terrainVertexCount, _terrainDepth, _cellSize, [], 0]] call CBA_fnc_addPerFrameHandler;

// add mouse button action and hint
[localize LSTRING(ConfirmDig), localize LSTRING(CancelDig), localize LSTRING(ScrollAction)] call EFUNC(interaction,showMouseHint);

_unit setVariable [QGVAR(Dig), [
    _unit, "DefaultAction",
    {GVAR(digPFH) != -1},
    {[_this select 1] call FUNC(placeConfirm)}
] call EFUNC(common,addActionEventHandler)];

_unit setVariable [QGVAR(isPlacing), true, true];
