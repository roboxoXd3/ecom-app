import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';

class WishlistRepository {
  final _api = ApiClient.instance;

  Future<List<String>> getWishlistProductIds() async {
    if (!AuthService.isAuthenticated()) return [];

    try {
      final response = await _api.get('/wishlist/');
      final results = ApiClient.unwrapResults(response.data);

      return results
          .map((item) {
            final m = item as Map<String, dynamic>;
            return (m['product_id'] ?? m['product']?['id'] ?? '').toString();
          })
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error fetching wishlist: $e');
      return [];
    }
  }

  Future<void> addToWishlist(String productId) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    await _api.post('/wishlist/', data: {
      'product_id': productId,
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    // The Django API uses DELETE /api/wishlist/{wishlist_item_id}/
    // First find the wishlist item by product_id, then delete by its id
    final response = await _api.get('/wishlist/');
    final results = ApiClient.unwrapResults(response.data);

    for (final item in results) {
      final m = item as Map<String, dynamic>;
      final itemProductId =
          (m['product_id'] ?? m['product']?['id'] ?? '').toString();
      if (itemProductId == productId) {
        final wishlistItemId = m['id'].toString();
        await _api.delete('/wishlist/$wishlistItemId/');
        return;
      }
    }
  }
}
