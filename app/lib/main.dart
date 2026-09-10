import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initSupabase();
  } catch (e) {
    // A network hiccup (or an unreachable/placeholder Supabase URL) during
    // startup shouldn't leave the user on a blank white screen — let the
    // app render normally; screens that need Supabase will surface their
    // own error state once a request actually fails.
    debugPrint('Supabase init failed: $e');
  }
  runApp(const ProviderScope(child: FamilienzentrumApp()));
}

class FamilienzentrumApp extends ConsumerWidget {
  const FamilienzentrumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Familienzentrum Lank',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
