--[[
Datei: EEP2Lua.lua

Das Modul EEP2Lua liest und konvertiert eine EEP-Anlage-Datei in Lua-Tabellen.

Achtung: Wenn man dieses Modul in EEP für die aktuellen Anlage nutzen will, z.B. weil man die Zugliste ermitteln will, dann muss man aufpassen: Es kann nicht der aktuelle Zustand der aktuellen EEP-Anlage gelesen werden sondern nur der zuletzt gespeicherte Zustand! 
Man muss also selber sicherstellen, dass die EEP-Anlage vor Aufruf dieses Moduls gespeichert wurde! 

Aufruf:
local Anlage 	= require("EEP2Lua")
local sutrackp 	= Anlage.loadFile(input_file)		

Der optionale Rückgabewert sutrackp enthält die Tabellenstruktur in der Form wie sie xml2lua liefert. 

Nach dem Aufruf von loadFile können aufbereitete Informationen zur EEP-Anlage abgefragt werden:
Anlage.Beschreibung
Anlage.GleissystemText
Anlage.Zugverbaende
Anlage.Rollmaterialien
usw.

Die Feldlisten werden entnimmt man am Besten den unten markierten Programmstellen oder dem Beispiel-Skript EEP_Inventar. (Die Feldlisten hier aufzuführen wäre mir bei Änderungen zu fehlerträchtig.)

Das Modul benötigt Teile des Paketes xml2lua
Quelle:
https://github.com/manoelcampos/xml2lua
Benötigte Dateien im LUA-Ordner:
xml2lua.lua
XmlParser.lua
xmlhandler/tree.lua

()

Eine EEP-Anlagedatei und die daraus abgeleitetet sutrackp-Tabellenstruktur hat folgenden Aufbau:

sutrackp
	Version
	Gleissystem (1..6)
		Dreibein
			Vektor ([1]=Pos=Position, [2]=Dir=Richtung, [3]=Nor=Normale, [4]=Bin=Binormale)
		Gleis (multiple)
			Dreibein
				Vektor ([1]=Pos=Position, [2]=Dir=Richtung, [3]=Nor=Normale, [4]=Bin=Binormale)
			Anfangsfuehrungsverdrehung
			Charakteristik
			Kontakt
	Kollektor
		Dreibein
			Vektor (s.o.)
		Gleis (mehrfach)
	Fuhrpark
		Zugverband (0..n)
			Gleisort
				Rollmaterial (0..n)
					Zugmaschine
						Motor
							Getriebe
					Modell
						Achse (mehrfach)
							Achse
	Gebaeudesammlung (1..6)
		Immobile
			BeweglichesTeil (mehrfach)
			Dreibein
				Vektor (s.o.)
			Modell
				Achse (mehrfach)
	Gleisbildstellpultsammlung
		...
	AnimRoll
	Goods
	CrowdSammlung
		...
	Kammerasammlung
		Kammera (mehrfach)
	Settings (enthält u.a. die Tastatur-Hotkeys)
	Options (enthält SoundItems und die Routenbezeichnungen)
	Weather
	TimeTable
	EEPLua (LUAS=Prüfsumme für Lua-Datei, LUAPath=Dateiname)
	Kamera3D
	Schandlaft
	Beschreibung

--]]

-- Lokale Daten und Funktionen ----------------------------------------

-- Ausführliche Protokollierung zur Fehleranalyse (true/false)
local log = false

-- Maximale Anzahl der gespeicherten Positionen von Dateien
local DateiMaxPositions = 10

-- Statische Texte
local GleissystemText = { 			-- GleissystemID
	[1] = 'Eisenbahn',
	[2] = 'Strassenbahn',
	[3] = 'Strasse',
	[4] = 'Wasserwege',
	[5] = 'Steuerstrecken',			-- nicht in EEP 9	
	[6] = 'GBS'						-- nicht in EEP 9
}

local Gleisart = { 					-- clsid
	['2E25C8E2-ADCD-469A-942E-7484556FF932'] = 'Normales Gleis',
	['C889EADB-63B5-44A2-AAB9-457424CFF15F'] = '2-Weg-Weiche',
	['B0818DD8-5DFD-409F-8022-993FD3C90759'] = '3-Weg-Weiche',
	['06D80C90-4E4B-469B-BFE0-509A573EBC99'] = 'Prellbock-Gleis'
}

local GebaeudesammlungText = { 		-- GebaudesammlungID
	[1] = 'Gleisobjekte-Gleise',	-- u.a. Weichen, Bahnhöfe, Brücken
	[2] = 'Gebaeudesammlung 2',
	[3] = 'Gleisobjekte-Strassen',
	[4] = 'Immobilien',				-- u.a. Gebäude, Mauern, Tunnel, stehende Fahrzeuge
	[5] = 'Landschaftselemente',	-- u.a. Personen, Flora, Terra
	[6] = 'Gebaeudesammlung 6'
}

local Statistics = { 
	-- Dateigroesse in Bytes
	FileSize = 0, 
	-- Laufzeit in Sekunden
	LoadFileTime = 0, ParserTime = 0, ProcessTime = 0, TotalTime = 0
}

-- Converted data
local sutrackp = nil

-- Position der Gleise:
-- Gleise[GleissystemID]{Anzahl, Laenge}
-- Gleise[GleissystemID][GleisID]{x,y,z}
local Gleise = {}

-- Übersicht zum Fuhrparks
-- Fuhrparks[FuhrparkID].Zugverbaende{Anzahl}
-- Fuhrparks[FuhrparkID].Rollmaterialien{Anzahl}
local Fuhrparks = {}

-- Zugverbände incl. Position und der enthaltenen Rollmaterialien
local Zugverbaende = {}

-- Rollmaterialien mit Verweis auf den zugehörigen Zugverband
local Rollmaterialien = {}

-- Immobilien incl. Statistik und Position
-- Immobilien[GebaeudesammlungID]{Anzahl}
-- Immobilien[GebaeudesammlungID][ImmoIdx]{x,y}
local Immobilien = {}

-- Übersicht der referenzierten Dateien:
-- Dateien[Typ][Datei]{Anzahl}
local Dateien = {}
Dateien['Gleissystem']  = {}
Dateien['Rollmaterial'] = {}
Dateien['Immobile']     = {}

-- Hilfsfunktion zur Prüfung ob eine Tabelle einen bestimmten Eintrag enthält
function tableHasKey(table,key)
    return table[key] ~= nil
end

-- Speichere Informationen zu Dateien
local function storeDatei(Gruppe, Dateiname, Position)
	if not Dateien[Gruppe][Dateiname] then
		Dateien[Gruppe][Dateiname] = { Anzahl = 1, Positionen = {} }
	else
		Dateien[Gruppe][Dateiname].Anzahl = Dateien[Gruppe][Dateiname].Anzahl + 1
	end
	
	-- Speichere bis zu DateiMaxPositions Positionen
	if #Dateien[Gruppe][Dateiname].Positionen < DateiMaxPositions then 
		table.insert(Dateien[Gruppe][Dateiname].Positionen, Position)
	end
end

-- Vorabdeklaration der Variablen der öffentlichen Schnittstelle
local EEP2Lua = {}

-- Laden und Verarbeiten der EEP-Anlagen-Datei
local function loadFile(input_file)
	local t0 = os.clock()
	
	local xml2lua = require("xml2lua")

-- The XML tree structure is mapped directly into a recursive
-- table structure with node names as keys and child elements
-- as either a table of values or directly as a string value
-- for text. Where there is only a single child element this
-- is inserted as a named key - if there are multiple
-- elements these are inserted as a vector (in some cases it
-- may be preferable to always insert elements as a vector
-- which can be specified on a per element basis in the
-- options). Attributes are inserted as a child element with
-- a key of '_attr'.
-- Kommentar: leider weiß ich noch nicht wie ich diese options für die Tags Rollmaterialien usw. setzen kann.
-- Daher bleibt es erst einmal so wie es ist.
	local handler = require("xmlhandler.tree")

	-- Load the XML file
	local xml = xml2lua.loadFile(input_file)
	
	Statistics.LoadFileTime = os.clock() - t0
	Statistics.FileSize = string.len(xml)
	t0 = os.clock()

	-- Instantiate the XML parser
	local parser = xml2lua.parser(handler)
	parser:parse(xml)
	
	Statistics.ParserTime = os.clock() - t0
	t0 = os.clock()

	-- xml-Tabelle speichern 
	sutrackp = handler.root.sutrackp

	-- xml-Tabelle verarbeiten
	processSutrackp(sutrackp) 
	
	Statistics.ProcessTime = os.clock() - t0
	Statistics.TotalTime   = Statistics.LoadFileTime + Statistics.ParserTime + Statistics.ProcessTime
	
	-- Informationen zur EEP-Anlage bereitstellen
	EEP2Lua.Datei 					= input_file
	EEP2Lua.Beschreibung			= sutrackp.Beschreibung
	EEP2Lua.EEP						= sutrackp.Version._attr.EEP
	EEP2Lua.No3DMs					= sutrackp.Version._attr.No3DMs
	
	EEP2Lua.Fuhrparks				= Fuhrparks
	EEP2Lua.Zugverbaende			= Zugverbaende
	EEP2Lua.Rollmaterialien			= Rollmaterialien	
	EEP2Lua.Gleise					= Gleise	
	EEP2Lua.Immobilien 				= Immobilien
	EEP2Lua.Dateien 				= Dateien
	
	return sutrackp
end

-- Stufenweise Analyse der xml-Tabelle
function processSutrackp(sutrackp)
	if log then print('processSutrackp') end

	for key, value in pairs(sutrackp) do

		if     	key == 'Gleissystem' then
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
end

function processGleissystem(Gleissystem)
	if not type(Gleissystem) == 'table' then
		print('GSv ', Gleissystem)

	elseif tableHasKey(Gleissystem, '_attr') then 		-- Single entry
		if log then print('GSa ', type(Gleissystem)) end

		local GleissystemID = tonumber(Gleissystem._attr.GleissystemID)

		-- Feldliste: Gleissystem
		Gleise[GleissystemID] = {
			Anzahl = 0,
			Laenge = 0
		}

		for key, value in pairs(Gleissystem) do
			if key == 'Gleis' then
				processGleis(GleissystemID, value)
			end
		end

	else											--	Multiple entries
		if log then print('G* ', type(Gleissystem)) end
		
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
		local Laenge  = math.floor(tonumber(Gleis.Charakteristik._attr.Laenge) / 100 + 0.5)

		-- Felder von Gleissystem aktualisieren
		Gleise[GleissystemID].Anzahl = Gleise[GleissystemID].Anzahl + 1
		Gleise[GleissystemID].Laenge = Gleise[GleissystemID].Laenge + Laenge

		-- Feldliste: Gleis
		Gleise[GleissystemID][GleisID] = {
			Gleisart = Gleis._attr.clsid,
			Position = {
				x = math.floor(tonumber(Gleis.Dreibein.Vektor[1]._attr.x) / 100 + 0.5), 
				y = math.floor(tonumber(Gleis.Dreibein.Vektor[1]._attr.y) / 100 + 0.5),
				z = math.floor(tonumber(Gleis.Dreibein.Vektor[1]._attr.z) / 100 + 0.5)
			},
			Laenge = Laenge
		}

		-- Speichere Datei
		storeDatei('Gleissystem', 
			Gleis._attr.gsbname,
			Gleise[GleissystemID][GleisID].Position
		)

	else											--	Multiple entries
		if log then print('G* ', type(Gleis)) end
		
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

		local FuhrparkID = tonumber(Fuhrpark._attr.FuhrparkID)

		-- Feldliste: Fuhrparks
		Fuhrparks[FuhrparkID] = {
			Zugverbaende 	= { Anzahl = 0 },
			Rollmaterialien	= { Anzahl = 0 }
		}

		for key, value in pairs(Fuhrpark) do
			if key == 'Zugverband' then
				processZugverband(value, FuhrparkID)
			end
		end

	else											--	Multiple entries
		if log then print('F* ', type(Fuhrpark)) end
		
		for key, value in pairs(Fuhrpark) do
			print('F ', key, ' ', type(value))
			
			processFuhrpark(value)
		end
	end
end

function processZugverband(Zugverband, FuhrparkID)
	if not type(Zugverband) == 'table' then
		print('Zv ', Zugverband)

	elseif tableHasKey(Zugverband, '_attr') then 	-- Single entry
		if log then print('Za ', type(Zugverband)) end

		local ZugID 		= tonumber(Zugverband._attr.ZugID)
		local GleissystemID = tonumber(Zugverband.Gleisort._attr.gleissystemID)
		local GleisID       = tonumber(Zugverband.Gleisort._attr.gleisID)

		-- Felder von Fuhrparks aktualisieren
		Fuhrparks[FuhrparkID].Zugverbaende.Anzahl = Fuhrparks[FuhrparkID].Zugverbaende.Anzahl + 1

		-- Feldliste: Zugverband
		Zugverbaende[ZugID] = {
			name 			= Zugverband._attr.name, 
			FuhrparkID      = FuhrparkID,
			GleissystemID 	= GleissystemID,
			GleisID 		= GleisID,
			Position 		= Gleise[GleissystemID][GleisID].Position,
			Geschwindigkeit = math.floor(tonumber(Zugverband._attr.Geschwindigkeit) * 36 ) / 10, -- Umgerechnet und gerundet in km/h
			Rollmaterialien = {}		-- Querverweise werden später eingetragen
		}	

		for key, value in pairs(Zugverband) do
			if key == 'Rollmaterial' then
				processRollmaterial(value, FuhrparkID, ZugID)
			end
		end

	else											--	Multiple entries
		if log then print('Z* ', type(Zugverband)) end
		
		for key, value in pairs(Zugverband) do
			if log then print('Z ', key, ' ', type(value)) end
			
			processZugverband(value, FuhrparkID)
		end
	end
end

function processRollmaterial(Rollmaterial, FuhrparkID, ZugID)
	if not type(Rollmaterial) == 'table' then
		print('Rv ', Rollmaterial)

	elseif tableHasKey(Rollmaterial, '_attr') then 	-- Single entry
		if log then print('Ra ', type(Rollmaterial)) end

		local name = Rollmaterial._attr.name

		-- Felder von Fuhrparks aktualisieren
		Fuhrparks[FuhrparkID].Rollmaterialien.Anzahl = Fuhrparks[FuhrparkID].Rollmaterialien.Anzahl + 1
		
		-- Feldliste: Rollmaterial
		Rollmaterialien[name] = {
			name			= name,
			typ 			= Rollmaterial._attr.typ,
			Zugmaschine 	= tableHasKey(Rollmaterial, 'Zugmaschine'),
			ZugID           = ZugID,
			Zugverband		= Zugverbaende[ZugID]
		}
		
		-- Querverweis eintragen
		table.insert( Zugverbaende[ZugID].Rollmaterialien, Rollmaterialien[name] )  
		
		-- Speichere Datei
		storeDatei('Rollmaterial', 
			Rollmaterial._attr.typ,
			Rollmaterialien[name].Zugverband.Position
		)

	else											--	Multiple entries
		if log then print('R* ', type(Rollmaterial)) end

		for key, value in pairs(Rollmaterial) do
			if log then print('R ', key, ' ', type(value)) end
			
			processRollmaterial(value, FuhrparkID, ZugID)
		end
	end
end

function processGebaeudesammlung(Gebaeudesammlung)
	if not type(Gebaeudesammlung) == 'table' then
		print('ISv ', Gebaeudesammlung)

	elseif tableHasKey(Gebaeudesammlung, '_attr') then 		-- Single entry
		if log then print('ISa ', type(Gebaeudesammlung)) end

		local GebaeudesammlungID = tonumber(Gebaeudesammlung._attr.GebaudesammlungID)

		-- Feldliste: Immobilien
		Immobilien[GebaeudesammlungID] = {
			Anzahl = 0
		}

		for key, value in pairs(Gebaeudesammlung) do
			if key == 'Immobile' then
				processImmobile(GebaeudesammlungID, value)
			end
		end

	else											--	Multiple entries
		if log then print('G* ', type(Gebaeudesammlung)) end
		
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

		-- Felder von Immobilien aktualisieren
		Immobilien[GebaeudesammlungID].Anzahl = Immobilien[GebaeudesammlungID].Anzahl + 1

		-- Feldliste: Immobilie
		Immobilien[GebaeudesammlungID][ImmoIdx] = { 
			Position = {
				x = math.floor(tonumber(Immobile.Dreibein.Vektor[1]._attr.x) / 100 + 0.5), 
				y = math.floor(tonumber(Immobile.Dreibein.Vektor[1]._attr.y) / 100 + 0.5), 
				z = math.floor(tonumber(Immobile.Dreibein.Vektor[1]._attr.z) / 100 + 0.5)
			}
		}

		-- Speichere Datei
		storeDatei('Immobile', 
			Immobile._attr.gsbname, 
			Immobilien[GebaeudesammlungID][ImmoIdx].Position
		)

	else											--	Multiple entries
		if log then print('I* ', type(Immobile)) end
		
		for key, value in pairs(Immobile) do
			if log then print('I ', key, ' ', type(value)) end
			
			processImmobile(GebaeudesammlungID, value)
		end
	end
end

-- Öffentliche Schnittstelle des Moduls -------------------------------

EEP2Lua._VERSION 				= "2019-01-18"

-- Laufzeit in Sekunden für { LoadFile, Parser, Process, Total }
EEP2Lua.Statistics				= Statistics
	
-- Hauptfunktion
EEP2Lua.loadFile				= loadFile

-- Informationen zur EEP-Anlage werden von loadFile gesetzt
EEP2Lua.Datei 					= nil 
EEP2Lua.Beschreibung			= nil 
EEP2Lua.EEP						= nil 
EEP2Lua.No3DMs					= nil 
	
EEP2Lua.Fuhrparks				= nil 
EEP2Lua.Zugverbaende			= nil 
EEP2Lua.Rollmaterialien			= nil
EEP2Lua.Gleise					= nil
EEP2Lua.Immobilien				= nil
EEP2Lua.Dateien					= nil

-- statische Texten und Definitionen
EEP2Lua.GleissystemText 		= GleissystemText
EEP2Lua.GebaeudesammlungText 	= GebaeudesammlungText
EEP2Lua.Gleisart				= Gleisart


return EEP2Lua
