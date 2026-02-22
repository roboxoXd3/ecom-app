import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/services/enhanced_product_service.dart';
import 'product_controller.dart';

/// Enhanced Product Controller for managing Enhanced PDP state
/// Handles loading complete product data from database with all enhanced features
class EnhancedProductController extends GetxController {
  final EnhancedProductService _productService = EnhancedProductService();

  // In-memory cache: productId → fully loaded Product
  final Map<String, Product> _cache = {};

  // Core product data
  final Rx<Product?> product = Rx<Product?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Product Q&A
  final RxList<Map<String, dynamic>> qaList = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingQA = false.obs;

  // Recommendations
  final RxList<Product> similarProducts = <Product>[].obs;
  final RxList<Product> fromSellerProducts = <Product>[].obs;
  final RxList<Product> youMightAlsoLike = <Product>[].obs;
  final RxBool isLoadingRecommendations = false.obs;

  // UI State
  final RxInt currentImageIndex = 0.obs;
  final RxString selectedColor = ''.obs;
  final RxString selectedSize = ''.obs;
  final RxInt quantity = 1.obs;

  // Enhanced PDP specific state
  final RxInt currentFeaturePosterIndex = 0.obs;
  final RxString selectedSpecGroup = ''.obs;
  final RxBool showAllSpecs = false.obs;

  /// Load complete enhanced product data with two-phase strategy:
  /// Phase 1 — show immediately from cache or allProducts list (zero network).
  /// Phase 2 — fetch full enhanced data in background and update UI.
  Future<void> loadEnhancedProduct(String productId) async {
    error.value = '';

    // Phase 1: show something immediately without any network call
    final cached = _cache[productId];
    if (cached != null) {
      product.value = cached;
      _initializeProductState(cached);
      isLoading.value = false;
      _loadAdditionalData(productId);
      return;
    }

    // Try to use the product already loaded for the home/listing screen
    if (Get.isRegistered<ProductController>()) {
      final listProduct = Get.find<ProductController>()
          .allProducts
          .firstWhereOrNull((p) => p.id == productId);
      if (listProduct != null) {
        product.value = listProduct;
        _initializeProductState(listProduct);
      }
    }

    // Phase 2: fetch full enhanced product (specs, highlights, etc.)
    // Only show the full-screen loader if we have nothing to show yet
    if (product.value == null) isLoading.value = true;

    try {
      final enhancedProduct = await _productService.getEnhancedProduct(
        productId,
      );
      _cache[productId] = enhancedProduct;
      product.value = enhancedProduct;
      _initializeProductState(enhancedProduct);
      _productService.trackProductView(productId);
      _loadAdditionalData(productId);
    } catch (e) {
      if (product.value == null) error.value = e.toString();
      print('Error loading enhanced product: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Initialize UI state based on product data
  void _initializeProductState(Product product) {
    // Set default color and size
    if (product.colors.isNotEmpty) {
      selectedColor.value = product.colors.first.name;
    }
    if (product.sizes.isNotEmpty) {
      selectedSize.value = product.sizes.first;
    }

    // Set default spec group
    if (product.specifications.isNotEmpty) {
      selectedSpecGroup.value = product.specifications.first.group;
    }

    // Reset other state
    currentImageIndex.value = 0;
    currentFeaturePosterIndex.value = 0;

    // ProductDetailsController has been removed - EnhancedProductController is now the single source of truth
    quantity.value = 1;
    showAllSpecs.value = false;
  }

  /// Load additional data that's not critical for initial render
  Future<void> _loadAdditionalData(String productId) async {
    // Load Q&A
    _loadProductQA(productId);

    // Load recommendations
    _loadRecommendations(productId);
  }

  /// Load product Q&A
  Future<void> _loadProductQA(String productId) async {
    try {
      isLoadingQA.value = true;
      final qa = await _productService.getProductQA(productId, limit: 5);
      qaList.value = qa;
    } catch (e) {
      print('Error loading product Q&A: $e');
    } finally {
      isLoadingQA.value = false;
    }
  }

  /// Load product recommendations
  Future<void> _loadRecommendations(String productId) async {
    try {
      isLoadingRecommendations.value = true;

      // Load all recommendation types in parallel
      final results = await Future.wait([
        _productService.getRecommendedProducts(
          productId,
          type: 'similar',
          limit: 6,
        ),
        _productService.getRecommendedProducts(
          productId,
          type: 'from_seller',
          limit: 6,
        ),
        _productService.getRecommendedProducts(
          productId,
          type: 'you_might_also_like',
          limit: 8,
        ),
      ]);

      similarProducts.value = results[0];
      fromSellerProducts.value = results[1];
      youMightAlsoLike.value = results[2];
    } catch (e) {
      print('Error loading recommendations: $e');
    } finally {
      isLoadingRecommendations.value = false;
    }
  }

  /// Update selected color and refresh images
  void updateSelectedColor(String color) {
    selectedColor.value = color;
    currentImageIndex.value = 0; // Reset to first image of new color

    // Force UI update by triggering reactive update
    update();
  }

  /// Update selected size
  void updateSelectedSize(String size) {
    selectedSize.value = size;
  }

  /// Update quantity
  void updateQuantity(int newQuantity) {
    if (newQuantity > 0) {
      quantity.value = newQuantity;
    }
  }

  /// Increment quantity
  void incrementQuantity() {
    quantity.value++;
  }

  /// Decrement quantity
  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  /// Update current image index
  void updateImageIndex(int index) {
    currentImageIndex.value = index;
  }

  /// Update feature poster index
  void updateFeaturePosterIndex(int index) {
    currentFeaturePosterIndex.value = index;
  }

  /// Toggle specification group visibility
  void toggleSpecGroup(String group) {
    if (selectedSpecGroup.value == group && showAllSpecs.value) {
      showAllSpecs.value = false;
    } else {
      selectedSpecGroup.value = group;
      showAllSpecs.value = true;
    }
  }

  /// Get current product images based on selected color
  List<String> get currentImages {
    final currentProduct = product.value;
    if (currentProduct == null) return [];

    return currentProduct.getImagesForColor(selectedColor.value);
  }

  /// Get current image URL for display
  String get currentImageUrl {
    final images = currentImages;
    if (images.isNotEmpty && currentImageIndex.value < images.length) {
      return images[currentImageIndex.value];
    }
    return '';
  }

  /// Check if more images available for current color
  bool get hasMultipleImages {
    return currentImages.length > 1;
  }

  /// Get current product price (considering sale price)
  double get currentPrice {
    final currentProduct = product.value;
    if (currentProduct == null) return 0.0;

    return currentProduct.salePrice ?? currentProduct.price;
  }

  /// Get savings amount if product is on sale
  double? get savingsAmount {
    final currentProduct = product.value;
    if (currentProduct == null || currentProduct.mrp == null) return null;

    return currentProduct.mrp! - currentPrice;
  }

  /// Get savings percentage
  double? get savingsPercentage {
    final currentProduct = product.value;
    if (currentProduct == null || currentProduct.mrp == null) return null;

    return ((currentProduct.mrp! - currentPrice) / currentProduct.mrp!) * 100;
  }

  /// Check if product has enhanced features
  bool get hasEnhancedFeatures {
    final currentProduct = product.value;
    if (currentProduct == null) return false;

    return currentProduct.offers.isNotEmpty ||
        currentProduct.highlights.isNotEmpty ||
        currentProduct.featurePosters.isNotEmpty ||
        currentProduct.specifications.isNotEmpty ||
        currentProduct.deliveryInfo != null ||
        currentProduct.warranty != null;
  }

  /// Get delivery ETA text
  String get deliveryETA {
    final deliveryInfo = product.value?.deliveryInfo;
    if (deliveryInfo == null) return 'Standard delivery';

    if (deliveryInfo.etaMinDays == deliveryInfo.etaMaxDays) {
      return '${deliveryInfo.etaMinDays} days';
    } else {
      return '${deliveryInfo.etaMinDays}-${deliveryInfo.etaMaxDays} days';
    }
  }

  /// Check if free delivery is available
  bool get hasFreeDelivery {
    return product.value?.deliveryInfo?.freeDelivery ?? false;
  }

  /// Get warranty text
  String get warrantyText {
    final warranty = product.value?.warranty;
    if (warranty == null) return 'No warranty';

    return '${warranty.duration} ${warranty.type.toLowerCase()} warranty';
  }

  /// Get return policy text
  String get returnPolicyText {
    final deliveryInfo = product.value?.deliveryInfo;
    if (deliveryInfo == null) return 'Standard returns';

    return '${deliveryInfo.returnWindowDays}-day returns';
  }

  /// Check if COD is available
  bool get isCODAvailable {
    return product.value?.deliveryInfo?.codEligible ?? false;
  }

  /// Get active offers count
  int get activeOffersCount {
    return product.value?.offers.length ?? 0;
  }

  /// Get highlights count
  int get highlightsCount {
    return product.value?.highlights.length ?? 0;
  }

  /// Get specifications groups
  List<String> get specificationGroups {
    final specs = product.value?.specifications ?? [];
    return specs.map((spec) => spec.group).toList();
  }

  /// Get specifications for selected group
  List<SpecRow> get selectedGroupSpecs {
    final specs = product.value?.specifications ?? [];
    final selectedGroup = specs.firstWhereOrNull(
      (spec) => spec.group == selectedSpecGroup.value,
    );
    return selectedGroup?.rows ?? [];
  }

  /// Refresh product data
  Future<void> refreshProduct() async {
    final currentProduct = product.value;
    if (currentProduct != null) {
      await loadEnhancedProduct(currentProduct.id);
    }
  }

  /// Invalidate the cache for a specific product (call after write operations)
  void invalidateCache(String productId) {
    _cache.remove(productId);
  }

  /// Clear controller state
  void clearState() {
    product.value = null;
    error.value = '';
    qaList.clear();
    similarProducts.clear();
    fromSellerProducts.clear();
    youMightAlsoLike.clear();

    // Reset UI state
    currentImageIndex.value = 0;
    selectedColor.value = '';
    selectedSize.value = '';
    quantity.value = 1;
    currentFeaturePosterIndex.value = 0;
    selectedSpecGroup.value = '';
    showAllSpecs.value = false;
  }

  @override
  void onClose() {
    clearState();
    super.onClose();
  }
}
