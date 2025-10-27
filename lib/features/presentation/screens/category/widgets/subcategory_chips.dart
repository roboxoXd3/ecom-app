import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../data/models/subcategory_model.dart';
import '../../../controllers/subcategory_controller.dart';
import '../../../../../core/theme/app_theme.dart';

class SubcategoryChips extends StatelessWidget {
  final String categoryId;
  final RxList<String> selectedSubcategoryIds;
  final Function(List<String>) onSelectionChanged;

  const SubcategoryChips({
    super.key,
    required this.categoryId,
    required this.selectedSubcategoryIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subcategoryController = Get.find<SubcategoryController>();

    return Obx(() {
      final subcategories = subcategoryController.getSubcategoriesForCategory(
        categoryId,
      );

      if (subcategories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FadeInLeft(
                duration: const Duration(milliseconds: 400),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter by Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    // Select All / Clear All button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _toggleSelectAll(subcategories);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selectedSubcategoryIds.length ==
                                      subcategories.length
                                  ? Colors.red.withOpacity(0.1)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                selectedSubcategoryIds.length ==
                                        subcategories.length
                                    ? Colors.red.withOpacity(0.3)
                                    : AppTheme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          selectedSubcategoryIds.length == subcategories.length
                              ? 'Clear All'
                              : 'Select All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                selectedSubcategoryIds.length ==
                                        subcategories.length
                                    ? Colors.red[700]
                                    : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chips Horizontal Scroll
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final subcategory = subcategories[index];
                  final isSelected = selectedSubcategoryIds.contains(
                    subcategory.id,
                  );

                  return FadeInRight(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          subcategory.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                        onSelected: (selected) {
                          HapticFeedback.lightImpact();
                          _toggleSubcategory(subcategory.id, selected);
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color:
                              isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        elevation: isSelected ? 4 : 0,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Selection Summary
            if (selectedSubcategoryIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    '${selectedSubcategoryIds.length} of ${subcategories.length} categories selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  void _toggleSubcategory(String subcategoryId, bool selected) {
    if (selected) {
      if (!selectedSubcategoryIds.contains(subcategoryId)) {
        selectedSubcategoryIds.add(subcategoryId);
      }
    } else {
      selectedSubcategoryIds.remove(subcategoryId);
    }
    onSelectionChanged(selectedSubcategoryIds.toList());
  }

  void _toggleSelectAll(List<Subcategory> subcategories) {
    if (selectedSubcategoryIds.length == subcategories.length) {
      // Clear all
      selectedSubcategoryIds.clear();
    } else {
      // Select all
      selectedSubcategoryIds.clear();
      selectedSubcategoryIds.addAll(subcategories.map((s) => s.id));
    }
    onSelectionChanged(selectedSubcategoryIds.toList());
  }
}
