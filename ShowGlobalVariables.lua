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

local _VERSION = 'v2022-12-01'

-- bekannte Namen, die nicht gezeigt werden sollen
local NamesTable = {
	-- EEP variables

	'EEPTime',                            -- EEP 10.2 plug-in 2
	'EEPTimeH',                           -- EEP 10.2 plug-in 2
	'EEPTimeM',                           -- EEP 10.2 plug-in 2
	'EEPTimeS',                           -- EEP 10.2 plug-in 2
	'EEPVer',                             -- EEP 10.2 plug-in 2
	'EEPLng',						                  -- EEP 17 

  -- EEP 10.2 functions

	'clearlog',                           -- EEP 10.2 plug-in 2
	'EEPMain',                            -- EEP 10.2 plug-in 2
	'EEPGetSignal',                       -- EEP 10.2 plug-in 2
	'EEPGetSwitch',                       -- EEP 10.2 plug-in 2
	'EEPOnSignal_1',	                    -- EEP 10.2 plug-in 2
	'EEPOnSwitch_1',	                    -- EEP 10.2 plug-in 2
	'EEPRegisterSignal',                  -- EEP 10.2 plug-in 2
	'EEPRegisterSwitch',                  -- EEP 10.2 plug-in 2
	'EEPSetSignal',                       -- EEP 10.2 plug-in 2
	'EEPSetSwitch',                       -- EEP 10.2 plug-in 2

  -- EEP 11.0 functions

	'EEPGetTrainSpeed',                   -- EEP 11.0
	'EEPLoadData',                        -- EEP 11.0
	'EEPRollingstockGetAxis',             -- EEP 11.0
	'EEPRollingstockGetCouplingFront',    -- EEP 11.0
	'EEPRollingstockGetCouplingRear',     -- EEP 11.0
	'EEPRollingstockSetAxis',             -- EEP 11.0
	'EEPRollingstockSetCouplingFront',    -- EEP 11.0
	'EEPRollingstockSetCouplingRear',     -- EEP 11.0
	'EEPRollingstockSetSlot',             -- EEP 11.0
	'EEPSaveData',                        -- EEP 11.0
	'EEPSetTrainSpeed',                   -- EEP 11.0

  -- EEP 11.1 functions

	'EEPStructureAnimateAxis',            -- EEP 11.1 Plug-in 1
	'EEPStructureGetAxis',                -- EEP 11.1 Plug-in 1
	'EEPStructureGetFire',                -- EEP 11.1 Plug-in 1
	'EEPStructureGetLight',               -- EEP 11.1 Plug-in 1
	'EEPStructureGetRotation',            -- EEP 11.1 Plug-in 1
	'EEPStructureGetSmoke',               -- EEP 11.1 Plug-in 1
	'EEPStructureSetAxis',                -- EEP 11.1 Plug-in 1
	'EEPStructureSetFire',                -- EEP 11.1 Plug-in 1
	'EEPStructureSetLight',               -- EEP 11.1 Plug-in 1
	'EEPStructureSetPosition',            -- EEP 11.1 Plug-in 1
	'EEPStructureSetRotation',            -- EEP 11.1 Plug-in 1
	'EEPStructureSetSmoke',               -- EEP 11.1 Plug-in 1

  -- EEP 11.2 functions

	'EEPGetTrainRoute',                   -- EEP 11.2 Plug-in 2
	'EEPSetTrainAxis',                    -- EEP 11.2 Plug-in 2
	'EEPSetTrainCouplingFront',           -- EEP 11.2 Plug-in 2
	'EEPSetTrainCouplingRear',            -- EEP 11.2 Plug-in 2
	'EEPSetTrainHook',                    -- EEP 11.2 Plug-in 2
	'EEPSetTrainHorn',                    -- EEP 11.2 Plug-in 2
	'EEPSetTrainLight',                   -- EEP 11.2 Plug-in 2, EEP 14.2 Plug-In 2
	'EEPSetTrainRoute',                   -- EEP 11.2 Plug-in 2
	'EEPSetTrainSmoke',                   -- EEP 11.2 Plug-in 2
	'EEPTrainLooseCoupling',              -- EEP 11.2 Plug-in 2

  -- EEP 11.3 functions

	'EEPGetTrainFromTrainyard',           -- EEP 11.3 plug-in 2, EEP 14.2 plug-In 2
	'EEPIsAuxiliaryTrackReserved',        -- EEP 11.3 Plug-in 3
	'EEPIsControlTrackReserved',          -- EEP 11.3 Plug-in 3
	'EEPIsRailTrackReserved',             -- EEP 11.3 Plug-in 3
	'EEPIsRoadTrackReserved',             -- EEP 11.3 Plug-in 3
	'EEPIsTramTrackReserved',             -- EEP 11.3 Plug-in 3
	'EEPLoadProject',                     -- EEP 11.3 Plug-in 3
	'EEPRegisterAuxiliaryTrack',          -- EEP 11.3 Plug-in 3
	'EEPRegisterControlTrack',            -- EEP 11.3 Plug-in 3
	'EEPRegisterRailTrack',               -- EEP 11.3 Plug-in 3
	'EEPRegisterRoadTrack',               -- EEP 11.3 Plug-in 3
	'EEPRegisterTramTrack',               -- EEP 11.3 Plug-in 3  
	'EEPSetCamera',                       -- EEP 11.3 Plug-in 3
	'EEPSetPerspectiveCamera',            -- EEP 11.3 Plug-in 3, EEP 14.2 Plug-In 2
  
	-- EEP 13 functions
  
	'EEPChangeInfoSignal',                -- EEP 13
	'EEPChangeInfoStructure',             -- EEP 13
	'EEPChangeInfoSwitch',                -- EEP 13
	'EEPShowInfoSignal',                  -- EEP 13
	'EEPShowInfoStructure',               -- EEP 13
	'EEPShowInfoSwitch',                  -- EEP 13

	-- EEP 13.1 functions

	'EEPHideInfoTextBottom',              -- EEP 13 plug-In 1
	'EEPHideInfoTextTop',                 -- EEP 13 plug-In 1
	'EEPPlaySound',                       -- EEP 13 plug-In 1
	'EEPShowInfoTextBottom',              -- EEP 13 plug-In 1
	'EEPShowInfoTextTop',                 -- EEP 13 plug-In 1
	'EEPShowScrollInfoTextBottom',        -- EEP 13 plug-In 1
	'EEPShowScrollInfoTextTop',           -- EEP 13 plug-In 1
	'EEPStructurePlaySound',              -- EEP 13 plug-In 1

	-- EEP 13.2 functions

	'EEPGetRollingstockItemName',         -- EEP 13.2 plug-in 2
	'EEPGetRollingstockItemsCount',       -- EEP 13.2 plug-in 2
	'EEPGetSignalTrainName',              -- EEP 13.2 plug-in 2           
	'EEPGetSignalTrainsCount',            -- EEP 13.2 plug-in 2
	'EEPGetTrainyardItemName',            -- EEP 13.2 plug-in 2
	'EEPGetTrainyardItemStatus',          -- EEP 13.2 plug-in 2
	'EEPGetTrainyardItemsCount',          -- EEP 13.2 plug-in 2

	-- EEP 14.1 functions

	'EEPOnTrainCoupling',                 -- EEP 14 Plug-In 1
	'EEPOnTrainExitTrainyard',            -- EEP 14 Plug-In 1
	'EEPOnTrainLooseCoupling',            -- EEP 14 Plug-In 1
	'EEPPause',                           -- EEP 14 plug-in 1
	'EEPSetTrainName',                    -- EEP 14 Plug-In 1

	-- EEP 14.2 functions

	'EEPGoodsGetModelType',               -- EEP 14.2 Plug-In 2
	'EEPGoodsGetPosition',                -- EEP 14.2 Plug-In 2
	'EEPGoodsSetPosition',                -- EEP 14.2 Plug-In 2
	'EEPGoodsSetRotation',                -- EEP 14.2 Plug-In 2
	'EEPRollingstockGetLength',           -- EEP 14.2 Plug-In 2
	'EEPRollingstockGetModelType',        -- EEP 14.2 Plug-In 2
	'EEPRollingstockGetMotor',            -- EEP 14.2 Plug-In 2
	'EEPRollingstockGetTagText',          -- EEP 14.2 Plug-In 2
	'EEPRollingstockGetTrack',            -- EEP 14.2 Plug-In 2
	'EEPRollingstockGetTrainName',        -- EEP 14.2 Plug-In 2
	'EEPRollingstockSetTagText',          -- EEP 14.2 Plug-In 2
	'EEPSetTime',                         -- EEP 14.2 Plug-In 2
	'EEPSetTrainHookGlue',                -- EEP 14.2 Plug-In 2
	'EEPStructureGetModelType',           -- EEP 14.2 Plug-In 2
	'EEPStructureGetPosition',            -- EEP 14.2 Plug-In 2
	'EEPStructureGetTagText',             -- EEP 14.2 Plug-In 2
	'EEPStructureIsAxisAnimate',          -- EEP 14.2 Plug-In 2
	'EEPStructureSetTagText',             -- EEP 14.2 Plug-In 2

	-- EEP 15 functions

	'EEPAuxiliaryTrackSetTextureText',    -- EEP 15
	'EEPGoodsSetTextureText',             -- EEP 15
	'EEPRailTrackSetTextureText',         -- EEP 15
	'EEPRoadTrackSetTextureText',         -- EEP 15
	'EEPRollingstockSetTextureText',      -- EEP 15
	'EEPSignalSetTextureText',            -- EEP 15
	'EEPStructureSetTextureText',         -- EEP 15
	'EEPTramTrackSetTextureText',         -- EEP 15

	-- EEP 15.1 functions

	'EEPGetTrainActive',                  -- EEP 15.1 Plug-in 1
	'EEPGetTrainLength',                  -- EEP 15.1 Plug-in 1
	'EEPRollingstockGetActive',           -- EEP 15.1 Plug-in 1
	'EEPRollingstockGetOrientation',      -- EEP 15.1 Plug-in 1
	'EEPRollingstockSetActive',           -- EEP 15.1 Plug-in 1
	'EEPSetTrainActive',                  -- EEP 15.1 Plug-in 1

	-- EEP 16.1 functions

	'EEPActivateCtrlDesk',	              -- EEP 16.1 Plug-in 1
	'EEPGetCameraPosition',	              -- EEP 16.1 Plug-in 1
	'EEPGetCameraRotation',	              -- EEP 16.1 Plug-in 1
	'EEPGetCloudsIntensity',              -- EEP 16.1 Plug-in 1
	'EEPGetFogIntensity',                 -- EEP 16.1 Plug-in 1
	'EEPGetHailIntensity',                -- EEP 16.1 Plug-in 1
	'EEPGetRainIntensity',                -- EEP 16.1 Plug-in 1
	'EEPGetSnowIntensity',                -- EEP 16.1 Plug-in 1
	'EEPGetWindIntensity',                -- EEP 16.1 Plug-in 1
	'EEPGoodsGetRotation',	              -- EEP 16.1 Plug-in 1
	'EEPOnSaveAnl',	                      -- EEP 16.1 Plug-in 1
	'EEPRollingstockGetHook',	            -- EEP 16.1 Plug-in 1
	'EEPRollingstockGetHookGlue',		      -- EEP 16.1 Plug-in 1
	'EEPRollingstockGetMileage',		      -- EEP 16.1 Plug-in 1
	'EEPRollingstockGetPosition',	        -- EEP 16.1 Plug-in 1
	'EEPRollingstockGetSmoke',	          -- EEP 16.1 Plug-in 1
	'EEPRollingstockSetHook',	            -- EEP 16.1 Plug-in 1
	'EEPRollingstockSetHookGlue',	        -- EEP 16.1 Plug-in 1
	'EEPRollingstockSetHorn',		          -- EEP 16.1 Plug-in 1
	'EEPRollingstockSetSmoke',	          -- EEP 16.1 Plug-in 1
	'EEPRollingstockSetUserCamera',	      -- EEP 16.1 Plug-in 1
	'EEPSetCameraPosition',	              -- EEP 16.1 Plug-in 1
	'EEPSetCameraRotation',	              -- EEP 16.1 Plug-in 1
	'EEPSetCloudsIntensity',              -- EEP 16.1 Plug-in 1
	'EEPSetDarkCloudsIntensity',          -- EEP 16.1 Plug-in 1
	'EEPSetFogIntensity',                 -- EEP 16.1 Plug-in 1
	'EEPSetHailIntensity',                -- EEP 16.1 Plug-in 1
	'EEPSetRainIntensity',                -- EEP 16.1 Plug-in 1
	'EEPSetSnowIntensity',                -- EEP 16.1 Plug-in 1
	'EEPSetWindIntensity',                -- EEP 16.1 Plug-in 1
  

	-- EEP 16.2 functions

	-- EEP 16.3 functions
	'EEPRollingstockGetTextureText',	    -- EEP 16.3 Plug-in 3 

	-- EEP 16.4 functions

	-- EEP 17 variables and functions
	'EEPOnBeforeSaveAnl',					        -- EEP 17
	'EEPGetAnlVer',					              -- EEP 17 
	'EEPGetAnlLng',					              -- EEP 17 
	'EEPRollingstockGetUserCamera',	      -- EEP 17

	-- EEP 17 Plugin 1

	'EEPSetZoneWindIntensity',					  -- EEP 17 Plug-in 1
	'EEPSetZoneRainIntensity',					  -- EEP 17 Plug-in 1
	'EEPSetZoneSnowIntensity',					  -- EEP 17 Plug-in 1
	'EEPSetZoneHailIntensity',					  -- EEP 17 Plug-in 1
	'EEPSetZoneFogIntensity',					    -- EEP 17 Plug-in 1
	'EEPSetZoneClouds',					          -- EEP 17 Plug-in 1
	'EEPSetZonePos',					            -- EEP 17 Plug-in 1
	'EEPGetZoneWindIntensity',					  -- EEP 17 Plug-in 1
	'EEPGetZoneRainIntensity',					  -- EEP 17 Plug-in 1
	'EEPGetZoneSnowIntensity',					  -- EEP 17 Plug-in 1
	'EEPGetZoneHailIntensity',					  -- EEP 17 Plug-in 1
	'EEPGetZoneFogIntensity',					    -- EEP 17 Plug-in 1
	'EEPGetZoneClouds',					          -- EEP 17 Plug-in 1
	'EEPGetZonePos',					            -- EEP 17 Plug-in 1
	'EEPGetAnlName',					            -- EEP 17 Plug-in 1
	'EEPSignalSetTagText',					      -- EEP 17 Plug-in 1
	'EEPSignalGetTagText',					      -- EEP 17 Plug-in 1

	-- NICHT enthalten:
	-- EEPSetZoneDarkClouds
	-- EEPGetZoneDarkClouds
	
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
