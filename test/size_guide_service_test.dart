import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/features/data/services/size_guide_service.dart';

void main() {
  group('SizeGuideService Tests', () {
    late SizeGuideService sizeGuideService;

    setUp(() {
      sizeGuideService = SizeGuideService();
    });

    test('should format size guide response correctly', () {
      final response = SizeGuideResponse(
        title: 'Test Size Guide',
        description: 'This is a test description',
        measurementTips: ['Tip 1: Measure chest', 'Tip 2: Measure waist'],
        recommendations: ['Small: 32-34 inches', 'Medium: 34-36 inches'],
        hasSpecificChart: false,
      );

      final formatted = response.toFormattedString();

      expect(formatted, contains('**Test Size Guide**'));
      expect(formatted, contains('This is a test description'));
      expect(formatted, contains('📏 **How to Measure:**'));
      expect(formatted, contains('💡 **Size Recommendations:**'));
      expect(formatted, contains('Tip 1: Measure chest'));
      expect(formatted, contains('Small: 32-34 inches'));
    });

    test('should include size chart info when available', () {
      final response = SizeGuideResponse(
        title: 'Test Size Guide with Chart',
        description: 'This guide has a chart',
        measurementTips: [],
        recommendations: [],
        hasSpecificChart: true,
      );

      final formatted = response.toFormattedString();

      expect(formatted, contains('📊 **Size Chart Available**'));
      expect(formatted, contains('Tap "View Size Chart" below'));
    });
  });
}
