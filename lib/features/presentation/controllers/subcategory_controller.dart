import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/subcategory_model.dart';

class SubcategoryController extends GetxController {
  final RxList<Subcategory> subcategories = <Subcategory>[].obs;
  final RxBool isLoading = false.obs;
  final supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    fetchSubcategories();
  }

  Future<void> fetchSubcategories() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('subcategories')
          .select()
          .eq('is_active', true)
          .order('name');

      subcategories.value =
          (response as List)
              .map((subcategory) => Subcategory.fromJson(subcategory))
              .toList();
    } catch (e) {
      print('Error fetching subcategories: $e');
      // Handle error appropriately
    } finally {
      isLoading.value = false;
    }
  }

  /// Get subcategories for a specific category
  List<Subcategory> getSubcategoriesForCategory(String categoryId) {
    return subcategories
        .where((subcategory) => subcategory.categoryId == categoryId)
        .toList();
  }

  /// Get subcategory by ID
  Subcategory? getSubcategoryById(String subcategoryId) {
    try {
      return subcategories.firstWhere((sub) => sub.id == subcategoryId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a category has subcategories
  bool hasSubcategories(String categoryId) {
    return subcategories.any((sub) => sub.categoryId == categoryId);
  }

  /// Get subcategory count for a category
  int getSubcategoryCount(String categoryId) {
    return subcategories.where((sub) => sub.categoryId == categoryId).length;
  }

  Future<void> addSubcategory(Subcategory subcategory) async {
    try {
      final response =
          await supabase
              .from('subcategories')
              .insert(subcategory.toJson())
              .select()
              .single();

      subcategories.add(Subcategory.fromJson(response));
    } catch (e) {
      print('Error adding subcategory: $e');
      // Handle error appropriately
    }
  }

  Future<void> updateSubcategory(Subcategory subcategory) async {
    try {
      await supabase
          .from('subcategories')
          .update(subcategory.toJson())
          .eq('id', subcategory.id);

      int index = subcategories.indexWhere((s) => s.id == subcategory.id);
      if (index != -1) {
        subcategories[index] = subcategory;
      }
    } catch (e) {
      print('Error updating subcategory: $e');
      // Handle error appropriately
    }
  }

  Future<void> deleteSubcategory(String id) async {
    try {
      await supabase.from('subcategories').delete().eq('id', id);
      subcategories.removeWhere((subcategory) => subcategory.id == id);
    } catch (e) {
      print('Error deleting subcategory: $e');
      // Handle error appropriately
    }
  }
}
