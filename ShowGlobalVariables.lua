-- Module 
--[[
Module ShowGlobalVariables.lua

Bei der Entwicklung von Modulen passiert es leicht, dass Variablen oder Funktionen global definiert werden obwohl sie lokal sein sollten.
Zumeist funktioniert das Skript dann trotzdem wie erwartet, so dass dieser Fehler nur schlecht auffällt.

Das Modul ShowGlobalVariables zeigt globale Variablen und globale Funktionen.
Die bekannten Namen aus EEP bzw. von Lua können unterdrückt werden, so dass man nur die selbst definierten Namen erhält.

Verwendung: 
local ShowGlobalVariables = require('ShowGlobalVariables')
ShowGlobalVariables()		-- Unterdrücke bekannte Namen
ShowGlobalVariables(true)	-- Zeige alle Namen

Frank Buchholz, 2019
]]

local _VERSION = 'v2020-02-18'

-- Die Funktion reicht bis an das Ende des Moduls
local function ShowGlobalVariables(all)

-- bekannte Namen, die nicht gezeigt werden sollen
local NamesTable = {
	-- EEP 13 variables

	'EEPTime',
	'EEPTimeH',
	'EEPTimeM',
	'EEPTimeS',
	'EEPVer',

	-- EEP 13 functions

	'clearlog',
	'EEPMain',
	'EEPChangeInfoSignal',
	'EEPChangeInfoStructure',
	'EEPChangeInfoSwitch',
	'EEPGetSignal',
	'EEPGetSwitch',
	'EEPGetTrainFromTrainyard',
	'EEPGetTrainRoute',
	'EEPGetTrainSpeed',
	'EEPHideInfoTextBottom',
	'EEPHideInfoTextTop',
	'EEPIsAuxiliaryTrackReserved',
	'EEPIsControlTrackReserved',
	'EEPIsRailTrackReserved',
	'EEPIsRoadTrackReserved',
	'EEPIsTramTrackReserved',
	'EEPLoadData',
	'EEPLoadProject',
	'EEPPlaySound',
	'EEPRegisterAuxiliaryTrack',
	'EEPRegisterControlTrack',
	'EEPRegisterRailTrack',
	'EEPRegisterRoadTrack',
	'EEPRegisterSignal',
	'EEPRegisterSwitch',
	'EEPRegisterTramTrack',
	'EEPRollingstockGetAxis',
	'EEPRollingstockGetCouplingFront',
	'EEPRollingstockGetCouplingRear',
	'EEPRollingstockSetAxis',
	'EEPRollingstockSetCouplingFront',
	'EEPRollingstockSetCouplingRear',
	'EEPRollingstockSetSlot',
	'EEPSaveData',
	'EEPSetCamera',
	'EEPSetPerspectiveCamera',
	'EEPSetSignal',
	'EEPSetSwitch',
	'EEPSetTrainAxis',
	'EEPSetTrainCouplingFront',
	'EEPSetTrainCouplingRear',
	'EEPSetTrainHook',
	'EEPSetTrainHorn',
	'EEPSetTrainLight',
	'EEPSetTrainRoute',
	'EEPSetTrainSmoke',
	'EEPSetTrainSpeed',
	'EEPShowInfoSignal',
	'EEPShowInfoStructure',
	'EEPShowInfoSwitch',
	'EEPShowInfoTextBottom',
	'EEPShowInfoTextTop',
	'EEPShowScrollInfoTextBottom',
	'EEPShowScrollInfoTextTop',
	'EEPStructureAnimateAxis',
	'EEPStructureGetAxis',
	'EEPStructureGetFire',
	'EEPStructureGetLight',
	'EEPStructureGetSmoke',
	'EEPStructurePlaySound',
	'EEPStructureSetAxis',
	'EEPStructureSetFire',
	'EEPStructureSetLight',
	'EEPStructureSetPosition',
	'EEPStructureSetRotation',
	'EEPStructureSetSmoke',
	'EEPTrainLooseCoupling',
	'EEPOnSignal_1',	-- Registrierte Signale rufen selbständig diese Funktion auf, wenn sich ihre Stellung ändert
	'EEPOnSwitch_1',	-- Registrierte Weichen rufen selbständig diese Funktion auf, wenn sich ihre Stellung ändert

	-- EEP 13.2 functions

	'EEPGetRollingstockItemName',
	'EEPGetRollingstockItemsCount',
	'EEPGetSignalTrainName',
	'EEPGetSignalTrainsCount',

	-- EEP 14.2 functions

	'EEPRollingstockGetLength',
	'EEPRollingstockGetMotor',
	'EEPRollingstockGetTrack',
	'EEPRollingstockGetModelType',
	'EEPRollingstockGetTagText',

	-- EEP 15 functions (or not assiged to correct release yet)

	'EEPAuxiliaryTrackSetTextureText',
	'EEPGetTrainyardItemName',
	'EEPGetTrainyardItemsCount',
	'EEPGetTrainyardItemStatus',
	'EEPGoodsGetModelType',
	'EEPGoodsGetPosition',
	'EEPGoodsSetPosition',
	'EEPGoodsSetRotation',
	'EEPGoodsSetTextureText',
	'EEPPause',
	'EEPRailTrackSetTextureText',
	'EEPRoadTrackSetTextureText',
	'EEPRollingstockGetTrainName',
	'EEPRollingstockSetTagText',
	'EEPRollingstockSetTextureText',
	'EEPSetTime',
	'EEPSetTrainHookGlue',
	'EEPSetTrainName',
	'EEPSignalSetTextureText',
	'EEPStructureGetModelType',
	'EEPStructureGetPosition',
	'EEPStructureGetTagText',
	'EEPStructureIsAxisAnimate',
	'EEPStructureSetTagText',
	'EEPStructureSetTextureText',
	'EEPTramTrackSetTextureText',

	-- EEP 15.1 functions

	'EEPRollingstockGetActive', -- Ermittelt, welches Fahrzeug derzeit im Steuerdialog ausgewählt ist.
	'EEPRollingstockSetActive', -- Wählt das angegebene Fahrzeug im Steuerdialog aus.
	'EEPRollingstockGetOrientation', -- Ermittelt, welche relative Ausrichtung das angegebene Fahrzeug im Zugverband hat.	

	'EEPGetTrainActive', -- Ermittelt, welcher Zug derzeit im Steuerdialog ausgewählt ist.
	'EEPSetTrainActive', -- Wählt den angegebenen Zug im Steuerdialog aus.
	'EEPGetTrainLength', -- Ermittelt die Gesamtlänge des angegebenen Zuges.

	-- EEP 16.1 functions

	'EEPActivateCtrlDesk',	-- Ruft das Stellpult im Radarfenster auf
	
	'EEPGetCameraPosition',
	'EEPSetCameraPosition',

	'EEPGetCameraRotation',
	'EEPSetCameraRotation',

	'EEPStructureGetRotation',
	'EEPGoodsGetRotation',

	'EEPOnSaveAnl',

	'EEPOnTrainExitTrainyard',
	
	'EEPOnTrainCoupling',
	'EEPOnTrainLooseCoupling',
	
	'EEPRollingstockGetHook',
	'EEPRollingstockGetHookGlue',
	'EEPRollingstockGetMileage',
	'EEPRollingstockGetPosition',
	'EEPRollingstockGetSmoke',
	'EEPRollingstockSetHook',
	'EEPRollingstockSetHookGlue',
	'EEPRollingstockSetHorn',	-- Lässt bei einem bestimmten Rollmaterial den Warnton (Pfeife, Hupe) ertönen
	'EEPRollingstockSetSmoke',
	'EEPRollingstockSetUserCamera',
	
	'EEPGetCloudIntensity',
	'EEPGetFogIntensity',
	'EEPGetHailIntensity',
	'EEPGetRainIntensity',
	'EEPGetSnowIntensity',
	'EEPGetWindIntensity',

	'EEPSetCloudIntensity',
	'EEPSetFogIntensity',
	'EEPSetHailIntensity',
	'EEPSetRainIntensity',
	'EEPSetSnowIntensity',
	'EEPSetWindIntensity',
	
	-- Lua standard variables
	'_G',
	'_VERSION',
	'bit32',
	'coroutine',
	'debug',
	'io',
	'math',
	'os',
	'package',
	'string',
	'table',
	'utf8',
	-- Lua standard functions
	'assert',
	'collectgarbage',
	'dofile',
	'error',
	'getmetatable',
	'ipairs',
	'load',
	'loadfile',
	'next',
	'pairs',
	'pcall',
	'print',
	'rawequal',
	'rawget',
	'rawlen',
	'rawset',
	'require',
	'select',
	'setmetatable',
	'tonumber',
	'tostring',
	'type',
	'xpcall',
}
 
-- Tabelle (mit impliziten numerischen Schlüssel) in Tabelle mit explizites Schlüsseln übertragen
local NamesSet = {}
for key, name in pairs(NamesTable) do 
	NamesSet[name] = true
end

print("")
print("Global Variables:")
print("")

-- Show EEP global variables
for key, value in pairs(_G) do 
	if all == true or not NamesSet[key] then
	if  string.sub(key, 1, 3) == "EEP" then
	if type(value) == "string" or type(value) == "number" then 
		print(key, " [", type(value), "] = ", value) 
	elseif type(value) == "table" then
		local size = 0
		for k,v in pairs(value) do size = size + 1 end
		print(key, " [", type(value), "] ", size, " entries") 
	end
	end
	end
end

print("")

-- Show other global variables
for key, value in pairs(_G) do 
	if all == true or not NamesSet[key] then
	if  string.sub(key, 1, 3) ~= "EEP" then
	if type(value) == "string" or type(value) == "number" then 
		print(key, " [", type(value), "] = ", value) 
	elseif type(value) == "table" then
		local size = 0
		for k,v in pairs(value) do size = size + 1 end
		print(key, " [", type(value), "] ", size, " entries") 
	end
	end
	end
end

print("")
print("Functions:")
print("")

-- Show EEP functions
for key, value in pairs(_G) do 
	if all == true or not NamesSet[key] then
	if type(value) == "function" and string.sub(key, 1, 3) == "EEP" then 
		print(key) 
	end
	end
end

print("")

-- Show other functions
for key, value in pairs(_G) do 
	if all == true or not NamesSet[key] then
	if type(value) == "function" and string.sub(key, 1, 3) ~= "EEP" then 
		print(key) 
	end
	end
end

end -- function ShowGlobalVariables

return ShowGlobalVariables
