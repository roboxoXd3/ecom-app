import 'category_model.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviews;
  final bool inStock;
  final String? categoryId;
  final Category? category;
  final String? brand;
  final double? discountPercentage;
  final bool isOnSale;
  final double? salePrice;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.sizes,
    required this.colors,
    required this.rating,
    required this.reviews,
    required this.inStock,
    this.categoryId,
    this.category,
    this.brand,
    this.discountPercentage = 0,
    this.isOnSale = false,
    this.salePrice,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      images: List<String>.from(json['images']),
      sizes: List<String>.from(json['sizes']),
      colors: List<String>.from(json['colors']),
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'],
      inStock: json['in_stock'],
      categoryId: json['category_id'],
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      brand: json['brand'],
      discountPercentage: json['discount_percentage']?.toDouble(),
      isOnSale: json['is_on_sale'] ?? false,
      salePrice: json['sale_price']?.toDouble(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'sizes': sizes,
      'colors': colors,
      'rating': rating,
      'reviews': reviews,
      'in_stock': inStock,
      'category_id': categoryId,
      'brand': brand,
      'discount_percentage': discountPercentage,
      'is_on_sale': isOnSale,
      'sale_price': salePrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
