--[[
Datei: EEP_Inventar.lua

Analyse einer EEP-Anlage-Datei

Frank Buchholz, 2019
]]

local _VERSION = 'v2019-01-30'

-- In Variable input_file wird der Pfad zur Anlagen-Datei eingetragen
-- Hier einige Varianten unter der Annahme, dass dieses Script im LUA-Ordner der EEP-Installation liegt:
local input_files = {
	-- relativer Pfad beim Start aus EEP heraus
	[1] = "./Anlagen/Tutorials/Tutorial_57_sanftes_Ankuppeln.anl3", 		-- Laufzeit ca 0.5 Sekunden		
	[2] = "./Anlagen/Demo.anl3",											-- Laufzeit ca 12 Sekunden
	[3] = "./Anlagen/Wasser Demo.anl3",	
	[4] = "./Anlagen/01 Weichen.anl3",	
	-- relativer Pfad bei standalone-Ausführung im Editor SciTE
	[11] = "../Resourcen/Anlagen/Tutorials/Tutorial_57_sanftes_Ankuppeln.anl3", 		
	[12] = "../Resourcen/Anlagen/Demo.anl3"		

}
-- Welche Datei soll es sein?
local input_file = input_files[ 1 ]

-- Hier den Pfad zur zusätzlichen Ausgabe-Datei angeben (siehe printtofile)
local output_file = "C:/temp/output.txt"

-- require('EEP_Inventar')--{file = '02 Kontakte.anl3'}

--[[------ printtofile (optional)--------------------------------------
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
		else return a[i], tab[a[i]]					-- return key, value
		end
	end
	return iter
end

local function printUebersicht(Anlage)
	print('')

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

local function printGleisUebersicht(Anlage)
	-- Ausgabe der Informationen zur Anlage 
	-- Das Komma am Anfang der Zeilen innerhalb von print erleichtert es, einzelne Zeilen auszukommentieren.

	print('')
	print('Gleise:')
	for GleissystemID, Gleissystem in pairs(Anlage.Gleise) do
		if Gleissystem.Anzahl.Gleise > 0 then 
		print(
			  Anlage.GleissystemText[GleissystemID], ' '
			, 'Laenge=', 			string.format('%d', Gleissystem.Laenge), 'm ' 
			, 'Gleise=', 			Gleissystem.Anzahl.Gleise, ' '
			, 'Kontakte=', 			Gleissystem.Anzahl.Kontakte, ' '
			, 'Signale=', 			Gleissystem.Anzahl.Signale, ' '
			, 'Zugverbaende=', 		Gleissystem.Anzahl.Zugverbaende, ' '
			, 'Rollmaterialien=', 	Gleissystem.Anzahl.Rollmaterialien, ' '
		)
		end
	end
end

local function printGleise(Anlage)

	local function printAnschluss(Text, GleisA, PositionA, GleisB, AnschlussB, Virtuell)
		if GleisB then 
		
			local PositionB = (AnschlussB == 'Anfang' and GleisB.Position or GleisB.PositionEnde)
		
			print( '  '
				, 'Gleis=', GleisA.GleisID, ' '
				, Text, ' '
				, 'x=' .. string.format('%d', PositionA.x) .. 'm' .. ' '
				, 'y=' .. string.format('%d', PositionA.y) .. 'm' .. ' '
				, ( math.abs(PositionA.z) >= 1 and 'z=' .. string.format('%d', PositionA.z) .. 'm' or '') .. ' '

				, 'Gleis=', GleisB.GleisID, ' '
				, AnschlussB, ' '
				, 'x=' .. string.format('%d', PositionB.x) .. 'm' .. ' '
				, 'y=' .. string.format('%d', PositionB.y) .. 'm' .. ' '
				, ( math.abs(PositionB.z) >= 1 and 'z=' .. string.format('%d', PositionB.z) .. 'm' or '') .. ' '

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
					, 'x=' .. string.format('%d', Gleis.Position.x) .. 'm' .. ' '
					, 'y=' .. string.format('%d', Gleis.Position.y) .. 'm' .. ' '
					, ( math.abs(Gleis.Position.z) >= 1 and 'z=' .. string.format('%d', Gleis.Position.z) .. 'm' or '') .. ' '
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

local function printKontakte(Anlage)
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
				, 'x=' .. string.format('%d', Gleis.Position.x) .. 'm', ' '
				, 'y=' .. string.format('%d', Gleis.Position.y) .. 'm', ' '
					, ( math.abs(Gleis.Position.z) >= 1 and 'z=' .. string.format('%d', Gleis.Position.z) .. 'm' or ''), ' '
			)
		]]
			for Nr, Kontakt in pairs(Gleis) do
				if type(Nr) == 'number' then 
				print(
					  Anlage.GleissystemText[Kontakt.Gleis.Gleissystem.GleissystemID]
					, ' Gleis=', Kontakt.Gleis.GleisID, ' ' 
					, ' Kontakt ', 	Nr, ' '

				--	, 'x=' .. string.format('%d', Gleis.Position.x) .. 'm', ' '
				--	, 'y=' .. string.format('%d', Gleis.Position.y) .. 'm', ' '
				--	, ( math.abs(Gleis.Position.z) >= 1 and 'z=' .. string.format('%d', Gleis.Position.z) .. 'm' or ''), ' '
					, '+', 			string.format('%d', Kontakt.relPosition), 'm', ' '

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

local function printSignale(Anlage)
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
			--	, 'x=' .. 			string.format('%d', Signal.Position.x) .. 'm', ' '
			--	, 'y=' .. 			string.format('%d', Signal.Position.y) .. 'm', ' '
			--	, ( math.abs(Signal.Position.z) >= 1 and 'z=' .. string.format('%d', Signal.Position.z) .. 'm' or ''), ' '
				, '+', 				string.format('%d', Signal.relPosition), 'm, '

				, 'Stellung: ', 	Signal.Stellung, ' '
				, 'Kontakt-Ziel: ', Signal.KontaktZiel, ' ', KontakteString, ' '
				, ( Signal.TipTxt 		and 'TipTxt=\"' 	.. Signal.TipTxt 		.. '\" ' or '' )
			)
		end
		
		end
	end
end

local function printFuhrparks(Anlage)
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

local function printImmobilien(Anlage)
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

local function printRouten(Anlage)
	print('')
	print('Routen:')
	for RoutenID, Route in sortedTable(Anlage.Routen) do
		print(
			  RoutenID, ' ', Route
		)
	end
end

local function printSounds(Anlage)
	print('')
	print('Sounds:')
	for SoundID, Sound in pairs(Anlage.Sounds) do
		print(
			  SoundID, ' ', Sound
		)
	end
end

local function printZugverbaende(Anlage)
	print('')
	print('Zugverbaende:')
	-- Die Tabelle der Zugverbände verwendet einen numerischen Schlüssel, daher kann pairs verwendet werden
	for ZugID, Zugverband in pairs(Anlage.Zugverbaende) do
		print('')
		print(
			  'Zugverband ', 	ZugID, ': ', Zugverband.name, ' '
			, 'Gleisort: ', 	Anlage.GleissystemText[Zugverband.GleissystemID], ' '
			, 'Gleis: ', 		Zugverband.Gleis.GleisID,  ' '
			, 'x=' ..			string.format('%d', Zugverband.Gleis.Position.x) .. 'm', ' '
			, 'y=' .. 			string.format('%d', Zugverband.Gleis.Position.y) .. 'm', ' '
			, ( math.abs(Zugverband.Gleis.Position.z) >= 1 and 'z=' .. string.format('%d', Zugverband.Gleis.Position.z) .. 'm' or ''), ' '
			, ( math.abs(Zugverband.Geschwindigkeit) >= 1 and 'v=' .. string.format('%.1d', Zugverband.Geschwindigkeit) .. 'km/h' or ''), ' '
		)
		for Nr, Rollmaterial in pairs(Zugverband.Rollmaterialien) do
			print(
	--			Nr, ' ', 
				  Rollmaterial.name, ' '
				, ( Rollmaterial.Zugmaschine and 'Zugmaschine' .. ' ' or '' )
	--			, 'Datei: ', Rollmaterial.typ
			)
		end
	end
end

local function printRollmaterialien(Anlage)
	print('')
	print('Rollmaterialien:')
	-- Die Tabelle der Rollmaterialien verwendet den Namen als Schlüssel. 
	-- Für eine sortierte Anzeige muss die Tabelle erst sortiert werden.
	for name, Rollmaterial in sortedTable(Anlage.Rollmaterialien) do
		print(
			  name, ' '
			, ( Rollmaterial.Zugmaschine and 'Zugmaschine' or 'Rollmaterial' ), ' '
			, 'Zugverband: ', 	Rollmaterial.ZugID, ' ', Rollmaterial.Zugverband.name, ' '
			, 'x=' .. 			string.format('%d', Rollmaterial.Zugverband.Position.x) .. 'm', ' '
			, 'y=' .. 			string.format('%d', Rollmaterial.Zugverband.Position.y) .. 'm', ' '
			, ( math.abs(Rollmaterial.Zugverband.Position.z) >= 1 and 'z=' .. string.format('%d', Rollmaterial.Zugverband.Position.z) .. 'm' or ''), ' '
			, 'Datei: ', 		Rollmaterial.typ
		)
	end
end

local function printLuaFunktionen(Anlage)
	print('')
	print('Lua-Funktionen:')
	for LuaFN, value in sortedTable(Anlage.LuaFunktionen) do
		
		-- Hier nur die erste Postion verwendet
		local PositionenString = ''
		if value.Positionen[1] then 
			PositionenString =
				   'x=' .. string.format('%d', value.Positionen[1].x) .. 'm '
				.. 'y=' .. string.format('%d', value.Positionen[1].y) .. 'm ' 
				.. ( math.abs(value.Positionen[1].z) >= 1 and 'z=' .. string.format('%d', value.Positionen[1].z) .. 'm ' or '' )
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

local function printDateien(Anlage)
	-- Die Dateitabelle enthält die Unterkategorien 'Gleissystem', 'Rollmaterial' und 'Immobile'
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
				, ( Datei.Positionen[1] and 'x=' .. string.format('%d', Datei.Positionen[1].x) .. 'm ' or '' )	-- bis zu 10 Positionen stehen zur Verfügung
				, ( Datei.Positionen[1] and 'y=' .. string.format('%d', Datei.Positionen[1].y) .. 'm ' or '' )	-- davon zeigen wir hier nur die erste Postion
				, ( Datei.Positionen[1] and math.abs(Datei.Positionen[1].z) >= 1 and 'z=' .. string.format('%d', Datei.Positionen[1].z) .. 'm' or ''), ' '
				, ( #Datei.Positionen > 1 and '...' or '' )
		)
		end
	end
end

local function printKontaktZiele(Anlage)
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

-- EEP-Anlagedatei analysieren ----------------------------------------

if EEPVer then -- Nur möglich und sinnvoll wenn das Skript aus EEP heraus gestartet wird
	clearlog()
	print("EEP Version", " ", string.format('%.1d', EEPVer), " ", "Lua Version", " ", _G._VERSION)
else
	print("Lua Version", " ", _G._VERSION)
end

-- Laden und Verarbeiten der EEP-Anlagen-Datei
-- Der optionale Rückgabewert sutrackp enthält die Tabellenstruktur in der Form wie sie xml2lua liefert (die Variable wird in diesem Beispiel-Skript nicht weiter verwendet). 
local Anlage 				= require('../git/EEP2Lua')
local sutrackp 				= Anlage.loadFile(input_file)

-- statische Texte und Definitionen stehen direkt nach dem require-Befehl zur Verfügung (die Variablen werden in diesem Beispiel-Skript nicht weiter verwendet).
local GleissystemText 		= Anlage.GleissystemText
local Gleisart				= Anlage.Gleisart
local KontaktTyp			= Anlage.KontaktTyp
local GebaeudesammlungText 	= Anlage.GebaeudesammlungText

-- Alle anderen Variablen stehen nach Aufruf von loadFile zur Verfügung 
print('EEP2Lua Version', ' ', 			Anlage._VERSION)

print('Auswertung der Anlage', ' ', 	Anlage.Datei )

	printUebersicht(Anlage)
	printGleisUebersicht(Anlage)
	printKontakte(Anlage)
	printSignale(Anlage)
	printKontaktZiele(Anlage)
	printFuhrparks(Anlage)
	printImmobilien(Anlage)
	printRouten(Anlage)
	printSounds(Anlage)
	printZugverbaende(Anlage)
	printRollmaterialien(Anlage)
	printLuaFunktionen(Anlage)
	printDateien(Anlage)
	printGleise(Anlage)

-- EEPMain --------------------------------------------------------------
function EEPMain()
	return 0
end