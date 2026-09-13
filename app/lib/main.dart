import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

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
  // v2 is a light theme (the old Nocturne dark theme relied on the
  // platform default, which reads fine against a dark background but
  // leaves light status-bar icons unreadable against our cream background).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
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
