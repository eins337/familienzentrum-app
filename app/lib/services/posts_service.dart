import '../models/models.dart';
import 'supabase_service.dart';

class PostsService {
  /// Kita-wide feed: posts with no group_id, or group posts where the
  /// caller may see them — RLS already limits to "signed in", we just sort.
  ///
  /// Sorted client-side (not via chained `.order()` calls) because
  /// `SupabaseStreamBuilder` only remembers a single order column — a
  /// second `.order()` call silently overwrites the first instead of
  /// adding a secondary sort key, which was dropping the pinned-first
  /// ordering entirely.
  Stream<List<Post>> streamFeed() {
    return supa.from('posts').stream(primaryKey: ['id']).map((rows) {
      final posts = rows.map(Post.fromMap).toList();
      posts.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return posts;
    });
  }

  Stream<List<Post>> streamGroupPosts(String groupId) {
    return supa
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Post.fromMap).toList());
  }

  Future<Post> createPost({
    required String authorId,
    String? groupId,
    required String kind,
    required String visibility,
    String? title,
    required String body,
    bool pinned = false,
    List<String> photoUrls = const [],
    String? fileName,
    String? fileSizeLabel,
    String? fileUrl,
    DateTime? eventDate,
    String? eventLocation,
    PostPoll? initialPoll,
  }) async {
    final row = await supa
        .from('posts')
        .insert({
          'author_id': authorId,
          'group_id': groupId,
          'kind': kind,
          'visibility': visibility,
          'title': title,
          'body': body,
          'pinned': pinned,
          'photo_urls': photoUrls,
          'file_name': fileName,
          'file_size_label': fileSizeLabel,
          'file_url': fileUrl,
          'event_date': eventDate?.toIso8601String(),
          'event_location': eventLocation,
          if (initialPoll != null)
            'poll': {
              'options': initialPoll.options.map((o) => {'label': o.label, 'votes': 0}).toList(),
              'voter_ids': <String>[],
            },
        })
        .select()
        .single();
    return Post.fromMap(row);
  }

  Future<Post> fetchPost(String postId) async {
    final row = await supa.from('posts').select().eq('id', postId).single();
    return Post.fromMap(row);
  }

  Future<void> toggleLike(String postId) => supa.rpc('toggle_post_like', params: {'p_post_id': postId});

  Future<void> votePoll(String postId, int optionIndex) =>
      supa.rpc('vote_poll', params: {'p_post_id': postId, 'p_option_index': optionIndex});

  Stream<List<PostComment>> streamComments(String postId) {
    return supa
        .from('post_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .map((rows) => rows.map(PostComment.fromMap).toList());
  }

  Future<void> addComment(String postId, String authorId, String body) =>
      supa.from('post_comments').insert({'post_id': postId, 'author_id': authorId, 'body': body});
}
