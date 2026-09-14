import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/birthdays.dart';
import '../../utils/group_colors.dart';
import '../../widgets/birthday_card.dart';
import '../../widgets/event_card.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/post_card.dart';
import '../../widgets/speiseplan_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  static const _weekdays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
  static const _months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final postsAsync = ref.watch(feedPostsProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final speiseplanAsync = ref.watch(speiseplanProvider);
    final allChildren = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final myChildren = ref.watch(myChildrenProvider).valueOrNull ?? [];
    final mySickReports = ref.watch(mySickReportsProvider).valueOrNull ?? [];
    final activeSickReport = mySickReports.where((r) => r.isActive).firstOrNull;
    final relevantGroups = profile?.isTeam ?? false
        ? profile!.groupIds.toSet()
        : myChildren.map((c) => c.groupId).toSet();
    final birthdays = upcomingBirthdays(allChildren.values, groupIds: relevantGroups);
    final now = DateTime.now();
    final dateLabel = '${_weekdays[now.weekday - 1]}, ${now.day}. ${_months[now.month - 1]}';

    return Scaffold(
      appBar: NHeader(title: 'Aktuelles', subtitle: 'Familienzentrum Lank', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Fehler: $e', style: const TextStyle(color: AppColors.ink))),
        data: (posts) {
          final pinned = posts.where((p) => p.pinned).toList();
          final rest = posts.where((p) => !p.pinned).toList();
          final events = eventsAsync.valueOrNull ?? [];
          final speiseplan = speiseplanAsync.valueOrNull;
          final isParent = !(profile?.isTeam ?? false);
          final myChild = myChildren.firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _GreetingCard(
                name: profile?.displayName.split(' ').first ?? '',
                dateLabel: dateLabel,
                groupLabel: myChild != null ? 'Gruppe ${groupName(myChild.groupId)}' : null,
              ),
              const SizedBox(height: 10),
              if (isParent && myChild != null) ...[
                _QuickActionsRow(child: myChild),
                const SizedBox(height: 10),
              ],
              if (profile?.isTeam ?? false) ...[
                NButton(
                  label: 'Beitrag, Speiseplan oder Info erstellen',
                  variant: NButtonVariant.primary,
                  block: true,
                  alignStart: true,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => context.push('/post-erstellen'),
                ),
                const SizedBox(height: 10),
              ],
              if (activeSickReport != null) ...[
                _SickStatusCard(dateLabel: activeSickReport.dateLabel),
                const SizedBox(height: 10),
              ],
              for (final p in pinned) ...[PostCard(post: p), const SizedBox(height: 10)],
              if (birthdays.isNotEmpty) ...[BirthdayCard(children: birthdays), const SizedBox(height: 10)],
              for (final p in rest) ...[PostCard(post: p), const SizedBox(height: 10)],
              if (events.isNotEmpty) ...[EventCard(event: events.first), const SizedBox(height: 10)],
              if (speiseplan != null) ...[SpeiseplanCard(speiseplan: speiseplan), const SizedBox(height: 10)],
              NButton(
                label: 'Alle Infos & Termine',
                variant: NButtonVariant.secondary,
                block: true,
                small: true,
                onPressed: () => context.push('/infos'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.name, required this.dateLabel, this.groupLabel});
  final String name;
  final String dateLabel;
  final String? groupLabel;

  @override
  Widget build(BuildContext context) {
    return NCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hallo ${name.isEmpty ? '' : name}', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 19, color: AppColors.ink)),
                const SizedBox(height: 3),
                Text([dateLabel, groupLabel].whereType<String>().join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const FeedGreetingIllustration(),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow({required this.child});
  final Child child;

  Future<void> _messageTeam(BuildContext context, WidgetRef ref) async {
    final myId = ref.read(profileProvider).valueOrNull?.id;
    if (myId == null || child.groupId == null) return;
    try {
      final toUid = await ref.read(kitaServiceProvider).fetchPrimaryTeamMemberUid(child.groupId!);
      if (toUid == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Für diese Gruppe ist noch kein Team-Konto hinterlegt.')));
        return;
      }
      final chat = await ref.read(chatsServiceProvider).findOrCreateDirectChat(myId, toUid);
      if (context.mounted) context.push('/chats/${chat.id}');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.thermostat_rounded,
            label: 'Krankmelden',
            color: AppColors.error,
            softColor: AppColors.errorSoft,
            onTap: () => context.push('/krankmelden/${child.id}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Erzieher schreiben',
            color: AppColors.primary,
            softColor: AppColors.primarySoft,
            onTap: () => _messageTeam(context, ref),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.groups_rounded,
            label: 'Spielanfrage',
            color: AppColors.info,
            softColor: AppColors.infoSoft,
            onTap: () => context.push('/spielanfrage-neu?myChildId=${child.id}'),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.softColor, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: softColor, borderRadius: BorderRadius.circular(AppRadius.iconBackplate)),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 7),
          Text(label, textAlign: TextAlign.center, maxLines: 2, style: AppText.outfit(size: 11.5, weight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _SickStatusCard extends StatelessWidget {
  const _SickStatusCard({required this.dateLabel});
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return NCard(
      background: AppColors.successSoft,
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.successInk),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Krankgemeldet', style: AppText.outfit(size: 14, weight: FontWeight.w600, color: AppColors.successInk)),
                Text(dateLabel, style: AppText.nunito(size: 11.5, color: AppColors.successInk2)),
              ],
            ),
          ),
          NButton(label: 'Details', variant: NButtonVariant.ghost, small: true, onPressed: () => context.go('/profil')),
        ],
      ),
    );
  }
}
