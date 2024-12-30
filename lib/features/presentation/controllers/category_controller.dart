import 'package:get/get.dart';

import '../../data/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryController extends GetxController {
  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;
  final supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name');

      categories.value =
          (response as List)
              .map((category) => Category.fromJson(category))
              .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      // Handle error appropriately
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      final response =
          await supabase
              .from('categories')
              .insert(category.toJson())
              .select()
              .single();

      categories.add(Category.fromJson(response));
    } catch (e) {
      print('Error adding category: $e');
      // Handle error appropriately
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await supabase
          .from('categories')
          .update(category.toJson())
          .eq('id', category.id);

      int index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category;
      }
    } catch (e) {
      print('Error updating category: $e');
      // Handle error appropriately
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await supabase.from('categories').delete().eq('id', id);

      categories.removeWhere((category) => category.id == id);
    } catch (e) {
      print('Error deleting category: $e');
      // Handle error appropriately
    }
  }
}
