import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/category_model.dart';

class CategoryController extends GetxController {
  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;
  final _api = ApiClient.instance;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final response = await _api.get('/categories/');
      final results = ApiClient.unwrapResults(response.data);
      categories.value = results
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
      print('CategoryController: Loaded ${categories.length} categories');
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Admin-only. Mobile app should not use this.
  Future<void> addCategory(Category category) async {
    throw UnsupportedError('addCategory is admin-only and not supported in the mobile app');
  }

  /// Admin-only. Mobile app should not use this.
  Future<void> updateCategory(Category category) async {
    throw UnsupportedError('updateCategory is admin-only and not supported in the mobile app');
  }

  /// Admin-only. Mobile app should not use this.
  Future<void> deleteCategory(String id) async {
    throw UnsupportedError('deleteCategory is admin-only and not supported in the mobile app');
  }
}
