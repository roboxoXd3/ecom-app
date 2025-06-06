import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../../core/utils/snackbar_utils.dart';

class CartController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      isLoading.value = true;

      // Get or create cart for current user
      final userId = supabase.auth.currentUser!.id;

      // Try to get existing cart
      final cart =
          await supabase
              .from('carts')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      String cartId;
      if (cart == null) {
        // Create new cart if none exists
        final newCart =
            await supabase
                .from('carts')
                .insert({'user_id': userId})
                .select()
                .single();
        cartId = newCart['id'];
      } else {
        cartId = cart['id'];
      }

      // Fetch cart items
      final response = await supabase
          .from('cart_items')
          .select('''
            *,
            products:product_id (*)
          ''')
          .eq('cart_id', cartId);

      items.value =
          (response as List<dynamic>)
              .map((item) => CartItem.fromJson(item))
              .toList();
    } catch (e) {
      print('Error fetching cart items: $e');
      // Only show error for actual errors, not for empty carts
      if (!e.toString().contains('no rows')) {
        SnackbarUtils.showError('Failed to load cart items');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart(
    Product product,
    String size,
    String color, [
    int quantity = 1,
  ]) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser!.id;

      // Get or create cart
      final cart =
          await supabase
              .from('carts')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      String cartId;
      if (cart == null) {
        final newCart =
            await supabase
                .from('carts')
                .insert({'user_id': userId})
                .select()
                .single();
        cartId = newCart['id'];
      } else {
        cartId = cart['id'];
      }

      // Check if item already exists
      final existingItem =
          await supabase
              .from('cart_items')
              .select()
              .eq('cart_id', cartId)
              .eq('product_id', product.id)
              .eq('selected_size', size)
              .eq('selected_color', color)
              .maybeSingle();

      if (existingItem != null) {
        // Update quantity if item exists
        await supabase
            .from('cart_items')
            .update({'quantity': existingItem['quantity'] + quantity})
            .eq('id', existingItem['id']);
      } else {
        // Add new item
        await supabase.from('cart_items').insert({
          'cart_id': cartId,
          'product_id': product.id,
          'quantity': quantity,
          'selected_size': size,
          'selected_color': color,
        });
      }

      await fetchCartItems();
      // SnackbarUtils.showSuccess('Added to cart');
    } catch (e) {
      print('Error adding to cart: $e');
      SnackbarUtils.showError('Failed to add item to cart');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFromCart(CartItem item) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser!.id;
      final cart =
          await supabase.from('carts').select().eq('user_id', userId).single();

      await supabase
          .from('cart_items')
          .delete()
          .eq('cart_id', cart['id'])
          .eq('product_id', item.product.id)
          .eq('selected_size', item.selectedSize)
          .eq('selected_color', item.selectedColor);

      await fetchCartItems();
      SnackbarUtils.showSuccess('Removed from cart');
    } catch (e) {
      print('Error removing from cart: $e');
      // SnackbarUtils.showError('Failed to remove item from cart');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateQuantity(CartItem item, int quantity) async {
    try {
      if (quantity < 1) return;

      isLoading.value = true;

      final userId = supabase.auth.currentUser!.id;
      final cart =
          await supabase.from('carts').select().eq('user_id', userId).single();

      await supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('cart_id', cart['id'])
          .eq('product_id', item.product.id)
          .eq('selected_size', item.selectedSize)
          .eq('selected_color', item.selectedColor);

      await fetchCartItems();
    } catch (e) {
      print('Error updating quantity: $e');
      SnackbarUtils.showError('Failed to update quantity');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser!.id;
      final cart =
          await supabase.from('carts').select().eq('user_id', userId).single();

      await supabase.from('cart_items').delete().eq('cart_id', cart['id']);

      items.clear();
      SnackbarUtils.showSuccess('Cart cleared');
    } catch (e) {
      print('Error clearing cart: $e');
      SnackbarUtils.showError('Failed to clear cart');
    } finally {
      isLoading.value = false;
    }
  }

  double get total =>
      items.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);
}
