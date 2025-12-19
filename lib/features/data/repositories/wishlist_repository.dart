import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<String>> getWishlistProductIds() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return []; // Return empty list if not authenticated
    }

    final response = await _supabase
        .from('wishlist')
        .select('product_id')
        .eq('user_id', currentUser.id);

    return (response as List)
        .map((item) => item['product_id'] as String)
        .toList();
  }

  Future<void> addToWishlist(String productId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _supabase.from('wishlist').insert({
      'product_id': productId,
      'user_id': currentUser.id,
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _supabase.from('wishlist').delete().match({
      'product_id': productId,
      'user_id': currentUser.id,
    });
  }
}
