import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin/admin_content_screen.dart';
import '../screens/admin/admin_families_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_invites_screen.dart';
import '../screens/admin/admin_sickreports_screen.dart';
import '../screens/admin/admin_team_screen.dart';
import '../screens/chats/chat_detail_screen.dart';
import '../screens/chats/chats_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/feed/post_comments_screen.dart';
import '../screens/feed/post_create_screen.dart';
import '../screens/gruppen/gruppe_detail_screen.dart';
import '../screens/gruppen/gruppen_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profil/einstellungen_screen.dart';
import '../screens/profil/infos_screen.dart';
import '../screens/profil/krankmelden_sheet.dart';
import '../screens/profil/mitteilungen_screen.dart';
import '../screens/profil/profil_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/spielen/spielanfrage_neu_screen.dart';
import '../screens/spielen/spielen_screen.dart';
import '../screens/team/team_screen.dart';
import '../state/providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final signedIn = ref.read(authStateProvider).valueOrNull?.session != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!signedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/feed';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/post-erstellen',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PostCreateScreen(),
      ),
      GoRoute(
        path: '/post/:postId/kommentare',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PostCommentsScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/infos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InfosScreen(),
      ),
      GoRoute(
        path: '/mitteilungen',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MitteilungenScreen(),
      ),
      GoRoute(
        path: '/einstellungen',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EinstellungenScreen(),
      ),
      GoRoute(
        path: '/spielanfrage-neu',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SpielanfrageNeuScreen(),
      ),
      GoRoute(
        path: '/krankmelden/:childId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => ModalBottomSheetPage(
          child: KrankmeldenSheet(childId: state.pathParameters['childId']!),
        ),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(path: 'invites', builder: (context, state) => const AdminInvitesScreen()),
          GoRoute(path: 'families', builder: (context, state) => const AdminFamiliesScreen()),
          GoRoute(path: 'team', builder: (context, state) => const AdminTeamScreen()),
          GoRoute(path: 'content', builder: (context, state) => const AdminContentScreen()),
          GoRoute(path: 'sickreports', builder: (context, state) => const AdminSickReportsScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/feed', builder: (context, state) => const FeedScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/gruppen',
              builder: (context, state) => const GruppenScreen(),
              routes: [
                GoRoute(path: ':groupId', builder: (context, state) => GruppeDetailScreen(groupId: state.pathParameters['groupId']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chats',
              builder: (context, state) => const ChatsScreen(),
              routes: [
                GoRoute(path: ':chatId', builder: (context, state) => ChatDetailScreen(chatId: state.pathParameters['chatId']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/spielen', builder: (context, state) => const SpielenScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/team', builder: (context, state) => const TeamScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profil', builder: (context, state) => const ProfilScreen())]),
        ],
      ),
    ],
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _sub = _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// A route "page" that renders as a modal bottom sheet instead of a full
/// page push — used for Krankmelden, matching the prototype's sheet.
class ModalBottomSheetPage<T> extends Page<T> {
  const ModalBottomSheetPage({required this.child, super.key});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: true,
      builder: (context) => child,
    );
  }
}
