import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

class EnhancedProductService {
  final _api = ApiClient.instance;

  Future<Product> getEnhancedProduct(String productId) async {
    try {
      // Product detail is required — let it throw if it fails.
      final productResponse = await _api.get('/products/$productId/');
      final productData = productResponse.data as Map<String, dynamic>;

      // All sub-endpoints are optional — fetch in parallel, swallow 404s.
      final extras = await Future.wait([
        _safeGet('/products/$productId/specifications/'),
        _safeGet('/products/$productId/highlights/'),
        _safeGet('/products/$productId/delivery-info/'),
        _safeGet('/products/$productId/warranty-info/'),
        _safeGet('/products/$productId/offers/'),
        _safeGet('/products/$productId/feature-posters/'),
        _safeGet('/products/$productId/reviews-summary/'),
        _safeGet('/products/$productId/recommendations/'),
      ]);

      final specs = _extractList(extras[0]);
      final highlights = _extractList(extras[1]);
      final deliveryInfo = _extractSingle(extras[2]);
      final warrantyInfo = _extractSingle(extras[3]);
      final offers = _extractList(extras[4]);
      final featurePosters = _extractList(extras[5]);
      final reviewsSummary = _extractSingle(extras[6]);
      final recommendationsRaw = _extractSingle(extras[7]);
      final recommendations = recommendationsRaw != null
          ? {
              'similar': recommendationsRaw['similar_products'] ??
                  recommendationsRaw['similar'] ??
                  [],
              'from_seller': recommendationsRaw['from_seller_products'] ??
                  recommendationsRaw['from_seller'] ??
                  [],
              'you_might_also_like': recommendationsRaw['you_might_also_like'] ?? [],
            }
          : null;

      final completeProductData = {
        ...productData,
        'product_specifications': specs,
        'product_highlights': highlights,
        if (deliveryInfo != null) 'delivery_info': deliveryInfo,
        if (warrantyInfo != null) 'warranty_info': warrantyInfo,
        'product_offers': offers,
        'feature_posters': featurePosters,
        if (reviewsSummary != null) 'product_reviews_summary': reviewsSummary,
        if (recommendations != null) 'product_recommendations': recommendations,
      };

      return Product.fromJson(completeProductData);
    } catch (e) {
      throw Exception('Failed to load enhanced product: $e');
    }
  }

  /// GET that returns null instead of throwing on 404 / network errors.
  Future<dynamic> _safeGet(String path) async {
    try {
      final response = await _api.get(path);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Product>> getEnhancedProducts({
    List<String>? productIds,
    String? categoryId,
    String? vendorId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (productIds != null && productIds.isNotEmpty) {
        params['ids'] = productIds.join(',');
      }
      if (categoryId != null) params['category_id'] = categoryId;
      if (vendorId != null) params['vendor_id'] = vendorId;

      final response = await _api.get('/products/', queryParameters: params);
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load enhanced products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProductQA(
    String productId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        '/products/$productId/qa/',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      final results = ApiClient.unwrapResults(data);
      return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getRecommendedProducts(
    String productId, {
    String type = 'similar',
    int limit = 10,
  }) async {
    try {
      final response = await _api.get('/products/$productId/recommendations/');
      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        return _fallbackRecommendations(productId, limit);
      }

      List<String> recommendedIds = [];
      switch (type) {
        case 'similar':
          recommendedIds = _parseIdList(data['similar_products']);
          break;
        case 'from_seller':
          recommendedIds = _parseIdList(data['from_seller_products']);
          break;
        case 'you_might_also_like':
          recommendedIds = _parseIdList(data['you_might_also_like']);
          break;
      }

      if (recommendedIds.isEmpty) {
        return _fallbackRecommendations(productId, limit);
      }

      return getEnhancedProducts(
        productIds: recommendedIds.take(limit).toList(),
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

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
      final params = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (query != null && query.isNotEmpty) params['search'] = query;
      if (categoryId != null) params['category_id'] = categoryId;
      if (minPrice != null) params['price__gte'] = minPrice;
      if (maxPrice != null) params['price__lte'] = maxPrice;
      if (minRating != null) params['rating__gte'] = minRating;
      if (brands != null && brands.isNotEmpty) params['brand'] = brands.join(',');
      if (freeDelivery == true) params['free_delivery'] = true;

      final response = await _api.get('/products/', queryParameters: params);
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search enhanced products: $e');
    }
  }

  Future<void> trackProductView(String productId, {String? userId}) async {
    try {
      final body = userId != null ? {'user_id': userId} : null;
      await _api.post('/products/$productId/view/', data: body);
    } catch (e) {}
  }

  List<dynamic> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List;
    }
    return [];
  }

  Map<String, dynamic>? _extractSingle(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data.isNotEmpty) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  List<String> _parseIdList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map && item.containsKey('id')) {
          return item['id']?.toString() ?? '';
        }
        return item?.toString() ?? '';
      }).where((id) => id.isNotEmpty).toList();
    }
    return [];
  }

  Future<List<Product>> _fallbackRecommendations(
      String productId, int limit) async {
    try {
      final response = await _api.get('/products/$productId/');
      final data = response.data as Map<String, dynamic>?;
      final categoryId = data?['category_id']?.toString();
      return getEnhancedProducts(categoryId: categoryId, limit: limit);
    } catch (_) {
      return [];
    }
  }
}
