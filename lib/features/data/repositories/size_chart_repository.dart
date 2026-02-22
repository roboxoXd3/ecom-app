import '../../../core/network/api_client.dart';
import '../models/size_chart_model.dart';
import '../models/product_model.dart' as ProductModule;

class SizeChartRepository {
  final _api = ApiClient.instance;

  /// Get size chart for a specific product via Django API.
  /// The backend handles priority: custom > template > category > legacy fallback.
  Future<SizeChartModel?> getSizeChartForProduct(
    ProductModule.Product product,
  ) async {
    if (product.sizeChartOverride == 'hide') return null;

    try {
      final response = await _api.get('/products/${product.id}/size-chart/');
      final data = response.data;

      if (data == null) return null;
      if (data is Map<String, dynamic> && data.isEmpty) return null;

      return SizeChartModel.fromApiResponse(data as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching size chart for product ${product.id}: $e');
      return _getLegacyFallback(product.categoryId);
    }
  }

  /// Get size chart template by ID
  Future<SizeChartModel?> getSizeChartTemplate(String templateId) async {
    try {
      final response = await _api.get('/size-charts/templates/$templateId/');
      final data = response.data;
      if (data == null) return null;
      return SizeChartModel.fromApiResponse(data as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching size chart template $templateId: $e');
      return null;
    }
  }

  /// Get size chart by category ID
  Future<SizeChartModel?> getSizeChartByCategory(String categoryId) async {
    try {
      final response = await _api.get(
        '/categories/$categoryId/size-chart/',
      );
      final data = response.data;
      if (data == null) return null;
      if (data is Map<String, dynamic> && data.isEmpty) return null;
      return SizeChartModel.fromApiResponse(data as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching size chart for category $categoryId: $e');
      return null;
    }
  }

  /// Get all available size chart templates
  Future<List<SizeChartModel>> getAllSizeChartTemplates() async {
    try {
      final response = await _api.get('/size-charts/templates/');
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((e) =>
              SizeChartModel.fromApiResponse(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all size chart templates: $e');
      return [];
    }
  }

  Future<String?> createSizeChartTemplate(SizeChartModel sizeChart) async {
    throw UnsupportedError(
      'createSizeChartTemplate is admin-only and not supported in the mobile app',
    );
  }

  Future<bool> updateProductSizeChart({
    required String productId,
    String? templateId,
    Map<String, dynamic>? customData,
    String sizeGuideType = 'template',
  }) async {
    throw UnsupportedError(
      'updateProductSizeChart is admin-only and not supported in the mobile app',
    );
  }

  /// Check if size chart exists for category
  Future<bool> hasSizeChartForCategory(String categoryId) async {
    final chart = await getSizeChartByCategory(categoryId);
    return chart != null;
  }

  /// Get category name by ID
  Future<String?> getCategoryName(String categoryId) async {
    try {
      final response = await _api.get('/categories/$categoryId/');
      final data = response.data as Map<String, dynamic>?;
      return data?['name']?.toString();
    } catch (e) {
      print('Error fetching category name: $e');
      return null;
    }
  }

  /// Legacy fallback using static charts
  Future<SizeChartModel?> getLegacyChartByCategory(String? categoryId) async {
    return _getLegacyFallback(categoryId);
  }

  SizeChartModel? _getLegacyFallback(String? categoryId) {
    if (categoryId == null) return null;
    final legacyCharts = SizeChartData.getSizeCharts();
    return legacyCharts['mens_clothing'];
  }
}
