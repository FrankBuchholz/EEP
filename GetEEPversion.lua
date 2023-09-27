--[[
Module GetEEPversion.lua
Bestimmt die Version von EEP incl. des installierten Plugins

Verwendung:

print("EEP Version: ", require("GetEEPversion") )
function EEPMain()
    return 1
end

oder:

local EEPversion = require("GetEEPversion")
print("EEP Version: ", EEPversion )
function EEPMain()
    return 1
end

]]

local _VERSION = 'v2023-09-27'

local function EEPversion()
  -- Ein bestimmtes Plugin ist genau dann in einer Version installiert 
  -- wenn eine darin enthaltene Funktion existiert
  local p = ""
  local v = math.floor(EEPVer)
  if v == 13 and EEPGetRollingstockItemsCount  then p = p + " plugin 2" end
  if v == 14 and EEPOnTrainCoupling            then p = p + " plugin 1" end
  if v == 14 and EEPRollingstockGetLength      then p = p + " plugin 2" end
  if v == 15 and EEPGetTrainLength             then p = p + " plugin 1" end
  if v == 16 and EEPActivateCtrlDesk           then p = p + " plugin 1" end
  if v == 16 and EEPRollingstockGetTextureText then p = p + " plugin 3" end
  if v == 17 and EEPGetAnlName                 then p = p + " plugin 1" end
  if v == 17 and EEPStructureGetTextureText    then p = p + " plugin 2" end
  -- Zeige die Version mit genau 1 Nachkommastelle gefolgt vom Plugin an
  return string.format("%.1f", EEPVer)..p 
end

return EEPversion()
