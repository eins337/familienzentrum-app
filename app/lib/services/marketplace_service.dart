import '../models/models.dart';
import 'supabase_service.dart';

/// Tauschbörse — a cross-group exchange board any parent can post to and
/// browse, independent of which Gruppe their child is in.
class MarketplaceService {
  Stream<List<MarketplaceItem>> streamItems() {
    return supa.from('marketplace_items').stream(primaryKey: ['id']).map((rows) {
      final items = rows.map(MarketplaceItem.fromMap).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<MarketplaceItem> createItem({
    required String authorId,
    String? familyId,
    required String title,
    String? description,
  }) async {
    final row = await supa
        .from('marketplace_items')
        .insert({
          'author_id': authorId,
          'family_id': familyId,
          'title': title,
          'description': description,
        })
        .select()
        .single();
    return MarketplaceItem.fromMap(row);
  }

  Future<void> updateStatus(String itemId, String status) =>
      supa.from('marketplace_items').update({'status': status}).eq('id', itemId);

  Future<void> deleteItem(String itemId) => supa.from('marketplace_items').delete().eq('id', itemId);
}
