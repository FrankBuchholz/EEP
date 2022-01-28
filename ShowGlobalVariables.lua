-- Module 
--[[
Module ShowGlobalVariables.lua

Bei der Entwicklung von Modulen passiert es leicht, dass Variablen oder Funktionen global definiert werden obwohl sie lokal sein sollten.
Zumeist funktioniert das Skript dann trotzdem wie erwartet, so dass dieser Fehler nur schlecht auffällt.

Das Modul ShowGlobalVariables zeigt globale Variablen und globale Funktionen.
Die bekannten Namen aus EEP bzw. von Lua können unterdrückt werden, so dass man nur die selbst definierten Namen erhält.

Verwendung (auch mehrfach):
require('ShowGlobalVariables')()		-- nur eigene Variablen und Funktionen
require('ShowGlobalVariables')(true) 	-- auch Variablen und Funktionen von EEP

Frank Buchholz, 2019-2022
]]

local _VERSION = 'v2022-01-28'

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
	
	'EEPGetCloudsIntensity',
	'EEPGetFogIntensity',
	'EEPGetHailIntensity',
	'EEPGetRainIntensity',
	'EEPGetSnowIntensity',
	'EEPGetWindIntensity',

	'EEPSetCloudsIntensity',
	'EEPSetDarkCloudsIntensity',
	'EEPSetFogIntensity',
	'EEPSetHailIntensity',
	'EEPSetRainIntensity',
	'EEPSetSnowIntensity',
	'EEPSetWindIntensity',

	-- EEP 16.2 functions

	-- EEP 16.3 functions
	'EEPRollingstockGetTextureText',	-- Liest den Text einer beschreibbaren Fläche eines Rollmaterials aus

	-- EEP 16.4 functions

	-- EEP 17 variables and functions
	'EEPLng',						-- Zeige Sprache GER, ENG, FRA der installierten EEP-Version
	'EEPOnBeforeSaveAnl',
	'EEPGetAnlVer',					-- EEP-Versionsnummer, mit der die Anlage vor dem Öffnen zuletzt gespeichert wurde
	'EEPGetAnlLng',					-- liefert die auf Achsnamen bezogene "Anlagensprache" (als GER, ENG oder FRA)
	'EEPRollingstockGetUserCamera',	-- related to EEPRollingstockSetUserCamera
	
	
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

-- Utility functions to access a table in sorted order
local sort = function (a, b)
	if type(a) == "number" and type(b) == "number" then
		-- sort numbers
		return a < b
	else
		-- sort anything else
		return string.lower(tostring(a)) < string.lower(tostring(b))
	end	
end
local function pairsByKeys (t, f)
	local f = f or sort
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
	end
	return iter
end

local function showVariable(key, value)
	if type(value) == "table" then
		local size = 0
		for k,v in pairs(value) do size = size + 1 end
		print(key, " [", type(value), "] ", size, " entries") 
	else -- if type(value) == "string" or type(value) == "number" then 
		print(key, " [", type(value), "] = ", value) 
	end
end

local function ShowGlobalVariables(all)

	print("\nGlobal Variables:")

	-- Show EEP global variables
	for key, value in pairsByKeys(_G) do 
		if all == true or not NamesSet[key] then
			if type(value) ~= "function" and string.sub(key, 1, 3) == "EEP" then
				showVariable(key, value)
			end
		end
	end

	print("")

	-- Show other global variables
	for key, value in pairsByKeys(_G) do 
		if all == true or not NamesSet[key] then
			if type(value) ~= "function" and string.sub(key, 1, 3) ~= "EEP" then
				showVariable(key, value)
			end
		end
	end

	print("\nGlobal Functions:")

	-- Show EEP functions
	for key, value in pairsByKeys(_G) do 
		if all == true or not NamesSet[key] then
			if type(value) == "function" and string.sub(key, 1, 3) == "EEP" then 
				print(key) 
			end
		end
	end

	print("")

	-- Show other functions
	for key, value in pairsByKeys(_G) do 
		if all == true or not NamesSet[key] then
			if type(value) == "function" and string.sub(key, 1, 3) ~= "EEP" then 
				print(key) 
			end
		end
	end

	print("")

	-- Return self to allow a construction like this:
	--[[
	ShowGlobalVariables = require("ShowGlobalVariables")() -- show it during initialization

	function EEPMain()
		ShowGlobalVariables() -- show it regularly
	end
	--]]
	
	return ShowGlobalVariables -- 
end

return ShowGlobalVariables
