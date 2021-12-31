# EEP Eisenbahn Simulation

EEP Anlagen, Lua-Bibliotheken und Tipps&amp;Tricks

Programm: <https://eepshopping.de/>  
Forum: <https://www.eepforum.de/>

## Module `ShowGlobalVariables`

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
