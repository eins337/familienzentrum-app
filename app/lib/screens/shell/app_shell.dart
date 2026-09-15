import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../widgets/kita_icons.dart';
import '../../widgets/n_bottom_nav.dart';

/// Bottom tab shell. Parents see Aktuelles/Gruppen/Chat/Spielen/Profil;
/// Kita-Team sees Aktuelles/Gruppen/Chat/Team/Profil (Spielanfragen is a
/// parent-to-parent feature the team doesn't need day to day — Team gets a
/// dedicated hub instead, with the admin panel one tap further for admins).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  // Branch order registered in the router: 0 feed, 1 gruppen, 2 chats,
  // 3 spielen, 4 team, 5 profil. Only one of spielen/team is shown per
  // role, so the visible tab strip maps onto a subset of branch indices.
  static const _parentBranches = [0, 1, 2, 3, 5];
  static const _teamBranches = [0, 1, 2, 4, 5];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final isTeam = profile?.isTeam ?? false;
    final visibleBranches = isTeam ? _teamBranches : _parentBranches;

    final items = isTeam
        ? const [
            NNavItem(KitaIcon.feed, 'Aktuelles'),
            NNavItem(KitaIcon.gruppen, 'Gruppen'),
            NNavItem(KitaIcon.chat, 'Chat'),
            NNavItem(KitaIcon.team, 'Team'),
            NNavItem(KitaIcon.profil, 'Profil'),
          ]
        : const [
            NNavItem(KitaIcon.feed, 'Aktuelles'),
            NNavItem(KitaIcon.gruppen, 'Gruppen'),
            NNavItem(KitaIcon.chat, 'Chat'),
            NNavItem(KitaIcon.spielen, 'Spielen'),
            NNavItem(KitaIcon.profil, 'Profil'),
          ];

    final currentPos = visibleBranches.indexOf(navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NBottomNav(
        items: items,
        currentIndex: currentPos < 0 ? 0 : currentPos,
        onTap: (i) {
          final branch = visibleBranches[i];
          navigationShell.goBranch(branch, initialLocation: branch == navigationShell.currentIndex);
        },
      ),
    );
  }
}
