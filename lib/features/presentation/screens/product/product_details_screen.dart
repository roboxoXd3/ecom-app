import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../controllers/cart_controller.dart';
import '../../../data/models/product_model.dart';
import '../home/home_screen.dart';

Color getColorFromString(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    case 'navy':
      return const Color(0xFF000080); // Navy blue color
    case 'grey':
      return Colors.grey;
    case 'blue':
      return Colors.blue;
    case 'red':
      return Colors.red;
    case 'green':
      return Colors.green;
    case 'brown':
      return Colors.brown;
    case 'tan':
      return Colors.brown;
    default:
      return Colors.grey;
  }
}

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Initialize CartController if not already initialized
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    final CartController cartController = Get.find<CartController>();
    final RxInt currentImageIndex = 0.obs;
    final RxString selectedSize = ''.obs;
    final RxString selectedColor = ''.obs;
    final RxInt quantity = 1.obs;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () {
                // TODO: Add to wishlist
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.black),
                  onPressed:
                      () => Get.off(() => const HomeScreen(), arguments: 2),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Obx(() {
                    int itemCount = cartController.items.length;
                    return itemCount > 0
                        ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        : const SizedBox.shrink();
                  }),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.black),
              onPressed: () {
                // TODO: Share product
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Carousel
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 400,
                  viewportFraction: 1,
                  onPageChanged: (index, reason) {
                    currentImageIndex.value = index;
                  },
                ),
                items:
                    product.images.map((image) {
                      return Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image,
                                size: 100,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
              ),
              Positioned(
                bottom: 16,
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        product.images.asMap().entries.map((entry) {
                          return Container(
                            width:
                                currentImageIndex.value == entry.key ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color:
                                  currentImageIndex.value == entry.key
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(
                        product.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(' (${product.reviews} Reviews)'),
                      const Spacer(),
                      Text(
                        product.inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color:
                              product.inStock ? Colors.green[700] : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Size Selection
                  const Text(
                    'Select Size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      children:
                          product.sizes.map((size) {
                            return ChoiceChip(
                              label: Text(size),
                              selected: selectedSize.value == size,
                              onSelected: (selected) {
                                selectedSize.value = selected ? size : '';
                              },
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color Selection
                  const Text(
                    'Select Color',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      children:
                          product.colors.map((colorName) {
                            return InkWell(
                              onTap: () {
                                selectedColor.value = colorName;
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: getColorFromString(colorName),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        selectedColor.value == colorName
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Product Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Premium quality cotton t-shirt with a comfortable fit. Perfect for everyday wear. Machine washable and durable.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar with Add to Cart
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
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (quantity.value > 1) quantity.value--;
                        },
                        color: AppTheme.primaryColor,
                      ),
                      Obx(
                        () => Text(
                          '${quantity.value}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => quantity.value++,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedSize.value.isEmpty) {
                        SnackbarUtils.showError('Please select a size');
                        return;
                      }
                      if (selectedColor.value.isEmpty) {
                        SnackbarUtils.showError('Please select a color');
                        return;
                      }

                      cartController.addToCart(
                        product,
                        selectedSize.value,
                        selectedColor.value,
                      );

                      SnackbarUtils.showSuccess('Added to cart successfully');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
