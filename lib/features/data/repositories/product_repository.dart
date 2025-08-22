import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRepository {
  final supabase = Supabase.instance.client;

  Future<List<Product>> getProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select('*, categories(*), vendors!inner(*)')
          .eq('in_stock', true)
          .eq('approval_status', 'approved')
          .eq('vendors.status', 'approved')
          .eq('vendors.is_active', true)
          .order('created_at');

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to fetch products');
    }
  }

  Future<List<Product>> getNewArrivals() async {
    try {
      final response = await supabase
          .from('products')
          .select('*, categories(*), vendors!inner(*)')
          .eq('is_new_arrival', true)
          .eq('approval_status', 'approved')
          .eq('vendors.status', 'approved')
          .eq('vendors.is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching new arrivals: $e');
      return [];
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select('*, categories(*), vendors!inner(*)')
          .eq('is_featured', true)
          .eq('approval_status', 'approved')
          .eq('vendors.status', 'approved')
          .eq('vendors.is_active', true)
          .limit(4);

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('Error fetching featured products: $e');
      throw Exception('Failed to fetch featured products');
    }
  }
}
