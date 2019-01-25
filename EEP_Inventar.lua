--[[
Analyse einer EEP-Anlage-Datei

Frank Buchholz, 2019
]]

local _VERSION = 'v2019-01-14'

-- In Variable input_file wird der Pfad zur Anlagen-Datei eingetragen
-- Hier einige Varianten unter der Annahme, dass dieses Script im LUA-Ordner der EEP-Installation liegt:
local input_files = {
	[1] = "./Anlagen/Tutorials/Tutorial_57_sanftes_Ankuppeln.anl3", 				-- relativer Pfad beim Start aus EEP heraus
	[2] = "../Resourcen/Anlagen/Tutorials/Tutorial_57_sanftes_Ankuppeln.anl3", 		-- relativer Pfad bei standalone-Ausführung im Editor SciTE
	[3] = "./Anlagen/Demo.anl3",													-- relativer Pfad beim Start aus EEP heraus
	[4] = "../Resourcen/Anlagen/Demo.anl3"											-- relativer Pfad bei standalone-Ausführung im Editor SciTE

}
-- Welche Datei soll es sein?
input_file = input_files[4]

-- Hier den Pfad zur zusätzlichen Ausgabe-Datei angeben (siehe printtofile)
local output_file = "C:/temp/output.txt"

-- Ausführliche Protokollierung zur Fehleranalyse (true/false)
local log = false




-- printtofile (optional)-----------------------------------------------------
--[[
Quelle:
https://emaps-eep.de/lua/printtofile

Benötigte Dateien im LUA-Ordner:
PrintToFile_BH2.lua

output:
0: keine Ausgabe (kann Sinn machen, wenn direkt die Ausgabedatei überwacht wird)
1: normale Ausgabe (Standardwert)
2: Ausgabe wie in Datei (diese kann sich von der normalen Ausgabe leicht unterscheiden)
--]]
if EEPVer then -- Nur notwendig wenn das Skript aus EEP heraus gestartet wird
	require("PrintToFile_BH2"){file = output_file, output = 1}
end

if EEPVer then -- Nur möglich wenn das Skript aus EEP heraus gestartet wird
	clearlog()
	print("EEP Version", " ", EEPVer, " ", "Lua Version", " ", _G._VERSION)
else
	print("Lua Version", " ", _G._VERSION)
end



-- xml2lua --------------------------------------------------------------
--[[
Quelle:
https://github.com/manoelcampos/xml2lua

Benötigte Dateien im LUA-Ordner:
xml2lua.lua
XmlParser.lua
xmlhandler/tree.lua
--]]

local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")

--Load the XML file
local xml = xml2lua.loadFile(input_file)

--Instantiates the XML parser
local parser = xml2lua.parser(handler)
parser:parse(xml)




-- process --------------------------------------------------------------

--[[
Eine EEP-Anlagedatei hat folgenden Aufbau:

sutrackp
	Version
	Gleissystem (multiple: 1=Eisenbahn, 2=Straßenbahn, 3=Straße, 4=Wasserwege, 5=Steuerstrecken, 6=GBS)
		Dreibein
			Vektor (multiple: Pos=Position, Dir=Richtung, Nor=Normale, Bin=Binormale)
		Gleis (multiple)
			Dreibein
				Vektor (multiple: Pos=Position, Dir=Richtung, Nor=Normale, Bin=Binormale)
			Anfangsfuehrungsverdrehung
			Charakteristik
			Kontakt
	Kollektor
		Dreibein
			Vektor (multiple)
		Gleis (multiple)
	Fuhrpark
		Zugverband (multiple)
			Gleisort
				Rollmaterial (multiple)
					Zugmaschine
						Motor
							Getriebe
					Modell
						Achse
							Achse
	Gebaeudesammlung (multiple)
		Immobile
			...
	Gleisbildstellpultsammlung
		...
	AnimRoll
	Goods
	CrowdSammlung
		...
	Kammerasammlung
		Kammera (multiple)
	Settings
	Options
	Weather
	TimeTable
	EEPLua (LUAS=Prüfsumme für Lua-Datei, LUAPath=Dateiname)
	Kamera3D
	Schandlaft
	Beschreibung

--]]

local Anlage = handler.root.sutrackp

local GleissystemText = { -- GleissystemID
	[1] = 'Eisenbahn',
	[2] = 'Straßenbahn',
	[3] = 'Straße',
	[4] = 'Wasserwege',
	[5] = 'Steuerstrecken',
	[6] = 'GBS'
}

local Gleisart = { -- clsid
	['2E25C8E2-ADCD-469A-942E-7484556FF932'] = 'Normales Gleis',
	['C889EADB-63B5-44A2-AAB9-457424CFF15F'] = '2-Weg-Weiche',
	['B0818DD8-5DFD-409F-8022-993FD3C90759'] = '3-Weg-Weiche',
	['06D80C90-4E4B-469B-BFE0-509A573EBC99'] = 'Prellbock-Gleis'
}

local GebaeudesammlungText = { -- GebaudesammlungID
	[1] = 'Gleisobjekte-Gleise',
	[2] = 'Gebaeudesammlung 2',
	[3] = 'Gleisobjekte-Strassen',
	[4] = 'Immobilien',
	[5] = 'Landschaftselemente',
	[6] = 'Gebaeudesammlung 6'
}

-- Position der Gleise:
-- Gleise[GleissystemID]{Anzahl, Laenge}
-- Gleise[GleissystemID][GleisID]{x,y}
local Gleise = {}

-- Position der Immobilen:
-- Immobilen[GebaeudesammlungID]{Anzahl}
-- Immobilen[GebaeudesammlungID][ImmoIdx]{x,y}
local Immobilen = {}


-- Übersicht zu referenzierten Dateien:
-- Dateien[Typ][Datei]{Anzahl}
local Dateien = {}
Dateien['Gleissystem']  = {}
Dateien['Rollmaterial'] = {}
Dateien['Immobile']     = {}

-- Hilfsfunktion zur Prüfung ob eine Tabelle einen bestimmten Eintrag enthält
function tableHasKey(table,key)
    return table[key] ~= nil
end

-- Hilfsfunktion zur sortierung einer Tabelle
-- siehe https://www.lua.org/pil/19.3.html
function sortedTable(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0					-- iterator variable
	local iter = function ()	-- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

function processAnlage(Anlage)
	for key, value in pairs(Anlage) do

		if     key == 'Beschreibung' then
			--print("Anlage Beschreibung: ", value)

		elseif  key == 'Gleissystem' then
			--print('Ag ', key, ' ', type(value))
			processGleissystem(value)

		elseif  key == 'Fuhrpark' then
			--print('Af ', key, ' ', type(value))
			processFuhrpark(value)

		elseif  key == 'Gebaeudesammlung' then
			--print('Af ', key, ' ', type(value))
			processGebaeudesammlung(value)

		else
			--print('Ax ', key, ' ', type(value))

		end
	end

	print("")
	print("Gleissysteme:")
	for key, value in pairs(Gleise) do
		print(GleissystemText[tonumber(key)], ' Anzahl=', value.Anzahl, ' Länge=', value.Laenge/100, 'm')
	end

	print("")
	print("Gebaeudesammlung:")
	for key, value in pairs(Immobilen) do
		print(GebaeudesammlungText[tonumber(key)], ' Anzahl=', value.Anzahl)
	end

	for key, value in pairs(Dateien) do
		print("")
		print("Dateien ", key, ':')
		for key, value in sortedTable(value) do
			print(key, ' Anzahl=', value)
		end
	end

end


function processGleissystem(Gleissystem)
	if not type(Gleissystem) == 'table' then
		print('GSv ', Gleissystem)

	elseif tableHasKey(Gleissystem, '_attr') then 		-- Single entry
		if log then print('GSa ', type(Gleissystem)) end

		local GleissystemID = tonumber(Gleissystem._attr.GleissystemID)

		Gleise[GleissystemID] = {}
		Gleise[GleissystemID].Anzahl = 0
		Gleise[GleissystemID].Laenge = 0

		if log then
			print("")
			print('Gleissystem ', GleissystemID, ': ', GleissystemText[GleissystemID])
		end

		for key, value in pairs(Gleissystem) do
			if key == 'Gleis' then
				processGleis(GleissystemID, value)
			end
		end

	else											--	Multiple entries
		if log then print('G- ', type(Gleissystem)) end
		for key, value in pairs(Gleissystem) do
			if log then print('GS ', key, ' ', type(value)) end
			processGleissystem(value)
		end
	end
end


function processGleis(GleissystemID, Gleis)
	if not type(Gleis) == 'table' then
		print('Gv ', Gleis)

	elseif tableHasKey(Gleis, '_attr') then 		-- Single entry
		if log then print('Ga ', type(Gleis)) end

		local GleisID = tonumber(Gleis._attr.GleisID)

		-- Speichere Position des Gleises
		Gleise[GleissystemID][GleisID] = { ['x'] = Gleis.Dreibein.Vektor[1]._attr.x, ['y'] = Gleis.Dreibein.Vektor[1]._attr.y }
		Gleise[GleissystemID].Anzahl = Gleise[GleissystemID].Anzahl + 1
		Gleise[GleissystemID].Laenge = Gleise[GleissystemID].Laenge + tonumber(Gleis.Charakteristik._attr.Laenge)

		-- Speichere Datei zum Gleis
		if Dateien['Gleissystem'][Gleis._attr.gsbname] then
			Dateien['Gleissystem'][Gleis._attr.gsbname] = Dateien['Gleissystem'][Gleis._attr.gsbname] + 1
		else
			Dateien['Gleissystem'][Gleis._attr.gsbname] = 1
		end

		if log then
			print(
				'Gleis ', GleisID, ': ',
				'x=', Gleis.Dreibein.Vektor[1]._attr.x, ' y=', Gleis.Dreibein.Vektor[1]._attr.y, ' ',
				'l=', Gleis.Charakteristik._attr.Laenge
			)
		end

	else											--	Multiple entries
		if log then print('G- ', type(Gleis)) end
		for key, value in pairs(Gleis) do
			if log then print('G ', key, ' ', type(value)) end
			processGleis(GleissystemID, value)
		end
	end
end


function processFuhrpark(Fuhrpark)
	if not type(Fuhrpark) == 'table' then
		print('Fv ', Fuhrpark)

	elseif tableHasKey(Fuhrpark, '_attr') then 		-- Single entry
		if log then print('Fa ', type(Fuhrpark)) end

		print('Fuhrpark ', Fuhrpark._attr.FuhrparkID, ': ')

		for key, value in pairs(Fuhrpark) do
			if key == 'Zugverband' then
				processZugverband(value)
			end
		end

	else											--	Multiple entries
		if log then print('F- ', type(Fuhrpark)) end
		for key, value in pairs(Fuhrpark) do
			print('F ', key, ' ', type(value))
			processFuhrpark(value)
		end
	end
end

function processZugverband(Zugverband)
	if not type(Zugverband) == 'table' then
		print('Zv ', Zugverband)

	elseif tableHasKey(Zugverband, '_attr') then 	-- Single entry
		if log then print('Za ', type(Zugverband)) end

		local GleissystemID = tonumber(Zugverband.Gleisort._attr.gleissystemID)
		local GleisID       = tonumber(Zugverband.Gleisort._attr.gleisID)

		print("")
		print(
			'Zugverband ', 	Zugverband._attr.ZugID, ': ', Zugverband._attr.name, ' ',
			'Gleisort: ',   GleissystemText[GleissystemID], ' ', GleisID, ' ',
			'x=', tonumber(Gleise[GleissystemID][GleisID].x)/100, 'm ',
			'y=', tonumber(Gleise[GleissystemID][GleisID].y)/100, "m"
		)

		for key, value in pairs(Zugverband) do
			if key == 'Rollmaterial' then
				processRollmaterial(value)
			end
		end

	else											--	Multiple entries
		if log then print('Z- ', type(Zugverband)) end
		for key, value in pairs(Zugverband) do
			if log then print('Z ', key, ' ', type(value)) end
			processZugverband(value)
		end
	end
end

function processRollmaterial(Rollmaterial)
	if not type(Rollmaterial) == 'table' then
		print('Rv ', Rollmaterial)

	elseif tableHasKey(Rollmaterial, '_attr') then 	-- Single entry
		if log then print('Ra ', type(Rollmaterial)) end

		local Zugmaschine = tableHasKey(Rollmaterial, 'Zugmaschine')

		if Zugmaschine then
			print('Zugmaschine: ', " ",  Rollmaterial._attr.name, "        \t", Rollmaterial._attr.typ)
		else
			print('Rollmaterial: ', " ", Rollmaterial._attr.name, "        \t", Rollmaterial._attr.typ)
		end

		-- Speichere Datei zum Rollmaterial
		if Dateien['Rollmaterial'][Rollmaterial._attr.typ] then
			Dateien['Rollmaterial'][Rollmaterial._attr.typ] = Dateien['Rollmaterial'][Rollmaterial._attr.typ] + 1
		else
			Dateien['Rollmaterial'][Rollmaterial._attr.typ] = 1
		end

	else											--	Multiple entries
		if log then print('R- ', type(Rollmaterial)) end
		for key, value in pairs(Rollmaterial) do
			if log then print('R ', key, ' ', type(value)) end
			processRollmaterial(value)
		end
	end
end

function processGebaeudesammlung(Gebaeudesammlung)
	if not type(Gebaeudesammlung) == 'table' then
		print('ISv ', Gebaeudesammlung)

	elseif tableHasKey(Gebaeudesammlung, '_attr') then 		-- Single entry
		if log then print('ISa ', type(Gebaeudesammlung)) end

		local GebaeudesammlungID = Gebaeudesammlung._attr.GebaudesammlungID

		Immobilen[GebaeudesammlungID] = {}
		Immobilen[GebaeudesammlungID].Anzahl = 0

		if log then
			print("")
			print('Gebaeudesammlung ', GebaeudesammlungID, ':')
		end

		for key, value in pairs(Gebaeudesammlung) do
			if key == 'Immobile' then
				processImmobile(GebaeudesammlungID, value)
			end
		end

	else											--	Multiple entries
		if log then print('G- ', type(Gebaeudesammlung)) end
		for key, value in pairs(Gebaeudesammlung) do
			if log then print('GS ', key, ' ', type(value)) end
			processGebaeudesammlung(value)
		end
	end
end


function processImmobile(GebaeudesammlungID, Immobile)
	if not type(Immobile) == 'table' then
		print('Iv ', Immobile)

	elseif tableHasKey(Immobile, '_attr') then 		-- Single entry
		if log then print('Ga ', type(Immobile)) end

		local ImmoIdx = Immobile._attr.ImmoIdx

		-- Speichere Position der Immobile
		Immobilen[GebaeudesammlungID][ImmoIdx] = { ['x'] = Immobile.Dreibein.Vektor[1]._attr.x, ['y'] = Immobile.Dreibein.Vektor[1]._attr.y }
		Immobilen[GebaeudesammlungID].Anzahl = Immobilen[GebaeudesammlungID].Anzahl + 1

		-- Speichere Datei zum Immobile
		if Dateien['Immobile'][Immobile._attr.gsbname] then
			Dateien['Immobile'][Immobile._attr.gsbname] = Dateien['Immobile'][Immobile._attr.gsbname] + 1
		else
			Dateien['Immobile'][Immobile._attr.gsbname] = 1
		end

		if log then
			print(
				'Immobile ', ImmoIdx, ': ',
				'x=', Immobile.Dreibein.Vektor[1]._attr.x, ' y=', Immobile.Dreibein.Vektor[1]._attr.y, ' '
			)
		end

	else											--	Multiple entries
		if log then print('I- ', type(Immobile)) end
		for key, value in pairs(Immobile) do
			if log then print('I ', key, ' ', type(value)) end
			processImmobile(GebaeudesammlungID, value)
		end
	end
end


-- Start ----------------------------------------------------------------

print("Auswertung der Anlage", " ", input_file)
--print(Anlage.Beschreibung)
print("")

print("EEP Version der Anlage", ": ", Anlage.Version._attr.EEP)
if Anlage.Version._attr.No3DMs then 		-- Das Attribut gibt es in alten EEP-Versionen noch nicht 
	print("Anzahl der Resourcen",   ": ", Anlage.Version._attr.No3DMs)
end
print("")

-- Los geht's
processAnlage(Anlage)


-- EEPMain --------------------------------------------------------------
function EEPMain()
	return 0
end
