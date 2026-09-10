import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/event_card.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_header.dart';
import '../../widgets/post_card.dart';
import '../../widgets/speiseplan_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final postsAsync = ref.watch(feedPostsProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final speiseplanAsync = ref.watch(speiseplanProvider);

    return Scaffold(
      appBar: NHeader(title: 'Aktuelles', subtitle: 'Familienzentrum Lank', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Fehler: $e', style: const TextStyle(color: AppColors.text))),
        data: (posts) {
          final pinned = posts.where((p) => p.pinned).toList();
          final rest = posts.where((p) => !p.pinned).toList();
          final events = eventsAsync.valueOrNull ?? [];
          final speiseplan = speiseplanAsync.valueOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (profile?.isTeam ?? false) ...[
                NButton(
                  label: 'Beitrag oder Info erstellen',
                  variant: NButtonVariant.primary,
                  block: true,
                  alignStart: true,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => context.push('/post-erstellen'),
                ),
                const SizedBox(height: 10),
              ],
              for (final p in pinned) ...[PostCard(post: p), const SizedBox(height: 10)],
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
