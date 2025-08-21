import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'image_search_service.dart';

class ProductSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImageSearchService _imageSearchService = ImageSearchService(); // NEW

  /// Basic text search using PostgreSQL full-text search
  Future<List<Product>> searchProducts({
    required String query,
    int limit = 20,
    int offset = 0,
    Map<String, dynamic>? filters,
  }) async {
    try {
      print('🔍 Searching for: "$query"');

      var queryBuilder = _supabase
          .from('products')
          .select('*, vendors(*)')
          .eq('in_stock', true)
          .eq('approval_status', 'approved');

      // Full-text search on name, description, and brand
      if (query.isNotEmpty) {
        // Use ilike for text search if textSearch is not available
        queryBuilder = queryBuilder.or(
          'name.ilike.%$query%,'
          'description.ilike.%$query%,'
          'brand.ilike.%$query%',
        );
      }

      // Apply filters
      if (filters != null) {
        queryBuilder = _applyFilters(queryBuilder, filters);
      }

      // Apply pagination and ordering
      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('📦 Found ${response.length} products for "$query"');
      if (response.isNotEmpty) {
        print('📦 First product: ${response[0]['name']}');
      }

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('❌ Error searching products: $e');
      return [];
    }
  }

  /// Natural language semantic search using vector embeddings
  Future<List<Product>> semanticSearch({
    required String query,
    int limit = 10,
    double threshold = 0.1, // Very low threshold for testing
  }) async {
    try {
      print('🧠 Starting semantic search for: "$query"');

      // Generate embedding for the search query
      final embeddingResponse = await _supabase.functions.invoke(
        'generate-query-embedding',
        body: {'query': query},
      );

      // Check if there's an error in the response
      if (embeddingResponse.data == null) {
        print('❌ Error generating query embedding: No data returned');
        print('🔄 Falling back to enhanced keyword search...');
        return enhancedKeywordSearch(
          query: query,
          limit: limit,
          threshold: threshold,
        );
      }

      final queryEmbedding = embeddingResponse.data['embedding'];
      if (queryEmbedding == null) {
        print('❌ No embedding received from function');
        print('🔄 Falling back to enhanced keyword search...');
        return enhancedKeywordSearch(
          query: query,
          limit: limit,
          threshold: threshold,
        );
      }

      print('🧠 Query embedding generated, performing vector search...');

      // Perform vector similarity search using RPC
      final response = await _supabase.rpc(
        'match_products',
        params: {
          'query_embedding': queryEmbedding,
          'match_threshold': threshold,
          'match_count': limit,
        },
      );

      if (response == null) {
        print('❌ No response from vector search');
        return [];
      }

      print('🧠 Vector search found: ${response.length} products');

      // Convert response to Product objects
      final products = <Product>[];
      for (final productData in response) {
        try {
          // The RPC function returns flattened data, we need to restructure for vendors
          final productMap = Map<String, dynamic>.from(productData);

          // Add missing fields that might be expected by Product.fromJson
          productMap['approval_status'] = 'approved';
          productMap['is_on_sale'] = productMap['is_on_sale'] ?? false;
          productMap['is_featured'] = productMap['is_featured'] ?? false;
          productMap['is_new_arrival'] = productMap['is_new_arrival'] ?? false;
          productMap['created_at'] =
              productMap['created_at'] ?? DateTime.now().toIso8601String();
          productMap['updated_at'] =
              productMap['updated_at'] ?? DateTime.now().toIso8601String();
          productMap['added_date'] =
              productMap['added_date'] ?? DateTime.now().toIso8601String();

          final product = Product.fromJson(productMap);
          products.add(product);
        } catch (e) {
          print('❌ Error parsing product: $e');
          print('Product data: $productData');
        }
      }

      return products;
    } catch (e) {
      print('❌ Error in semantic search: $e');
      // Fallback to enhanced keyword search
      return enhancedKeywordSearch(
        query: query,
        limit: limit,
        threshold: threshold,
      );
    }
  }

  /// Hybrid search combining keyword and semantic search for best results
  Future<List<Product>> hybridSearch({
    required String query,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      print('🔄 Starting hybrid search for: "$query"');

      // Run both searches in parallel
      final futures = await Future.wait([
        semanticSearch(query: query, limit: limit ~/ 2, threshold: 0.1),
        searchProducts(query: query, limit: limit ~/ 2, filters: filters),
      ]);

      final semanticResults = futures[0];
      final keywordResults = futures[1];

      print('🔄 Semantic results: ${semanticResults.length}');
      print('🔄 Keyword results: ${keywordResults.length}');

      // Score and rank products for image search
      final productScores = <String, double>{};
      final allProducts = <String, Product>{};

      // Score semantic results higher (they're more relevant for image descriptions)
      for (int i = 0; i < semanticResults.length; i++) {
        final product = semanticResults[i];
        allProducts[product.id] = product;
        productScores[product.id] =
            (productScores[product.id] ?? 0) +
            (10.0 - i); // Higher score for earlier results
      }

      // Score keyword results lower
      for (int i = 0; i < keywordResults.length; i++) {
        final product = keywordResults[i];
        allProducts[product.id] = product;
        productScores[product.id] =
            (productScores[product.id] ?? 0) + (5.0 - i * 0.5); // Lower scoring
      }

      // Sort by score and return top results
      final sortedProducts =
          allProducts.values.toList()..sort(
            (a, b) =>
                (productScores[b.id] ?? 0).compareTo(productScores[a.id] ?? 0),
          );

      print('🔄 Hybrid search found ${sortedProducts.length} unique products');
      for (final product in sortedProducts.take(3)) {
        print(
          '🔄 Top result: ${product.name} (score: ${productScores[product.id]?.toStringAsFixed(1)})',
        );
      }

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('❌ Error in hybrid search: $e');
      // Fallback to keyword search only
      return searchProducts(query: query, limit: limit, filters: filters);
    }
  }

  /// Get product recommendations based on category, price range, or similar products
  Future<List<Product>> getRecommendations({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? userId,
    int limit = 10,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('products')
          .select('*, vendors(*)')
          .eq('in_stock', true)
          .eq('approval_status', 'approved');

      if (categoryId != null) {
        queryBuilder = queryBuilder.eq('category_id', categoryId);
      }

      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('price', minPrice);
      }

      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', maxPrice);
      }

      final response = await queryBuilder
          .order('rating', ascending: false)
          .limit(limit);

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  /// Get trending/popular products
  Future<List<Product>> getTrendingProducts({int limit = 10}) async {
    try {
      print('⭐ Getting trending products (limit: $limit)');

      final response = await _supabase
          .from('products')
          .select('*, vendors(*)')
          .eq('in_stock', true)
          .eq('approval_status', 'approved')
          .order('rating', ascending: false)
          .order('reviews', ascending: false)
          .limit(limit);

      print('⭐ Found ${response.length} trending products');
      if (response.isNotEmpty) {
        print(
          '⭐ Top product: ${response[0]['name']} (rating: ${response[0]['rating']})',
        );
      }

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('❌ Error getting trending products: $e');
      return [];
    }
  }

  /// Get products on sale
  Future<List<Product>> getSaleProducts({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, vendors(*)')
          .eq('in_stock', true)
          .eq('approval_status', 'approved')
          .eq('is_on_sale', true)
          .order('discount_percentage', ascending: false)
          .limit(limit);

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('Error getting sale products: $e');
      return [];
    }
  }

  /// Get products by category for chatbot
  Future<List<Product>> getProductsByCategory(String categoryName) async {
    try {
      // First, try to get the category ID by name
      final categoryResponse =
          await _supabase
              .from('categories')
              .select('id')
              .eq('name', categoryName)
              .eq('is_active', true)
              .maybeSingle();

      if (categoryResponse == null) {
        print('Category "$categoryName" not found');
        return [];
      }

      final categoryId = categoryResponse['id'];

      // Then get products by category_id
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('in_stock', true)
          .eq('category_id', categoryId)
          .order('rating', ascending: false)
          .limit(10);

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('Error getting products by category: $e');
      // Fallback: try direct name search in product table
      try {
        final response = await _supabase
            .from('products')
            .select('*')
            .eq('in_stock', true)
            .ilike('name', '%$categoryName%')
            .order('rating', ascending: false)
            .limit(10);

        return (response as List)
            .map((product) => Product.fromJson(product))
            .toList();
      } catch (fallbackError) {
        print('Fallback search also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Apply filters to query builder
  dynamic _applyFilters(dynamic queryBuilder, Map<String, dynamic> filters) {
    if (filters['category_id'] != null) {
      queryBuilder = queryBuilder.eq('category_id', filters['category_id']);
    }

    if (filters['min_price'] != null) {
      queryBuilder = queryBuilder.gte('price', filters['min_price']);
    }

    if (filters['max_price'] != null) {
      queryBuilder = queryBuilder.lte('price', filters['max_price']);
    }

    if (filters['brand'] != null) {
      queryBuilder = queryBuilder.eq('brand', filters['brand']);
    }

    if (filters['is_on_sale'] == true) {
      queryBuilder = queryBuilder.eq('is_on_sale', true);
    }

    if (filters['min_rating'] != null) {
      queryBuilder = queryBuilder.gte('rating', filters['min_rating']);
    }

    return queryBuilder;
  }

  /// Expand search query with synonyms and related terms
  String _expandSearchQuery(String query) {
    // Enhanced synonyms with singular/plural forms and variations
    final synonyms = {
      // Clothing
      'shirt': 'shirts top tops blouse blouses tee tees t-shirt t-shirts',
      'shirts': 'shirt top tops blouse blouses tee tees t-shirt t-shirts',
      'pants': 'pant trousers trouser jeans jean bottoms bottom',
      'pant': 'pants trousers trouser jeans jean bottoms bottom',
      'jeans': 'jean pants pant trousers trouser denim denims',
      'jean': 'jeans pants pant trousers trouser denim denims',

      // Footwear
      'shoes': 'shoe sneakers sneaker boots boot sandals sandal footwear',
      'shoe': 'shoes sneakers sneaker boots boot sandals sandal footwear',
      'sneakers': 'sneaker shoes shoe boots boot running runners',
      'sneaker': 'sneakers shoes shoe boots boot running runners',
      'boots': 'boot shoes shoe sneakers sneaker footwear',
      'boot': 'boots shoes shoe sneakers sneaker footwear',

      // Accessories
      'bags': 'bag handbags handbag purses purse backpacks backpack',
      'bag': 'bags handbags handbag purses purse backpacks backpack',
      'handbags': 'handbag bags bag purses purse accessories',
      'handbag': 'handbags bags bag purses purse accessories',

      // Electronics
      'watches':
          'watch timepieces timepiece clocks clock smartwatches smartwatch',
      'watch':
          'watches timepieces timepiece clocks clock smartwatches smartwatch',
      'phones': 'phone mobile mobiles smartphone smartphones device devices',
      'phone': 'phones mobile mobiles smartphone smartphones device devices',
      'laptops': 'laptop computer computers notebook notebooks',
      'laptop': 'laptops computer computers notebook notebooks',

      // Clothing categories
      'dresses': 'dress gowns gown frocks frock outfits outfit',
      'dress': 'dresses gowns gown frocks frock outfits outfit',
      'jackets': 'jacket coats coat blazers blazer outerwear',
      'jacket': 'jackets coats coat blazers blazer outerwear',

      // Price-related
      'cheap': 'affordable budget low-cost inexpensive discounted',
      'expensive': 'premium luxury high-end costly pricey',
      'affordable': 'cheap budget low-cost inexpensive reasonable',

      // Condition/status
      'new': 'latest recent fresh newest brand-new',
      'sale': 'discount discounted offer offers deal deals',
      'trending': 'popular hot bestselling best-selling top-rated',

      // Gender/category
      'mens': 'men man male masculine guys',
      "men's": 'men man male masculine guys mens',
      'womens': 'women woman female feminine ladies',
      "women's": 'women woman female feminine ladies womens',
      'kids': 'children child kid baby babies toddler',
    };

    String expandedQuery = query.toLowerCase();

    // Apply synonym expansion
    synonyms.forEach((key, value) {
      if (expandedQuery.contains(key)) {
        expandedQuery += ' $value';
      }
    });

    // Apply basic stemming for common patterns
    expandedQuery = _applyStemming(expandedQuery);

    print('🔄 Original query: "$query"');
    print('🔄 Expanded query: "$expandedQuery"');

    return expandedQuery;
  }

  /// Apply basic stemming rules for common English patterns
  String _applyStemming(String query) {
    final words = query.split(' ');
    final stemmedWords = <String>[];

    for (String word in words) {
      word = word.trim().toLowerCase();
      if (word.isEmpty) continue;

      String stemmed = word;

      // Remove common plural endings
      if (word.endsWith('ies') && word.length > 4) {
        stemmed = '${word.substring(0, word.length - 3)}y'; // babies → baby
      } else if (word.endsWith('es') && word.length > 3) {
        stemmed = word.substring(0, word.length - 2); // watches → watch
      } else if (word.endsWith('s') && word.length > 3) {
        stemmed = word.substring(0, word.length - 1); // products → product
      }

      // Handle -ing endings
      if (word.endsWith('ing') && word.length > 4) {
        stemmed = word.substring(0, word.length - 3); // running → run
      }

      // Handle -ed endings
      if (word.endsWith('ed') && word.length > 3) {
        stemmed = word.substring(0, word.length - 2); // walked → walk
      }

      // Add both original and stemmed forms
      stemmedWords.add(word);
      if (stemmed != word) {
        stemmedWords.add(stemmed);
      }
    }

    return stemmedWords.join(' ');
  }

  /// Get search suggestions for autocomplete
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from('products')
          .select('name, brand')
          .or('name.ilike.%$query%,brand.ilike.%$query%')
          .limit(5);

      final suggestions = <String>[];
      for (final item in response) {
        if (item['name'].toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(item['name']);
        }
        if (item['brand'].toLowerCase().contains(query.toLowerCase()) &&
            !suggestions.contains(item['brand'])) {
          suggestions.add(item['brand']);
        }
      }

      return suggestions;
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  /// Get all categories for filtering
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Get all brands for filtering
  Future<List<String>> getBrands() async {
    try {
      final response = await _supabase
          .from('products')
          .select('brand')
          .not('brand', 'is', null)
          .order('brand');

      final brands = <String>{};
      for (final item in response) {
        if (item['brand'] != null) {
          brands.add(item['brand']);
        }
      }

      return brands.toList();
    } catch (e) {
      print('Error getting brands: $e');
      return [];
    }
  }

  /// Debug method - get all products to see what's in the database
  Future<List<Product>> getAllProducts() async {
    try {
      print('🔍 Getting ALL products for debugging...');

      final response = await _supabase.from('products').select('*').limit(10);

      print('📦 Total products in database: ${response.length}');
      for (final product in response) {
        print(
          '📦 Product: ${product['name']} (in_stock: ${product['in_stock']})',
        );
      }

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('❌ Error getting all products: $e');
      return [];
    }
  }

  /// NEW: Search products using image
  Future<List<Product>> searchByImage({
    required File imageFile,
    int limit = 10,
  }) async {
    try {
      print('🖼️ Starting image-based product search...');

      // Validate image
      if (!_imageSearchService.isValidImageFile(imageFile)) {
        throw Exception('Invalid image file format');
      }

      // Check file size (max 20MB for OpenAI)
      if (_imageSearchService.getFileSizeInMB(imageFile) > 20) {
        throw Exception('Image file too large (max 20MB)');
      }

      // Analyze image with OpenAI Vision
      final productDescription = await _imageSearchService
          .analyzeImageForProductSearch(imageFile);

      // Use enhanced search with better relevance scoring for image search
      print('🔍 Searching products with description: "$productDescription"');

      // Try semantic search first with stricter threshold
      final semanticProducts = await semanticSearch(
        query: productDescription,
        limit: limit,
        threshold: 0.05, // Slightly higher threshold for better relevance
      );

      if (semanticProducts.isNotEmpty) {
        print('✅ Semantic search found ${semanticProducts.length} products');

        // Score products based on name relevance to image description
        final scoredProducts = _scoreProductsByRelevance(
          semanticProducts,
          productDescription,
        );
        return scoredProducts.take(limit).toList();
      } else {
        // Fallback to keyword search with enhanced scoring
        print('🔄 Fallback: Using enhanced keyword search...');
        final keywordProducts = await enhancedKeywordSearch(
          query: productDescription,
          limit: limit,
        );

        if (keywordProducts.isNotEmpty) {
          final scoredProducts = _scoreProductsByRelevance(
            keywordProducts,
            productDescription,
          );
          return scoredProducts.take(limit).toList();
        }
      }

      // No products found, return empty list
      print('❌ No products found matching the image');
      return [];
    } catch (e) {
      print('❌ Error in image search: $e');
      throw Exception('Image search failed: $e');
    }
  }

  /// Score products by relevance to image description
  List<Product> _scoreProductsByRelevance(
    List<Product> products,
    String description,
  ) {
    final descriptionLower = description.toLowerCase();

    print('🔍 Analyzing description: "$descriptionLower"');

    // Score each product
    final scoredProducts =
        products.map((product) {
          double score = 0.0;
          final productName = product.name.toLowerCase();
          final productDesc = product.description.toLowerCase();

          print('🔍 Scoring product: "${product.name}"');

          // FOOTWEAR DETECTION (for running shoes search)
          if (descriptionLower.contains('shoes') ||
              descriptionLower.contains('sneakers') ||
              descriptionLower.contains('running shoes') ||
              descriptionLower.contains('athletic') ||
              descriptionLower.contains('footwear')) {
            if (productName.contains('shoe') ||
                productName.contains('sneaker') ||
                productName.contains('running')) {
              score += 100.0; // Very high bonus for footwear match
              print('   ✅ Footwear match bonus: +100');
            }
          }

          // SMARTWATCH DETECTION (for watch searches)
          if (descriptionLower.contains('smartwatch') ||
              descriptionLower.contains('smart watch') ||
              descriptionLower.contains('watch') ||
              descriptionLower.contains('wearable')) {
            if (productName.contains('smart') &&
                productName.contains('watch')) {
              score += 100.0; // Very high bonus for smartwatch match
              print('   ✅ Smartwatch match bonus: +100');
            } else if (productName.contains('watch')) {
              score += 50.0; // High bonus for watch match
              print('   ✅ Watch match bonus: +50');
            }
          }

          // CLOTHING DETECTION
          if (descriptionLower.contains('shirt') ||
              descriptionLower.contains('t-shirt') ||
              descriptionLower.contains('top') ||
              descriptionLower.contains('clothing')) {
            if (productName.contains('shirt') ||
                productName.contains('t-shirt')) {
              score += 100.0;
              print('   ✅ Clothing match bonus: +100');
            }
          }

          // YOGA/FITNESS CLOTHING
          if (descriptionLower.contains('yoga') ||
              descriptionLower.contains('pants') ||
              descriptionLower.contains('leggings') ||
              descriptionLower.contains('workout')) {
            if (productName.contains('yoga') || productName.contains('pants')) {
              score += 100.0;
              print('   ✅ Yoga/Pants match bonus: +100');
            }
          }

          // ACCESSORIES DETECTION
          if (descriptionLower.contains('sunglasses') ||
              descriptionLower.contains('glasses') ||
              descriptionLower.contains('eyewear')) {
            if (productName.contains('sunglasses') ||
                productName.contains('glasses')) {
              score += 100.0;
              print('   ✅ Sunglasses match bonus: +100');
            }
          }

          // WALLET/LEATHER GOODS
          if (descriptionLower.contains('wallet') ||
              descriptionLower.contains('leather')) {
            if (productName.contains('wallet') ||
                productName.contains('leather')) {
              score += 100.0;
              print('   ✅ Wallet/Leather match bonus: +100');
            }
          }

          // ELECTRONICS/EARBUDS
          if (descriptionLower.contains('earbuds') ||
              descriptionLower.contains('headphones') ||
              descriptionLower.contains('wireless') ||
              descriptionLower.contains('bluetooth')) {
            if (productName.contains('earbuds') ||
                productName.contains('headphones') ||
                productName.contains('wireless')) {
              score += 100.0;
              print('   ✅ Electronics match bonus: +100');
            }
          }

          // COLOR MATCHING BONUS (smaller bonus)
          final colors = [
            'black',
            'white',
            'gray',
            'grey',
            'pink',
            'blue',
            'red',
            'green',
            'silver',
            'gold',
          ];
          for (final color in colors) {
            if (descriptionLower.contains(color) &&
                (productName.contains(color) || productDesc.contains(color))) {
              score += 10.0;
              print('   ✅ Color match bonus ($color): +10');
            }
          }

          // PENALTY for completely unrelated items
          bool isFootwearSearch =
              descriptionLower.contains('shoe') ||
              descriptionLower.contains('sneaker') ||
              descriptionLower.contains('running shoes');
          bool isWatchSearch =
              descriptionLower.contains('watch') ||
              descriptionLower.contains('smartwatch');

          if (isFootwearSearch &&
              !productName.contains('shoe') &&
              !productName.contains('sneaker')) {
            score -= 50.0; // Penalty for non-footwear when searching shoes
            print('   ❌ Non-footwear penalty: -50');
          }

          if (isWatchSearch &&
              !productName.contains('watch') &&
              !productName.contains('smart')) {
            score -= 50.0; // Penalty for non-watch when searching watches
            print('   ❌ Non-watch penalty: -50');
          }

          print('   📊 Final score: ${score.toStringAsFixed(1)}');
          return MapEntry(product, score);
        }).toList();

    // Sort by score (highest first)
    scoredProducts.sort((a, b) => b.value.compareTo(a.value));

    // Filter out products with negative or very low scores
    final filteredProducts =
        scoredProducts.where((entry) => entry.value > 0.0).toList();

    // Log top results
    print('🎯 Product relevance scores:');
    for (final entry in scoredProducts.take(3)) {
      print('   ${entry.key.name}: ${entry.value.toStringAsFixed(1)}');
    }

    print('🎯 Filtered results (score > 0):');
    for (final entry in filteredProducts.take(3)) {
      print('   ${entry.key.name}: ${entry.value.toStringAsFixed(1)} ✅');
    }

    // Return only products with positive scores
    final result = filteredProducts.map((entry) => entry.key).toList();
    print(
      '🎯 Final result count: ${result.length} products (filtered from ${scoredProducts.length})',
    );

    return result;
  }

  /// Enhanced keyword search with semantic-like matching
  Future<List<Product>> enhancedKeywordSearch({
    required String query,
    int limit = 10,
    double threshold = 0.3,
  }) async {
    try {
      print('🔍 Starting enhanced keyword search for: "$query"');

      // Enhanced query expansion
      final expandedQuery = _expandSearchQuery(query);
      final queryWords =
          expandedQuery
              .toLowerCase()
              .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
              .split(' ')
              .where((word) => word.trim().isNotEmpty && word.length > 2)
              .toSet() // Remove duplicates
              .toList();

      if (queryWords.isEmpty) {
        return getTrendingProducts(limit: limit);
      }

      print('🔍 Query words: $queryWords');

      // Use a more reliable search approach - search for each word individually and combine
      final allResults = <Product>[];
      final seenIds = <String>{};

      // Prioritize important keywords for image search
      final priorityWords =
          queryWords
              .where(
                (word) => [
                  // Electronics & Tech
                  'smartwatch',
                  'watch',
                  'smart',
                  'fitness',
                  'tracking',
                  'tracker',
                  'wireless', 'earbuds', 'headphones', 'bluetooth',

                  // Clothing & Accessories
                  'shirt',
                  'tshirt',
                  't-shirt',
                  'pants',
                  'jeans',
                  'shoes',
                  'sneakers',
                  'dress', 'jacket', 'coat', 'wallet', 'bag', 'purse',
                  'sunglasses', 'glasses', 'hat', 'cap',

                  // Materials & Colors (important for visual matching)
                  'leather', 'cotton', 'silicone', 'metal', 'plastic', 'fabric',
                  'black',
                  'white',
                  'blue',
                  'red',
                  'green',
                  'gray',
                  'brown',
                  'teal',
                  'silver', 'gold', 'pink', 'purple', 'yellow', 'orange',

                  // Descriptive terms
                  'round', 'square', 'rectangular', 'oval', 'long', 'short',
                  'casual', 'formal', 'sporty', 'elegant', 'modern', 'classic',
                ].contains(word),
              )
              .toList();

      final otherWords =
          queryWords
              .where(
                (word) =>
                    !priorityWords.contains(word) &&
                    ![
                      'with',
                      'and',
                      'for',
                      'the',
                      'this',
                      'that',
                    ].contains(word),
              )
              .toList();

      // Search priority words first, then others
      final wordsToSearch = [
        ...priorityWords,
        ...otherWords.take(5),
      ]; // Limit to avoid too many searches

      for (final word in wordsToSearch) {
        try {
          print('🔍 Searching for word: "$word"');

          // Search in name
          var nameResults = await _supabase
              .from('products')
              .select('*, vendors(*)')
              .ilike('name', '%$word%')
              .eq('in_stock', true)
              .eq('approval_status', 'approved')
              .limit(limit);

          // Search in description
          var descResults = await _supabase
              .from('products')
              .select('*, vendors(*)')
              .ilike('description', '%$word%')
              .eq('in_stock', true)
              .eq('approval_status', 'approved')
              .limit(limit);

          // Search in brand
          var brandResults = await _supabase
              .from('products')
              .select('*, vendors(*)')
              .ilike('brand', '%$word%')
              .eq('in_stock', true)
              .eq('approval_status', 'approved')
              .limit(limit);

          // Combine all results
          final wordResults = [...nameResults, ...descResults, ...brandResults];
          print('🔍 Found ${wordResults.length} results for word "$word"');

          for (final productData in wordResults) {
            final productId = productData['id'] as String;
            if (!seenIds.contains(productId)) {
              try {
                final product = Product.fromJson(productData);
                allResults.add(product);
                seenIds.add(productId);
              } catch (e) {
                print('❌ Error parsing product: $e');
              }
            }
          }
        } catch (e) {
          print('❌ Error searching for word "$word": $e');
        }
      }

      print(
        '🔍 Enhanced keyword search found: ${allResults.length} unique products',
      );

      // Sort by rating and return
      allResults.sort((a, b) => b.rating.compareTo(a.rating));
      return allResults.take(limit).toList();
    } catch (e) {
      print('❌ Error in enhanced keyword search: $e');
      return [];
    }
  }
}
