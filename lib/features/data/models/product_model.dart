import 'vendor_model.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String images;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviews;
  final bool inStock;
  final String categoryId;
  final String brand;
  final double? discountPercentage;
  final bool isOnSale;
  final double? salePrice;
  final bool isFeatured;
  final bool isNewArrival;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime addedDate;
  final String? imageUrl;
  // New vendor-related fields
  final String vendorId;
  final Vendor? vendor;
  final String approvalStatus;

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
    required this.categoryId,
    required this.brand,
    this.discountPercentage,
    required this.isOnSale,
    this.salePrice,
    required this.isFeatured,
    required this.isNewArrival,
    required this.createdAt,
    required this.updatedAt,
    required this.addedDate,
    this.imageUrl,
    // New vendor-related parameters
    required this.vendorId,
    this.vendor,
    required this.approvalStatus,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      images: json['images'],
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      rating: double.parse(json['rating'].toString()),
      reviews: json['reviews'] ?? 0,
      inStock: json['in_stock'] ?? true,
      categoryId: json['category_id'],
      brand: json['brand'],
      discountPercentage:
          json['discount_percentage'] != null
              ? double.parse(json['discount_percentage'].toString())
              : null,
      isOnSale: json['is_on_sale'] ?? false,
      salePrice:
          json['sale_price'] != null
              ? double.parse(json['sale_price'].toString())
              : null,
      isFeatured: json['is_featured'] ?? false,
      isNewArrival: json['is_new_arrival'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      addedDate: DateTime.parse(json['added_date']),
      imageUrl: json['image_url'],
      // New vendor-related fields
      vendorId: json['vendor_id'] ?? '',
      vendor: json['vendors'] != null ? Vendor.fromJson(json['vendors']) : null,
      approvalStatus: json['approval_status'] ?? 'approved',
    );
  }

  List<String> get imageList => images.split(',').map((e) => e.trim()).toList();
}
