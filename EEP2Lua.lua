--[[
Datei: EEP2Lua.lua

Das Modul EEP2Lua liest und konvertiert eine EEP-Anlage-Datei in Lua-Tabellen.

Achtung: Wenn man dieses Modul in EEP fuer die aktuellen Anlage nutzen will, z.B. weil man die Zugliste ermitteln will, dann muss man aufpassen: Es kann nicht der aktuelle Zustand der aktuellen EEP-Anlage gelesen werden sondern nur der zuletzt gespeicherte Zustand!
Man muss also selber sicherstellen, dass die EEP-Anlage vor Aufruf dieses Moduls gespeichert wurde!

Aufruf:
--local Anlage 	= require("EEP2Lua"){ debug = true } -- mit erweiterter Protokollausgabe
local Anlage 	= require("EEP2Lua"){}
local sutrackp 	= Anlage.loadFile(input_file)

Der optionale Rueckgabewert sutrackp enthaelt die Tabellenstruktur in der Form wie sie xml2lua liefert.

Nach dem Aufruf von loadFile koennen aufbereitete Informationen zur EEP-Anlage abgefragt werden:
Anlage.Beschreibung
Anlage.GleissystemText
Anlage.Zugverbaende
Anlage.Rollmaterialien
usw.

Die Feldlisten entnimmt man am Besten den unten markierten Programmstellen oder dem Beispiel-Skript EEP_Inventar.lua . (Die Feldlisten hier aufzufuehren waere mir bei Änderungen zu fehlertraechtig.)

Die Lua-Datei EEP_Inventar.lua sollte im LUA-Ordner der EEP-Programminstallation angelegt werden und kann sowohl aus EEP heraus mit require('EEP_Inventar') wie auch standalone z.B. in SciTE in gestartet werden.

Das Modul benoetigt Teile des Paketes xml2lua
Quelle:
https://github.com/manoelcampos/xml2lua
Benoetigte Dateien im LUA-Ordner:
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
		Gleisverbindung
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
	Settings (enthaelt u.a. die Tastatur-Hotkeys)
	Options (enthaelt SoundItems und die Routenbezeichnungen)
	Weather
	TimeTable
	EEPLua (LUAS=Pruefsumme fuer Lua-Datei, LUAPath=Dateiname)
	Kamera3D
	Schandlaft
	Beschreibung

Die Mitte der Anlage hat die Koordinaten x = 0 und y = 0.
--]]

-- Lokale Daten und Funktionen ----------------------------------------

-- Ausfuehrliche Protokollierung zur Fehleranalyse (true/false)
local debug = false

-- Maximale Anzahl der gespeicherten Positionen von Dateien
-- (Das wird begrenzt, da dies bei Landschaftselementen eine sehr grosse Zahl sein koennte)
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

local KontaktTyp = {				-- SetType ist ein Bit-Feld (noch nicht vollstaendig analysiert)
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
	[1] = 'Gleisobjekte-Gleise',	-- u.a. Weichen, Bahnhoefe, Bruecken
	[2] = 'Gebaeudesammlung 2',
	[3] = 'Gleisobjekte-Strassen',
	[4] = 'Immobilien',				-- u.a. Gebaeude, Mauern, Tunnel, stehende Fahrzeuge
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
local Gleisverbindungen = {}
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

-- Vorabdeklaration der Variablen der oeffentlichen Schnittstelle
local EEP2Lua = {}

-- Hilfsfunktion zur Pruefung ob eine Tabelle einen bestimmten Eintrag enthaelt
local function tableHasKey(table,key)
    return table[key] ~= nil
end

-- Speichere Informationen zu Dateien
local function storeDatei(Gruppe, Dateiname, Position)
	-- neue Datei
	if not Dateien[Gruppe][Dateiname] then
		Dateien[Gruppe][Dateiname] = { Anzahl = 0, Positionen = {} }
	end

	-- Nur zaehlen wenn auf der Anlage verbaut (evt. wichtig fuer Sounds)
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
	-- Besser waere es, den Funktionsnamen von den Parameters zu trennen
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
	if debug then print('processSutrackp') end

	-- hier gibt es nichts zu tun

	return Parameters
end


local function processGleissystem(xmlGleissystem, Parameters)
	if debug then print('processGleissystem') end

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
		GleissystemID		= GleissystemID,			-- Schluessel des aktuellen Eintrages

		Laenge 				= 0,						-- Gesamtlaenge aller Gleise
		Anzahl = {
			Gleise 			= 0,
			Kontakte 		= 0,
			Signale 		= 0,
			Zugverbaende 	= 0,
			Rollmaterialien = 0,
		}
		--.. hier weitere Felder zu einem Gleissystem eintragen
	}
	local Gleissystem = Gleise[GleissystemID]

	return Gleissystem									-- Elternknoten fuer die naechste Ebene
end

local function processGleis(xmlGleis, Gleissystem)
	if debug then print('processGleis') end

--[[

Wo befindet dich das Gleis, Der Kontakt oder das Signal?
Wo befindet sich das 'heisse' Ende einer Weiche?

Auch wenn eine grobe Naeherungsantwort recht leicht anzugeben ist - man waehlt dazu einfach die
Anfangskoordinaten des Gleises - ist eine exakte Angabe ueberraschend schwer genau zu ermitteln.
Zuerst muessen die entspechenden Attribute identifiziert werden und dann gilt es, entweder in
eine 3D-Matrix-Berechnung einzusteigen oder vereinfacht auf 2D einige trigonometrische  Formeln
aufzustellen.


Parameter eines Gleises

alle Gleise:
Position x,y,z des Gleisanfangs [m]: Vektor[1]{x, y, z} / 100
Laenge [m]: Charakteristik.Laenge / 100
Kruemmung [°] des Gleises: math.deg( Charakteristik.Kruemmung * Charakteristik.Laenge )
Skalierung: _attr.scale
Gleisart: clsid
	['2E25C8E2-ADCD-469A-942E-7484556FF932'] = 'Normales Gleis',
	['C889EADB-63B5-44A2-AAB9-457424CFF15F'] = '2-Weg-Weiche',
	['B0818DD8-5DFD-409F-8022-993FD3C90759'] = '3-Weg-Weiche',
	['06D80C90-4E4B-469B-BFE0-509A573EBC99'] = 'Prellbock-Gleis'

weitere Felder (die jetzt noch nicht beruecksichtigt werden):
Anfangsfuehrungsverdrehung: Anfangsfuehrungsverdrehung.Wert
Fuehrungsverdrehung: Charakteristik.Fuehrungsverdrehung
Biegung: Charakteristik.Korve
Torsion: Charakteristik.Torsion

zusaetzlich bei 2-Weg-Weiche / 3-Weg-Weiche:
WeicheID: Key_Id
Stellung der Weiche: weichenstellung


Die Kruemmung eines Gleises wird im Bogenmass bezogen auf die Laenge normalisiert gespeichert:
Charakteristik.Kruemmung = math.rad( WinkelGrad ) / Laenge
bzw.
Winkel [°]:	deg( Charakteristik.Kruemmung * Charakteristik.Laenge )


Der normalisiert Winkel (des Gleisanfangs) auf der xy-Ebene sowie die normalisierte Steigung
wird in den weiteren Dreibein-Vektoren gespeichert, die damit eine 3x3 Matrix darstellen.

Mit solch einer Matrix lassen sich die Berechnungen fuer eine oder mehrerer Translationen (Verschiebungen), Skalierungen
oder Rotationen beschreiben und effizient ueber Matrixmultiplikationen berechnen.

http://www.mttcs.org/Skripte/Pra/Material/vorlesung3.pdf
https://www.tu-ilmenau.de/fileadmin/media/gdv/Lehre/Computergrafik_I/Uebung/gdv1gt.pdf

a) Translation (Verschiebung)

	1		0		Dx
	0		1		Dy
	0		0		1

Die Verschiebung wird in EEP nicht genutzt.

b) Skalierung

	Sx		0		0
	0		Sy		0
	0		0		1

Die Skalierung wird in EEP ueber ein separates Attribut dargestellt.

c) Rotation

Winkel des Gleises (= Drehung um die z-Achse)
Die Drehung eines Gleises auf der Ebene gegen den Uhrzeigersinn um den Winkel w wird mit einer Matrixmultiplikation berechnet:
Dies entspricht dem 2D-Fall (die drei Zeilen der Matrix entsprechen den Werten von Dir, Nor und Bin):
Drehung eines normalisierten Vektors r (mit der Laenge 1) um die z-Achse gegen den Uhrzeigersinn
um den Winkel w

	cos w	-sin w	0
	sin w	cos w	0
	0		0		1

Damit ergibt sich folgende Formel fuer den Endpunkt eines Gleises dessen Anfang auf x0, y0 liegt:
	x1 = x0 + l * cos( w )
	y1 = y0 + l * sin( w )

Steigung des Gleises (= Drehung um die y-Achse)
Drehung eines Vektors r um die y-Achse gegen den Uhrzeigersinn um den Winkel w

	cos w	0		sin w
	0		1		0
	-sin w	0		cos w

Verdrehung des Gleises
Drehung eines Vektors r um die x-Achse gegen den Uhrzeigersinn um den Winkel w

	1		0		0
	0		cos w	-sin w
	0		sin w	cos w

Wenn mehrere dieser Rotationen vorgenommen werden, dann werden die jeweiligen Matixen multipliziert.

Umrechnung der Rotationsmatrix in Winkel:
https://www.andre-gaschler.com/rotationconverter/
http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToMatrix/
http://web.cs.iastate.edu/~cs577/handouts/homogeneous-transform.pdf

Da in EEP anscheinend nur die Steigung und die Drehung in der Matrix abgebildet werden verwendet (und somit
genuegend 0-en und 1-en bei einer Matrixmultiplikation beteiligt sind) werden lassen sich die Werte fuer den
Winkel und die Steigung zumeist vereinfacht ablesen:

Winkel [rad]: 	acos( Vektor[3].y ) * sign( Vektor[2].y )
Steigung [rad]:	acos( Vektor[4].z ) * sign( Vektor[2].z )

Eine genauere Rechnug wuerde z.B. ueber die Diagonale der Roationsmatrix laufen (Vorzeichen wie oben korrigieren):
Winkel [rad]: 	acos( ( Vektor[2].x + Vektor[3].y + Vektor[z].z - 1) / 2 ) * sign( Vektor[2].z )

Fuer die Umrechnung zwischen Radius eines gebobenen Gleisen und dem Winkel gilt:
	r = l / rad( a )
	a = deg( l / r )

Fuer die Umrechnung der Steigung gilt:

	s = asin( sm / l )
	sm = l * sin( s )

--]]

-- Gleisattribute, linke Seite (in Klammern die Einheit)

	--	  Position des Gleisanfangs auf der Ebene [m]
	local x		= tonumber( xmlGleis.Dreibein.Vektor[1]._attr.x ) / 100
	local y		= tonumber( xmlGleis.Dreibein.Vektor[1]._attr.y ) / 100

	--	  absolute Hoehe des Gleisanfangs [m]
	local z		= tonumber( xmlGleis.Dreibein.Vektor[1]._attr.z ) / 100

	--	  relative Hoehe [m]
	local zr	= nil

	--	  Winkel der Drehung des Gleisanfangs um die Z-Achse gegen den Uhrzeigersinn [rad] (vereinfacht!!!)
	local wc 	= tonumber( xmlGleis.Dreibein.Vektor[3]._attr.y )	-- cos(w)
	local w		= math.acos( wc ) 									-- [rad]
				  * ( tonumber( xmlGleis.Dreibein.Vektor[2]._attr.y ) < 0 and -1 or 1 )

	--	  Skalierung, Faktor bezueglich der Laenge [dimensionslos]
	local f		= tonumber( xmlGleis._attr.scale )

-- Gleisattribute, rechte Seite

	--	  Laenge des Gleises [m]
	local L		= tonumber( xmlGleis.Charakteristik._attr.Laenge )	/ 100

	--	  Winkel der Kruemmung auf der Ebene gegen den Uhrzeigersinn [rad]
	local al	= tonumber( xmlGleis.Charakteristik._attr.Kruemmung ) * 100	-- normalisiert
	local a		= L * al											-- [rad]		-- a = 0 fuer gerade Gleise

	--	  Radius der Kruemmung auf der Ebene [m]
	local r		= (a ~= 0 and L / a or 0)	-- oder r = 1 / al						-- r = 0 fuer gerade Gleise

	--	  Steigung [rad] (vereinfacht!!!)
	local sc 	= tonumber( xmlGleis.Dreibein.Vektor[4]._attr.z ) 	-- cos(s)
	local s 	= math.acos( sc )									-- [rad]
				  * ( tonumber( xmlGleis.Dreibein.Vektor[2]._attr.z ) < 0 and -1 or 1 )

	--	  Steigung [m]
	local sm 	= L * math.asin( s )

-- vereinfachte 2D-Berechnung fuer das Gleisende

	--	  Abstand zwischen Anfangs- und Endpunkt eines gekruemmtes Gleises [m]
	local dx	= (a ~= 0 and r * math.sin( a )			or 0 )
	local dy	= (a ~= 0 and r * ( 1 - math.cos( a ))	or 0 )

	--	  effektive Laenge eines Gleises
	local d		= (a ~= 0 and math.sqrt( dx * dx + dy * dy ) or L)				-- d = L fuer gerade Gleise

	--	  Winkel zwischen Anfangs- und Endpunkt [m]								-- a = 0 fuer gerade Gleise
	local b		= a / 2 		-- bzw. asin( dy / d ) oder acos( dx / d )

	--	  Position des Gleisendes auf der Ebene unter Beruecksichtigung von Drehung und Kruemmung [m]
	local xe	= x + d * math.cos( w + b )
	local ye	= y + d * math.sin( w + b )

	--	  Winkel der Drehung des Gleisendes um die Z-Achse gegen den Uhrzeigersinn [rad]
	local we	= w + a


	local GleisID = tonumber(xmlGleis._attr.GleisID)

	local GleissystemID = Gleissystem.GleissystemID

	-- Felder von Gleissystem aktualisieren
	Gleissystem.Laenge 			= Gleissystem.Laenge + L
	Gleissystem.Anzahl.Gleise 	= Gleissystem.Anzahl.Gleise + 1

	if debug then
		print(
			'Gleis = ', GleisID, ' ',
			'x = ',  x,  ' ',
			'y = ',  y,  ' ',
			'L = ',  L,  ' ',
			'w = ',  w,  ' rad ', math.deg(w), ' grad ',
			'a = ',  a,  ' rad ', math.deg(a), ' grad ',
			'r = ',  r,  ' ',
			'dx = ', dx, ' ',
			'dy = ', dy, ' ',
			'd = ',  d,  ' ',
			'b = ',  b,  ' rad ', math.deg(b), ' grad ',
			'xe = ', xe, ' ',
			'ye = ', ye, ' ',
			'we = ', we, ' rad ', math.deg(we), ' grad '
		)
	end

	-- neues Gleis anlegen
	Gleise[GleissystemID][GleisID] = {
		Gleissystem		= Gleissystem,						-- Elternknoten
		GleisID			= GleisID,							-- Schluessel des aktuellen Eintrages

		Gleisart		= xmlGleis._attr.clsid,

		Laenge			= L,								-- [m]
		Position		= { x = x,  y = y,  z = z },		-- [m]
		PositionEnde	= { x = xe, y = ye, z = z },		-- [m] (z wird noch nicht berechnet)
		WinkelAnfang	= w,								-- [Bogenmass]
		WinkelEnde		= we,								-- [Bogenmass]
		Kruemmung 		= a,								-- [Bogenmass]
		Radius			= r, 								-- [m] (fuer gerades Gleis: 0)
		Steigung 		= s, 								-- [Bogenmass]

		WeicheID		= tonumber(xmlGleis._attr.Key_Id),		-- nil fuer normale Gleise
		Weichenstellung = tonumber(xmlGleis._attr.weichenstellung),
		KontaktZiel		= tonumber(xmlGleis.KontaktZiel),	-- Weichen sind potentielle Kontakt-Ziele

		Verbindung 		= {},								-- Verbindungen zu anderen Gleisen werden spaeter eingetragen
															-- siehe Funktion verbindeGleise
															-- es werden ggf. mehrere der folgenden Tabellen eingetragen:
															-- 	{ Anfang = Gleis, AnfangAnschluss = ... }
															-- 	{ Ende = Gleis, EndeAnschluss = ... }
															-- 	{ EndeAbzweig = Gleis, EndeAbzweigAnschluss = ... }
															-- 	{ EndeKoAbzweig = Gleis, EndeKoAbzweigAnschluss = ... }

		TipTxt			= xmlGleis._attr.TipTxt,			-- Tipp-Text (kann auch nil sein)
		--.. hier weitere Felder zu einem Gleis eintragen
	}
	local Gleis = Gleise[GleissystemID][GleisID]

	-- Kontakt-Ziel fuer Gleis/Weiche eintagen
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

	return Gleis										-- Elternknoten fuer die naechste Ebene
end

local function processKontakt(xmlKontakt, Gleis)
	if debug then print('processKontakt') end

	local KontaktID				= 0						-- keine KontaktID vorhanden (wird spaeter bestimmt)

	local GleisID				= Gleis.GleisID
	local GleissystemID			= Gleis.Gleissystem.GleissystemID
	local LuaFn     			= xmlKontakt._attr.LuaFn

	-- Felder von Gleissystem aktualisieren
	Gleise[GleissystemID].Anzahl.Kontakte = Gleise[GleissystemID].Anzahl.Kontakte + 1

	-- Die Position kann in grober Naeherung gleich der Anfangsposition des Gleises angenommen werden
	local  Position = Gleis.Position
	-- Ein verbesserte Position beruecksichtigt den Winkel des Gleises und die relative Position auf dem Gleis
	local relPosition = tonumber(xmlKontakt._attr.Position) / 100	-- Position relativ zum Gleisursprung [m]
	Position = {
		x = Gleis.Position.x + relPosition * math.cos( Gleis.WinkelAnfang ),
		y = Gleis.Position.y + relPosition * math.sin( Gleis.WinkelAnfang ),
		z = Gleis.Position.z,
	}

	-- erster Kontakt des Gleises
	if not Kontakte[GleissystemID][GleisID] then
		Kontakte[GleissystemID][GleisID] = {}
	end

	-- neuen Kontakt anlegen
	table.insert(
		Kontakte[GleissystemID][GleisID],
		{
			Gleis			= Gleis,					-- Elternknoten
			KontaktID		= KontaktID,				-- Schluessel des aktuellen Eintrages (vorlaeufig)

			Position 		= Position,							-- (berechnet/geschaetzt) [m]
			relPosition 	= relPosition,						-- Position relativ zum Gleisursprung [m]

			SetType			= tonumber(xmlKontakt._attr.SetType),		-- KontaktTyp (Bit-Vektor)
			SetValue		= xmlKontakt._attr.SetValue,		-- Interpretation je nach Kontakttyp

			Delay			= xmlKontakt._attr.Delay,			-- Startverzoegerung
			Group			= xmlKontakt._attr.Group,			-- Kontaktgruppe
			KontaktZiel		= tonumber(xmlKontakt._attr.KontaktZiel), 	-- Kontakt-Ziel des Kontaktes (kann auch nil sein)
			LuaFn			= ( LuaFn == '' and nil or LuaFn ),	-- Lua-Funktion (nur wenn nicht leer)
			clsid 			= xmlKontakt._attr.clsid,			-- konstanter Wert

			TipTxt			= xmlKontakt._attr.TipTxt,			-- Tipp-Text (kann auch nil sein)
			--.. hier weitere Felder zu einem Kontakt eintragen
		}
	)
	KontaktID = #Kontakte[GleissystemID][GleisID]			-- nun kann die KontaktID bestimmt werden
	local Kontakt = Kontakte[GleissystemID][GleisID][KontaktID]
	Kontakt.KontaktID = KontaktID							-- Schluessel des aktuellen Eintrages eintragen

	-- Kontakt-Ziel fuer Kontakt eintragen
	if Kontakt.KontaktZiel then
		-- Neues Kontakt-Ziel?
		if not KontaktZiele[Kontakt.KontaktZiel] then
			KontaktZiele[Kontakt.KontaktZiel] = {}
		end
		-- neuer Kontakt fuer Kontakt-Ziel?
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

	return Kontakt										-- Elternknoten fuer die naechste Ebene
end

local function processMeldung(xmlMeldung, Gleis)
	if debug then print('processMeldung') end

	local SignalID 		= tonumber(xmlMeldung._attr.Key_Id)

	local GleisID		= Gleis.GleisID
	local GleissystemID	= Gleis.Gleissystem.GleissystemID

	-- Felder von Gleissystem aktualisieren
	Gleise[GleissystemID].Anzahl.Signale = Gleise[GleissystemID].Anzahl.Signale + 1

	-- Die Position kann in grober Naeherung gleich der Anfangsposition des Gleises angenommen werden
	local  Position = Gleis.Position
	-- Ein verbesserte Position beruecksichtigt den Winkel des Gleises und die relative Position auf dem Gleis
	local relPosition = tonumber(xmlMeldung._attr.Position) / 100	-- Position relativ zum Gleisursprung [m]
	Position = {
		x = Gleis.Position.x + relPosition * math.cos( Gleis.WinkelAnfang ),
		y = Gleis.Position.y + relPosition * math.sin( Gleis.WinkelAnfang ),
		z = Gleis.Position.z,
	}

	-- neues Signal anlegen
	Signale[GleissystemID][SignalID] = {
		Gleis			= Gleis,							-- Elternknoten
		SignalID		= SignalID,							-- Schluessel des aktuellen Eintrages

		Position 		= Position,							-- (berechnet/geschaetzt) [m]
		relPosition 	= relPosition,						-- Position relativ zum Gleisursprung
		name			= xmlMeldung._attr.name,
		Stellung		= xmlMeldung.Signal._attr.stellung,
		KontaktZiel		= tonumber(xmlMeldung.KontaktZiel),	-- Signale sind potentielle Kontakt-Ziele

		TipTxt			= xmlMeldung._attr.TipTxt,			-- Tipp-Text (kann auch nil sein)
		--.. hier weitere Felder zu einem Signal eintragen
	}
	local Signal = Signale[GleissystemID][SignalID]

	-- Kontakt-Ziel fuer Signal eintragen
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

	return Signal										-- Elternknoten fuer die naechste Ebene
end


local function processFuhrpark(xmlFuhrpark, Parameters)
	if debug then print('processFuhrpark') end

	local FuhrparkID = tonumber(xmlFuhrpark._attr.FuhrparkID)

	-- neuen Fuhrpark anlegen
	Fuhrparks[FuhrparkID] = {
		--..											-- kein Elternknoten
		FuhrparkID		= FuhrparkID,					-- Schluessel des aktuellen Eintrages

		Anzahl 			= {
			Zugverbaende 	= 0,
			Rollmaterialien	= 0,
		},
		--.. hier weitere Felder zu einem Fuhrpark eintragen
	}
	local Fuhrpark = Fuhrparks[FuhrparkID]

	return Fuhrpark										-- Elternknoten fuer die naechste Ebene
end

local function processZugverband(xmlZugverband, Fuhrpark)
	if debug then print('processZugverband') end

	local ZugID 		= tonumber(xmlZugverband._attr.ZugID)

	local GleissystemID = tonumber(xmlZugverband.Gleisort._attr.gleissystemID)
	local GleisID       = tonumber(xmlZugverband.Gleisort._attr.gleisID)

	-- Felder des uebergeordneten Fuhrparks aktualisieren
	Fuhrpark.Anzahl.Zugverbaende = Fuhrpark.Anzahl.Zugverbaende + 1

	-- Felder des Gleissystems aktualisieren (das geht nur wenn das Gleissystem vor dem Fuhrpark verarbeitet wurde)
	Gleise[GleissystemID].Anzahl.Zugverbaende = Gleise[GleissystemID].Anzahl.Zugverbaende + 1

	-- neuen Zugverband anlegen
	Zugverbaende[ZugID] = {
		Fuhrpark		= Fuhrpark,							-- Elternknoten
		ZugID			= ZugID,							-- Schluessel des aktuellen Eintrages
		Gleis			= Gleise[GleissystemID][GleisID],	-- Querverweis auf das Gleis
		GleissystemID 	= GleissystemID,					-- kann auch ueber .Gleis.GleisID ermittelt werden
		GleisID 		= GleisID,							-- kann auch ueber .Gleis.Gleissystem.GleisID ermittelt werden

		name 			= xmlZugverband._attr.name,
		FuhrparkID      = Fuhrpark.FuhrparkID,
		Position 		= Gleise[GleissystemID][GleisID].Position,		-- Annahme: Zug steht am Enfang des Gleises
		Geschwindigkeit = tonumber(xmlZugverband._attr.Geschwindigkeit) * 3.6 , -- Umgerechnet in km/h
		Rollmaterialien = {},		-- Querverweise werden spaeter eingetragen
		--.. hier weitere Felder zu einem Zugverband eintragen
	}
	local Zugverband = Zugverbaende[ZugID]

	return Zugverband									-- Elternknoten fuer die naechste Ebene
end

local function processRollmaterial(xmlRollmaterial, Zugverband)
	if debug then print('processRollmaterial') end

	local name = xmlRollmaterial._attr.name

	local GleissystemID = Zugverband.GleissystemID

	-- Felder des zugehoerigen Fuhrparks aktualisieren
	Zugverband.Fuhrpark.Anzahl.Rollmaterialien = Zugverband.Fuhrpark.Anzahl.Rollmaterialien + 1

	-- Felder des Gleissystems aktualisieren
	Gleise[GleissystemID].Anzahl.Rollmaterialien = Gleise[GleissystemID].Anzahl.Rollmaterialien + 1

	-- neues Rollmaterial anlegen
	Rollmaterialien[name] = {
		Zugverband		= Zugverband,				-- Elternknoten
		name			= name,						-- Schluessel des aktuellen Eintrages

		typ 			= xmlRollmaterial._attr.typ,
		Zugmaschine 	= tableHasKey(xmlRollmaterial, 'Zugmaschine'),
		ZugID           = Zugverband.ZugID,			-- kann auch ueber .Zugverband.ZugID ermittelt werden
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

	return Rollmaterial									-- Elternknoten fuer die naechste Ebene
end


local function processGebaeudesammlung(xmlGebaeudesammlung, Parameters)
	if debug then print('processGebaeudesammlung') end

	local GebaeudesammlungID = tonumber(xmlGebaeudesammlung._attr.GebaudesammlungID)

	-- neue Gebaeudesammlung anlegen
	Immobilien[GebaeudesammlungID] = {
		--..											-- Elternknoten
		GebaeudesammlungID = GebaeudesammlungID,		-- Schluessel des aktuellen Eintrages

		Anzahl = 0,
		--.. hier weitere Felder zu einer Gebaeudesammlung eintragen
	}
	local Gebaeudesammlung = Immobilien[GebaeudesammlungID]

	return Gebaeudesammlung 							-- Elternknoten fuer die naechste Ebene
end

local function processImmobile(xmlImmobile, Gebaeudesammlung)
	if debug then print('processImmobile') end

	local ImmoIdx = tonumber(xmlImmobile._attr.ImmoIdx)

	-- Felder der uebergeordneten Gebaeudesammlung aktualisieren
	Gebaeudesammlung.Anzahl = Gebaeudesammlung.Anzahl + 1

	-- neue Immobilie anlegen
	Gebaeudesammlung[ImmoIdx] = {
		Gebaeudesammlung = Gebaeudesammlung,			-- Elternknoten
		ImmoIdx  		 = ImmoIdx,						-- Schluessel des aktuellen Eintrages

		Position = {
			x = tonumber(xmlImmobile.Dreibein.Vektor[1]._attr.x) / 100,
			y = tonumber(xmlImmobile.Dreibein.Vektor[1]._attr.y) / 100,
			z = tonumber(xmlImmobile.Dreibein.Vektor[1]._attr.z) / 100,
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

	return Immobilie									-- Elternknoten fuer die naechste Ebene
end


local function processOptions(xmlOptions, Parameters)
	if debug then print('processOptions') end

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

local function processGleisverbindung(xmlGleisverbindung, Gleissystem)
	if debug then print('processGleisverbindung') end

	-- Attribute: GleisID1, Anschluss1, GleisID2, Anschluss2
	-- Werte fuer Anschluss: Anfang, Ende, EndeAbzweig, EndeKoAbzweig

	-- neues Gleissystem?
	if not Gleisverbindungen[Gleissystem.GleissystemID] then Gleisverbindungen[Gleissystem.GleissystemID] = {} end

	-- Sammle Verbindungen
	table.insert(
		Gleisverbindungen[Gleissystem.GleissystemID],
		{
			GleisID1 			= tonumber(xmlGleisverbindung._attr.GleisID1),
			Anschluss1			= xmlGleisverbindung._attr.Anschluss1,
			GleisID2 			= tonumber(xmlGleisverbindung._attr.GleisID2),
			Anschluss2			= xmlGleisverbindung._attr.Anschluss2,
			Flags				= tonumber(xmlGleisverbindung._attr.Flags),		-- 1 = virtuelle Gleisverbindung
		}
	)

	return Gleisverbindungen[Gleissystem.GleissystemID]
end

local function verbindeGleise()
	-- Erst nachdem alle Tokens verarbeitet wurden, koennen mit dieser Funktion
	-- die Verweise zwischen verbundenen Gleisen eingetragen werden

	local function verbindeGleis(GleisA, AnschlussA, GleisB, AnschlussB, Flags)
		-- Die Gleisverbindung wird in beiden Richtugen bei den Gleisen eingetragen.
		-- Diese lokale Funktion macht das fuer jeweils eine Richtung

		-- neue Verbindung
		if not GleisA.Verbindung then GleisA.Verbindung = {} end

		-- Verbindung eintragen
		if	   AnschlussA == 'Anfang' 		 	then
			table.insert(GleisA.Verbindung,
				{
					Anfang					= GleisB,			-- das andere Gleis eintragen
					AnfangAnschluss			= AnschlussB,		-- den Anschluss des anderen Gleises eintragen
					Virtuell				= Flags == 1,
				}
			)

		elseif AnschlussA == 'Ende' 			then
			table.insert(GleisA.Verbindung,
				{
					Ende					= GleisB,
					EndeAnschluss			= AnschlussB,
					Virtuell				= Flags == 1,
				}
			)

		elseif AnschlussA == 'EndeAbzweig' 		then
			table.insert(GleisA.Verbindung,
				{
					EndeAbzweig				= GleisB,
					EndeAbzweigAnschluss	= AnschlussB,
					Virtuell				= Flags == 1,
				}
			)

		elseif AnschlussA == 'EndeKoAbzweig' 	then
			table.insert(GleisA.Verbindung,
				{
					EndeKoAbzweig			= GleisB,
					EndeKoAbzweigAnschluss	= AnschlussB,
					Virtuell				= Flags == 1,
				}
			)

		else
			print('Fehler: Anschluss=', AnschlussA, ' nicht bekannt')

		end
	end -- function verbindeGleis

	if debug then print('verbindeGleise') end

	for GleissystemID, Gleissystem in pairs(Gleisverbindungen) do

		for key, Gleisverbindung in pairs(Gleissystem) do

			if debug then
				print(
					  'GleissystemID=',	GleissystemID, 	' '
					, 'key=', 			key, 		' '
					, 'GleisID1=', 		Gleisverbindung.GleisID1, 			' '
					, 'Anschluss1=', 	Gleisverbindung.Anschluss1, 		' '
					, 'GleisID2=', 		Gleisverbindung.GleisID2, 			' '
					, 'Anschluss2=', 	Gleisverbindung.Anschluss2, 		' '
					, ( Gleisverbindung.Flags == 1 and 'virtuell' or ''), 	' '
				)
			end

			-- verbinde Gleise 1->2
			verbindeGleis(
				Gleise[GleissystemID][Gleisverbindung.GleisID1],
				Gleisverbindung.Anschluss1,
				Gleise[GleissystemID][Gleisverbindung.GleisID2],
				Gleisverbindung.Anschluss2,
				Gleisverbindung.Flags								-- 1: virtueller Anschluss
			)

			-- verbinde Gleise 2->1
			verbindeGleis(
				Gleise[GleissystemID][Gleisverbindung.GleisID2],
				Gleisverbindung.Anschluss2,
				Gleise[GleissystemID][Gleisverbindung.GleisID1],
				Gleisverbindung.Anschluss1,
				Gleisverbindung.Flags								-- 1: virtueller Anschluss
			)

		end
	end

end -- function verbindeGleise

-- Aufrufhierarchie der zu verarbeitenden Token gemaess XML-Struktur, optional mit Funktionen, die die einzelnen Token verarbeiten
local xmlHierarchy = {				_Call = nil,
	sutrackp = {					_Call = processSutrackp,
		Gleissystem = {				_Call = processGleissystem,
			Gleis = {				_Call = processGleis,
				Kontakt = { 		_Call = processKontakt 			},
				Meldung = { 		_Call = processMeldung 			},
			},
			Gleisverbindung = {		_Call = processGleisverbindung,	},
		},
		Fuhrpark = {				_Call = processFuhrpark,
			Zugverband = {			_Call = processZugverband,
				Rollmaterial = { 	_Call = processRollmaterial 	},
			},
		},
		Gebaeudesammlung = {		_Call = processGebaeudesammlung,
			Immobile = { 			_Call = processImmobile 		},
		},
		Options = { 				_Call = processOptions 			},
	},
}

-- Rahmenprogramm zur Verarbeitumng der XML-Tokens
local function processToken(
		Name,					-- Name des aktuellen Tokens (wird nur fuer Dubugging benoetigt)
		Token, 					-- aktuelles Token in xml-Tabelle
		xmlHierarchy,			-- aktuelle Position in Aufrufhierarchie
		Parameters				-- Ergebnis der Verarbeitung des aktuellen Tokens zur Übergabe an darunter liegende Tokens
	)

	-- Did we got a value instead of a table? This should not happen!
	if type(Token) ~= 'table' then
		print('Error: ', 'Name=', Name, 'Token=', Token, ' ', type(Token))
		return nil
	end

	if debug then
		print('')
		print('Name=', Name, ' ', type(Token))
		print('  Call=', type(xmlHierarchy._Call))
		for key, value in pairs(xmlHierarchy) do
			if key ~= '_Call' then
				print('  Next=', key)
			end
		end
	end

	-- mehrfaches Token (mit numerischen Schluessel) auf gleicher Ebene verarbeiten
	local multiple_token = false
	for key, value in ipairs(Token) do
		if debug then print('= ', Name, '[', key, ']') end

		multiple_token = true
		processToken(Name, value, xmlHierarchy, Parameters)
	end
	if multiple_token == false then

		-- einzelnes Token verarbeiten
		local Results = Parameters
		if xmlHierarchy._Call and type(xmlHierarchy._Call) == 'function' then
			if debug then
				print('= ', Name, ' Call')
				for key, value in pairs(Token) do
					print('  Sub=', key)
				end
			end

			Results = xmlHierarchy._Call(Token, Parameters)
		end

		-- Token der naechsten Ebene verarbeiten
		-- Problem: Das Gleissystem muss vor dem Fuhrpark verarbeitet werden
		local key_Gleissystem = "Gleissystem"
		if Token[key_Gleissystem] then -- Gleissystem vorab verarbeiten
			if debug then print('Token.Gleissystem gefunden') end
			
			local NextName = key_Gleissystem
			local value = Token[key_Gleissystem] 
			if xmlHierarchy[NextName] then -- passt das Token?
				if debug then print('> ', NextName, ' ', type(xmlHierarchy[NextName])) end

				processToken(NextName, value, xmlHierarchy[NextName], Results)
			end
		end
		for NextName, value in pairs(Token) do
			if NextName ~= key_Gleissystem then -- Gleissystem wurde vorab verarbeitet
				if xmlHierarchy[NextName] then -- passt das Token?
					if debug then print('> ', NextName, ' ', type(xmlHierarchy[NextName])) end

					processToken(NextName, value, xmlHierarchy[NextName], Results)
				end
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

	-- Uebertrage die Gleisverbindungen in die Gleise
	-- Erst nachdem alle Tokens verarbeitet wurden, koennen mit dieser Funktion
	-- die Verweise zwischen verbundenen Gleisen eingetragen werden
	verbindeGleise()

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



-- Oeffentliche Schnittstelle des Moduls -------------------------------

EEP2Lua._VERSION 				= "2022-01-03"

-- Extended log
EEP2Lua.debug					= debug

-- Laufzeit in Sekunden fuer { LoadFile, Parser, Process, Total }
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

return function (options)
		-- Erweiterte Protokollausgabe
		debug = options and options.debug or false

		return EEP2Lua
	end
