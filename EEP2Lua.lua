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

--

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

Die Mitte der Anlage hat die Koordinaten x = 0 und y = 0.
--]]

-- Lokale Daten und Funktionen ----------------------------------------

-- Ausführliche Protokollierung zur Fehleranalyse (true/false)
local log = false

-- Maximale Anzahl der gespeicherten Positionen von Dateien 
-- (Das wird begrenzt, da dies bei Landschaftselementen eine sehr große Zahl sein könnte)
local MaxPositions = 10

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

local KontaktTyp = {				-- SetType ist ein Bit-Feld (noch nicht vollständig analysiert)
	[0]		= { Typ = 'Signal', 			Farbe = 'rot' },			-- $0000000000000000
	[1]		= { Typ = 'Fahrzeug', 			Farbe = 'lila' },			-- $0000000000000001
	[3]		= { Typ = '(3)?', 				Farbe = '(3)?' },			-- $0000000000000011
	[7]		= { Typ = '(7)?', 				Farbe = '(7)?' },			-- $0000000000000111
	[256]	= { Typ = 'Sound', 				Farbe = 'gelb' },			-- $0000000100000000
	[512]	= { Typ = 'Kamera', 			Farbe = 'gruen' },			-- $0000001000000000
	[1280]	= { Typ = 'Einfahrt Zug-Depot', Farbe = 'grau, Quadrat' },	-- $0000010100000000
	[1536]	= { Typ = 'Ausfahrt Zug-Depot', Farbe = 'grau, Dreieck' },	-- $0000011000000000
	[32768]	= { Typ = 'Gruppenkontakt', 	Farbe = 'blau' },			-- $1000000000000000 
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

-- xml_tabelle
local sutrackp = nil

-- Konvertierte Daten
local Gleise = {}
local Fuhrparks = {}
local Zugverbaende = {}
local Rollmaterialien = {}
local Kontakte = {}
local Signale = {}
local KontaktZiele = {}
local Routen = {}
local Sounds = {}
local LuaFunktionen = {}
local Immobilien = {}
local Dateien = {
	Gleissystem  	= {},
	Signal  		= {},
	Rollmaterial 	= {},
	Immobile     	= {},
	Sound     		= {},
}

-- Vorabdeklaration der Variablen der öffentlichen Schnittstelle
local EEP2Lua = {}

-- Hilfsfunktion zur Prüfung ob eine Tabelle einen bestimmten Eintrag enthält
local function tableHasKey(table,key)
    return table[key] ~= nil
end

-- Speichere Informationen zu Dateien
local function storeDatei(Gruppe, Dateiname, Position)
	-- neue Datei
	if not Dateien[Gruppe][Dateiname] then
		Dateien[Gruppe][Dateiname] = { Anzahl = 0, Positionen = {} }
	end

	-- Nur zählen wenn auf der Anlage verbaut (evt. wichtig für Sounds)
	if Position then 
		Dateien[Gruppe][Dateiname].Anzahl = Dateien[Gruppe][Dateiname].Anzahl + 1
	end
	
	-- Speichere nur bis zu MaxPositions Positionen
	if Position and #Dateien[Gruppe][Dateiname].Positionen < MaxPositions then 
		table.insert(Dateien[Gruppe][Dateiname].Positionen, Position)
	end
end

-- Speichere Lua-Funktion
local function storeLuaFunktion(LuaFn, KontaktIDTab, Position)
	-- Wie sollen Lua-Funktionen mit Parametern verwaltet werden?
	-- In der aktuellen Version werden alle Strings als unterschiedlich betrachtet
	-- Besser wäre es, den Funktionsnamen von den Parameters zu trennen
	-- Achtung: es kann auch inline-Lua ohne Funktion angegeben sein

	-- neue Lua-Funktion
	if not LuaFunktionen[LuaFn] then
		LuaFunktionen[LuaFn] = { Anzahl = 0, Kontakte = {}, Positionen = {} }
	end	
	
	LuaFunktionen[LuaFn].Anzahl = LuaFunktionen[LuaFn].Anzahl + 1
	table.insert(LuaFunktionen[LuaFn].Kontakte, KontaktIDTab)
	table.insert(LuaFunktionen[LuaFn].Positionen, Position)
end



-- Funktionen zur Verarbeitung einzelner Tokens

local function processSutrackp(xmlsutrackp, Parameters)
	if log == true then print('processSutrackp') end
	
	-- hier gibt es nichts zu tun
	
	return Parameters
end


local function processGleissystem(xmlGleissystem, Parameters)
	if log == true then print('processGleissystem') end
	
	local GleissystemID = tonumber(xmlGleissystem._attr.GleissystemID)
	
	-- Feldliste: Kontakte
	Kontakte[GleissystemID] = {
		Anzahl = 0
	}
	-- Feldliste: Signale
	Signale[GleissystemID] = {
		Anzahl = 0
	}

	-- neues Gleissystem anlegen
	Gleise[GleissystemID] = {
		--..											-- kein Elternknoten
		GleissystemID		= GleissystemID,			-- Schlüssel des aktuellen Eintrages 
		
		Laenge 				= 0,
		Anzahl = { 
			Gleise 			= 0,
			Kontakte 		= 0,
			Signale 		= 0,
			Zugverbaende 	= 0,
			Rollmaterialien = 0,
		}	
	}
	local Gleissystem = Gleise[GleissystemID]
	
	return Gleissystem									-- Elternknoten für die nächste Ebene
end

local function processGleis(xmlGleis, Gleissystem)
	if log == true then print('processGleis') end
	
	local GleisID = tonumber(xmlGleis._attr.GleisID)

	local GleissystemID = Gleissystem.GleissystemID
	local Laenge  = math.floor(tonumber(xmlGleis.Charakteristik._attr.Laenge) / 100 + 0.5)

	-- Felder von Gleissystem aktualisieren
	Gleissystem.Laenge 			= Gleissystem.Laenge + Laenge
	Gleissystem.Anzahl.Gleise 	= Gleissystem.Anzahl.Gleise + 1

	-- neues Gleis anlegen
	Gleise[GleissystemID][GleisID] = {
		Gleissystem	= Gleissystem,						-- Elternknoten
		GleisID		= GleisID,							-- Schlüssel des aktuellen Eintrages 

		Gleisart	= xmlGleis._attr.clsid,
		Laenge		= Laenge,
		Position	= {
			x = math.floor(tonumber(xmlGleis.Dreibein.Vektor[1]._attr.x) / 100 + 0.5), 
			y = math.floor(tonumber(xmlGleis.Dreibein.Vektor[1]._attr.y) / 100 + 0.5),
			z = math.floor(tonumber(xmlGleis.Dreibein.Vektor[1]._attr.z) / 100 + 0.5)
		},
		KontaktZiel	= tonumber(xmlGleis.KontaktZiel),	-- Weichen sind potentielle Kontakt-Ziele
		TipTxt		= xmlGleis._attr.TipTxt,			-- Tipp-Text (kann auch nil sein)
	}
	local Gleis = Gleise[GleissystemID][GleisID]
	
	-- Kontakt-Ziel für Gleis/Weiche eintagen
	if Gleis.KontaktZiel then
		-- Neues Kontakt-Ziel?
		if not KontaktZiele[Gleis.KontaktZiel] then 
			KontaktZiele[Gleis.KontaktZiel] = {}
		end	
		-- Gleis/Weiche eintragen
		KontaktZiele[Gleis.KontaktZiel].Gleis = Gleis
	end

	-- Speichere Datei
	storeDatei('Gleissystem', 
		xmlGleis._attr.gsbname,
		Gleis.Position
	)
	
	return Gleis										-- Elternknoten für die nächste Ebene
end

local function processKontakt(xmlKontakt, Gleis)
	if log == true then print('processKontakt') end
	
	local KontaktID				= 0						-- keine KontaktID vorhanden (wird später bestimmt)

	local GleisID				= Gleis.GleisID
	local GleissystemID			= Gleis.Gleissystem.GleissystemID
	local LuaFn     			= xmlKontakt._attr.LuaFn
	
	-- Felder von Gleissystem aktualisieren
	Gleise[GleissystemID].Anzahl.Kontakte = Gleise[GleissystemID].Anzahl.Kontakte + 1

	-- erster Kontakt des Gleises
	if not Kontakte[GleissystemID][GleisID] then
		Kontakte[GleissystemID][GleisID] = {
			-- Position des Gleises
			Position 	= Gleise[GleissystemID][GleisID].Position
		}
	end
	
	-- neuen Kontakt anlegen
	table.insert( 
		Kontakte[GleissystemID][GleisID],
		{
			Gleis			= Gleis,					-- Elternknoten
			KontaktID		= KontaktID,				-- Schlüssel des aktuellen Eintrages (vorläufig)						 
		
			relPosition 	= math.floor(tonumber(xmlKontakt._attr.Position) / 100 + 0.5),		-- Position relativ zum Gleisursprung
			SetType			= tonumber(xmlKontakt._attr.SetType),		-- KontaktTyp (Bit-Vektor)
			SetValue		= xmlKontakt._attr.SetValue,		-- Interpretation je nach Kontakttyp
			Delay			= xmlKontakt._attr.Delay,			-- Startverzögerung		
			Group			= xmlKontakt._attr.Group,			-- Kontaktgruppe
			KontaktZiel		= tonumber(xmlKontakt._attr.KontaktZiel), 	-- Kontakt-Ziel des Kontaktes (kann auch nil sein)
			LuaFn			= ( LuaFn == '' and nil or LuaFn ),	-- Lua-Funktion (nur wenn nicht leer)
			clsid 			= xmlKontakt._attr.clsid,			-- konstanter Wert		
			TipTxt			= xmlKontakt._attr.TipTxt,			-- Tipp-Text (kann auch nil sein)
		}
	)
	KontaktID = #Kontakte[GleissystemID][GleisID]			-- nun kann die KontaktID bestimmt werden
	local Kontakt = Kontakte[GleissystemID][GleisID][KontaktID]
	Kontakt.KontaktID = KontaktID							-- Schlüssel des aktuellen Eintrages eintragen

	-- Kontakt-Ziel für Kontakt eintragen
	if Kontakt.KontaktZiel then
		-- Neues Kontakt-Ziel?
		if not KontaktZiele[Kontakt.KontaktZiel] then 
			KontaktZiele[Kontakt.KontaktZiel] = {}
		end	
		-- neuer Kontakt für Kontakt-Ziel?
		if not KontaktZiele[Kontakt.KontaktZiel].Kontakte then 
			KontaktZiele[Kontakt.KontaktZiel].Kontakte = {}
		end	
		-- Kontakt eintragen
		table.insert(KontaktZiele[Kontakt.KontaktZiel].Kontakte, Kontakt)
	end

	-- Speichere Lua-Funktion
	if LuaFn and LuaFn ~='' then
		storeLuaFunktion(
			LuaFn,
			{GleissystemID = GleissystemID, GleisID = GleisID, KontaktID = KontaktID},	-- Identifikation des Kontaks
			Gleise[GleissystemID][GleisID].Position
		)
	end	
		
	return Kontakt										-- Elternknoten für die nächste Ebene
end

local function processMeldung(xmlMeldung, Gleis)
	if log == true then print('processMeldung') end
	
	local SignalID 		= tonumber(xmlMeldung._attr.Key_Id)

	local GleisID		= Gleis.GleisID
	local GleissystemID	= Gleis.Gleissystem.GleissystemID

	-- Felder von Gleissystem aktualisieren
	Gleise[GleissystemID].Anzahl.Signale = Gleise[GleissystemID].Anzahl.Signale + 1

	-- neues Signal anlegen
	Signale[GleissystemID][SignalID] = {
		Gleis			= Gleis,						-- Elternknoten
		SignalID		= SignalID,						-- Schlüssel des aktuellen Eintrages
		
		Position 		= Gleise[GleissystemID][GleisID].Position,						-- vorläufig, müsste genau berechnet werden
		relPosition 	= math.floor(tonumber(xmlMeldung._attr.Position) / 100 + 0.5),	-- Position relativ zum Gleisursprung
		name			= xmlMeldung._attr.name,
		Stellung		= xmlMeldung.Signal._attr.stellung,
		KontaktZiel		= tonumber(xmlMeldung.KontaktZiel),	-- Signale sind potentielle Kontakt-Ziele
		TipTxt			= xmlMeldung._attr.TipTxt,		-- Tipp-Text (kann auch nil sein)
	}
	local Signal = Signale[GleissystemID][SignalID]
	
	-- Kontakt-Ziel für Signal eintragen
	if Signal.KontaktZiel then
		-- Neues Kontakt-Ziel?
		if not KontaktZiele[SignalID] then 
			KontaktZiele[SignalID] = {}
		end	
		-- Signal eintragen
		KontaktZiele[SignalID].Signal = Signal
	end
	
	-- Speichere Datei
	storeDatei('Signal', 
		xmlMeldung._attr.name,
		Gleise[GleissystemID][GleisID].Position
	)
		
	return Signal										-- Elternknoten für die nächste Ebene
end


local function processFuhrpark(xmlFuhrpark, Parameters)
	if log == true then print('processFuhrpark') end
	
	local FuhrparkID = tonumber(xmlFuhrpark._attr.FuhrparkID)
	
	-- neuen Fuhrpark anlegen
	Fuhrparks[FuhrparkID] = {
		--..											-- kein Elternknoten
		FuhrparkID		= FuhrparkID,					-- Schlüssel des aktuellen Eintrages
		
		Anzahl 			= {
			Zugverbaende 	= 0,
			Rollmaterialien	= 0, 
		},
		--.. hier weitere Felder zu einem Fuhrpark eintragen
	}
	local Fuhrpark = Fuhrparks[FuhrparkID]

	return Fuhrpark										-- Elternknoten für die nächste Ebene
end

local function processZugverband(xmlZugverband, Fuhrpark)
	if log == true then print('processZugverband') end

	local ZugID 		= tonumber(xmlZugverband._attr.ZugID)
	
	local GleissystemID = tonumber(xmlZugverband.Gleisort._attr.gleissystemID)
	local GleisID       = tonumber(xmlZugverband.Gleisort._attr.gleisID)

	-- Felder des übergeordneten Fuhrparks aktualisieren
	Fuhrpark.Anzahl.Zugverbaende = Fuhrpark.Anzahl.Zugverbaende + 1

	-- Felder des Gleissystems aktualisieren
	Gleise[GleissystemID].Anzahl.Zugverbaende = Gleise[GleissystemID].Anzahl.Zugverbaende + 1

	-- neuen Zugverband anlegen
	Zugverbaende[ZugID] = {
		Fuhrpark		= Fuhrpark,						-- Elternknoten
		ZugID			= ZugID,						-- Schlüssel des aktuellen Eintrages
		
		name 			= xmlZugverband._attr.name, 
		FuhrparkID      = Fuhrpark.FuhrparkID,
		GleissystemID 	= GleissystemID,
		GleisID 		= GleisID,
		Position 		= Gleise[GleissystemID][GleisID].Position,
		Geschwindigkeit = math.floor(tonumber(xmlZugverband._attr.Geschwindigkeit) * 36 + 0.5) / 10, -- Umgerechnet und gerundet in km/h
		Rollmaterialien = {},		-- Querverweise werden später eingetragen
		--.. hier weitere Felder zu einem Zugverband eintragen
	}	
	local Zugverband = Zugverbaende[ZugID] 
	
	return Zugverband									-- Elternknoten für die nächste Ebene
end

local function processRollmaterial(xmlRollmaterial, Zugverband)
	if log == true then print('processRollmaterial') end
	
	local name = xmlRollmaterial._attr.name

	local GleissystemID = Zugverband.GleissystemID
	
	-- Felder des zugehörigen Fuhrparks aktualisieren
	Zugverband.Fuhrpark.Anzahl.Rollmaterialien = Zugverband.Fuhrpark.Anzahl.Rollmaterialien + 1

	-- Felder des Gleissystems aktualisieren
	Gleise[GleissystemID].Anzahl.Rollmaterialien = Gleise[GleissystemID].Anzahl.Rollmaterialien + 1
	
	-- neues Rollmaterial anlegen
	Rollmaterialien[name] = {
		Zugverband		= Zugverband,				-- Elternknoten
		name			= name,						-- Schlüssel des aktuellen Eintrages

		typ 			= xmlRollmaterial._attr.typ,
		Zugmaschine 	= tableHasKey(xmlRollmaterial, 'Zugmaschine'),
		ZugID           = Zugverband.ZugID,
		--.. hier weitere Felder zu einem Rollmaterial eintragen
	}
	local Rollmaterial				= Rollmaterialien[name]
	
	-- Querverweis in Zugverband eintragen
	table.insert( Zugverband.Rollmaterialien, Rollmaterial )  
	
	-- Speichere Datei
	storeDatei('Rollmaterial', 
		xmlRollmaterial._attr.typ,
		Rollmaterial.Zugverband.Position
	)
	
	return Rollmaterial									-- Elternknoten für die nächste Ebene
end


local function processGebaeudesammlung(xmlGebaeudesammlung, Parameters)
	if log == true then print('processGebaeudesammlung') end

	local GebaeudesammlungID = tonumber(xmlGebaeudesammlung._attr.GebaudesammlungID)

	-- neue Gebaeudesammlung anlegen
	Immobilien[GebaeudesammlungID] = {
		--..											-- Elternknoten
		GebaeudesammlungID = GebaeudesammlungID,		-- Schlüssel des aktuellen Eintrages
		
		Anzahl = 0,
		--.. hier weitere Felder zu einer Gebaeudesammlung eintragen
	}	
	local Gebaeudesammlung = Immobilien[GebaeudesammlungID]
	
	return Gebaeudesammlung 							-- Elternknoten für die nächste Ebene
end

local function processImmobile(xmlImmobile, Gebaeudesammlung)
	if log == true then print('processImmobile') end

	local ImmoIdx = tonumber(xmlImmobile._attr.ImmoIdx)

	-- Felder der übergeordneten Gebaeudesammlung aktualisieren
	Gebaeudesammlung.Anzahl = Gebaeudesammlung.Anzahl + 1

	-- neue Immobilie anlegen
	Gebaeudesammlung[ImmoIdx] = { 
		Gebaeudesammlung = Gebaeudesammlung,			-- Elternknoten
		ImmoIdx  		 = ImmoIdx,						-- Schlüssel des aktuellen Eintrages
		
		Position = {
			x = math.floor(tonumber(xmlImmobile.Dreibein.Vektor[1]._attr.x) / 100 + 0.5), 
			y = math.floor(tonumber(xmlImmobile.Dreibein.Vektor[1]._attr.y) / 100 + 0.5), 
			z = math.floor(tonumber(xmlImmobile.Dreibein.Vektor[1]._attr.z) / 100 + 0.5),
		},
		TipTxt		= xmlImmobile._attr.TipTxt,			-- Tipp-Text (kann auch nil sein)
		--.. hier weitere Felder zu einer Immobilie eintragen
	}
	local Immobilie	= Gebaeudesammlung[ImmoIdx]

	-- Speichere Datei
	storeDatei('Immobile', 
		xmlImmobile._attr.gsbname, 
		Immobilie.Position
	)
	
	return Immobilie									-- Elternknoten für die nächste Ebene
end


local function processOptions(xmlOptions, Parameters)
	if log == true then print('processOptions')end
	
	local I
	local Route = {}
	local Sound = {}
	-- Sammele RouteItems und SoundItems
	for key, value in pairs(xmlOptions._attr) do
		if     string.sub(key, 1, 8)  == 'RouteId_'   then
			I = string.sub(key, 9 )
			if not Route[I] then
				Route[I] = {}
			end	
			Route[I].RouteId = value

		elseif string.sub(key, 1, 10) == 'RouteName_' then
			I = string.sub(key, 11 )
			if not Route[I] then
				Route[I] = {}
			end	
			Route[I].RouteName = value
			
		elseif string.sub(key, 1, 6)  == 'SndId_'   then
			I = string.sub(key, 7 )
			if not Sound[I] then
				Sound[I] = {}
			end	
			Sound[I].SndId = value

		elseif string.sub(key, 1, 8) == 'SndName_' then
			I = string.sub(key, 9 )
			if not Sound[I] then
				Sound[I] = {}
			end	
			Sound[I].SndName = value

		end
	end	
	
	-- Speichere Routen und Sounds
	for key, value in pairs(Route) do
		if value.RouteId then 
			Routen[value.RouteId] = value.RouteName
		end		
	end
	for key, value in pairs(Sound) do
		if value.SndId then 
			Sounds[value.SndId] = value.SndName

			-- Speichere Datei
			storeDatei('Sound', 
				value.SndName
			)
		end		
	end	
	
	return Parameters
end


-- Aufrufhierarchie der zu verarbeitenden Token gemäß XML-Struktur, optional mit Funktionen, die die einzelnen Token verarbeiten
local xmlHierarchy = {				_Call = nil,
	sutrackp = {					_Call = processSutrackp,
		Gleissystem = {				_Call = processGleissystem,
			Gleis = {				_Call = processGleis,
				Kontakt = { 		_Call = processKontakt 			},
				Meldung = { 		_Call = processMeldung 			}, 
			}, 
		}, 
		Fuhrpark = {				_Call = processFuhrpark,
			Zugverband = {			_Call = processZugverband,
				Rollmaterial = { 	_Call = processRollmaterial 		}, 
			}, 
		}, 
		Gebaeudesammlung = {		_Call = processGebaeudesammlung,	
			Immobile = { 			_Call = processImmobile 			}, 
		},
		Options = { 				_Call = processOptions 			}, 
	}, 
}

-- Rahmenprogramm zur Verarbeitumng der XML-Tokens
local function processToken(
		Name,					-- Name des aktuellen Tokens (wird nur für Dubugging benötigt)
		Token, 					-- aktuelles Token in xml-Tabelle
		xmlHierarchy,			-- aktuelle Position in Aufrufhierarchie
		Parameters				-- Ergebnis der Verarbeitung des aktuellen Tokens zur Übergabe an darunter liegende Tokens 
	)
	
	-- Did we got a value instead of a table? This should not happen!
	if type(Token) ~= 'table' then
		print('Error: ', 'Name=', Name, 'Token=', Token, ' ', type(Token))
		return nil
	end 
	
	if log == true then 
		print('')
		print('Name=', Name, ' ', type(Token))
		print('  Call=', type(xmlHierarchy._Call))
		for key, value in pairs(xmlHierarchy) do	
			if key ~= '_Call' then 
				print('  Next=', key)
			end	
		end	
	end

	-- mehrfaches Token (mit numerischen Schlüssel) auf gleicher Ebene verarbeiten 
	local multiple_token = false
	for key, value in ipairs(Token) do	
		if log == true then print('= ', Name, '[', key, ']') end

		multiple_token = true
		processToken(Name, value, xmlHierarchy, Parameters)
	end	
	if multiple_token == false then

		-- einzelnes Token verarbeiten
		local Results = Parameters
		if xmlHierarchy._Call and type(xmlHierarchy._Call) == 'function' then
			if log == true then print('= ', Name, ' Call') for key, value in pairs(Token) do print('  Sub=', key) end end
			
			Results = xmlHierarchy._Call(Token, Parameters)	
		end
	
		-- Token der nächsten Ebene verarbeiten 
		for NextName, value in pairs(Token) do		
			if xmlHierarchy[NextName] then -- passt das Token?
				if log == true then print('> ', NextName, ' ', xmlHierarchy[NextName]) end
				
				processToken(NextName, value, xmlHierarchy[NextName], Results)
			end
		end	
		
	end
end


-- Laden und Verarbeiten der EEP-Anlagen-Datei
local function loadFile(input_file)
	local t0 = os.clock()
	
	local xml2lua = require("xml2lua")

-- The XML tree structure is mapped directly into a recursive table structure 
-- with node names as keys and child elements as either a table of values or 
-- directly as a string value for text. Where there is only a single child 
-- element this is inserted as a named key - if there are multiple elements 
-- these are inserted as a vector. 
-- Attributes are inserted as a child element with a key of '_attr'.
	local handler = require("xmlhandler.tree")

	-- Load the XML file
	local xml = xml2lua.loadFile(input_file)
	
	Statistics.LoadFileTime = os.clock() - t0
	Statistics.FileSize = string.len(xml)
	t0 = os.clock()

	-- Instantiate the XML parser
	local parser = xml2lua.parser(handler)
	-- Do it
	parser:parse(xml)
	
	Statistics.ParserTime = os.clock() - t0
	t0 = os.clock()

	-- xml-Tabelle speichern 
	sutrackp = handler.root.sutrackp
	
	-- xml-Tabelle verarbeiten
	processToken('root', handler.root, xmlHierarchy)

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
	EEP2Lua.Kontakte				= Kontakte	
	EEP2Lua.Signale					= Signale
	EEP2Lua.KontaktZiele 			= KontaktZiele
	EEP2Lua.Routen					= Routen	
	EEP2Lua.Sounds					= Sounds	
	EEP2Lua.LuaFunktionen			= LuaFunktionen	
	EEP2Lua.Gleise					= Gleise	
	EEP2Lua.Immobilien 				= Immobilien
	EEP2Lua.Dateien 				= Dateien
	
	return sutrackp
end



-- Öffentliche Schnittstelle des Moduls -------------------------------

EEP2Lua._VERSION 				= "2019-01-25"

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
EEP2Lua.Kontakte				= nil
EEP2Lua.Signale					= nil
EEP2Lua.KontaktZiele			= nil
EEP2Lua.Routen					= nil
EEP2Lua.Sounds					= nil
EEP2Lua.LuaFunktionen			= nil
EEP2Lua.Immobilien				= nil
EEP2Lua.Dateien					= nil

-- statische Texten und Definitionen
EEP2Lua.GleissystemText 		= GleissystemText
EEP2Lua.Gleisart				= Gleisart
EEP2Lua.KontaktTyp 				= KontaktTyp 				-- {Typ, Farbe}
EEP2Lua.GebaeudesammlungText 	= GebaeudesammlungText

return EEP2Lua
