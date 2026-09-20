import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../theme/tokens.dart';
import '../utils/group_colors.dart';
import '../utils/time_format.dart';
import 'n_avatar.dart';
import 'n_card.dart';
import 'n_tag.dart';
import 'n_toast.dart';

/// Renders one feed/group post — the exact visual treatment depends on
/// `kind` and `pinned`, matching the different card styles in the design
/// (pinned Elternbrief w/ attachment, photo post w/ privacy badge and
/// likes/comments, Umfrage poll, plain Hinweis).
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, this.showGroupHeader = true});
  final Post post;
  final bool showGroupHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (post.pinned) return _PinnedCard(post: post);
    switch (post.kind) {
      case 'foto':
        return _PhotoCard(post: post, showGroupHeader: showGroupHeader);
      case 'umfrage':
        return _PollCard(post: post);
      default:
        return _InfoCard(post: post);
    }
  }
}

class _MetaRow extends ConsumerWidget {
  const _MetaRow({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};
    final authorName = post.authorName ?? profiles[post.authorId]?.displayName ?? '…';
    return Row(
      children: [
        Expanded(
          child: Text(
            '$authorName · ${formatRelative(post.createdAt)}',
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return NCard(
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NTag('Angepinnt', variant: NTagVariant.accent),
              const Spacer(),
              Text(formatRelative(post.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 8),
          if (post.title != null)
            Text(post.title!, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(post.body, style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4)),
          if (post.fileName != null) ...[
            const SizedBox(height: 8),
            _AttachmentRow(post: post),
          ],
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: post.fileUrl == null
          ? null
          : () => launchUrl(Uri.parse(post.fileUrl!), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(post.fileName!, style: const TextStyle(fontSize: 12, color: AppColors.ink))),
            if (post.fileSizeLabel != null) ...[
              Text(post.fileSizeLabel!, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(width: 6),
            ],
            if (post.fileUrl != null) const Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends ConsumerWidget {
  const _PhotoCard({required this.post, required this.showGroupHeader});
  final Post post;
  final bool showGroupHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(profileProvider).valueOrNull?.id;
    final liked = myId != null && post.likes.contains(myId);
    final isGroupVisible = post.visibility == 'group';

    return NCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              children: [
                if (showGroupHeader && post.groupId != null) ...[
                  NAvatar(initials: groupInitial(post.groupId), size: 24, background: groupColor(post.groupId), foreground: AppColors.background),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Gruppe ${groupName(post.groupId)}',
                            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.ink)),
                        _MetaRow(post: post),
                      ],
                    ),
                  ),
                ] else
                  Expanded(child: _MetaRow(post: post)),
                if (isGroupVisible)
                  NTag('Nur Gruppe', variant: NTagVariant.neutral, icon: const Icon(Icons.lock_outline_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 168,
            width: double.infinity,
            child: post.photoUrls.isNotEmpty
                ? CachedNetworkImage(imageUrl: post.photoUrls.first, fit: BoxFit.cover)
                : Container(
                    color: AppColors.soft,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, color: AppColors.border, size: 32),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.body, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink)),
                if (isGroupVisible) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 11, color: AppColors.muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text('Fotos nur für Familien der Gruppe ${groupName(post.groupId)} · Speichern deaktiviert',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _ActionBtn(
                      icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: '${post.likes.length}',
                      color: liked ? AppColors.primary : AppColors.ink,
                      onTap: () => runOrShowError(context, () => ref.read(postsServiceProvider).toggleLike(post.id)),
                    ),
                    _ActionBtn(
                      icon: Icons.mode_comment_outlined,
                      label: '${post.commentCount}',
                      onTap: () => context.push('/post/${post.id}/kommentare'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PollCard extends ConsumerStatefulWidget {
  const _PollCard({required this.post});
  final Post post;

  @override
  ConsumerState<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<_PollCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final profile = ref.watch(profileProvider).valueOrNull;
    final myId = profile?.id;
    final poll = post.poll;
    final voted = myId != null && (poll?.voterIds.contains(myId) ?? false);
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};

    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NTag('Umfrage', variant: NTagVariant.outline),
              const Spacer(),
              Text(formatRelative(post.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          if (post.title != null)
            Text(post.title!, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 6),
          if (poll != null)
            ...poll.options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: voted ? null : () => runOrShowError(context, () => ref.read(postsServiceProvider).votePoll(post.id, i)),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(
                      children: [
                        Text(opt.label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                        const Spacer(),
                        Text('${opt.votes}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          InkWell(
            onTap: (profile?.isTeam ?? false) && (poll?.voterIds.isNotEmpty ?? false) ? () => setState(() => _expanded = !_expanded) : null,
            child: Row(
              children: [
                Text(
                  voted ? 'Danke! Das Team sieht deine Zusage.' : '${poll?.voterIds.length ?? 0} Familien haben geantwortet.',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
                if ((profile?.isTeam ?? false) && (poll?.voterIds.isNotEmpty ?? false)) ...[
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 14, color: AppColors.muted),
                ],
              ],
            ),
          ),
          if (_expanded && poll != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final uid in poll.voterIds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(profiles[uid]?.displayName ?? uid, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    return NCard(
      borderColor: AppColors.mutedAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NTag('Hinweis', variant: NTagVariant.neutral),
              const Spacer(),
              Text(formatRelative(post.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          if (post.title != null)
            Text(post.title!, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(post.body, style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4)),
          if (post.kind == 'termin' && post.eventDate != null) ...[
            const SizedBox(height: 6),
            Text(
              '${formatDateLong(post.eventDate!)}${post.eventLocation != null ? ' · ${post.eventLocation}' : ''}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ],
          if (post.fileName != null) ...[
            const SizedBox(height: 8),
            _AttachmentRow(post: post),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color = AppColors.ink});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
