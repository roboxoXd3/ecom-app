import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/search_controller.dart' as app;
import '../../controllers/category_controller.dart';
import '../../controllers/search_controller.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final app.SearchController _searchController = Get.find();
  final CategoryController _categoryController = Get.find();

  late RangeValues _priceRange;
  late List<String> _selectedCategories;
  late double? _minRating;

  @override
  void initState() {
    super.initState();
    _priceRange = _searchController.currentFilter.value.priceRange;
    _selectedCategories = List.from(
      _searchController.currentFilter.value.categories,
    );
    _minRating = _searchController.currentFilter.value.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 1000);
                    _selectedCategories = [];
                    _minRating = null;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),

          // Categories
          const Text(
            'Categories',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children:
                _categoryController.categories.map((category) {
                  return FilterChip(
                    label: Text(category.name),
                    selected: _selectedCategories.contains(category.id),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category.id);
                        } else {
                          _selectedCategories.remove(category.id);
                        }
                      });
                    },
                  );
                }).toList(),
          ),

          // Rating
          const Text(
            'Minimum Rating',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index + 1 <= (_minRating ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _minRating = index + 1.0;
                  });
                },
              );
            }),
          ),

          // Apply Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _searchController.applyFilters(
                  ProductFilter(
                    priceRange: _priceRange,
                    categories: _selectedCategories,
                    minRating: _minRating,
                  ),
                );
                Get.back();
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
