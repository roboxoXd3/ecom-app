import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductRepository {
  final _api = ApiClient.instance;

  Future<List<Product>> getProducts() async {
    try {
      print('ProductRepository: Fetching /products/ ...');
      final response = await _api.get('/products/');
      final results = ApiClient.unwrapResults(response.data);
      final products = results
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      print('ProductRepository: Loaded ${products.length} products');
      return products;
    } catch (e) {
      print('ProductRepository: Error fetching products: $e');
      return [];
    }
  }

  Future<List<Product>> getNewArrivals() async {
    try {
      print('ProductRepository: Fetching /products/new-arrivals/ ...');
      final response = await _api.get('/products/new-arrivals/');
      final list = ApiClient.unwrapResults(response.data);
      final products = list
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      print('ProductRepository: Loaded ${products.length} new arrivals');
      return products;
    } catch (e) {
      print('ProductRepository: Error fetching new arrivals: $e');
      return [];
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      print('ProductRepository: Fetching /products/featured/ ...');
      final response = await _api.get('/products/featured/');
      final list = ApiClient.unwrapResults(response.data);
      final products = list
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      print('ProductRepository: Loaded ${products.length} featured products');
      return products;
    } catch (e) {
      print('ProductRepository: Error fetching featured products: $e');
      return [];
    }
  }
}
