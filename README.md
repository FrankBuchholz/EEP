# EEP Eisenbahn Simulation
EEP Anlagen, Lua-Bibliotheken und Tipps&amp;Tricks

Programm: https://eepshopping.de/  
Forum: https://www.eepforum.de/

## Notepad++ - Text-Editor (für Lua)

### User defined language EEP_Lua
Take file `userDefineLang.xml` and put it into roaming location:  
`C:\Users\<user>\AppData\Roaming\Notepad++\userDefineLang.xml`  
If you already work with user defined languages, then merge token `<UserLang name="EEP_Lua">...</UserLang>` into your existing file.  

### Auto-completion
Take file `lua.xml` and replace existing file in the program folder:  
`C:\Program Files\Notepad++\autoCompletion\lua.xml`  


## foxe - XML-Editor

Im Prinzip kann man auch Anlage-Dateien mit Notepad++ bearbeiten, allerdings es es deutlich bessen den foxe XML-Editor von http://www.firstobject.com/dn_editor.htm zu verwenden.  
Dieses Programm ist auch bei großen Anlage-Dateien sehr schnell.  
Mit `Tools -> Indent (F8)` kann man die xml-Daten schön formatieren.  
Mit `Refresh (F5)` kann man in der Navigation links denjenigen Eintrag aufklappen wo rechts gerade der Cursor steht.  
Werte ändern (nachdem man natürlich eine Sicherungskopie gemacht hat) macht man am Besten in der Navigation links, denn dort kann man gezielt nur Werte ansprechen und nicht so leicht aus Versehen auch die XML-Struktur beeinflussen.  
Über `Tools -> Preferences -> Tree customization` kann man die Zusatzinformationen in der Navigationsansicht auf der linken Seite kofigurieren (siehe http://www.firstobject.com/tre…ization-in-xml-editor.htm). Ein Beispiel dazu ist in der Datei `foxePreferences` zu finden.
