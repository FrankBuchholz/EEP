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

## Module `EEP2Lua` / `EEP_Inventar`

Es ist mit Lua möglich, eine EEP-Anlagedatei zu lesen und zu analysieren. Dazu dient das Modul `EEP2Lua`, das die xml-Datenstruktur einer Anlagedatei in Lua-Tabellen umwandelt. Das Modul `EEP_Inventar` ist ein Beispiel, wie man diese Lua-Tabellen nutzen kann.  Beide Module können sowohl in einem EEP-Skipt wie auch standalone genutzt werden.

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

## Notepad++ - Text-Editor (für Lua)

### User defined language EEP_Lua

Installation: Kopiere die Datei [`userDefineLang.xml`](https://raw.githubusercontent.com/FrankBuchholz/EEP/master/userDefineLang.xml) in den entsprechenden Roaming-Ordner:  
`C:\Users\<user>\AppData\Roaming\Notepad++\userDefineLang.xml`  
Wenn dort bereits eine Datei mit benutzerdefinierten Sprachen liegt, dann kopiert man stattdessen das Token `<UserLang name="EEP_Lua">...</UserLang>` in diese vorhandene Datei.  

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
