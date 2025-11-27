import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../controllers/search_controller.dart' as app;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final app.SearchController _searchCtrl = Get.find<app.SearchController>();
  final RxBool _isSearching = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      print('🔵 [SEARCH_SCREEN] Suggestion clicked: "$query"');
      print('🔵 [SEARCH_SCREEN] Calling searchProducts with query: "$query"');
      _searchCtrl.searchProducts(query);
      print(
        '🔵 [SEARCH_SCREEN] Navigating to search-results with query: "$query"',
      );
      Get.toNamed('/search-results', arguments: query);
    }
  }

  /// Handle suggestion tap - navigate to product details if it's a product, otherwise perform search
  void _handleSuggestionTap(Map<String, dynamic> suggestion) {
    HapticFeedback.lightImpact();

    final type = suggestion['type'] as String?;
    final productId = suggestion['id'] as String?;
    final displayText = suggestion['display'] as String? ?? '';

    print(
      '🔵 [SEARCH_SCREEN] Suggestion tapped: "$displayText" (type: $type, id: $productId)',
    );

    // If it's a product suggestion with valid ID, navigate directly to product details
    if (type == 'product' && productId != null && productId.isNotEmpty) {
      print('🔵 [SEARCH_SCREEN] Navigating to product details: $productId');
      Get.toNamed('/product-details', arguments: productId);
    } else {
      // Otherwise, perform a search (for brands or fallback)
      print('🔵 [SEARCH_SCREEN] Performing search for: "$displayText"');
      _handleSearch(displayText);
    }
  }

  /// Handle image search
  Future<void> _handleImageSearch() async {
    try {
      HapticFeedback.lightImpact();

      // Show image source selection
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Start image search
        await _searchCtrl.searchProductsByImage(imageFile);

        // Navigate to results
        Get.toNamed('/search-results', arguments: 'Image Search');
      }
    } catch (e) {
      print('Error in image search: $e');
      Get.snackbar(
        'Error',
        'Failed to process image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Show dialog to select image source
  Future<ImageSource?> _showImageSourceDialog() async {
    return await Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image search button
                Obx(
                  () =>
                      _searchCtrl.isImageSearching.value
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.blue,
                            ),
                            onPressed: _handleImageSearch,
                            tooltip: 'Search by image',
                          ),
                ),
                // Clear/Search button
                Obx(
                  () =>
                      _isSearching.value
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchCtrl.suggestions.clear();
                              _isSearching.value = false;
                            },
                          )
                          : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          onChanged: (value) {
            _isSearching.value = value.isNotEmpty;
            _searchCtrl.getSuggestions(value);
          },
          onSubmitted: _handleSearch,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
      body: Obx(
        () =>
            _searchCtrl.suggestions.isEmpty
                ? _buildRecentSearches()
                : _buildSuggestions(),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_searchCtrl.recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () => _searchCtrl.clearRecentSearches(),
                  child: const Text('Clear All'),
                ),
            ],
          ),
        ),
        Expanded(
          child: Obx(
            () => ListView.builder(
              itemCount: _searchCtrl.recentSearches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_searchCtrl.recentSearches[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _searchCtrl.recentSearches.removeAt(index),
                  ),
                  onTap: () => _handleSearch(_searchCtrl.recentSearches[index]),
                );
              },
            ),
          ),
        ),
        // Popular searches section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Popular Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'iPhone',
                      'Headphones',
                      'Nike',
                      'Samsung',
                      'Watch',
                    ].map((tag) => _buildSearchTag(tag)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchCtrl.suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _searchCtrl.suggestions[index];
        final displayText = suggestion['display'] as String? ?? '';
        final suggestionType = suggestion['type'] as String? ?? 'brand';

        // Determine icon based on suggestion type
        final icon =
            suggestionType == 'product'
                ? Icons.shopping_bag_rounded
                : Icons.search_rounded;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 0.5,
            child: InkWell(
              onTap: () => _handleSuggestionTap(suggestion),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Icon - product icon for products, search icon for brands
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Suggestion text
                    Expanded(
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Arrow icon
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTag(String tag) {
    return InkWell(
      onTap: () => _handleSearch(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(tag, style: TextStyle(color: AppTheme.primaryColor)),
      ),
    );
  }
}
