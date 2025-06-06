import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Semantic search - finds similar products based on meaning
  Future<List<Product>> semanticSearch({
    required String query,
    int limit = 10,
  }) async {
    try {
      print('🧠 Semantic search for: "$query"');

      // Get enhanced query with synonyms and stemming
      final expandedQuery = _expandSearchQuery(query);
      final queryWords =
          expandedQuery
              .split(' ')
              .where((word) => word.trim().isNotEmpty)
              .toList();

      // Build a more flexible OR query
      final searchConditions = <String>[];

      // Add conditions for each word in the expanded query
      for (final word in queryWords) {
        if (word.length > 2) {
          // Skip very short words
          searchConditions.add('name.ilike.%$word%');
          searchConditions.add('description.ilike.%$word%');
          searchConditions.add('brand.ilike.%$word%');
        }
      }

      if (searchConditions.isEmpty) {
        print('🧠 No valid search conditions, falling back to trending');
        return getTrendingProducts(limit: limit);
      }

      final orCondition = searchConditions.join(',');
      print('🧠 Search conditions: $orCondition');

      final response = await _supabase
          .from('products')
          .select('*, vendors(*)')
          .or(orCondition)
          .eq('in_stock', true)
          .eq('approval_status', 'approved')
          .order('rating', ascending: false)
          .limit(limit);

      print('🧠 Semantic search found: ${response.length} products');

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('❌ Error in semantic search: $e');
      return [];
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
}
