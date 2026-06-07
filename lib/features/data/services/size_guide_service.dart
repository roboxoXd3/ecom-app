import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/size_chart_model.dart';
import '../repositories/size_chart_repository.dart';

class SizeGuideService {
  final _api = ApiClient.instance;
  final SizeChartRepository _sizeChartRepository = SizeChartRepository();

  Future<SizeGuideResponse> getSizeGuideInfo({
    String? categoryId,
    String? productId,
    String? query,
  }) async {
    try {
      if (productId != null) {
        return await _getProductSizeGuide(productId);
      }

      if (categoryId != null) {
        return await _getCategorySizeGuide(categoryId);
      }

      if (query != null && query.isNotEmpty) {
        return await _getQueryBasedSizeGuide(query);
      }

      return await _getGeneralSizeGuide();
    } catch (e) {
      debugPrint('Error in getSizeGuideInfo: $e');
      return _getFallbackSizeGuide();
    }
  }

  Future<SizeGuideResponse> _getProductSizeGuide(String productId) async {
    try {
      final response = await _api.get('/products/$productId/');
      final product = response.data as Map<String, dynamic>;
      final categoryName = product['category_name'] ??
          product['categories']?['name'] ??
          'Unknown';

      final sizeChart =
          await _sizeChartRepository.getSizeChartByCategory(
            product['category_id']?.toString() ?? '',
          );

      if (sizeChart != null) {
        return SizeGuideResponse(
          title: 'Size Guide for ${product['name']}',
          description: 'Here\'s the detailed size chart for this product:',
          sizeChart: sizeChart,
          measurementTips: _getMeasurementTips(categoryName.toString()),
          recommendations: _getSizeRecommendations(categoryName.toString()),
          hasSpecificChart: true,
        );
      } else {
        return await _getCategorySizeGuide(
          product['category_id']?.toString() ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error getting product size guide: $e');
      return _getFallbackSizeGuide();
    }
  }

  Future<SizeGuideResponse> _getCategorySizeGuide(String categoryId) async {
    try {
      final response = await _api.get('/categories/$categoryId/');
      final category = response.data as Map<String, dynamic>;
      final categoryName = category['name']?.toString() ?? 'Unknown';

      final sizeChart = await _sizeChartRepository.getSizeChartByCategory(
        categoryId,
      );

      return SizeGuideResponse(
        title: 'Size Guide for $categoryName',
        description: 'Here\'s the size guide for $categoryName products:',
        sizeChart: sizeChart,
        measurementTips: _getMeasurementTips(categoryName),
        recommendations: _getSizeRecommendations(categoryName),
        hasSpecificChart: sizeChart != null,
      );
    } catch (e) {
      debugPrint('Error getting category size guide: $e');
      return _getFallbackSizeGuide();
    }
  }

  Future<SizeGuideResponse> _getQueryBasedSizeGuide(String query) async {
    try {
      final lowerQuery = query.toLowerCase();

      final catResponse = await _api.get(
        '/categories/',
        queryParameters: {'search': query},
      );
      final categories = ApiClient.unwrapResults(catResponse.data);

      if (categories.isNotEmpty) {
        final category = categories.first as Map<String, dynamic>;
        return await _getCategorySizeGuide(category['id'].toString());
      }

      final prodResponse = await _api.get(
        '/products/',
        queryParameters: {'search': query, 'limit': 1},
      );
      final products = ApiClient.unwrapResults(prodResponse.data);

      if (products.isNotEmpty) {
        final product = products.first as Map<String, dynamic>;
        return await _getProductSizeGuide(product['id'].toString());
      }

      return _getKeywordBasedSizeGuide(lowerQuery);
    } catch (e) {
      debugPrint('Error getting query-based size guide: $e');
      return _getFallbackSizeGuide();
    }
  }

  Future<SizeGuideResponse> _getGeneralSizeGuide() async {
    try {
      final response = await _api.get(
        '/categories/',
        queryParameters: {'limit': 5},
      );
      final results = ApiClient.unwrapResults(response.data);
      final categoryNames =
          results.map((c) => (c as Map)['name']).join(', ');

      return SizeGuideResponse(
        title: 'Size Guide Information',
        description:
            'I can help you with size guides for various product categories. '
            'We have detailed size charts for: $categoryNames.\n\n'
            'You can ask me about:\n'
            '• Specific product sizes\n'
            '• Category-specific size guides\n'
            '• How to measure yourself\n'
            '• Size recommendations\n\n'
            'What would you like to know about sizing?',
        measurementTips: _getGeneralMeasurementTips(),
        recommendations: _getGeneralRecommendations(),
        hasSpecificChart: false,
      );
    } catch (e) {
      debugPrint('Error getting general size guide: $e');
      return _getFallbackSizeGuide();
    }
  }

  SizeGuideResponse _getKeywordBasedSizeGuide(String query) {
    if (query.contains('shirt') ||
        query.contains('top') ||
        query.contains('blouse')) {
      return SizeGuideResponse(
        title: 'Shirt & Top Size Guide',
        description: 'For shirts and tops, here are the key measurements:',
        measurementTips: _getMeasurementTips('Shirts'),
        recommendations: _getSizeRecommendations('Shirts'),
        hasSpecificChart: false,
      );
    } else if (query.contains('pant') ||
        query.contains('trouser') ||
        query.contains('jean')) {
      return SizeGuideResponse(
        title: 'Pants & Trousers Size Guide',
        description: 'For pants and trousers, focus on these measurements:',
        measurementTips: _getMeasurementTips('Pants'),
        recommendations: _getSizeRecommendations('Pants'),
        hasSpecificChart: false,
      );
    } else if (query.contains('dress')) {
      return SizeGuideResponse(
        title: 'Dress Size Guide',
        description: 'For dresses, you\'ll need these measurements:',
        measurementTips: _getMeasurementTips('Dresses'),
        recommendations: _getSizeRecommendations('Dresses'),
        hasSpecificChart: false,
      );
    } else if (query.contains('shoe') || query.contains('footwear')) {
      return SizeGuideResponse(
        title: 'Footwear Size Guide',
        description: 'For shoes and footwear:',
        measurementTips: _getMeasurementTips('Footwear'),
        recommendations: _getSizeRecommendations('Footwear'),
        hasSpecificChart: false,
      );
    }

    return _getFallbackSizeGuide();
  }

  List<String> _getMeasurementTips(String categoryName) {
    final lowerCategory = categoryName.toLowerCase();

    if (lowerCategory.contains('men') ||
        lowerCategory.contains('shirt') ||
        lowerCategory.contains('top')) {
      return [
        '📏 **Chest**: Measure around the fullest part of your chest, keeping the tape horizontal',
        '📐 **Length**: Measure from the highest point of shoulder to the bottom hem',
        '👔 **Shoulder**: Measure from shoulder point to shoulder point across the back',
        '👕 **Sleeve**: Measure from shoulder seam to cuff',
        '💡 **Tip**: Wear well-fitted undergarments while measuring',
        '📏 **Tip**: Keep the measuring tape comfortably loose, not tight',
      ];
    } else if (lowerCategory.contains('women') ||
        lowerCategory.contains('dress')) {
      return [
        '📏 **Bust**: Measure around the fullest part of your bust, keeping the tape horizontal',
        '⏰ **Waist**: Measure around your natural waistline (smallest part of your torso)',
        '🍑 **Hip**: Measure around the fullest part of your hips',
        '📐 **Length**: Measure from shoulder to hem (for tops) or desired length',
        '💡 **Tip**: Wear well-fitted undergarments while measuring',
        '📏 **Tip**: Stand straight and breathe normally while measuring',
      ];
    } else if (lowerCategory.contains('pant') ||
        lowerCategory.contains('trouser') ||
        lowerCategory.contains('jean')) {
      return [
        '⏰ **Waist**: Measure around your natural waistline',
        '🍑 **Hip**: Measure around the fullest part of your hips',
        '📐 **Inseam**: Measure from crotch to ankle',
        '🦵 **Thigh**: Measure around the fullest part of your thigh',
        '💡 **Tip**: Measure over thin clothing or underwear',
        '📏 **Tip**: Stand with feet slightly apart for accurate measurements',
      ];
    } else if (lowerCategory.contains('shoe') ||
        lowerCategory.contains('footwear')) {
      return [
        '👣 **Foot Length**: Measure from heel to longest toe',
        '📏 **Foot Width**: Measure the widest part of your foot',
        '🕐 **Best Time**: Measure feet in the evening when they\'re slightly swollen',
        '👟 **Tip**: Measure both feet as they may differ slightly',
        '🧦 **Tip**: Wear the type of socks you\'ll use with the shoes',
        '📐 **Tip**: Stand on a piece of paper and trace your foot for accuracy',
      ];
    }

    return [
      '📏 **General**: Use a flexible measuring tape for accurate measurements',
      '👥 **Help**: Ask someone to help you for better accuracy',
      '📐 **Posture**: Stand straight with arms at your sides',
      '💡 **Comfort**: Keep the tape snug but not tight',
      '🕐 **Timing**: Measure at the same time of day for consistency',
    ];
  }

  List<String> _getSizeRecommendations(String categoryName) {
    final lowerCategory = categoryName.toLowerCase();

    if (lowerCategory.contains('men') || lowerCategory.contains('shirt')) {
      return [
        '👔 **Small (S)**: Best for chest size 34-36 inches',
        '👕 **Medium (M)**: Best for chest size 36-38 inches',
        '👔 **Large (L)**: Best for chest size 38-40 inches',
        '👕 **Extra Large (XL)**: Best for chest size 40-42 inches',
        '💡 **Fit Preference**: Consider if you prefer slim, regular, or loose fit',
        '📏 **Between Sizes**: If between sizes, consider the garment\'s intended fit',
      ];
    } else if (lowerCategory.contains('women') ||
        lowerCategory.contains('dress')) {
      return [
        '👗 **Extra Small (XS)**: Best for bust size 30-32 inches',
        '👚 **Small (S)**: Best for bust size 32-34 inches',
        '👗 **Medium (M)**: Best for bust size 34-36 inches',
        '👚 **Large (L)**: Best for bust size 36-38 inches',
        '👗 **Extra Large (XL)**: Best for bust size 38-40 inches',
        '💡 **Fit Style**: Consider the dress style - fitted vs. flowy',
      ];
    } else if (lowerCategory.contains('footwear')) {
      return [
        '👟 **US 7**: Foot length: 9.5-9.75 inches',
        '👠 **US 8**: Foot length: 9.75-10 inches',
        '👟 **US 9**: Foot length: 10-10.25 inches',
        '👠 **US 10**: Foot length: 10.25-10.5 inches',
        '💡 **Width**: Consider narrow, regular, or wide width options',
        '👟 **Activity**: Choose based on intended use (casual, formal, sports)',
      ];
    }

    return [
      '📏 **Accurate Measurement**: Always measure yourself before ordering',
      '📋 **Size Chart**: Check the specific size chart for each product',
      '💡 **Brand Variation**: Sizes may vary between different brands',
      '🔄 **Return Policy**: Check return policy in case of size issues',
      '📞 **Help**: Contact customer support if unsure about sizing',
    ];
  }

  List<String> _getGeneralMeasurementTips() {
    return [
      '📏 **Use a flexible measuring tape** for the most accurate measurements',
      '👥 **Ask for help** - having someone assist you ensures better accuracy',
      '📐 **Stand straight** with your arms at your sides in a natural position',
      '💡 **Keep the tape snug** but not tight - you should be able to breathe comfortably',
      '🕐 **Measure at the same time of day** for consistency',
      '👕 **Wear fitted clothing** or undergarments while measuring',
      '📝 **Write down measurements** to reference when shopping',
    ];
  }

  List<String> _getGeneralRecommendations() {
    return [
      '📋 **Always check the size chart** for each specific product',
      '📏 **Measure yourself regularly** as body measurements can change',
      '💡 **When in doubt, size up** - it\'s often easier to alter down than up',
      '🔄 **Check return policies** before purchasing',
      '📞 **Contact customer support** if you\'re unsure about sizing',
      '👗 **Consider the fit style** - some items are meant to be loose or fitted',
      '🛍️ **Read reviews** from other customers about sizing and fit',
    ];
  }

  SizeGuideResponse _getFallbackSizeGuide() {
    return SizeGuideResponse(
      title: 'Size Guide Help',
      description:
          'I\'m here to help you with sizing! While I couldn\'t find a specific size chart for your request, '
          'I can provide general sizing guidance.\n\n'
          'Here are some ways I can help:\n'
          '• General measurement tips\n'
          '• Category-specific size guides\n'
          '• How to find the right fit\n\n'
          'Try asking me about a specific product or category!',
      measurementTips: _getGeneralMeasurementTips(),
      recommendations: _getGeneralRecommendations(),
      hasSpecificChart: false,
    );
  }
}

class SizeGuideResponse {
  final String title;
  final String description;
  final SizeChartModel? sizeChart;
  final List<String> measurementTips;
  final List<String> recommendations;
  final bool hasSpecificChart;

  SizeGuideResponse({
    required this.title,
    required this.description,
    this.sizeChart,
    required this.measurementTips,
    required this.recommendations,
    required this.hasSpecificChart,
  });

  String toFormattedString() {
    final buffer = StringBuffer();

    buffer.writeln('**$title**\n');
    buffer.writeln(description);

    if (hasSpecificChart && sizeChart != null) {
      buffer.writeln('\n📊 **Size Chart Available**');
      buffer.writeln(
        'Tap "View Size Chart" below to see detailed measurements.',
      );
    }

    if (measurementTips.isNotEmpty) {
      buffer.writeln('\n📏 **How to Measure:**');
      for (final tip in measurementTips) {
        buffer.writeln('• $tip');
      }
    }

    if (recommendations.isNotEmpty) {
      buffer.writeln('\n💡 **Size Recommendations:**');
      for (final rec in recommendations) {
        buffer.writeln('• $rec');
      }
    }

    buffer.writeln(
      '\n❓ Need more help? Ask me about specific products or categories!',
    );

    return buffer.toString();
  }
}
