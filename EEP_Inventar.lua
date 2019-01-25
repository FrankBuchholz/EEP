--[[
Analyse einer EEP-Anlage-Datei

Frank Buchholz, 2019
]]

local _VERSION = 'v2019-01-18'

-- In Variable input_file wird der Pfad zur Anlagen-Datei eingetragen
-- Hier einige Varianten unter der Annahme, dass dieses Script im LUA-Ordner der EEP-Installation liegt:
local input_files = {
	-- relativer Pfad beim Start aus EEP heraus
	[1] = "./Anlagen/Tutorials/Tutorial_57_sanftes_Ankuppeln.anl3", 		-- Laufzeit ca 0.5 Sekunden		
	[2] = "./Anlagen/Demo.anl3",											-- Laufzeit ca 12 Sekunden
	[3] = "./Anlagen/Wasser Demo.anl3",	
	-- relativer Pfad bei standalone-Ausführung im Editor SciTE
	[4] = "../Resourcen/Anlagen/Tutorials/Tutorial_57_sanftes_Ankuppeln.anl3", 		
	[5] = "../Resourcen/Anlagen/Demo.anl3"		

}
-- Welche Datei soll es sein?
input_file = input_files[3]

-- Hier den Pfad zur zusätzlichen Ausgabe-Datei angeben (siehe printtofile)
local output_file = "C:/temp/output.txt"



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



-- Hilfsfunktion zur Sortierung einer Tabelle
-- siehe https://www.lua.org/pil/19.3.html
function sortedTable(tab, func)
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

-- EEP-Anlagedatei analysieren ----------------------------------------

if EEPVer then -- Nur möglich und sinnvoll wenn das Skript aus EEP heraus gestartet wird
	clearlog()
	print("EEP Version", " ", EEPVer, " ", "Lua Version", " ", _G._VERSION)
else
	print("Lua Version", " ", _G._VERSION)
end

-- Laden und Verarbeiten der EEP-Anlagen-Datei
-- Der optionale Rückgabewert sutrackp enthält die Tabellenstruktur in der Form wie sie xml2lua liefert. 
local Anlage 				= require('EEP2Lua')
local sutrackp 				= Anlage.loadFile(input_file)

-- statische Texte und Definitionen stehen direkt nach dem require-Befehl zur Verfügung
local GleissystemText 		= Anlage.GleissystemText
local Gleisart				= Anlage.Gleisart
local GebaeudesammlungText 	= Anlage.GebaeudesammlungText

-- Alle anderen Variablen stehen nach Aufruf von loadFile zur Verfügung 
print('EEP2Lua Version', ' ', 			Anlage._VERSION)

print('Auswertung der Anlage', ' ', 	Anlage.Datei )
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


-- Ausgabe der Informationen zur Anlage 
-- Das Komma am Anfang der Zeilen innerhalb von print erleichtert es, einzelne Zeilen auszukommentieren.

print('')
print('Gleise:')
for GleissystemID, Gleissystem in pairs(Anlage.Gleise) do
	if Gleissystem.Anzahl > 0 then 
	print(
		  GleissystemText[GleissystemID], ' '
		, 'Anzahl=', 		Gleissystem.Anzahl, ' '
		, 'Laenge=', 		Gleissystem.Laenge, 'm' 
	)
	end
end

print('')
--print('Fuhrparks:')
for FuhrparkID, Fuhrpark in pairs(Anlage.Fuhrparks) do
	print('Fuhrpark ',	FuhrparkID, ':')
	if Fuhrpark.Zugverbaende.Anzahl > 0 then 
		print(
			'Zugverbaende: ', 		'Anzahl=', Fuhrpark.Zugverbaende.Anzahl
		)
	end
	if Fuhrpark.Rollmaterialien.Anzahl > 0 then 
		print(
			'Rollmaterialien: ', 	'Anzahl=', Fuhrpark.Rollmaterialien.Anzahl
		)
	end
end

print('')
print('Immobilien:')
for GebaeudesammlungID, Gebaeudesammlung in pairs(Anlage.Immobilien) do
	if Gebaeudesammlung.Anzahl > 0 then 
	print(
--		  GebaeudesammlungID, ' ',
		  GebaeudesammlungText[GebaeudesammlungID], ' '
		, 'Anzahl=', 		Gebaeudesammlung.Anzahl
	)
	end
end

print('')
print('Zugverbaende:')
-- Die Tabelle der Zugverbände verwendet einen numerischen Schlüssel, daher kann pairs verwendet werden
for ZugID, Zugverband in pairs(Anlage.Zugverbaende) do
	print('')
	print(
		  'Zugverband ', 	ZugID, ': ', Zugverband.name, ' '
		, 'Gleisort: ', 	GleissystemText[Zugverband.GleissystemID], ' '
		, 'Gleis: ', 		Zugverband.GleisID,  ' '
		, 'x=' ..			Zugverband.Position.x .. 'm', ' '
		, 'y=' .. 			Zugverband.Position.y .. 'm', ' '
		, ( Zugverband.Position.z ~= 0 and 'z=' .. Zugverband.Position.z .. 'm' or ''), ' '
		, ( Zugverband.Geschwindigkeit ~= 0 and 'v=' .. Zugverband.Geschwindigkeit .. 'km/h' or ''), ' '
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

print('')
print('Rollmaterialien:')
-- Die Tabelle der Rollmaterialien verwendet den Namen als Schlüssel. 
-- Für eine sortierte Anzeige muss die Tabelle erst sortiert werden.
for name, Rollmaterial in sortedTable(Anlage.Rollmaterialien) do
	print(
		  name, ' '
		, ( Rollmaterial.Zugmaschine and 'Zugmaschine' or 'Rollmaterial' ), ' '
		, 'Zugverband: ', 	Rollmaterial.ZugID, ' ', Rollmaterial.Zugverband.name, ' '
		, 'x=' .. 			Rollmaterial.Zugverband.Position.x .. 'm', ' '
		, 'y=' .. 			Rollmaterial.Zugverband.Position.y .. 'm', ' '
		, ( Rollmaterial.Zugverband.Position.z ~= 0 and 'z=' .. Rollmaterial.Zugverband.Position.z .. 'm' or ''), ' '
		, 'Datei: ', 		Rollmaterial.typ
	)
end

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
			, 'x=' .. 		Datei.Positionen[1].x .. 'm', ' '	-- bis zu 10 Positionen stehen zur Verfügung
			, 'y=' .. 		Datei.Positionen[1].y .. 'm', ' '	-- davon zeigen wir hier nur die erste Postion
			, ( Datei.Positionen[1].z ~= 0 and 'z=' .. Datei.Positionen[1].z .. 'm' or ''), ' '
			, ( #Datei.Positionen > 1 and '...' or '' )
	)
	end
end


-- EEPMain --------------------------------------------------------------
function EEPMain()
	return 0
end
