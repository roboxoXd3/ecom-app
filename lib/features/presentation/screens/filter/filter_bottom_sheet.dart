import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/filter_controller.dart';
import '../../../data/models/sort_option.dart' as sort;
import '../../../../core/utils/currency_utils.dart';

class FilterBottomSheet extends StatelessWidget {
  final FilterController controller = Get.find();

  FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRangeFilter(),
                  const Divider(),
                  _buildCategoriesFilter(),
                  const Divider(),
                  _buildBrandsFilter(),
                  const Divider(),
                  _buildRatingFilter(),
                  const Divider(),
                  _buildToggleFilters(),
                  const Divider(),
                  _buildSortOptions(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Filter & Sort',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            controller.resetFilters();
          },
          child: const Text('Reset All'),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values:
                controller.currentFilter.value.priceRange ??
                RangeValues(
                  controller.minPrice.value,
                  controller.maxPrice.value,
                ),
            min: controller.minPrice.value,
            max: controller.maxPrice.value,
            onChanged: (RangeValues values) {
              controller.updatePriceRange(values);
            },
            labels: RangeLabels(
              CurrencyUtils.formatAmount(
                controller.currentFilter.value.priceRange?.start ?? 0,
                decimalPlaces: 0,
              ),
              CurrencyUtils.formatAmount(
                controller.currentFilter.value.priceRange?.end ?? 0,
                decimalPlaces: 0,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCategoriesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            // Add your category chips here
          ],
        ),
      ],
    );
  }

  Widget _buildBrandsFilter() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Brands',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                controller.availableBrands.map((brand) {
                  final isSelected = controller.currentFilter.value.brands
                      .contains(brand);
                  return FilterChip(
                    label: Text(brand),
                    selected: isSelected,
                    onSelected: (selected) {
                      controller.toggleBrand(brand);
                    },
                  );
                }).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Obx(() {
          return Slider(
            value: controller.currentFilter.value.minRating ?? 0,
            min: 0,
            max: 5,
            divisions: 5,
            label: '${controller.currentFilter.value.minRating ?? 0}',
            onChanged: (value) {
              controller.updateRating(value);
            },
          );
        }),
      ],
    );
  }

  Widget _buildToggleFilters() {
    return Obx(() {
      return Column(
        children: [
          SwitchListTile(
            title: const Text('In Stock Only'),
            value: controller.currentFilter.value.inStock ?? false,
            onChanged: (value) {
              controller.toggleInStock();
            },
          ),
          SwitchListTile(
            title: const Text('On Sale'),
            value: controller.currentFilter.value.onSale ?? false,
            onChanged: (value) {
              controller.toggleOnSale();
            },
          ),
        ],
      );
    });
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Obx(() {
          return Column(
            children:
                sort.SortOption.values.map((option) {
                  return RadioListTile<sort.SortOption>(
                    title: Text(option.displayName),
                    value: option,
                    groupValue: controller.currentFilter.value.sortBy,
                    onChanged: (sort.SortOption? value) {
                      if (value != null) {
                        controller.updateSortOption(value);
                      }
                    },
                  );
                }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Get.back(result: true);
            },
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}
