// Seeds demo data into a Supabase project: run the migrations first
// (supabase db push, or paste the SQL files into the SQL editor), then:
//
//   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_SERVICE_ROLE_KEY=... dart run scripts/seed.dart
//
// Uses only dart:io/dart:convert (no pub deps) so it runs with the Dart SDK
// bundled in the Flutter SDK, no extra `pub get` needed. Talks to Supabase's
// REST (PostgREST) and Auth Admin APIs directly with the service role key,
// which bypasses RLS — this script is meant to run once, locally, never
// shipped with the app.

import 'dart:convert';
import 'dart:io';

late final String supabaseUrl;
late final String serviceKey;
final _client = HttpClient();

Future<void> main() async {
  supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  serviceKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  if (supabaseUrl.isEmpty || serviceKey.isEmpty) {
    stderr.writeln('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY first.');
    exit(1);
  }

  print('Creating groups…');
  await upsert('groups', [
    {'id': 'blau', 'name': 'Blau', 'color': '#7f93c9', 'child_count': 18},
    {'id': 'gelb', 'name': 'Gelb', 'color': '#c9b47f', 'child_count': 16},
    {'id': 'rot', 'name': 'Rot', 'color': '#c98b8b', 'child_count': 21},
  ]);

  await upsert('group_team_members', [
    {'group_id': 'blau', 'name': 'Frau Özdemir', 'title': 'Gruppenleitung', 'sort_order': 0},
    {'group_id': 'blau', 'name': 'Herr Klein', 'title': 'Fachkraft', 'sort_order': 1},
    {'group_id': 'gelb', 'name': 'Frau Bergmann', 'title': 'Gruppenleitung', 'sort_order': 0},
    {'group_id': 'gelb', 'name': 'Frau Lohmann', 'title': 'Fachkraft', 'sort_order': 1},
    {'group_id': 'rot', 'name': 'Frau Haas', 'title': 'Gruppenleitung', 'sort_order': 0},
    {'group_id': 'rot', 'name': 'Frau Nowak', 'title': 'Fachkraft', 'sort_order': 1},
  ]);

  print('Creating families…');
  final familyWeber = await insertOne('families', {'name': 'Familie Weber'});
  final familyKaya = await insertOne('families', {'name': 'Familie Kaya'});
  final familySchmidt = await insertOne('families', {'name': 'Familie Schmidt'});
  final familyBrand = await insertOne('families', {'name': 'Familie Brand'});

  print('Creating auth users + profiles…');
  final sandra = await createUserWithProfile(
    email: 'sandra.weber@example.de',
    password: 'LANK-2026',
    displayName: 'Sandra Weber',
    role: 'parent',
    familyId: familyWeber['id'],
  );
  final kaya = await createUserWithProfile(
    email: 'familie.kaya@example.de',
    password: 'LANK-2026',
    displayName: 'Familie Kaya',
    role: 'parent',
    familyId: familyKaya['id'],
  );
  await createUserWithProfile(
    email: 'petra.schmidt@example.de',
    password: 'LANK-2026',
    displayName: 'Petra Schmidt',
    role: 'parent',
    familyId: familySchmidt['id'],
  );
  await createUserWithProfile(
    email: 'familie.brand@example.de',
    password: 'LANK-2026',
    displayName: 'Familie Brand',
    role: 'parent',
    familyId: familyBrand['id'],
  );
  await createUserWithProfile(
    email: 'oezdemir@familienzentrum-lank.de',
    password: 'TEAM-2026',
    displayName: 'Frau Özdemir',
    role: 'team',
    groupIds: ['blau'],
    staffTitle: 'Gruppenleitung',
  );
  await createUserWithProfile(
    email: 'petersen@familienzentrum-lank.de',
    password: 'TEAM-2026',
    displayName: 'Frau Petersen',
    role: 'team',
    groupIds: ['blau', 'gelb', 'rot'],
    staffTitle: 'Kita-Leitung',
    isAdmin: true,
  );

  await insertRow('family_members', {'family_id': familyWeber['id'], 'user_id': sandra['id'], 'relation': 'Mutter'});
  await insertRow('family_members', {'family_id': familyKaya['id'], 'user_id': kaya['id'], 'relation': 'Mutter'});

  print('Creating children…');
  await insertOne('children', {
    'family_id': familyWeber['id'],
    'group_id': 'blau',
    'name': 'Jonas Weber',
    'birth_year': DateTime.now().year - 4,
    'tags': ['Nussallergie', 'Vegetarisch', 'Schläft mittags'],
  });
  await insertOne('children', {'family_id': familyWeber['id'], 'group_id': 'blau', 'name': 'Mia Weber', 'birth_year': DateTime.now().year - 5});
  await insertOne('children', {'family_id': familyKaya['id'], 'group_id': 'rot', 'name': 'Elif Kaya', 'birth_year': DateTime.now().year - 4});
  await insertOne('children', {'family_id': familySchmidt['id'], 'group_id': 'blau', 'name': 'Mia Schmidt', 'birth_year': DateTime.now().year - 4});
  await insertOne('children', {'family_id': familyBrand['id'], 'group_id': 'blau', 'name': 'Lina Brand', 'birth_year': DateTime.now().year - 4});

  print('Creating posts…');
  final petersenId = (await selectOne('profiles', 'email', 'petersen@familienzentrum-lank.de'))!['id'];
  final oezdemirId = (await selectOne('profiles', 'email', 'oezdemir@familienzentrum-lank.de'))!['id'];

  await insertRow('posts', {
    'author_id': petersenId,
    'kind': 'info',
    'visibility': 'all',
    'pinned': true,
    'title': 'Elternbrief September',
    'body': 'Alle Termine fürs Herbstquartal, die neuen Bringzeiten und Infos zum Laternenfest. Bitte bis Freitag anschauen.',
    'file_name': 'Elternbrief_09.pdf',
    'file_size_label': '248 KB',
  });
  await insertRow('posts', {
    'author_id': oezdemirId,
    'group_id': 'blau',
    'kind': 'foto',
    'visibility': 'group',
    'body': 'Kastanien gesammelt, ein Blätterhaus gebaut, Stockbrot am Feuer. Der nächste Waldtag ist Mittwoch — bitte Gummistiefel einpacken.',
  });
  await insertRow('posts', {
    'author_id': petersenId,
    'kind': 'umfrage',
    'visibility': 'all',
    'title': 'Herbstfest: Wer bringt was mit?',
    'body': '',
    'poll': {
      'options': [
        {'label': 'Kuchen backen', 'votes': 6},
        {'label': 'Salat mitbringen', 'votes': 3},
        {'label': 'Beim Aufbau helfen', 'votes': 2},
      ],
      'voter_ids': [],
    },
  });
  await insertRow('posts', {
    'author_id': petersenId,
    'group_id': 'rot',
    'kind': 'info',
    'visibility': 'all',
    'title': 'Magen-Darm in Gruppe Rot',
    'body': 'Drei Kinder sind erkrankt. Bitte melde dein Kind bis 8:30 telefonisch ab, wenn es Symptome hat, und lass es 48 Stunden zu Hause.',
  });

  print('Creating event, closures, speiseplan, documents…');
  final nextMonth = DateTime.now().add(const Duration(days: 30));
  await insertRow('events', {
    'title': 'Laternenfest',
    'event_date': _dateOnly(DateTime(nextMonth.year, 11, 12)),
    'time_label': '17:00',
    'location': 'Innenhof',
  });
  await insertRow('closures', {'title': 'Herbstferien', 'start_date': _dateOnly(DateTime(DateTime.now().year, 10, 12)), 'end_date': _dateOnly(DateTime(DateTime.now().year, 10, 16))});
  await insertRow('closures', {'title': 'Weihnachtsschließung', 'start_date': _dateOnly(DateTime(DateTime.now().year, 12, 23)), 'end_date': _dateOnly(DateTime(DateTime.now().year + 1, 1, 2))});
  await upsertOne('speiseplan', {
    'id': 'current',
    'items': [
      {'day': 'Mo', 'text': 'Nudelauflauf mit Gemüse'},
      {'day': 'Di', 'text': 'Linsensuppe mit Brot'},
      {'day': 'Mi', 'text': 'Kartoffelpuffer, Apfelmus'},
      {'day': 'Do', 'text': 'Hähnchenfrikassee, Reis'},
      {'day': 'Fr', 'text': 'Milchreis mit Kirschen'},
    ],
  });
  await insertRow('documents', {'title': 'Elternbrief September', 'file_url': 'https://example.de/elternbrief_09.pdf', 'size_label': '248 KB'});

  print('Creating a demo invite (erika.muster@example.de)…');
  await insertRow('invites', {
    'email': 'erika.muster@example.de',
    'code': 'DEMO2026',
    'role': 'parent',
    'display_name': 'Erika Muster',
    'created_by': petersenId,
  });

  print('Done. Demo logins (email / Zugangscode = password):');
  print('  sandra.weber@example.de / LANK-2026');
  print('  familie.kaya@example.de / LANK-2026');
  print('  petra.schmidt@example.de / LANK-2026');
  print('  familie.brand@example.de / LANK-2026');
  print('  oezdemir@familienzentrum-lank.de / TEAM-2026');
  print('  petersen@familienzentrum-lank.de / TEAM-2026 (admin)');
  print('  Invite waiting to be redeemed: erika.muster@example.de / DEMO2026');
  _client.close();
}

String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

Future<Map<String, dynamic>> createUserWithProfile({
  required String email,
  required String password,
  required String displayName,
  required String role,
  String? familyId,
  List<String>? groupIds,
  String? staffTitle,
  bool isAdmin = false,
}) async {
  final user = await _request('POST', '/auth/v1/admin/users', body: {
    'email': email,
    'password': password,
    'email_confirm': true,
  });
  final uid = user['id'] as String;
  await insertRow('profiles', {
    'id': uid,
    'email': email,
    'display_name': displayName,
    'role': role,
    'family_id': familyId,
    'is_admin': isAdmin,
    'group_ids': groupIds ?? [],
    'staff_title': staffTitle,
  });
  return {'id': uid};
}

Future<Map<String, dynamic>> insertOne(String table, Map<String, dynamic> row) async {
  final rows = await _request('POST', '/rest/v1/$table', body: row, prefer: 'return=representation');
  return (rows as List).first as Map<String, dynamic>;
}

Future<void> insertRow(String table, Map<String, dynamic> row) async {
  await _request('POST', '/rest/v1/$table', body: row);
}

Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
  await _request('POST', '/rest/v1/$table', body: rows, prefer: 'resolution=merge-duplicates');
}

Future<void> upsertOne(String table, Map<String, dynamic> row) async {
  await _request('POST', '/rest/v1/$table', body: row, prefer: 'resolution=merge-duplicates');
}

Future<Map<String, dynamic>?> selectOne(String table, String column, String value) async {
  final rows = await _request('GET', '/rest/v1/$table?$column=eq.$value&select=*');
  final list = rows as List;
  return list.isEmpty ? null : list.first as Map<String, dynamic>;
}

Future<dynamic> _request(String method, String path, {dynamic body, String? prefer}) async {
  final uri = Uri.parse('$supabaseUrl$path');
  final req = await _client.openUrl(method, uri);
  req.headers.set('apikey', serviceKey);
  req.headers.set('Authorization', 'Bearer $serviceKey');
  req.headers.set('Content-Type', 'application/json');
  if (prefer != null) req.headers.set('Prefer', prefer);
  if (body != null) req.write(jsonEncode(body));
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  if (res.statusCode >= 400) {
    throw Exception('$method $path -> ${res.statusCode}: $text');
  }
  if (text.isEmpty) return null;
  return jsonDecode(text);
}
