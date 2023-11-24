# EEP Eisenbahn Simulation

EEP Anlagen, Lua-Bibliotheken und Tipps&amp;Tricks

Programm: <https://eepshopping.de/>  
Forum: <https://www.eepforum.de/>

## Modul `ShowGlobalVariables`

Bei der Entwicklung von Modulen passiert es leicht, dass Variablen oder Funktionen global definiert werden obwohl sie lokal sein sollten.
Zumeist funktioniert das Skript dann trotzdem wie erwartet, so dass dieser Fehler nur schlecht auffällt.

Das Modul [`ShowGlobalVariables.lua`](https://raw.githubusercontent.com/FrankBuchholz/EEP/master/ShowGlobalVariables.lua) zeigt globale Variablen und globale Funktionen.
Die bekannten Namen aus EEP bzw. von Lua können unterdrückt werden, so dass man nur die selbst definierten Namen erhält.

Verwendung:

``` lua
local ShowGlobalVariables = require('ShowGlobalVariables')
ShowGlobalVariables()  -- Unterdrücke bekannte Namen
ShowGlobalVariables(true) -- Zeige alle Namen
```

## Modul `GetEEPversion`

Bestimmt die Version von EEP incl. des installierten Plugins.

Verwendung:

``` lua
print("EEP Version: ", require("GetEEPversion") )
```

oder

``` lua
local EEPversion = require("GetEEPversion")
print("EEP Version: ", EEPversion )
```

## Module `EEP2Lua`

Es ist mit Lua möglich, eine EEP-Anlagedatei zu lesen und zu analysieren. Dazu dient das Modul `EEP2Lua`, das die xml-Datenstruktur einer Anlagedatei in Lua-Tabellen umwandelt. Das Modul `EEP_Inventar` ist ein Beispiel, wie man diese Lua-Tabellen nutzen kann. Beide Module können sowohl in einem EEP-Skript wie auch standalone genutzt werden.

_Achtung: Das neue Gleissystem ab EEP 16 wird nicht unterstützt!_

### Installation von `EEP2Lua`

Die Datei `EEP2Lua.lua` wird in das Lua-Verzeichnis kopiert.
Weiterhin benötigt das Modul Teile des Paketes `xml2lua` von <https://github.com/manoelcampos/xml2lua>.
Dazu legt man im Lua-Verzeichnis einen Ordner `xml2lua` an und kopiert dort zumindest folgende Dateien hinein:
`xml2lua.lua`
`XmlParser.lua`
`xmlhandler/tree.lua`

Alternativ kann man mit dem `cmd`-Befehl `mklink /d` eine symbolische Verzeichnisverknüfung auf den entspechenden Github-Ordner anlegen.

### Aufruf von `EEP2Lua`

``` lua
--local Anlage = require("EEP2Lua"){ debug = false } -- mit erweiterter Protokollanzeige
local Anlage = require("EEP2Lua"){}
local sutrackp = Anlage.loadFile(input_file)
```

Der optionale Rueckgabewert `sutrackp` enthält die Tabellenstruktur in der Form wie sie das Modul `xml2lua` liefert.

Nach dem Aufruf der Funktion `loadFile` können aufbereitete Informationen zur EEP-Anlage abgefragt werden:
`Anlage.Beschreibung`
`Anlage.GleissystemText`
`Anlage.Zugverbaende`
`Anlage.Rollmaterialien`
usw.

Die Feldliste entnimmt man am Besten dem Modul selber.

## Modul `EEP_Inventar`

Als ein Beispiel, was man mit dem Modul `EEP2Lua` anfangen kann, dient das Modul `EEP_Inventar`, das verschiedene Informationen zu Gleisen, Kontakten, Signalen, Zugverbänden und verwendeten Dateien anzeigt. Dieses Modul kann z.B. so verwendet werden:

``` lua
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
```

Die Funktionsliste neben `printInventar` entnimmt man am Besten dem Modul selber.

Wenn man diese Module für die aktuell in EEP geladene Anlage nutzen will, dann benötigt man einen Trick, um den Namen der Datei zu erhalten. Das kann dann z.B. so aussehen:

``` lua
function EEPOnSaveAnl(Anlagenpfad)
    print("Die Anlage wurde unter "..Anlagenpfad.." gespeichert!")

    -- Zeige das Inventar dieser Anlage nachdem sie gesichert wurde
    if printInventarAfterSave == true then
        printInventar(Anlagenpfad)
        printInventarAfterSave = false
    end
end

function printInventar(inputFile, debug)
    -- Die Laufzeit des EEP-Inventar-Programmes kann recht lang sein, daher wird EEP währenddessen pausiert
    print(EEPPause(1) == 1 and "EEP pausiert" or "EEP läuft")

    EEP_Inventar = require('EEP_Inventar'){ inputFile = inputFile }

    -- Alles anzeigen
    EEP_Inventar.printInventar()

    -- EEP wieder starten
    print(EEPPause(0) == 1 and "EEP pausiert" or "EEP läuft")
end

print("Zeige das Inventar dieser Anlage sobald sie gesichert wird")
printInventarAfterSave = true
```

## Notepad++ - Text-Editor (für Lua)

### User defined language EEP_Lua

Installation: Kopiere die Datei [`EEP_Lua.xml`](https://raw.githubusercontent.com/FrankBuchholz/EEP/master/EEP_Lua.xml) in den entsprechenden Roaming-Ordner:  
`C:\Users\<user>\AppData\Roaming\Notepad++\userDefineLang.xml`  
Zur Installation öffnet man Notepad++, klickt dort auf den Reiter "Sprache". Im sich öffnenden Fenster scrollt man ganz nach unten. Unterhalb der Trennlinie klickt man auf "Verzeichnis mit benutzerdefinierten Sprachen öffnen ...". Es öffnet sich der Windows-Explorer mit dem entsprechenden Verzeichnis (in der Regel: C:\<Users(Benutzer)>\AppData\Roaming\Notpad++\userDefineLangs). Hierein kopiert man die Datei EEP_Lua.xml.  
Nach dem Schließen des Windows-Explorers öffnet man erneut Notepad++, klickt auf den Reiter "Sprache" und scrollt wiederum ans Ende des Fensters. Hier befindet sich unterhalb der Trennlinie ein Eintrag "EEP_Lua". Den wählt man durch Anklicken aus.  
Wer lieber andere Farben und/oder Schriftstile zur Hervorhebung hätte und sich traut das Skript zu ändern findet unter https://npp-user-manual.org/do…-defined-language-system/ eine Anleitung in englischer Sprache.  

### Auto-completion

Installation: Kopiere bzw. ersetze die Datei [`lua.xml`](https://raw.githubusercontent.com/FrankBuchholz/EEP/master/lua.xml) im Programm-Ordner:  
`C:\Program Files\Notepad++\autoCompletion\lua.xml`  

## foxe - XML-Editor

Im Prinzip kann man auch eine Anlage-Dateien mit Notepad++ bearbeiten, allerdings ist es deutlich besser dafür den [foxe XML-Editor](http://www.firstobject.com/dn_editor.htm) zu verwenden.  
Dieses Programm ist auch bei großen Anlage-Dateien sehr schnell.  

Mit `Tools -> Indent (F8)` kann man die xml-Daten auf der rechten Seite formatieren.  

Mit `Refresh (F5)` kann man in der Navigation links denjenigen Eintrag aufrufen zu dem rechts gerade der Cursor steht.
  
Werte ändern (Sicherungskopie nicht vergessen!) macht man am Besten in der Navigation links, denn dort kann man gezielt nur Werte ansprechen und nicht so leicht aus Versehen auch die XML-Struktur beeinflussen.  

Über `Tools -> Preferences -> Tree customization` kann man die Zusatzinformationen in der Navigationsansicht auf der linken Seite konfigurieren (siehe [Tree customization](http://www.firstobject.com/tree-customization-in-xml-editor.htm)). Dazu kann der Inhalt der Datei  [`foxePreferences`](https://github.com/FrankBuchholz/EEP/blob/master/foxePreferences) verwendet werden.  

## Debugging

### Zeige Reihenfolge der geladenen Module

Wenn man mehrere Module läd möchte man evt. wissen, wann welches Modul zum ersten Mal geladen wird. Dazu kann man folgende erste Zeile in jedes Modul eintragen:

`if debugInfo then print("Loading " .. debug.getinfo(1,"S").source) end`

Einschränkung: Es ist so nicht möglich, zu sehen wann welche Module mehrfach geladen werden.

### Stack trace

Der Stack-Trace wird mit folgender Funktion angezeigt:

`print(debug.traceback("Stack trace", 1)) -- starting with level 1`

## Lua-Tipps

### Zeige Info-Texte für Signale oder Weichen

Zur Anzeige von Info-Texten dient der Aufruf von showInfoTexts(true/false) in EEPMain.

``` lua
Signale = {} -- Liste der Signal-Nummern
Weichen = {} -- Liste der Weichen-Nummern 
function showInfoTexts(status)
  -- Performanceoptimierung: Speichere existierenede Signal- und Weichennummern, um genau diese später ansprechen zu können
  if #Signale == 0 or #Weichen == 0 then -- Wurden bereits Signale oder Weichen gefunden?
    -- Initialisierung  (einmalig)
    for nr = 1, 9999 do 
      if EEPGetSignal(nr) > 0 then
        table.insert(Signale, nr) -- Signal gefunden
      end  
      if EEPGetSwitch(nr) > 0 then
        table.insert(Weichen, nr) -- Weiche gefunden
      end  
    end  
  end

  -- Aktualisierung (regelmäßig in EEPMain)
    if status == true then
        for nr in pairs(Signale) do
          -- Verwendung von string.format um eine Zahl ohne Nachkommastellen anzuzeigen
          EEPChangeInfoSignal(nr, "<b><bgrgb=0,190,190>Signal "..nr..": "..string.format("%d", EEPGetSignal(nr)) )
          EEPShowInfoSignal(nr, true) 
        end
        for nr in pairs(Weichen) do
          -- Alternative Verwendung von string.format um den gesamten Text mit mehreren Variablen zu formatieren
          EEPChangeInfoSwitch(nr, string.format( "<b><bgrgb=200,150,230>Weiche %d: %d",
            nr, -- Erste Variable, die mit dem ersten %d formatiert wird
            EEPGetSwitch(nr) -- Zweite Variable, die mit dem zweiten %d formatiert wird
          ))
          EEPShowInfoSwitch(nr, true) 
        end
    else
        for nr in pairs(Signale) do
          EEPShowInfoSignal(nr, false)
    end  
        for nr in pairs(Weichen) do
          EEPShowInfoSwitch(nr, false)
        end
    end
end
```
