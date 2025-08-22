import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/currency_controller.dart';
import '../checkout/checkout_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final CurrencyController currencyController =
        Get.find<CurrencyController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              if (cartController.items.isNotEmpty) {
                Get.defaultDialog(
                  title: 'Clear Cart',
                  middleText: 'Are you sure you want to clear your cart?',
                  textConfirm: 'Clear',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  onConfirm: () {
                    cartController.clearCart();
                    Get.back();
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Obx(
        () =>
            cartController.items.isEmpty
                ? const Center(
                  child: Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 16),
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartController.items.length,
                        itemBuilder: (context, index) {
                          final item = cartController.items[index];
                          return Dismissible(
                            key: Key(item.product.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) {
                              cartController.removeFromCart(item);

                              Get.snackbar(
                                'Item Removed',
                                '${item.product.name} was removed from cart',
                                mainButton: TextButton(
                                  onPressed: () {
                                    cartController.addToCart(
                                      item.product,
                                      item.selectedSize,
                                      item.selectedColor,
                                      item.quantity,
                                    );
                                  },
                                  child: const Text('UNDO'),
                                ),
                                duration: const Duration(seconds: 3),
                              );
                            },
                            confirmDismiss: (direction) async {
                              return await Get.dialog<bool>(
                                    AlertDialog(
                                      title: const Text('Remove Item'),
                                      content: Text(
                                        'Are you sure you want to remove ${item.product.name} from cart?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Get.back(result: false),
                                          child: const Text('CANCEL'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Get.back(result: true),
                                          child: const Text(
                                            'REMOVE',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              item.product.imageList.isNotEmpty
                                                  ? item.product.imageList.first
                                                  : '',
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                          errorWidget: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.image,
                                                color: Colors.grey[400],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Size: ${item.selectedSize} • Color: ${item.selectedColor}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Obx(
                                            () => Text(
                                              currencyController
                                                  .getFormattedProductPrice(
                                                    item.product.price,
                                                    item.product.currency,
                                                  ),
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            cartController.updateQuantity(
                                              item,
                                              item.quantity - 1,
                                            );
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            cartController.updateQuantity(
                                              item,
                                              item.quantity + 1,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Obx(() {
                                final total = cartController.items.fold(0.0, (
                                  sum,
                                  item,
                                ) {
                                  final convertedPrice = currencyController
                                      .convertPrice(
                                        item.product.price,
                                        item.product.currency,
                                      );
                                  return sum + convertedPrice * item.quantity;
                                });
                                return Text(
                                  currencyController.formatPrice(total),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  cartController.items.isEmpty
                                      ? null
                                      : () =>
                                          Get.to(() => const CheckoutScreen()),
                              child: const Text(
                                'Proceed to Checkout',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
