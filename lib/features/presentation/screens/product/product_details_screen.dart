import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../controllers/cart_controller.dart';
import '../../../data/models/product_model.dart';
import '../home/home_screen.dart';
import '../../controllers/product_details_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/product_controller.dart';
import '../vendor/vendor_profile_screen.dart';

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
  final productDetailsController = Get.put(ProductDetailsController());
  final productController = Get.find<ProductController>();
  final CartController cartController = Get.find<CartController>();

  ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Initialize CartController if not already initialized
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    final CartController cartController = Get.find<CartController>();

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
          onPressed: () {
            try {
              // Close any active snackbars first
              if (Get.isSnackbarOpen) {
                Get.closeAllSnackbars();
              }
              Navigator.pop(context);
            } catch (e) {
              // Fallback to Navigator.pop if GetX fails
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Obx(
              () => IconButton(
                icon: Icon(
                  productController.wishlistProductIds.contains(product.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      productController.wishlistProductIds.contains(product.id)
                          ? Colors.red
                          : Colors.black,
                ),
                onPressed: () => productController.toggleWishlist(product),
              ),
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
                  onPressed: () {
                    final homeController = Get.find<HomeController>();
                    homeController.navigateToTab(2); // Set cart tab index first
                    Get.delete<ProductDetailsController>();
                    Get.off(() => const HomeScreen());
                  },
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
                    productDetailsController.updateImageIndex(index);
                  },
                ),
                items:
                    product.imageList.map((image) {
                      return Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => Center(
                                child: Icon(
                                  Icons.image,
                                  size: 100,
                                  color: Colors.grey[400],
                                ),
                              ),
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
                        product.images.split(',').asMap().entries.map((entry) {
                          return Container(
                            width:
                                productDetailsController
                                            .currentImageIndex
                                            .value ==
                                        entry.key
                                    ? 24
                                    : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color:
                                  productDetailsController
                                              .currentImageIndex
                                              .value ==
                                          entry.key
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryColor.withAlpha(77),
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
                        '₹${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Vendor Information - NEW
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Sold by ',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      InkWell(
                        onTap: () {
                          if (product.vendor != null) {
                            Get.to(
                              () =>
                                  VendorProfileScreen(vendor: product.vendor!),
                            );
                          }
                        },
                        child: Text(
                          product.vendor?.businessName ?? 'Be Smart Mall',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppTheme.ratingStars,
                        size: 20,
                      ),
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
                              selected:
                                  productDetailsController.selectedSize.value ==
                                  size,
                              onSelected: (selected) {
                                productDetailsController.updateSize(
                                  selected ? size : '',
                                );
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
                                productDetailsController.updateColor(colorName);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: getColorFromString(colorName),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        productDetailsController
                                                    .selectedColor
                                                    .value ==
                                                colorName
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
                          if (productDetailsController.quantity.value > 1) {
                            productDetailsController.decrementQuantity();
                          }
                        },
                        color: AppTheme.primaryColor,
                      ),
                      Obx(
                        () => Text(
                          '${productDetailsController.quantity.value}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed:
                            () => productDetailsController.incrementQuantity(),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (productDetailsController.selectedSize.value.isEmpty) {
                        SnackbarUtils.showError('Please select a size');
                        return;
                      }
                      if (productDetailsController
                          .selectedColor
                          .value
                          .isEmpty) {
                        SnackbarUtils.showError('Please select a color');
                        return;
                      }

                      await cartController.addToCart(
                        product,
                        productDetailsController.selectedSize.value,
                        productDetailsController.selectedColor.value,
                        productDetailsController.quantity.value,
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
