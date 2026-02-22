import 'package:get/get.dart';

import '../../data/models/subcategory_model.dart';
import 'category_controller.dart';

class SubcategoryController extends GetxController {
  final RxList<Subcategory> subcategories = <Subcategory>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _syncFromCategories();
  }

  void _syncFromCategories() {
    final catCtrl = Get.find<CategoryController>();

    // If categories are already loaded, extract immediately.
    if (catCtrl.categories.isNotEmpty) {
      _extractSubcategories(catCtrl);
    }

    // Re-extract whenever the categories list changes (e.g. after fetch).
    ever(catCtrl.categories, (_) => _extractSubcategories(catCtrl));
  }

  void _extractSubcategories(CategoryController catCtrl) {
    isLoading.value = true;
    final all = <Subcategory>[];
    for (final cat in catCtrl.categories) {
      all.addAll(cat.subcategories);
    }
    subcategories.value = all;
    isLoading.value = false;
    print('SubcategoryController: Extracted ${all.length} subcategories from ${catCtrl.categories.length} categories');
  }

  List<Subcategory> getSubcategoriesForCategory(String categoryId) {
    return subcategories
        .where((subcategory) => subcategory.categoryId == categoryId)
        .toList();
  }

  Subcategory? getSubcategoryById(String subcategoryId) {
    try {
      return subcategories.firstWhere((sub) => sub.id == subcategoryId);
    } catch (e) {
      return null;
    }
  }

  bool hasSubcategories(String categoryId) {
    return subcategories.any((sub) => sub.categoryId == categoryId);
  }

  int getSubcategoryCount(String categoryId) {
    return subcategories.where((sub) => sub.categoryId == categoryId).length;
  }
}
