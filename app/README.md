# Familienzentrum Lank

Die Kita-App fürs Familienzentrum Lank: ein Aktuelles-Feed, Gruppen-Feeds
(Blau/Gelb/Rot), Eltern-Chat, Spielanfragen zwischen Familien, ein
Team/Leitung-Bereich fürs Kita-Personal und ein Admin-Panel. Invite-only
Registrierung per Zugangscode — kein offenes Sign-up.

Neuaufbau als natives **Flutter**-Projekt (iOS/Android/Web aus einer
Codebasis) mit **Supabase** als Backend (Postgres + Auth + Realtime +
Storage + Edge Functions), als Ersatz für einen früheren React-Native/
Firebase-Prototyp mit demselben [Nocturne-Design](../project/Familienzentrum%20App.dc.html).

## Tech-Stack

- **Flutter** (Dart) — `lib/screens` für die Screens, `lib/widgets` für die
  wiederverwendeten Nocturne-Komponenten (`NButton`, `NCard`, `NTag`, …),
  `lib/theme/tokens.dart` für die 1:1 aus dem Design übernommenen Farben/
  Abstände/Radien.
- **go_router** — Auth-gated Routing, rollenabhängige Bottom-Tab-Shell
  (Eltern sehen "Spielen", Kita-Team sieht "Team" statt dessen).
- **flutter_riverpod** — State-Management; `lib/state/providers.dart`
  bündelt alle Supabase-Realtime-Streams als Provider.
- **Supabase** — Postgres-Schema + Row-Level-Security in
  `supabase/migrations/`, zwei Edge Functions in `supabase/functions/`.

## Setup

### 1. Flutter SDK

```bash
flutter --version   # 3.35+ empfohlen
flutter pub get
```

### 2. Supabase-Projekt

Lokales Supabase per Docker ist hier nicht Voraussetzung — die App zielt
auf ein echtes (kostenloses) Projekt auf [supabase.com](https://supabase.com):

1. Projekt anlegen.
2. Schema einspielen — entweder die drei Dateien in `supabase/migrations/`
   nacheinander in den SQL-Editor des Projekts einfügen, oder mit der
   Supabase-CLI:
   ```bash
   supabase link --project-ref <dein-projekt-ref>
   supabase db push
   ```
3. Edge Functions deployen (Service-Role-Key wird von Supabase automatisch
   als `SUPABASE_SERVICE_ROLE_KEY` in die Functions injiziert):
   ```bash
   supabase functions deploy redeem-invite --no-verify-jwt
   supabase functions deploy admin-set-user-disabled
   supabase functions deploy admin-delete-user
   ```
4. `.env` anlegen (siehe `.env.example`) mit Project-URL und **anon key**
   aus den Projekteinstellungen (Settings → API).

### 3. Demo-Daten seeden (optional)

```bash
SUPABASE_URL=https://xxxx.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=eyJ... \
dart run scripts/seed.dart
```

Legt Gruppen, Familien, Kinder, Beispiel-Posts, einen Speiseplan und
Demo-Logins an (siehe Skript-Ausgabe für die Zugangsdaten) — inklusive
eines noch nicht eingelösten Einladungscodes, um den Registrierungs-Flow
zu testen.

### 4. App starten

```bash
flutter run -d chrome     # Web
flutter run                # verbundenes Gerät/Simulator
```

## Wie die Anmeldung funktioniert

Es gibt keine offene Registrierung. Eine Familie oder ein Teammitglied
bekommt vom Admin-Panel aus eine Einladung (E-Mail + Rolle) — das System
generiert einen Zugangscode. Beim ersten Login mit E-Mail + Code prüft
`AuthService.signInWithAccessCode`:

1. Normaler Login-Versuch (`signInWithPassword`) — funktioniert für
   wiederkehrende Nutzer:innen.
2. Schlägt der fehl, ruft die App die Edge Function `redeem-invite` auf,
   die serverseitig (mit dem Service-Role-Key, der nie im Client landet)
   den Zugangscode prüft, das Auth-Konto anlegt (Passwort = Zugangscode)
   und das zugehörige Profil erstellt.
3. Danach greift der normale Login.

Die `invites`-Tabelle selbst ist für niemanden außer Admins lesbar — die
Einlösung läuft ausschließlich über die Edge Function.

## Admin-Panel

Erreichbar über den Team-Tab (nur für `is_admin`-Profile sichtbar):
Einladungen erstellen/verwalten, Familien & Kinder, Team-Rollen &
Admin-Rechte (inkl. Konto sperren/löschen über die beiden
Admin-Edge-Functions), Inhalte (Termine, Schließtage, Dokumente,
Speiseplan), Krankmeldungen.

## Bekannte Lücken

- Foto-Uploads gehen in den `post-photos`-Storage-Bucket, es gibt aber
  noch keine Bildkomprimierung/Thumbnails.
- Mitteilungen ist eine aus Posts/Spielanfragen abgeleitete Ansicht, keine
  eigene Notifications-Tabelle — reicht für den Alltag, aber kein
  Push-Notification-System.
- Kein automatisierter Test-Suite; Verifikation bisher über
  `flutter analyze` + einen manuellen Web-Build-Check.
