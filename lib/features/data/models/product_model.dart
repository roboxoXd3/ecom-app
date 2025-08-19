import 'dart:convert';
import 'vendor_model.dart';

// New model classes for PDP features
class ProductOffer {
  final String type; // 'coupon', 'bank', 'delivery', 'cod', 'timer'
  final String? code;
  final String description;
  final DateTime? expiryDate;
  final String? iconUrl;

  ProductOffer({
    required this.type,
    this.code,
    required this.description,
    this.expiryDate,
    this.iconUrl,
  });

  factory ProductOffer.fromJson(Map<String, dynamic> json) {
    return ProductOffer(
      type: json['type']?.toString() ?? '',
      code: json['code']?.toString(),
      description: json['description']?.toString() ?? '',
      expiryDate:
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'].toString())
              : null,
      iconUrl: json['icon_url']?.toString(),
    );
  }
}

class FeaturePoster {
  final String title;
  final String subtitle;
  final String mediaUrl;
  final String aspectRatio;
  final String? ctaLabel;

  FeaturePoster({
    required this.title,
    required this.subtitle,
    required this.mediaUrl,
    this.aspectRatio = '16:9',
    this.ctaLabel,
  });

  factory FeaturePoster.fromJson(Map<String, dynamic> json) {
    return FeaturePoster(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      aspectRatio: json['aspect_ratio']?.toString() ?? '16:9',
      ctaLabel: json['cta_label']?.toString(),
    );
  }
}

class ProductSpec {
  final String group;
  final List<SpecRow> rows;

  ProductSpec({required this.group, required this.rows});

  factory ProductSpec.fromJson(Map<String, dynamic> json) {
    return ProductSpec(
      group: json['group']?.toString() ?? '',
      rows:
          (json['rows'] as List? ?? [])
              .map((row) => SpecRow.fromJson(row))
              .toList(),
    );
  }
}

class SpecRow {
  final String name;
  final String value;

  SpecRow({required this.name, required this.value});

  factory SpecRow.fromJson(Map<String, dynamic> json) {
    return SpecRow(
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class ProductHighlight {
  final String label;
  final String? iconUrl;

  ProductHighlight({required this.label, this.iconUrl});

  factory ProductHighlight.fromJson(Map<String, dynamic> json) {
    return ProductHighlight(
      label: json['label']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
    );
  }
}

class DeliveryInfo {
  final int returnWindowDays;
  final bool codEligible;
  final bool freeDelivery;
  final double? shippingFee;
  final int? etaMinDays;
  final int? etaMaxDays;

  DeliveryInfo({
    required this.returnWindowDays,
    required this.codEligible,
    this.freeDelivery = false,
    this.shippingFee,
    this.etaMinDays,
    this.etaMaxDays,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      returnWindowDays: json['return_window_days'] ?? 7,
      codEligible: json['cod_eligible'] ?? false,
      freeDelivery: json['free_delivery'] ?? false,
      shippingFee: json['shipping_fee']?.toDouble(),
      etaMinDays: json['eta_min_days'],
      etaMaxDays: json['eta_max_days'],
    );
  }
}

class WarrantyInfo {
  final String type;
  final String duration;
  final String? description;

  WarrantyInfo({required this.type, required this.duration, this.description});

  factory WarrantyInfo.fromJson(Map<String, dynamic> json) {
    return WarrantyInfo(
      type: json['type']?.toString() ?? 'Manufacturer',
      duration: json['duration']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class ReviewsSummary {
  final int withMedia;
  final List<int> histogram; // [1-star count, 2-star, 3-star, 4-star, 5-star]

  ReviewsSummary({required this.withMedia, required this.histogram});

  factory ReviewsSummary.fromJson(Map<String, dynamic> json) {
    return ReviewsSummary(
      withMedia: json['with_media'] ?? 0,
      histogram: List<int>.from(json['histogram'] ?? [0, 0, 0, 0, 0]),
    );
  }
}

class ProductRecommendations {
  final List<String> similar;
  final List<String> fromSeller;
  final List<String> youMightAlsoLike;

  ProductRecommendations({
    required this.similar,
    required this.fromSeller,
    required this.youMightAlsoLike,
  });

  factory ProductRecommendations.fromJson(Map<String, dynamic> json) {
    return ProductRecommendations(
      similar: List<String>.from(json['similar'] ?? []),
      fromSeller: List<String>.from(json['from_seller'] ?? []),
      youMightAlsoLike: List<String>.from(json['you_might_also_like'] ?? []),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String images;
  final List<String> sizes;
  final List<String> colors;
  final Map<String, List<String>>? colorImages; // NEW: Color-specific images
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
  final String? videoUrl; // NEW: Video URL field
  // New vendor-related fields
  final String vendorId;
  final Vendor? vendor;
  final String approvalStatus;

  // Size chart related fields
  final String? sizeChartTemplateId;
  final Map<String, dynamic>? customSizeChartData;
  final String sizeGuideType; // 'template', 'custom', 'none'

  // NEW PDP FIELDS
  final String? subtitle;
  final double? mrp; // Maximum Retail Price
  final String currency;
  final int? ordersCount;
  final List<ProductOffer> offers;
  final List<ProductHighlight> highlights;
  final List<FeaturePoster> featurePosters;
  final List<ProductSpec> specifications;
  final List<String> boxContents;
  final List<String> usageInstructions;
  final List<String> careInstructions;
  final List<String> safetyNotes;
  final DeliveryInfo? deliveryInfo;
  final WarrantyInfo? warranty;
  final ReviewsSummary? reviewsSummary;
  final ProductRecommendations? recommendations;
  final Map<String, dynamic>? seoData;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.sizes,
    required this.colors,
    this.colorImages, // NEW: Color images parameter
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
    this.videoUrl, // NEW: Video URL parameter
    // New vendor-related parameters
    required this.vendorId,
    this.vendor,
    required this.approvalStatus,

    // Size chart related parameters
    this.sizeChartTemplateId,
    this.customSizeChartData,
    this.sizeGuideType = 'template',

    // NEW PDP PARAMETERS
    this.subtitle,
    this.mrp,
    this.currency = 'INR',
    this.ordersCount,
    this.offers = const [],
    this.highlights = const [],
    this.featurePosters = const [],
    this.specifications = const [],
    this.boxContents = const [],
    this.usageInstructions = const [],
    this.careInstructions = const [],
    this.safetyNotes = const [],
    this.deliveryInfo,
    this.warranty,
    this.reviewsSummary,
    this.recommendations,
    this.seoData,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      images: json['images'] ?? '',
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      colorImages: _parseColorImages(
        json['color_images'],
      ), // NEW: Parse color images
      rating:
          json['rating'] != null
              ? double.parse(json['rating'].toString())
              : 0.0,
      reviews: json['reviews'] ?? 0,
      inStock: json['in_stock'] ?? true,
      categoryId: json['category_id'] ?? '',
      brand: json['brand'] ?? '',
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
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      addedDate:
          json['added_date'] != null
              ? DateTime.parse(json['added_date'])
              : DateTime.now(),
      imageUrl: json['image_url'],
      videoUrl: json['video_url'], // NEW: Parse video URL from JSON
      // New vendor-related fields
      vendorId: json['vendor_id'] ?? '',
      vendor: json['vendors'] != null ? Vendor.fromJson(json['vendors']) : null,
      approvalStatus: json['approval_status'] ?? 'approved',

      // Size chart related fields
      sizeChartTemplateId: json['size_chart_template_id'],
      customSizeChartData: json['custom_size_chart_data'],
      sizeGuideType: json['size_guide_type'] ?? 'template',

      // NEW PDP FIELDS FROM DATABASE
      subtitle: json['subtitle'],
      mrp: json['mrp']?.toDouble(),
      currency: json['currency'] ?? 'INR',
      ordersCount: json['orders_count'],

      // Handle related data from separate tables/queries
      offers:
          (json['product_offers'] as List? ?? json['offers'] as List? ?? [])
              .map((offer) => ProductOffer.fromJson(offer))
              .toList(),
      highlights:
          (json['product_highlights'] as List? ??
                  json['highlights'] as List? ??
                  [])
              .map((highlight) => ProductHighlight.fromJson(highlight))
              .toList(),
      featurePosters:
          (json['feature_posters'] as List? ?? [])
              .map((poster) => FeaturePoster.fromJson(poster))
              .toList(),
      specifications: _parseSpecifications(
        json['product_specifications'] ?? json['specifications'] ?? [],
      ),

      // Direct array fields from products table
      boxContents: List<String>.from(json['box_contents'] ?? []),
      usageInstructions: List<String>.from(json['usage_instructions'] ?? []),
      careInstructions: List<String>.from(json['care_instructions'] ?? []),
      safetyNotes: List<String>.from(json['safety_notes'] ?? []),

      // Related table data (1:1 relationships)
      deliveryInfo:
          json['delivery_info'] != null
              ? DeliveryInfo.fromJson(
                json['delivery_info'] is List
                    ? (json['delivery_info'] as List).first
                    : json['delivery_info'],
              )
              : null,
      warranty:
          json['warranty_info'] != null
              ? WarrantyInfo.fromJson(
                json['warranty_info'] is List
                    ? (json['warranty_info'] as List).first
                    : json['warranty_info'],
              )
              : json['warranty'] != null
              ? WarrantyInfo.fromJson(json['warranty'])
              : null,
      reviewsSummary:
          json['product_reviews_summary'] != null
              ? ReviewsSummary.fromJson(
                json['product_reviews_summary'] is List
                    ? (json['product_reviews_summary'] as List).first
                    : json['product_reviews_summary'],
              )
              : json['reviews_summary'] != null
              ? ReviewsSummary.fromJson(json['reviews_summary'])
              : null,
      recommendations:
          json['product_recommendations'] != null
              ? ProductRecommendations.fromJson(
                json['product_recommendations'] is List
                    ? (json['product_recommendations'] as List).first
                    : json['product_recommendations'],
              )
              : json['recommendations'] != null
              ? ProductRecommendations.fromJson(json['recommendations'])
              : null,
      seoData: json['seo_data'],
    );
  }

  // NEW: Parse specifications from database format
  static List<ProductSpec> _parseSpecifications(dynamic specificationsData) {
    if (specificationsData == null) return [];

    try {
      // If it's already in the correct format (from mock data)
      if (specificationsData is List &&
          specificationsData.isNotEmpty &&
          specificationsData.first is Map &&
          specificationsData.first.containsKey('group')) {
        return specificationsData
            .map<ProductSpec>((spec) => ProductSpec.fromJson(spec))
            .toList();
      }

      // If it's from database (flat list with group_name, spec_name, spec_value)
      if (specificationsData is List) {
        final Map<String, List<SpecRow>> groupedSpecs = {};

        for (final spec in specificationsData) {
          if (spec is Map<String, dynamic>) {
            final groupName = spec['group_name']?.toString() ?? 'General';
            final specName = spec['spec_name']?.toString() ?? '';
            final specValue = spec['spec_value']?.toString() ?? '';

            if (!groupedSpecs.containsKey(groupName)) {
              groupedSpecs[groupName] = [];
            }

            groupedSpecs[groupName]!.add(
              SpecRow(name: specName, value: specValue),
            );
          }
        }

        return groupedSpecs.entries
            .map((entry) => ProductSpec(group: entry.key, rows: entry.value))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error parsing specifications: $e');
      return [];
    }
  }

  // NEW: Parse color images from JSON
  static Map<String, List<String>>? _parseColorImages(dynamic colorImagesJson) {
    if (colorImagesJson == null) return null;

    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        colorImagesJson,
      );
      return data.map(
        (key, value) => MapEntry(key, List<String>.from(value ?? [])),
      );
    } catch (e) {
      print('Error parsing color images: $e');
      return null;
    }
  }

  // NEW: Get images for specific color with intelligent fallback
  List<String> getImagesForColor(String? selectedColor) {
    // Use color-specific images if available
    if (colorImages != null && selectedColor != null) {
      final colorSpecificImages = colorImages![selectedColor];
      if (colorSpecificImages != null && colorSpecificImages.isNotEmpty) {
        return colorSpecificImages;
      }
    }

    // Fallback to first available color if current color not found
    if (colorImages != null && colorImages!.isNotEmpty) {
      return colorImages!.values.first;
    }

    // Final fallback to original images parsing
    return imageList;
  }

  // NEW: Get primary image for product listings
  String get primaryImage {
    // First try to get from color_images
    if (colorImages != null && colorImages!.isNotEmpty) {
      final firstColorImages = colorImages!.values.first;
      if (firstColorImages.isNotEmpty) {
        return firstColorImages.first;
      }
    }
    // Fallback to original images
    if (images.isNotEmpty && images != '') {
      return imageList.first;
    }
    // Final fallback
    return '';
  }

  // NEW: Check if product has color-specific images
  bool get hasColorSpecificImages {
    return colorImages != null && colorImages!.isNotEmpty;
  }

  // NEW: Get image count for specific color
  int getImageCountForColor(String color) {
    if (colorImages != null && colorImages!.containsKey(color)) {
      return colorImages![color]!.length;
    }
    return imageList.length;
  }

  List<String> get imageList {
    if (images.isEmpty) return [];

    try {
      // Try to parse as JSON array first
      if (images.startsWith('[') && images.endsWith(']')) {
        final List<dynamic> jsonList = json.decode(images);
        return jsonList.map((e) => e.toString()).toList();
      }
      // Fallback to comma-separated parsing
      return images.split(',').map((e) => e.trim()).toList();
    } catch (e) {
      // If JSON parsing fails, fallback to comma-separated
      return images.split(',').map((e) => e.trim()).toList();
    }
  }
}
