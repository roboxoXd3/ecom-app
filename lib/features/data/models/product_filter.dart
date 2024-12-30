import 'package:flutter/material.dart';
import 'sort_option.dart';

class ProductFilter {
  RangeValues? priceRange;
  List<String> categories;
  List<String> brands;
  double? minRating;
  bool? inStock;
  bool? onSale;
  SortOption sortBy;

  ProductFilter({
    this.priceRange,
    this.categories = const [],
    this.brands = const [],
    this.minRating,
    this.inStock,
    this.onSale,
    this.sortBy = SortOption.newest,
  });

  ProductFilter copyWith({
    RangeValues? priceRange,
    List<String>? categories,
    List<String>? brands,
    double? minRating,
    bool? inStock,
    bool? onSale,
    SortOption? sortBy,
  }) {
    return ProductFilter(
      priceRange: priceRange ?? this.priceRange,
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      minRating: minRating ?? this.minRating,
      inStock: inStock ?? this.inStock,
      onSale: onSale ?? this.onSale,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasFilters =>
      priceRange != null ||
      categories.isNotEmpty ||
      brands.isNotEmpty ||
      minRating != null ||
      inStock != null ||
      onSale != null;

  void reset() {
    priceRange = null;
    categories.clear();
    brands.clear();
    minRating = null;
    inStock = null;
    onSale = null;
  }

  Map<String, dynamic> toJson() {
    return {
      'price_range':
          priceRange != null
              ? {'start': priceRange!.start, 'end': priceRange!.end}
              : null,
      'categories': categories,
      'brands': brands,
      'min_rating': minRating,
      'in_stock': inStock,
      'on_sale': onSale,
      'sort_by': sortBy.toString(),
    };
  }
}
