class SizeChartModel {
  final String id;
  final String name;
  final String category;
  final String subcategory;
  final List<SizeChartEntry> entries;
  final List<String> measurementTypes;
  final String measurementInstructions;
  final Map<String, String> sizeRecommendations;
  final String chartType;
  final bool isActive;
  final String? categoryId;

  SizeChartModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.entries,
    required this.measurementTypes,
    required this.measurementInstructions,
    required this.sizeRecommendations,
    this.chartType = 'standard',
    this.isActive = true,
    this.categoryId,
  });

  // Factory constructor for database data
  factory SizeChartModel.fromDatabase(
    Map<String, dynamic> template,
    List<Map<String, dynamic>> entries,
  ) {
    return SizeChartModel(
      id: template['id'],
      name: template['name'],
      category: template['category'] ?? 'Unknown',
      subcategory: template['subcategory'] ?? '',
      measurementTypes: List<String>.from(template['measurement_types'] ?? []),
      measurementInstructions: template['measurement_instructions'] ?? '',
      sizeRecommendations: Map<String, String>.from(
        template['size_recommendations'] ?? {},
      ),
      chartType: template['chart_type'] ?? 'standard',
      isActive: template['is_active'] ?? true,
      categoryId: template['category_id'],
      entries:
          entries.map((entry) => SizeChartEntry.fromDatabase(entry)).toList(),
    );
  }

  // Factory constructor for custom product data
  factory SizeChartModel.fromCustomData(
    Map<String, dynamic> customData,
    String productName,
  ) {
    return SizeChartModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom Size Chart - $productName',
      category: customData['category'] ?? 'Custom',
      subcategory: customData['subcategory'] ?? '',
      measurementTypes: List<String>.from(
        customData['measurement_types'] ?? [],
      ),
      measurementInstructions: customData['measurement_instructions'] ?? '',
      sizeRecommendations: Map<String, String>.from(
        customData['size_recommendations'] ?? {},
      ),
      chartType: 'custom',
      isActive: true,
      entries:
          (customData['entries'] as List<dynamic>? ?? [])
              .map((entry) => SizeChartEntry.fromMap(entry))
              .toList(),
    );
  }

  // Backward compatibility - convert from legacy static data
  factory SizeChartModel.fromLegacy(
    String category,
    SizeChartModel legacyChart,
  ) {
    return SizeChartModel(
      id: 'legacy_$category',
      name: legacyChart.category,
      category: legacyChart.category,
      subcategory: legacyChart.subcategory,
      entries: legacyChart.entries,
      measurementTypes: legacyChart.measurementTypes,
      measurementInstructions: legacyChart.measurementInstructions,
      sizeRecommendations: legacyChart.sizeRecommendations,
      chartType: 'legacy',
      isActive: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'measurement_types': measurementTypes,
      'measurement_instructions': measurementInstructions,
      'size_recommendations': sizeRecommendations,
      'chart_type': chartType,
      'is_active': isActive,
      'category_id': categoryId,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}

class SizeChartEntry {
  final String size;
  final Map<String, SizeMeasurement> measurements;
  final int sortOrder;

  SizeChartEntry({
    required this.size,
    required this.measurements,
    this.sortOrder = 0,
  });

  // Factory constructor for database data
  factory SizeChartEntry.fromDatabase(Map<String, dynamic> data) {
    final measurementsMap = <String, SizeMeasurement>{};
    final measurementsData = data['measurements'] as Map<String, dynamic>;

    measurementsData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        measurementsMap[key] = SizeMeasurement(
          cm: (value['cm'] as num).toDouble(),
          inches: (value['inches'] as num).toDouble(),
          additionalInfo: value['additional_info'],
        );
      }
    });

    return SizeChartEntry(
      size: data['size_name'],
      measurements: measurementsMap,
      sortOrder: data['sort_order'] ?? 0,
    );
  }

  // Factory constructor for custom/legacy data
  factory SizeChartEntry.fromMap(Map<String, dynamic> data) {
    final measurementsMap = <String, SizeMeasurement>{};
    final measurementsData = data['measurements'] as Map<String, dynamic>;

    measurementsData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        measurementsMap[key] = SizeMeasurement(
          cm: (value['cm'] as num).toDouble(),
          inches: (value['inches'] as num).toDouble(),
          additionalInfo: value['additional_info'],
        );
      }
    });

    return SizeChartEntry(
      size: data['size'],
      measurements: measurementsMap,
      sortOrder: data['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final measurementsJson = <String, dynamic>{};
    measurements.forEach((key, value) {
      measurementsJson[key] = {
        'cm': value.cm,
        'inches': value.inches,
        if (value.additionalInfo != null)
          'additional_info': value.additionalInfo,
      };
    });

    return {
      'size': size,
      'measurements': measurementsJson,
      'sort_order': sortOrder,
    };
  }
}

class SizeMeasurement {
  final double cm;
  final double inches;
  final String? additionalInfo;

  SizeMeasurement({
    required this.cm,
    required this.inches,
    this.additionalInfo,
  });

  double get value => cm;
  double get inInches => inches;
}

class SizeChartData {
  static Map<String, SizeChartModel> getSizeCharts() {
    return {
      'mens_clothing': _getMensClothingSizeChart(),
      'womens_clothing': _getWomensClothingSizeChart(),
      'footwear': _getFootwearSizeChart(),
      'accessories': _getAccessoriesSizeChart(),
    };
  }

  static SizeChartModel _getMensClothingSizeChart() {
    return SizeChartModel(
      id: 'legacy_mens_clothing',
      name: 'Men\'s Clothing Size Chart',
      category: 'Men\'s Clothing',
      subcategory: 'Shirts & T-Shirts',
      measurementTypes: ['Chest', 'Length', 'Shoulder', 'Sleeve'],
      measurementInstructions: '''
📏 How to Measure:

• Chest: Measure around the fullest part of your chest, keeping the tape horizontal
• Length: Measure from the highest point of shoulder to the bottom hem
• Shoulder: Measure from shoulder point to shoulder point across the back
• Sleeve: Measure from shoulder seam to cuff

💡 Tips:
- Wear well-fitted undergarments while measuring
- Keep the measuring tape comfortably loose
- Ask someone to help you for accurate measurements
      ''',
      entries: [
        SizeChartEntry(
          size: 'XS',
          measurements: {
            'Chest': SizeMeasurement(cm: 86, inches: 34),
            'Length': SizeMeasurement(cm: 66, inches: 26),
            'Shoulder': SizeMeasurement(cm: 41, inches: 16),
            'Sleeve': SizeMeasurement(cm: 58, inches: 23),
          },
        ),
        SizeChartEntry(
          size: 'S',
          measurements: {
            'Chest': SizeMeasurement(cm: 91, inches: 36),
            'Length': SizeMeasurement(cm: 68, inches: 27),
            'Shoulder': SizeMeasurement(cm: 43, inches: 17),
            'Sleeve': SizeMeasurement(cm: 60, inches: 24),
          },
        ),
        SizeChartEntry(
          size: 'M',
          measurements: {
            'Chest': SizeMeasurement(cm: 96, inches: 38),
            'Length': SizeMeasurement(cm: 70, inches: 28),
            'Shoulder': SizeMeasurement(cm: 45, inches: 18),
            'Sleeve': SizeMeasurement(cm: 62, inches: 24.5),
          },
        ),
        SizeChartEntry(
          size: 'L',
          measurements: {
            'Chest': SizeMeasurement(cm: 101, inches: 40),
            'Length': SizeMeasurement(cm: 72, inches: 28.5),
            'Shoulder': SizeMeasurement(cm: 47, inches: 18.5),
            'Sleeve': SizeMeasurement(cm: 64, inches: 25),
          },
        ),
        SizeChartEntry(
          size: 'XL',
          measurements: {
            'Chest': SizeMeasurement(cm: 106, inches: 42),
            'Length': SizeMeasurement(cm: 74, inches: 29),
            'Shoulder': SizeMeasurement(cm: 49, inches: 19),
            'Sleeve': SizeMeasurement(cm: 66, inches: 26),
          },
        ),
        SizeChartEntry(
          size: 'XXL',
          measurements: {
            'Chest': SizeMeasurement(cm: 111, inches: 44),
            'Length': SizeMeasurement(cm: 76, inches: 30),
            'Shoulder': SizeMeasurement(cm: 51, inches: 20),
            'Sleeve': SizeMeasurement(cm: 68, inches: 27),
          },
        ),
      ],
      sizeRecommendations: {
        'XS': 'Best for chest size 32-34 inches',
        'S': 'Best for chest size 34-36 inches',
        'M': 'Best for chest size 36-38 inches',
        'L': 'Best for chest size 38-40 inches',
        'XL': 'Best for chest size 40-42 inches',
        'XXL': 'Best for chest size 42-44 inches',
      },
    );
  }

  static SizeChartModel _getWomensClothingSizeChart() {
    return SizeChartModel(
      id: 'legacy_womens_clothing',
      name: 'Women\'s Clothing Size Chart',
      category: 'Women\'s Clothing',
      subcategory: 'Tops & Dresses',
      measurementTypes: ['Bust', 'Waist', 'Hip', 'Length'],
      measurementInstructions: '''
📏 How to Measure:

• Bust: Measure around the fullest part of your bust, keeping the tape horizontal
• Waist: Measure around your natural waistline (smallest part of your torso)
• Hip: Measure around the fullest part of your hips
• Length: Measure from shoulder to hem (for tops) or desired length

💡 Tips:
- Wear well-fitted undergarments while measuring
- Stand straight and breathe normally
- Don't pull the tape too tight or too loose
      ''',
      entries: [
        SizeChartEntry(
          size: 'XS',
          measurements: {
            'Bust': SizeMeasurement(cm: 81, inches: 32),
            'Waist': SizeMeasurement(cm: 64, inches: 25),
            'Hip': SizeMeasurement(cm: 89, inches: 35),
            'Length': SizeMeasurement(cm: 61, inches: 24),
          },
        ),
        SizeChartEntry(
          size: 'S',
          measurements: {
            'Bust': SizeMeasurement(cm: 86, inches: 34),
            'Waist': SizeMeasurement(cm: 69, inches: 27),
            'Hip': SizeMeasurement(cm: 94, inches: 37),
            'Length': SizeMeasurement(cm: 63, inches: 25),
          },
        ),
        SizeChartEntry(
          size: 'M',
          measurements: {
            'Bust': SizeMeasurement(cm: 91, inches: 36),
            'Waist': SizeMeasurement(cm: 74, inches: 29),
            'Hip': SizeMeasurement(cm: 99, inches: 39),
            'Length': SizeMeasurement(cm: 65, inches: 26),
          },
        ),
        SizeChartEntry(
          size: 'L',
          measurements: {
            'Bust': SizeMeasurement(cm: 96, inches: 38),
            'Waist': SizeMeasurement(cm: 79, inches: 31),
            'Hip': SizeMeasurement(cm: 104, inches: 41),
            'Length': SizeMeasurement(cm: 67, inches: 26.5),
          },
        ),
        SizeChartEntry(
          size: 'XL',
          measurements: {
            'Bust': SizeMeasurement(cm: 101, inches: 40),
            'Waist': SizeMeasurement(cm: 84, inches: 33),
            'Hip': SizeMeasurement(cm: 109, inches: 43),
            'Length': SizeMeasurement(cm: 69, inches: 27),
          },
        ),
        SizeChartEntry(
          size: 'XXL',
          measurements: {
            'Bust': SizeMeasurement(cm: 106, inches: 42),
            'Waist': SizeMeasurement(cm: 89, inches: 35),
            'Hip': SizeMeasurement(cm: 114, inches: 45),
            'Length': SizeMeasurement(cm: 71, inches: 28),
          },
        ),
      ],
      sizeRecommendations: {
        'XS': 'Best for bust size 30-32 inches',
        'S': 'Best for bust size 32-34 inches',
        'M': 'Best for bust size 34-36 inches',
        'L': 'Best for bust size 36-38 inches',
        'XL': 'Best for bust size 38-40 inches',
        'XXL': 'Best for bust size 40-42 inches',
      },
    );
  }

  static SizeChartModel _getFootwearSizeChart() {
    return SizeChartModel(
      id: 'legacy_footwear',
      name: 'Footwear Size Chart',
      category: 'Footwear',
      subcategory: 'Shoes & Sneakers',
      measurementTypes: ['Length', 'Width'],
      measurementInstructions: '''
📏 How to Measure Your Feet:

• Length: Place your foot on paper, mark heel and longest toe, measure the distance
• Width: Measure the widest part of your foot across the ball
• Best time: Measure feet in the evening when they're at their largest

💡 Tips:
- Always measure both feet and use the larger measurement
- Wear the type of socks you plan to wear with the shoes
- Consider the shoe style - some may run large or small
      ''',
      entries: [
        SizeChartEntry(
          size: '6',
          measurements: {
            'Length': SizeMeasurement(cm: 24.1, inches: 9.5),
            'Width': SizeMeasurement(cm: 8.9, inches: 3.5),
          },
        ),
        SizeChartEntry(
          size: '7',
          measurements: {
            'Length': SizeMeasurement(cm: 25.4, inches: 10),
            'Width': SizeMeasurement(cm: 9.2, inches: 3.6),
          },
        ),
        SizeChartEntry(
          size: '8',
          measurements: {
            'Length': SizeMeasurement(cm: 26.7, inches: 10.5),
            'Width': SizeMeasurement(cm: 9.5, inches: 3.7),
          },
        ),
        SizeChartEntry(
          size: '9',
          measurements: {
            'Length': SizeMeasurement(cm: 27.9, inches: 11),
            'Width': SizeMeasurement(cm: 9.8, inches: 3.9),
          },
        ),
        SizeChartEntry(
          size: '10',
          measurements: {
            'Length': SizeMeasurement(cm: 29.2, inches: 11.5),
            'Width': SizeMeasurement(cm: 10.2, inches: 4),
          },
        ),
        SizeChartEntry(
          size: '11',
          measurements: {
            'Length': SizeMeasurement(cm: 30.5, inches: 12),
            'Width': SizeMeasurement(cm: 10.5, inches: 4.1),
          },
        ),
      ],
      sizeRecommendations: {
        '6': 'EU 39 | UK 5.5',
        '7': 'EU 40 | UK 6.5',
        '8': 'EU 41 | UK 7.5',
        '9': 'EU 42 | UK 8.5',
        '10': 'EU 43 | UK 9.5',
        '11': 'EU 44 | UK 10.5',
      },
    );
  }

  static SizeChartModel _getAccessoriesSizeChart() {
    return SizeChartModel(
      id: 'legacy_accessories',
      name: 'Accessories Size Chart',
      category: 'Accessories',
      subcategory: 'Watches & Jewelry',
      measurementTypes: ['Circumference', 'Width'],
      measurementInstructions: '''
📏 How to Measure:

• Wrist: Wrap a measuring tape around your wrist where you wear your watch
• Ring: Measure the inside diameter of a well-fitting ring
• Necklace: Measure desired length from neck

💡 Tips:
- For a snug fit, use exact measurement
- For loose fit, add 1-2 cm to measurement
- Consider the style and comfort preference
      ''',
      entries: [
        SizeChartEntry(
          size: 'S',
          measurements: {
            'Circumference': SizeMeasurement(cm: 15, inches: 5.9),
            'Width': SizeMeasurement(cm: 1.8, inches: 0.7),
          },
        ),
        SizeChartEntry(
          size: 'M',
          measurements: {
            'Circumference': SizeMeasurement(cm: 17, inches: 6.7),
            'Width': SizeMeasurement(cm: 2.0, inches: 0.8),
          },
        ),
        SizeChartEntry(
          size: 'L',
          measurements: {
            'Circumference': SizeMeasurement(cm: 19, inches: 7.5),
            'Width': SizeMeasurement(cm: 2.2, inches: 0.9),
          },
        ),
      ],
      sizeRecommendations: {
        'S': 'Best for wrist size 5.5-6.5 inches',
        'M': 'Best for wrist size 6.5-7.5 inches',
        'L': 'Best for wrist size 7.5-8.5 inches',
      },
    );
  }

  static String getCategoryFromProductCategory(String productCategory) {
    switch (productCategory.toLowerCase()) {
      case 'men\'s clothing':
        return 'mens_clothing';
      case 'women\'s clothing':
        return 'womens_clothing';
      case 'sports':
        return 'footwear'; // Assuming sports items are primarily footwear
      case 'accessories':
        return 'accessories';
      case 'electronics':
        return 'accessories'; // Electronics like watches
      default:
        return 'mens_clothing'; // Default fallback
    }
  }
}
