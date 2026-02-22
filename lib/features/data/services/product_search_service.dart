import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductSearchService {
  final _api = ApiClient.instance;

  Future<List<Product>> searchProducts({
    required String query,
    int limit = 20,
    int offset = 0,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final params = <String, dynamic>{
        'search': query,
        'limit': limit,
        'offset': offset,
      };
      if (filters != null) {
        params.addAll(_buildFilterParams(filters));
      }
      final response = await _api.get(
        '/products/search/',
        queryParameters: params,
      );
      final results = ApiClient.unwrapResults(response.data);
      return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  Future<List<Product>> semanticSearch({
    required String query,
    int limit = 10,
    double threshold = 0.3,
  }) async {
    return searchProducts(query: query, limit: limit);
  }

  Future<List<Product>> hybridSearch({
    required String query,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    return searchProducts(query: query, limit: limit, filters: filters);
  }

  Future<List<Product>> getRecommendations({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? userId,
    int limit = 10,
  }) async {
    try {
      final params = <String, dynamic>{
        'ordering': '-rating',
        'limit': limit,
      };
      if (categoryId != null) params['category_id'] = categoryId;
      if (minPrice != null) params['price__gte'] = minPrice;
      if (maxPrice != null) params['price__lte'] = maxPrice;

      final response = await _api.get('/products/', queryParameters: params);
      final results = ApiClient.unwrapResults(response.data);
      return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  Future<List<Product>> getTrendingProducts({int limit = 10}) async {
    try {
      final response = await _api.get(
        '/products/',
        queryParameters: {'ordering': '-rating', 'limit': limit},
      );
      final results = ApiClient.unwrapResults(response.data);
      return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting trending products: $e');
      return [];
    }
  }

  Future<List<Product>> getSaleProducts({int limit = 10}) async {
    try {
      final response = await _api.get(
        '/products/',
        queryParameters: {'is_on_sale': true, 'limit': limit},
      );
      final results = ApiClient.unwrapResults(response.data);
      return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting sale products: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryName) async {
    try {
      final categories = await getCategories();
      Map<String, dynamic>? category;
      for (final c in categories) {
        final name = c['name']?.toString();
        if (name != null && name.toLowerCase() == categoryName.toLowerCase()) {
          category = c;
          break;
        }
      }
      if (category == null) return searchProducts(query: categoryName, limit: 10);
      final categoryId = category['id'];
      final response = await _api.get(
        '/products/',
        queryParameters: {'category_id': categoryId, 'ordering': '-rating', 'limit': 10},
      );
      final results = ApiClient.unwrapResults(response.data);
      return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting products by category: $e');
      return searchProducts(query: categoryName, limit: 10);
    }
  }

  Future<List<Map<String, dynamic>>> getSearchSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];
      final products = await searchProducts(query: query, limit: 5);
      final suggestions = <Map<String, dynamic>>[];
      final addedBrands = <String>{};

      for (final p in products) {
        if (p.name.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add({
            'type': 'product',
            'id': p.id,
            'name': p.name,
            'display': p.name,
          });
        }
        if (p.brand.toLowerCase().contains(query.toLowerCase()) &&
            !addedBrands.contains(p.brand)) {
          addedBrands.add(p.brand);
          suggestions.add({'type': 'brand', 'name': p.brand, 'display': p.brand});
        }
      }
      return suggestions;
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _api.get('/categories/');
      final data = response.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      final results = ApiClient.unwrapResults(data);
      return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<List<String>> getBrands() async {
    return [];
  }

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _api.get('/products/', queryParameters: {'limit': 100});
      final results = ApiClient.unwrapResults(response.data);
      return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  Future<List<Product>> searchByImage({
    required File imageFile,
    int limit = 10,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'search_image.jpg',
        ),
      });
      final response = await _api.upload(
        '/products/search-by-image/',
        formData: formData,
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return [];
      final products = data['products'] as List<dynamic>? ?? [];
      return products.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error in image search: $e');
      throw Exception('Image search failed: $e');
    }
  }

  Future<List<Product>> enhancedKeywordSearch({
    required String query,
    int limit = 10,
    double threshold = 0.3,
  }) async {
    return searchProducts(query: query, limit: limit);
  }

  Map<String, dynamic> _buildFilterParams(Map<String, dynamic> filters) {
    final params = <String, dynamic>{};
    if (filters['category_id'] != null) {
      params['category_id'] = filters['category_id'];
    } else if (filters['categories'] != null && filters['categories'] is List) {
      final list = filters['categories'] as List;
      if (list.isNotEmpty) params['category_id__in'] = list.join(',');
    }
    if (filters['subcategory_id'] != null) {
      params['subcategory_id'] = filters['subcategory_id'];
    }
    if (filters['vendor_id'] != null) params['vendor_id'] = filters['vendor_id'];
    if (filters['min_price'] != null) params['price__gte'] = filters['min_price'];
    if (filters['max_price'] != null) params['price__lte'] = filters['max_price'];
    if (filters['brand'] != null) params['brand'] = filters['brand'];
    if (filters['is_on_sale'] == true) params['is_on_sale'] = true;
    if (filters['min_rating'] != null) params['rating__gte'] = filters['min_rating'];
    return params;
  }
}
