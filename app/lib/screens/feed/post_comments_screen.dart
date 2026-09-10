import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_avatar.dart';
import '../../widgets/n_header.dart';

class PostCommentsScreen extends ConsumerStatefulWidget {
  const PostCommentsScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  final _draftCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _draftCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _draftCtrl.text.trim();
    final profile = ref.read(profileProvider).valueOrNull;
    if (text.isEmpty || profile == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(postsServiceProvider).addComment(widget.postId, profile.id, text);
      _draftCtrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsStream = ref.watch(postsServiceProvider).streamComments(widget.postId);
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: const NHeader(title: 'Kommentare', showBack: true),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PostComment>>(
              stream: commentsStream,
              builder: (context, snap) {
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('Noch keine Kommentare.', style: TextStyle(color: AppColors.neutral500)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = comments[i];
                    final name = c.authorName ?? profiles[c.authorId]?.displayName ?? '…';
                    final initials = name.trim().isEmpty ? '?' : name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NAvatar(initials: initials, size: 28),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.text)),
                                  const SizedBox(width: 6),
                                  Text(formatRelative(c.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.neutral500)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(c.body, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draftCtrl,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'Kommentar schreiben',
                        hintStyle: const TextStyle(color: AppColors.neutral600),
                        filled: true,
                        fillColor: AppColors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.accent)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 7),
                  InkWell(
                    onTap: _sending ? null : _send,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: AppColors.accent), borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: const Icon(Icons.send_rounded, size: 17, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
