--[[
Datei: EEP_Inventar.lua

Analyse einer EEP-Anlage-Datei

Frank Buchholz, 2019-2022

Beispiel:

-- PrintToFile (optional) https://emaps-eep.de/lua/printtofile
local output_file = "C:/temp/output.txt"
require("PrintToFile_BH2"){ file = output_file, output = 1 }
clearlog()

-- EEP-Anlagedatei
local inputFile = ".\\Resourcen\\Anlagen\\Tutorials\\Tutorial_57_sanftes_Ankuppeln.anl3"

-- Modul laden und EEP-Anlagedatei verarbeiten

-- Option A
local EEP_Inventar = require('EEP_Inventar'){ inputFile = inputFile }

-- Option B in zwei Schritten
--local EEP_Inventar = require('EEP_Inventar'){}
--local sutrackp = EEP_Inventar.loadFile(input_file) -- Der optionale Rueckgabewert sutrackp enthaelt die Tabellenstruktur in der Form wie sie xml2lua liefert

-- Option C wie A oder B jedoch mit erweiterter Protokollausgabe
--local EEP_Inventar = require('EEP_Inventar'){ inputFile = inputFile, debug = true }

-- Alles anzeigen
EEP_Inventar.printInventar()

function EEPMain()
    return 0
end

]]

local _VERSION = '2022-01-03'

local debug = false

local Anlage = {}

local function loadFile(inputFile)
	-- Der optionale Rueckgabewert sutrackp enthaelt die Tabellenstruktur in der Form wie sie xml2lua liefert
	local sutrackp = Anlage.loadFile(inputFile)
end

local function sortedTable(tab, func)
	-- Hilfsfunktion zur Sortierung einer Tabelle
	-- siehe https://www.lua.org/pil/19.3.html
	local a = {}
	for n in pairs(tab) do table.insert(a, n) end	-- copy references to table entries into local table
	table.sort(a, func)
	local i = 0										-- iterator variable
	local iter = function ()						-- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], tab[a[i]]				-- return key, value
		end
	end
	return iter
end

local function printVersion()
	print('EEP_Inventar Version', ' ',	_VERSION)
	print('EEP2Lua Version', ' ',		Anlage._VERSION)
end

local function printUebersicht()
	print('Auswertung der Anlage', ' ',	Anlage.Datei )
	print('Dateigroessee: ', 				math.floor(Anlage.Statistics.FileSize / 1000), ' kB')
	print('Laufzeit:')
	print('Datei laden: ', 					string.format("%.3f", Anlage.Statistics.LoadFileTime), ' sek')
	print('XML in Lua-Tabelle umwandeln: ', string.format("%.3f", Anlage.Statistics.ParserTime),   ' sek')
	print('XML verarbeiten: ', 				string.format("%.3f", Anlage.Statistics.ProcessTime),  ' sek')
	print('Gesamt: ', 						string.format("%.3f", Anlage.Statistics.TotalTime),    ' sek')

	print('')
	print('Beschreibung:')
	print(Anlage.Beschreibung )
	print('----')

	print('EEP Version der Anlage', ': ', 	Anlage.EEP )
	if Anlage.No3DMs then 		-- Das Attribut gibt ab EEP 13
		print('Anzahl der Resourcen',   ': ', Anlage.No3DMs )
	end
end

local function printGleisUebersicht()
	-- Ausgabe der Informationen zur Anlage
	-- Das Komma am Anfang der Zeilen innerhalb von print erleichtert es, einzelne Zeilen auszukommentieren.

	print('')
	print('Gleise:')
	for GleissystemID, Gleissystem in pairs(Anlage.Gleise) do
		if Gleissystem.Anzahl.Gleise > 0 then
		print(
			  Anlage.GleissystemText[GleissystemID], ' '
			, 'Laenge=', 			string.format('%.2f', Gleissystem.Laenge), 'm '
			, 'Gleise=', 			Gleissystem.Anzahl.Gleise, ' '
			, 'Kontakte=', 			Gleissystem.Anzahl.Kontakte, ' '
			, 'Signale=', 			Gleissystem.Anzahl.Signale, ' '
			, 'Zugverbaende=', 		Gleissystem.Anzahl.Zugverbaende, ' '
			, 'Rollmaterialien=', 	Gleissystem.Anzahl.Rollmaterialien, ' '
		)
		end
	end
end

local function printGleise()

	local function printAnschluss(Text, GleisA, PositionA, GleisB, AnschlussB, Virtuell)
		if GleisB then

			local PositionB = (AnschlussB == 'Anfang' and GleisB.Position or GleisB.PositionEnde)

			print( '  '
				, 'Gleis=', GleisA.GleisID, ' '
				, Text, ' '
				, 'x=' .. string.format('%.2f', PositionA.x) .. 'm' .. ' '
				, 'y=' .. string.format('%.2f', PositionA.y) .. 'm' .. ' '
				, ( math.abs(PositionA.z) >= 1 and 'z=' .. string.format('%.2f', PositionA.z) .. 'm' or '') .. ' '

				, 'Gleis=', GleisB.GleisID, ' '
				, AnschlussB, ' '
				, 'x=' .. string.format('%.2f', PositionB.x) .. 'm' .. ' '
				, 'y=' .. string.format('%.2f', PositionB.y) .. 'm' .. ' '
				, ( math.abs(PositionB.z) >= 1 and 'z=' .. string.format('%.2f', PositionB.z) .. 'm' or '') .. ' '

				, ( Virtuell and 'virtuell' or '') .. ' '

				, ( (math.abs(PositionA.x - PositionB.x) > 10 or math.abs(PositionA.y - PositionB.y) > 10 )
					and 'Sprungverbindung' or '') .. ' '
				)

		end
	end -- function printAnschluss

	print('')
	print('Gleise:')
	for GleissystemID, Gleissystem in pairs(Anlage.Gleise) do
		for GleisID, Gleis in pairs(Gleissystem) do
			if type(GleisID) == 'number' then

				print(
					  Anlage.GleissystemText[GleissystemID], ' '
					, 'Gleis=', GleisID, ' ', ' '
					, 'x=' .. string.format('%.2f', Gleis.Position.x) .. 'm' .. ' '
					, 'y=' .. string.format('%.2f', Gleis.Position.y) .. 'm' .. ' '
					, ( math.abs(Gleis.Position.z) >= 1 and 'z=' .. string.format('%.2f', Gleis.Position.z) .. 'm' or '') .. ' '
				)

				for key, Verbindung in pairs(Gleis.Verbindung) do
					printAnschluss('Anfang', 		Gleis, Gleis.Position, 		Verbindung.Anfang, 		Verbindung.AnfangAnschluss,			Verbindung.Virtuell)
					printAnschluss('Ende', 			Gleis, Gleis.PositionEnde, 	Verbindung.Ende, 		Verbindung.EndeAnschluss,			Verbindung.Virtuell)
					printAnschluss('EndeAbzweig', 	Gleis, Gleis.PositionEnde, 	Verbindung.Abzweig, 	Verbindung.EndeAbzweigAnschluss,	Verbindung.Virtuell)
					printAnschluss('EndeKoAbzweig', Gleis, Gleis.PositionEnde, 	Verbindung.KoAbzweig, 	Verbindung.EndeKoAbzweigAnschluss,	Verbindung.Virtuell)
				end

			end
		end
	end
end

local function printKontakte()
	print('')
	print('Kontakte:')
	for GleissystemID, Gleissystem in pairs(Anlage.Kontakte) do
		for GleisID, Gleis in pairs(Gleissystem) do
			if type(Gleis) == 'table' then
--[[
			print('Gleis ', GleisID, ' ', type(Gleis), Gleis)
			for k, v in pairs(Gleis) do
				print( 'Gleis.', k, '=', v)
			end
			print(Gleis.Position)
			for k, v in pairs(Gleis.Position) do
				print( 'Gleis.Position.', k, '=', v)
			end

			print(
				  Anlage.GleissystemText[GleissystemID], ' '
				, 'Gleis ', GleisID, ' '
				, 'x=' .. string.format('%.2f', Gleis.Position.x) .. 'm', ' '
				, 'y=' .. string.format('%.2f', Gleis.Position.y) .. 'm', ' '
					, ( math.abs(Gleis.Position.z) >= 1 and 'z=' .. string.format('%.2f', Gleis.Position.z) .. 'm' or ''), ' '
			)
		]]
			for Nr, Kontakt in pairs(Gleis) do
				if type(Nr) == 'number' then
				print(
					  Anlage.GleissystemText[Kontakt.Gleis.Gleissystem.GleissystemID]
					, ' Gleis=', Kontakt.Gleis.GleisID, ' '
					, ' Kontakt ', 	Nr, ' '

				--	, 'x=' .. string.format('%.2f', Gleis.Position.x) .. 'm', ' '
				--	, 'y=' .. string.format('%.2f', Gleis.Position.y) .. 'm', ' '
				--	, ( math.abs(Gleis.Position.z) >= 1 and 'z=' .. string.format('%.2f', Gleis.Position.z) .. 'm' or ''), ' '
					, '+', 			string.format('%.2f', Kontakt.relPosition), 'm', ' '

					, 'Typ=', 		Kontakt.SetType, ' '
					, ( Anlage.KontaktTyp[Kontakt.SetType] and Anlage.KontaktTyp[Kontakt.SetType].Typ .. ' ' or '' )
					, 'SetValue=', 	Kontakt.SetValue, ' '

					, 'Delay=', 	Kontakt.Delay, ' '
					, ( Kontakt.Group ~= 0 	and 'Group=' 		.. Kontakt.Group 		.. ' ' or '' )
					, ( Kontakt.KontaktZiel and 'Kontakt-Ziel=' .. Kontakt.KontaktZiel 	.. ' ' or '' )
					, ( Kontakt.LuaFn   	and 'LuaFn='  		.. Kontakt.LuaFn  		.. ' ' or '' )
					, ( Kontakt.TipTxt 		and 'TipTxt=\"' 	.. Kontakt.TipTxt 		.. '\" ' or '' )
				)
				end
			end
			end
		end
	end
end

local function printSignale()
	print('')
	print('Signale:')
	for GleissystemID, Signale in pairs(Anlage.Signale) do
		for SignalID, Signal in pairs(Signale) do
			if type(SignalID) == 'number' then

			local KontakteString = nil
			if Signal.KontaktZiel and Anlage.KontaktZiele[Signal.KontaktZiel].Kontakte then
				for key, Kontakt in pairs(Anlage.KontaktZiele[Signal.KontaktZiel].Kontakte) do
					KontakteString =
						( not KontakteString and ' Kontakte: ' or KontakteString .. ', ' ) ..
						Anlage.GleissystemText[Kontakt.Gleis.Gleissystem.GleissystemID]    ..  ' ' ..
						Kontakt.Gleis.GleisID 		.. 	'-' ..
						Kontakt.KontaktID
				end
			else
				-- Optional: die folgende Zeile kann auskommentiert werden
				KontakteString = '*keine Kontakte*'		-- Weiche bzw. Signal wird nicht von Kontakren angesprochen
			end


			print(
				  'Signal ', SignalID, ' \"', Signal.name, '\": '
				, Anlage.GleissystemText[Signal.Gleis.Gleissystem.GleissystemID], ' Gleis=', Signal.Gleis.GleisID, ' '
			--	, 'x=' .. 			string.format('%.2f', Signal.Position.x) .. 'm', ' '
			--	, 'y=' .. 			string.format('%.2f', Signal.Position.y) .. 'm', ' '
			--	, ( math.abs(Signal.Position.z) >= 1 and 'z=' .. string.format('%.2f', Signal.Position.z) .. 'm' or ''), ' '
				, '+', 				string.format('%.2f', Signal.relPosition), 'm, '

				, 'Stellung: ', 	Signal.Stellung, ' '
				, 'Kontakt-Ziel: ', Signal.KontaktZiel, ' ', KontakteString, ' '
				, ( Signal.TipTxt 		and 'TipTxt=\"' 	.. Signal.TipTxt 		.. '\" ' or '' )
			)
		end

		end
	end
end

local function printFuhrparks()
	print('')
	--print('Fuhrparks:')
	for FuhrparkID, Fuhrpark in pairs(Anlage.Fuhrparks) do
		print('Fuhrpark ',	FuhrparkID, ':')

		if Fuhrpark.Anzahl.Zugverbaende > 0 then
			print(
				'Zugverbaende: ', 		'Anzahl=', Fuhrpark.Anzahl.Zugverbaende
			)
		end
		if Fuhrpark.Anzahl.Rollmaterialien > 0 then
			print(
				'Rollmaterialien: ', 	'Anzahl=', Fuhrpark.Anzahl.Rollmaterialien
			)
		end
	end
end

local function printImmobilien()
	print('')
	print('Immobilien:')
	for GebaeudesammlungID, Gebaeudesammlung in pairs(Anlage.Immobilien) do
		if Gebaeudesammlung.Anzahl > 0 then
		print(
	--		  GebaeudesammlungID, ' ',
			  Anlage.GebaeudesammlungText[GebaeudesammlungID], ' '
			, 'Anzahl=', 		Gebaeudesammlung.Anzahl
		)
		end
	end
end

local function printRouten()
	print('')
	print('Routen:')
	for RoutenID, Route in sortedTable(Anlage.Routen) do
		print(
			  RoutenID, ' ', Route
		)
	end
end

local function printSounds()
	print('')
	print('Sounds:')
	for SoundID, Sound in pairs(Anlage.Sounds) do
		print(
			  SoundID, ' ', Sound
		)
	end
end

local function printZugverbaende()
	print('')
	print('Zugverbaende:')
	-- Die Tabelle der Zugverbaende verwendet einen numerischen Schluessel, daher kann pairs verwendet werden
	for ZugID, Zugverband in pairs(Anlage.Zugverbaende) do
		print('')
		print(
			  'Zugverband ', 	ZugID, ': ', Zugverband.name, ' '
			, 'Gleisort: ', 	Anlage.GleissystemText[Zugverband.GleissystemID], ' '
			, 'Gleis: ', 		Zugverband.Gleis.GleisID,  ' '
			, 'x=' ..			string.format('%.2f', Zugverband.Gleis.Position.x) .. 'm', ' '
			, 'y=' .. 			string.format('%.2f', Zugverband.Gleis.Position.y) .. 'm', ' '
			, ( math.abs(Zugverband.Gleis.Position.z) >= 1 and 'z=' .. string.format('%.2f', Zugverband.Gleis.Position.z) .. 'm' or ''), ' '
			, ( math.abs(Zugverband.Geschwindigkeit) >= 1 and 'v=' .. string.format('%.1f', Zugverband.Geschwindigkeit) .. 'km/h' or ''), ' '
		)
		for key, Rollmaterial in pairs(Zugverband.Rollmaterialien) do
			print(
	--			Nr, ' ',
				  Rollmaterial.name, ' '
				, ( Rollmaterial.Zugmaschine and 'Zugmaschine' .. ' ' or '' )
	--			, 'Datei: ', Rollmaterial.typ
			)
		end
	end
end

local function printRollmaterialien()
	print('')
	print('Rollmaterialien:')
	-- Die Tabelle der Rollmaterialien verwendet den Namen als Schluessel.
	-- Fuer eine sortierte Anzeige muss die Tabelle erst sortiert werden.
	for name, Rollmaterial in sortedTable(Anlage.Rollmaterialien) do
		print(
			  name, ' '
			, ( Rollmaterial.Zugmaschine and 'Zugmaschine' or 'Rollmaterial' ), ' '
			, 'Zugverband: ', 	Rollmaterial.ZugID, ' ', Rollmaterial.Zugverband.name, ' '
			, 'x=' .. 			string.format('%.2f', Rollmaterial.Zugverband.Position.x) .. 'm', ' '
			, 'y=' .. 			string.format('%.2f', Rollmaterial.Zugverband.Position.y) .. 'm', ' '
			, ( math.abs(Rollmaterial.Zugverband.Position.z) >= 1 and 'z=' .. string.format('%.2f', Rollmaterial.Zugverband.Position.z) .. 'm' or ''), ' '
			, 'Datei: ', 		Rollmaterial.typ
		)
	end
end

local function printLuaFunktionen()
	print('')
	print('Lua-Funktionen:')
	for LuaFN, value in sortedTable(Anlage.LuaFunktionen) do

		-- Hier nur die erste Postion verwendet
		local PositionenString = ''
		if value.Positionen[1] then
			PositionenString =
				   'x=' .. string.format('%.2f', value.Positionen[1].x) .. 'm '
				.. 'y=' .. string.format('%.2f', value.Positionen[1].y) .. 'm '
				.. ( math.abs(value.Positionen[1].z) >= 1 and 'z=' .. string.format('%.2f', value.Positionen[1].z) .. 'm ' or '' )
				.. ( #value.Positionen > 1 and 	'...' or '' )
		end

		-- Hier werden alle Kontakte verwendet
		local KontakteString = nil
		for key, KontaktIDTab in pairs(value.Kontakte) do
			KontakteString =
				( not KontakteString and ' Kontakte: ' or KontakteString .. ', ' ) ..
				Anlage.GleissystemText[KontaktIDTab.GleissystemID] 	..  ' ' ..
				KontaktIDTab.GleisID 		.. 	'-' ..
				KontaktIDTab.KontaktID
		end

		print(
			  'Funktion=', LuaFN
			, ' Anzahl=', 	value.Anzahl, ' '
			, PositionenString
			, KontakteString
		)
	end
end

local function printDateien()
	-- Die Dateitabelle enthaelt die Unterkategorien 'Gleissystem', 'Rollmaterial' und 'Immobile'
	-- Daher muss die Dateitabelle zweistufig durchlaufen werden
	print('')
	print('Dateien:')
	for Typ, Dateiliste in pairs(Anlage.Dateien) do
		print("")
		print("Dateien ", Typ, ':')
		for Dateiname, Datei in sortedTable(Dateiliste) do
			print(
				  Dateiname
				, ' Anzahl=', 	Datei.Anzahl, ' '
				, ( Datei.Positionen[1] and 'x=' .. string.format('%.2f', Datei.Positionen[1].x) .. 'm ' or '' )	-- bis zu 10 Positionen stehen zur Verfuegung
				, ( Datei.Positionen[1] and 'y=' .. string.format('%.2f', Datei.Positionen[1].y) .. 'm ' or '' )	-- davon zeigen wir hier nur die erste Postion
				, ( Datei.Positionen[1] and math.abs(Datei.Positionen[1].z) >= 1 and 'z=' .. string.format('%.2f', Datei.Positionen[1].z) .. 'm' or ''), ' '
				, ( #Datei.Positionen > 1 and '...' or '' )
		)
		end
	end
end

local function printKontaktZiele()
	print('')
	print('Kontakt-Ziele:')
	for KontaktZielID, KontaktZiel in pairs(Anlage.KontaktZiele) do

		local KontakteString = nil
		if KontaktZiel.Kontakte then
			for key, Kontakt in pairs(KontaktZiel.Kontakte) do
				KontakteString =
					( not KontakteString and ' Kontakte: ' or KontakteString .. ', ' ) ..
					Anlage.GleissystemText[Kontakt.Gleis.Gleissystem.GleissystemID]    ..  ' ' ..
					Kontakt.Gleis.GleisID 		.. 	'-' ..
					Kontakt.KontaktID
			end
		else
			-- Optional: die folgende Zeile kann auskommentiert werden
			KontakteString = '*keine Kontakte*'		-- Weiche bzw. Signal wird nicht von Kontakren angesprochen
		end

		print(
			'Kontakt-Ziel ', KontaktZielID, ': ',
			(
				KontaktZiel.Gleis
				and Anlage.GleissystemText[KontaktZiel.Gleis.Gleissystem.GleissystemID] .. ' Gleis=' .. KontaktZiel.Gleis.GleisID
				or (
						KontaktZiel.Signal
						and Anlage.GleissystemText[KontaktZiel.Signal.Gleis.Gleissystem.GleissystemID] .. ' Signal=' .. KontaktZiel.Signal.SignalID
						or '*unbekannt*'			-- Fehler: Kontakt verweist auf unbekanntes Ziel
					)
			),
			( KontakteString and ' ' .. KontakteString or '')
		)
	end
end

local function printInventar()
	-- Zeige alles
	printVersion()
	printUebersicht()
	printGleisUebersicht()
	printKontakte()
	printSignale()
	printKontaktZiele()
	printFuhrparks()
	printImmobilien()
	printRouten()
	printSounds()
	printZugverbaende()
	printRollmaterialien()
	printLuaFunktionen()
	printDateien()
	printGleise()
end

-- Öffentliche Schnittstelle des Moduls
local EEP_Inventar = {
	_VERSION				= _VERSION,

	-- statische Texte und Definitionen stehen direkt nach dem require-Befehl zur Verfuegung (die Variablen werden in diesem Beispiel-Skript nicht weiter verwendet).
	GleissystemText 		= Anlage.GleissystemText,
	Gleisart				= Anlage.Gleisart,
	KontaktTyp				= Anlage.KontaktTyp,
	GebaeudesammlungText 	= Anlage.GebaeudesammlungText,

	-- EEP-Datei laden
	loadFile				= loadFile,

	-- Alles anzeigen
	printInventar 			= printInventar,

	-- Einzelne Teile anzeigen
	printVersion			= printVersion,
	printUebersicht			= printUebersicht,
	printGleisUebersicht	= printGleisUebersicht,
	printKontakte			= printKontakte,
	printSignale			= printSignale,
	printKontaktZiele		= printKontaktZiele,
	printFuhrparks			= printFuhrparks,
	printImmobilien			= printImmobilien,
	printRouten				= printRouten,
	printSounds				= printSounds,
	printZugverbaende		= printZugverbaende,
	printRollmaterialien	= printRollmaterialien,
	printLuaFunktionen		= printLuaFunktionen,
	printDateien			= printDateien,
	printGleise				= printGleise,
}

return function (options)
		-- Erweiterte Protokollausgabe
		debug = options and options.debug or false

		-- Store filename if provided
		local inputFile
		if options and options.inputFile then
			assert( (type(options.inputFile) == "string"), "EEP2Lua: options.inputFile is not a string")

			if debug then print("EEP_inventar: option inputFile = ", options.inputFile) end

			inputFile = options.inputFile
		end

		Anlage = require('EEP2Lua'){ inputFile = inputFile, debug = debug }

		return EEP_Inventar
	end
