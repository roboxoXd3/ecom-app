import 'package:flutter/material.dart';
import 'sort_option.dart';

class ProductFilter {
  RangeValues? priceRange;
  Set<String> categories;
  Set<String> brands;
  Set<String> vendors;
  double? minRating;
  bool? inStock;
  bool? onSale;
  SortOption sortBy;

  ProductFilter({
    this.priceRange,
    Set<String>? categories,
    Set<String>? brands,
    Set<String>? vendors,
    this.minRating,
    this.inStock,
    this.onSale,
    this.sortBy = SortOption.newest,
  }) : categories = categories ?? {},
       brands = brands ?? {},
       vendors = vendors ?? {};

  bool get hasFilters =>
      priceRange != null ||
      categories.isNotEmpty ||
      brands.isNotEmpty ||
      vendors.isNotEmpty ||
      minRating != null ||
      inStock != null ||
      onSale != null ||
      sortBy != SortOption.newest;
}
