import 'product_model.dart';

class CartItem {
  final Product product;
  final String selectedSize;
  final String selectedColor;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['products'] as Map<String, dynamic>),
      selectedSize: json['selected_size'] ?? '',
      selectedColor: json['selected_color'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'selected_size': selectedSize,
      'selected_color': selectedColor,
      'quantity': quantity,
    };
  }

  double get totalPrice => product.price * quantity;
}
