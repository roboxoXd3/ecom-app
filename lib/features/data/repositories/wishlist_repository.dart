import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<String>> getWishlistProductIds() async {
    final response = await _supabase.from('wishlist').select('product_id');

    return (response as List)
        .map((item) => item['product_id'] as String)
        .toList();
  }

  Future<void> addToWishlist(String productId) async {
    await _supabase.from('wishlist').insert({
      'product_id': productId,
      'user_id': _supabase.auth.currentUser!.id,
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    await _supabase.from('wishlist').delete().match({
      'product_id': productId,
      'user_id': _supabase.auth.currentUser!.id,
    });
  }
}
