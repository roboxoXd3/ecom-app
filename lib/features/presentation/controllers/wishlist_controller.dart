import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../../core/utils/snackbar_utils.dart';

class WishlistController extends GetxController {
  final RxList<Product> _items = <Product>[].obs;

  List<Product> get items => _items;
  int get itemCount => _items.length;

  bool isInWishlist(Product product) => _items.contains(product);

  void toggleWishlist(Product product) {
    if (isInWishlist(product)) {
      _items.remove(product);
      SnackbarUtils.showSuccess('Removed from wishlist');
    } else {
      _items.add(product);
      SnackbarUtils.showSuccess('Added to wishlist');
    }
  }

  void removeFromWishlist(Product product) {
    _items.remove(product);
    SnackbarUtils.showSuccess('Removed from wishlist');
  }

  void clearWishlist() {
    _items.clear();
    SnackbarUtils.showSuccess('Wishlist cleared');
  }
}
