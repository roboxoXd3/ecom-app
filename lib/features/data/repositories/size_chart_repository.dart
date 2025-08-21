import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/size_chart_model.dart';
import '../models/product_model.dart' as ProductModule;

class SizeChartRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get size chart for a specific product
  /// Priority: Product custom chart > Product template > Category template > Legacy fallback
  Future<SizeChartModel?> getSizeChartForProduct(
    ProductModule.Product product,
  ) async {
    try {
      // Priority 1: Check if product has custom size chart data
      if (product.sizeGuideType == 'custom' &&
          product.customSizeChartData != null) {
        return SizeChartModel.fromCustomData(
          product.customSizeChartData!,
          product.name,
        );
      }

      // Priority 2: Check if product has assigned template
      if (product.sizeGuideType == 'template' &&
          product.sizeChartTemplateId != null) {
        return await getSizeChartTemplate(product.sizeChartTemplateId!);
      }

      // Priority 3: Try to get template by category
      if (product.categoryId != null) {
        final categoryTemplate = await getSizeChartByCategory(
          product.categoryId!,
        );
        if (categoryTemplate != null) return categoryTemplate;
      }

      // Priority 4: Fallback to legacy charts
      final legacyChart = await getLegacyChartByCategory(product.categoryId);
      return legacyChart;
    } catch (e) {
      print('Error fetching size chart for product ${product.id}: $e');
      // Return legacy fallback as last resort
      return await getLegacyChartByCategory(product.categoryId);
    }
  }

  /// Get size chart template by ID
  Future<SizeChartModel?> getSizeChartTemplate(String templateId) async {
    try {
      // Get template data
      final templateResponse =
          await _supabase
              .from('size_chart_templates')
              .select('*, categories(name)')
              .eq('id', templateId)
              .eq('is_active', true)
              .single();

      // Get template entries
      final entriesResponse = await _supabase
          .from('size_chart_entries')
          .select('*')
          .eq('template_id', templateId)
          .order('sort_order');

      return SizeChartModel.fromDatabase(templateResponse, entriesResponse);
    } catch (e) {
      print('Error fetching size chart template $templateId: $e');
      return null;
    }
  }

  /// Get size chart by category ID
  Future<SizeChartModel?> getSizeChartByCategory(String categoryId) async {
    try {
      // Get template for category
      final templateResponse =
          await _supabase
              .from('size_chart_templates')
              .select('*, categories(name)')
              .eq('category_id', categoryId)
              .eq('is_active', true)
              .limit(1)
              .single();

      // Get template entries
      final entriesResponse = await _supabase
          .from('size_chart_entries')
          .select('*')
          .eq('template_id', templateResponse['id'])
          .order('sort_order');

      return SizeChartModel.fromDatabase(templateResponse, entriesResponse);
    } catch (e) {
      print('Error fetching size chart for category $categoryId: $e');
      return null;
    }
  }

  /// Get all available size chart templates
  Future<List<SizeChartModel>> getAllSizeChartTemplates() async {
    try {
      final templatesResponse = await _supabase
          .from('size_chart_templates')
          .select('*, categories(name)')
          .eq('is_active', true)
          .order('name');

      final List<SizeChartModel> templates = [];

      for (final template in templatesResponse) {
        final entriesResponse = await _supabase
            .from('size_chart_entries')
            .select('*')
            .eq('template_id', template['id'])
            .order('sort_order');

        templates.add(SizeChartModel.fromDatabase(template, entriesResponse));
      }

      return templates;
    } catch (e) {
      print('Error fetching all size chart templates: $e');
      return [];
    }
  }

  /// Create a new size chart template
  Future<String?> createSizeChartTemplate(SizeChartModel sizeChart) async {
    try {
      // Insert template
      final templateResponse =
          await _supabase
              .from('size_chart_templates')
              .insert({
                'name': sizeChart.name,
                'category_id': sizeChart.categoryId,
                'subcategory': sizeChart.subcategory,
                'measurement_types': sizeChart.measurementTypes,
                'measurement_instructions': sizeChart.measurementInstructions,
                'size_recommendations': sizeChart.sizeRecommendations,
                'chart_type': sizeChart.chartType,
                'is_active': sizeChart.isActive,
              })
              .select('id')
              .single();

      final templateId = templateResponse['id'] as String;

      // Insert entries
      final entries =
          sizeChart.entries.asMap().entries.map((entry) {
            return {
              'template_id': templateId,
              'size_name': entry.value.size,
              'measurements': entry.value.toJson()['measurements'],
              'sort_order': entry.key,
            };
          }).toList();

      await _supabase.from('size_chart_entries').insert(entries);

      return templateId;
    } catch (e) {
      print('Error creating size chart template: $e');
      return null;
    }
  }

  /// Update product's size chart assignment
  Future<bool> updateProductSizeChart({
    required String productId,
    String? templateId,
    Map<String, dynamic>? customData,
    String sizeGuideType = 'template',
  }) async {
    try {
      await _supabase
          .from('products')
          .update({
            'size_chart_template_id': templateId,
            'custom_size_chart_data': customData,
            'size_guide_type': sizeGuideType,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      return true;
    } catch (e) {
      print('Error updating product size chart: $e');
      return false;
    }
  }

  /// Enhanced legacy fallback method with proper category mapping
  Future<SizeChartModel?> getLegacyChartByCategory(String? categoryId) async {
    if (categoryId == null) return null;

    try {
      // Get category name from database
      final categoryName = await getCategoryName(categoryId);
      if (categoryName == null) return null;

      // Get enhanced legacy charts
      final legacyCharts = SizeChartData.getSizeCharts();

      // Map category name to appropriate chart type
      String chartKey = _mapCategoryToChartType(categoryName);

      return legacyCharts[chartKey];
    } catch (e) {
      print('Error getting legacy chart: $e');
      return null;
    }
  }

  /// Maps category names to size chart types
  String _mapCategoryToChartType(String categoryName) {
    final category = categoryName.toLowerCase();

    if (category.contains("men") && category.contains("clothing")) {
      return 'mens_clothing';
    }

    if (category.contains("women") && category.contains("clothing")) {
      return 'womens_clothing';
    }

    if (category.contains("sport") ||
        category.contains("athletic") ||
        category.contains("footwear")) {
      return 'footwear';
    }

    if (category.contains("accessories") || category.contains("jewelry")) {
      return 'accessories';
    }

    // Default fallback
    return 'mens_clothing';
  }

  /// Check if size chart exists for category
  Future<bool> hasSizeChartForCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('size_chart_templates')
          .select('id')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking size chart for category: $e');
      return false;
    }
  }

  /// Get category name by ID (helper method)
  Future<String?> getCategoryName(String categoryId) async {
    try {
      final response =
          await _supabase
              .from('categories')
              .select('name')
              .eq('id', categoryId)
              .single();

      return response['name'];
    } catch (e) {
      print('Error fetching category name: $e');
      return null;
    }
  }
}
