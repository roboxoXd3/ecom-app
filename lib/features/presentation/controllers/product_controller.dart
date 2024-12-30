import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/product_model.dart';
import '../../presentation/controllers/filter_controller.dart';
import '../screens/filter/filter_bottom_sheet.dart';

class ProductController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final FilterController filterController = Get.put(FilterController());

  @override
  void onInit() {
    super.onInit();
    fetchProducts().then((_) {
      filterController.initializeFilterRanges(products);
    });
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      products.value =
          (response as List<dynamic>)
              .map((json) => Product.fromJson(json))
              .toList();
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Product>> getNewArrivals() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      return (response as List<dynamic>)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching new arrivals: $e');
      return [];
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .eq('rating', 5) // Example: featured products have 5-star rating
          .limit(5);

      return (response as List<dynamic>)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching featured products: $e');
      return [];
    }
  }

  Future<void> showFilterBottomSheet() async {
    final result = await Get.bottomSheet(
      FilterBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );

    if (result == true) {
      // Apply filters and refresh products
      applyFilters();
    }
  }

  void applyFilters() {
    final filteredList = filterController.filterProducts(products);
    final sortedList = filterController.sortProducts(filteredList);
    products.value = sortedList;
  }
}
