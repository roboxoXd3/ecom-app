import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

/// Enhanced Product Service for fetching products with all PDP features
/// Handles complex queries to get complete product data from multiple tables
class EnhancedProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get a complete enhanced product with all related data
  /// This is the main method for loading products in the Enhanced PDP
  Future<Product> getEnhancedProduct(String productId) async {
    try {
      // Main product query with basic joins
      final productResponse =
          await _supabase
              .from('products')
              .select('''
            *,
            vendors(*),
            categories(id, name, description),
            delivery_info(*),
            warranty_info(*),
            product_reviews_summary(*),
            product_recommendations(*)
          ''')
              .eq('id', productId)
              .single();

      // Get related data from separate tables
      final enhancedData = await Future.wait([
        _getProductOffers(productId),
        _getProductHighlights(productId),
        _getFeaturePosters(productId),
        _getProductSpecifications(productId),
      ]);

      // Combine all data
      final completeProductData = {
        ...productResponse,
        'product_offers': enhancedData[0],
        'product_highlights': enhancedData[1],
        'feature_posters': enhancedData[2],
        'product_specifications': enhancedData[3],
      };

      return Product.fromJson(completeProductData);
    } catch (e) {
      throw Exception('Failed to load enhanced product: $e');
    }
  }

  /// Get multiple enhanced products (for listings, recommendations, etc.)
  Future<List<Product>> getEnhancedProducts({
    List<String>? productIds,
    String? categoryId,
    String? vendorId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('products').select('''
            *,
            vendors(id, business_name, business_logo, average_rating),
            categories(id, name),
            delivery_info(free_delivery, eta_min_days, eta_max_days),
            product_reviews_summary(average_rating, total_reviews)
          ''');

      // Apply filters
      if (productIds != null && productIds.isNotEmpty) {
        query = query.inFilter('id', productIds);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (vendorId != null) {
        query = query.eq('vendor_id', vendorId);
      }

      // Apply pagination and ordering
      final response = await query
          .eq('approval_status', 'approved')
          .eq('in_stock', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // For listings, we don't need all the heavy data (offers, specs, etc.)
      // Just basic product info with key highlights
      final products = <Product>[];
      for (final productData in response) {
        try {
          final highlights = await _getProductHighlights(
            productData['id']?.toString() ?? '',
          );
          final productWithHighlights = {
            ...productData,
            'product_highlights': highlights,
          };
          products.add(Product.fromJson(productWithHighlights));
        } catch (e) {
          print('Error processing product ${productData['id']}: $e');
          // Skip this product and continue with others
          continue;
        }
      }

      return products;
    } catch (e) {
      throw Exception('Failed to load enhanced products: $e');
    }
  }

  /// Get product offers (coupons, bank offers, delivery offers, etc.)
  Future<List<Map<String, dynamic>>> _getProductOffers(String productId) async {
    try {
      if (productId.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('product_offers')
          .select('*')
          .eq('product_id', productId)
          .eq('is_active', true)
          .or(
            'expiry_date.is.null,expiry_date.gt.${DateTime.now().toIso8601String()}',
          )
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching product offers: $e');
      return [];
    }
  }

  /// Get product highlights (key selling points)
  Future<List<Map<String, dynamic>>> _getProductHighlights(
    String productId,
  ) async {
    try {
      if (productId.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('product_highlights')
          .select('*')
          .eq('product_id', productId)
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching product highlights: $e');
      return [];
    }
  }

  /// Get feature posters (marketing carousels)
  Future<List<Map<String, dynamic>>> _getFeaturePosters(
    String productId,
  ) async {
    try {
      if (productId.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('feature_posters')
          .select('*')
          .eq('product_id', productId)
          .eq('is_active', true)
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching feature posters: $e');
      return [];
    }
  }

  /// Get product specifications (grouped technical specs)
  Future<List<Map<String, dynamic>>> _getProductSpecifications(
    String productId,
  ) async {
    try {
      if (productId.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('product_specifications')
          .select('*')
          .eq('product_id', productId)
          .order('group_name, sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching product specifications: $e');
      return [];
    }
  }

  /// Get product Q&A
  Future<List<Map<String, dynamic>>> getProductQA(
    String productId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('product_qa')
          .select('*')
          .eq('product_id', productId)
          .eq('status', 'answered')
          .order('is_helpful_count', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching product Q&A: $e');
      return [];
    }
  }

  /// Get recommended products based on the recommendation engine
  Future<List<Product>> getRecommendedProducts(
    String productId, {
    String type = 'similar', // 'similar', 'from_seller', 'you_might_also_like'
    int limit = 10,
  }) async {
    try {
      // Get recommendation data
      final recommendationResponse =
          await _supabase
              .from('product_recommendations')
              .select('*')
              .eq('product_id', productId)
              .maybeSingle();

      List<String> recommendedIds = [];

      if (recommendationResponse != null) {
        switch (type) {
          case 'similar':
            final similarData = recommendationResponse['similar_products'];
            if (similarData is List) {
              recommendedIds =
                  similarData
                      .where((id) => id != null && id is String)
                      .cast<String>()
                      .toList();
            }
            break;
          case 'from_seller':
            final fromSellerData =
                recommendationResponse['from_seller_products'];
            if (fromSellerData is List) {
              recommendedIds =
                  fromSellerData
                      .where((id) => id != null && id is String)
                      .cast<String>()
                      .toList();
            }
            break;
          case 'you_might_also_like':
            final youMightLikeData =
                recommendationResponse['you_might_also_like'];
            if (youMightLikeData is List) {
              recommendedIds =
                  youMightLikeData
                      .where((id) => id != null && id is String)
                      .cast<String>()
                      .toList();
            }
            break;
        }
      }

      if (recommendedIds.isEmpty) {
        // Fallback: get products from same category
        final productResponse =
            await _supabase
                .from('products')
                .select('category_id')
                .eq('id', productId)
                .single();

        return getEnhancedProducts(
          categoryId: productResponse['category_id']?.toString(),
          limit: limit,
        );
      }

      // Get the recommended products
      return getEnhancedProducts(
        productIds: recommendedIds.take(limit).toList(),
        limit: limit,
      );
    } catch (e) {
      print('Error fetching recommended products: $e');
      return [];
    }
  }

  /// Search enhanced products with filters
  Future<List<Product>> searchEnhancedProducts({
    String? query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? brands,
    bool? freeDelivery,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var supabaseQuery = _supabase.from('products').select('''
            *,
            vendors(id, business_name, average_rating),
            categories(id, name),
            delivery_info(free_delivery, eta_min_days, eta_max_days),
            product_reviews_summary(average_rating, total_reviews)
          ''');

      // Apply filters
      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.textSearch('search_vector', query);
      }
      if (categoryId != null) {
        supabaseQuery = supabaseQuery.eq('category_id', categoryId);
      }
      if (minPrice != null) {
        supabaseQuery = supabaseQuery.gte('price', minPrice);
      }
      if (maxPrice != null) {
        supabaseQuery = supabaseQuery.lte('price', maxPrice);
      }
      if (minRating != null) {
        supabaseQuery = supabaseQuery.gte('rating', minRating);
      }
      if (brands != null && brands.isNotEmpty) {
        supabaseQuery = supabaseQuery.inFilter('brand', brands);
      }

      // Apply delivery filter through join
      if (freeDelivery == true) {
        // This requires a more complex query, for now we'll filter after fetch
      }

      final response = await supabaseQuery
          .eq('approval_status', 'approved')
          .eq('in_stock', true)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      // Convert to Product objects
      final products = <Product>[];
      for (final productData in response) {
        // Filter by free delivery if needed
        if (freeDelivery == true) {
          final deliveryInfo = productData['delivery_info'];
          if (deliveryInfo == null ||
              deliveryInfo.isEmpty ||
              !(deliveryInfo is List
                  ? deliveryInfo.first['free_delivery']
                  : deliveryInfo['free_delivery'])) {
            continue;
          }
        }

        final highlights = await _getProductHighlights(productData['id']);
        final productWithHighlights = {
          ...productData,
          'product_highlights': highlights,
        };
        products.add(Product.fromJson(productWithHighlights));
      }

      return products;
    } catch (e) {
      throw Exception('Failed to search enhanced products: $e');
    }
  }

  /// Update product view count and analytics
  Future<void> trackProductView(String productId, {String? userId}) async {
    try {
      // Update orders_count as a proxy for popularity
      await _supabase.rpc(
        'increment_product_views',
        params: {'product_id': productId},
      );
    } catch (e) {
      print('Error tracking product view: $e');
      // Don't throw error for analytics failures
    }
  }
}
