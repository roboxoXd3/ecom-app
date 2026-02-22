import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

class ImageSearchResult {
  final String description;
  final List<Product> products;

  const ImageSearchResult({required this.description, required this.products});
}

class ImageSearchService {
  final _api = ApiClient.instance;

  /// Analyze an image via backend and return a description + matching products.
  /// POST /api/ai/image-search/ (multipart)
  Future<ImageSearchResult> analyzeImageForProductSearch(File imageFile) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🖼️ Image search via backend (attempt $attempt/$maxRetries)');

        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imageFile.path,
            contentType: DioMediaType.parse(mimeType),
          ),
        });

        final response = await _api.upload<Map<String, dynamic>>(
          '/ai/image-search/',
          formData: formData,
        );
        final data = response.data as Map<String, dynamic>;

        final description = data['description'] as String? ?? 'product search';
        final rawProducts = data['products'] as List<dynamic>? ?? [];
        final products = rawProducts
            .map((p) {
              try {
                return Product.fromJson(p as Map<String, dynamic>);
              } catch (_) {
                return null;
              }
            })
            .whereType<Product>()
            .toList();

        print('🧠 Image analysis result: $description (${products.length} products)');
        return ImageSearchResult(description: description, products: products);
      } catch (e) {
        print('❌ Image search attempt $attempt/$maxRetries failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      }
    }

    print('⚠️ All image search attempts failed, returning fallback');
    return const ImageSearchResult(description: 'product search', products: []);
  }

  /// Returns just the description string (backwards-compatible helper).
  Future<String> analyzeImageDescription(File imageFile) async {
    final result = await analyzeImageForProductSearch(imageFile);
    return result.description;
  }

  /// Validate image file
  bool isValidImageFile(File file) {
    final mimeType = lookupMimeType(file.path);
    return mimeType != null && mimeType.startsWith('image/');
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }
}
