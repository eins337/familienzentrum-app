# Kindergarten Social-Media-App

_Started 2026-09-09 12:35 UTC_

---

## User

ich möchte eine App für unseren Kindergarten erstellen welche wie social media funktioniert, ich möchte dass der Kindergarten seine posts und infos erstellen kann, dann möchte ich gruppen für die Gruppen der Kinder haben: Blau, Gelb, Rot.  zusätzlich sollen die eltern untereinander chatten können, und mann soll spielanfragen stellen können sodass die eltern die kinder verabreden können. mache erst nur das design die funktionen mach ich später mit claude code.

## Assistant



## User

Answered — platform: Handy (iOS-Rahmen); screens: Feed (Startseite), Gruppen-Feed (Blau/Gelb/Rot), Post erstellen (Kindergarten), Eltern-Chat Liste, Chat-Verlauf, Spielanfragen-Übersicht, Spielanfrage erstellen, Kind-/Familienprofil, Infos & Termine…; roles: Beides, mit Rollen-Umschalter im Prototyp; playdate: Direkte Anfrage an eine bestimmte Familie, Terminvorschläge mit Zu-/Absage; privacy: Sichtbarkeits-Badge pro Post (Gruppe / alle / privat), Foto-Freigabe-Hinweis bei Bildern; feed_content: Fotos vom Alltag, Wochenrückblick / Text, Termine & Erinnerungen, Speiseplan, Krankmeldung-Hinweis…

## Assistant

Bevor ich baue, ein paar Fragen — alles Überspringbare entscheide ich selbst.

_[tool: ask_user]_

_[tool: list_files]_

_[tool: read_file]_

_[tool: read_file]_

_[tool: read_file]_

_[tool: copy_starter_component]_

_[tool: copy_starter_component]_

_[tool: grep]_

_[tool: read_file]_

_[tool: dc_write]_

Deine Antworten passen zum begonnenen Aufbau — ich baue jetzt alle 12 Screens durch.

_[tool: dc_write]_

_[tool: dc_js_str_replace]_

_[tool: ready_for_verification]_

Der klickbare Prototyp steht — im Nocturne-Look, iPhone-Rahmen, Rollen-Umschalter (Eltern / Kita-Team) über dem Gerät.

Enthalten: Anmelden, Aktuelles-Feed (Elternbrief, Foto-Post mit Sichtbarkeits-Badge, Helfer-Umfrage, Termin, Krankmeldungs-Hinweis, Speiseplan), Gruppen Blau/Gelb/Rot mit eigenem Feed und Team, Beitrag erstellen (Team-Rolle) mit Sichtbarkeitswahl und Fotofreigabe-Warnung, Chatliste + Chatverlauf mit Spielanfrage-Karte, Spielanfragen-Übersicht mit Terminvorschlägen und Zu-/Absage, Spielanfrage erstellen, Familienprofil, Infos & Termine, Mitteilungen, Einstellungen sowie ein Krankmeldungs-Sheet.

Fotos sind Platzhalter — du kannst echte Bilder direkt hineinziehen. Sag mir, welche Screens du inhaltlich noch anders brauchst.

## User

Found issues — fixing…

## Assistant

_[tool: dc_html_str_replace]_

_[tool: dc_html_str_replace]_

_[tool: ready_for_verification]_

