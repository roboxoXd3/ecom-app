import '../../../core/network/api_client.dart';

/// Product Specification Detail Model (for knowledge base)
/// Note: ProductSpec in product_model.dart is different (grouped format)
class ProductSpecDetail {
  final String id;
  final String productId;
  final String groupName;
  final String specName;
  final String specValue;
  final int sortOrder;

  ProductSpecDetail({
    required this.id,
    required this.productId,
    required this.groupName,
    required this.specName,
    required this.specValue,
    required this.sortOrder,
  });

  factory ProductSpecDetail.fromJson(Map<String, dynamic> json) {
    return ProductSpecDetail(
      id: json['id'],
      productId: json['product_id'],
      groupName: json['group_name'] ?? '',
      specName: json['spec_name'] ?? '',
      specValue: json['spec_value'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

/// FAQ Model
class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int orderIndex;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.orderIndex,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      category: json['category'] ?? '',
      orderIndex: json['order_index'] ?? 0,
    );
  }
}

/// Knowledge Base Service
/// Retrieves FAQs, product specifications, and policy information for RAG context
class KnowledgeBaseService {
  final _api = ApiClient.instance;

  Future<List<FAQ>> searchFAQs(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _api.get(
        '/content/faqs/',
        queryParameters: {'search': query, 'page_size': 5},
      );
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => FAQ.fromJson(json)).toList();
    } catch (e) {
      print('Error searching FAQs: $e');
      return [];
    }
  }

  Future<List<ProductSpecDetail>> getProductSpecs(String productId) async {
    try {
      if (productId.isEmpty) return [];

      final response = await _api.get('/products/$productId/specifications/');
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => ProductSpecDetail.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching product specs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSupportInfo({
    String? type,
    int limit = 5,
  }) async {
    try {
      final params = <String, dynamic>{'page_size': limit};
      if (type != null) params['type'] = type;

      final response = await _api.get('/content/support-info/', queryParameters: params);
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      print('Error fetching support info: $e');
      return [];
    }
  }

  Future<List<FAQ>> getRelevantFAQsForQuery(String userQuery) async {
    try {
      final queryTerms = _extractKeyTerms(userQuery);
      if (queryTerms.isEmpty) return [];

      final allFAQs = <FAQ>[];
      for (final term in queryTerms.take(3)) {
        final faqs = await searchFAQs(term);
        allFAQs.addAll(faqs);
      }

      final uniqueFAQs = <String, FAQ>{};
      for (final faq in allFAQs) {
        if (!uniqueFAQs.containsKey(faq.id)) {
          uniqueFAQs[faq.id] = faq;
        }
      }

      return uniqueFAQs.values.take(5).toList();
    } catch (e) {
      print('Error getting relevant FAQs: $e');
      return [];
    }
  }

  List<String> _extractKeyTerms(String query) {
    final lowerQuery = query.toLowerCase();
    final terms = <String>[];

    final importantTerms = [
      'return', 'refund', 'shipping', 'delivery', 'order', 'track',
      'cancel', 'exchange', 'warranty', 'guarantee', 'payment', 'price',
      'discount', 'coupon', 'size', 'fit', 'measurement', 'quality',
      'material', 'care', 'wash', 'policy', 'terms', 'privacy',
      'account', 'login', 'password', 'help', 'support', 'contact',
    ];

    for (final term in importantTerms) {
      if (lowerQuery.contains(term)) {
        terms.add(term);
      }
    }

    final words = lowerQuery.split(' ');
    final commonWords = [
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can',
      'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him',
      'his', 'how', 'its', 'may', 'new', 'now', 'old', 'see', 'two',
      'way', 'who', 'boy', 'did', 'let', 'put', 'say', 'she', 'too', 'use',
    ];

    for (final word in words) {
      if (word.length > 4 && !commonWords.contains(word) && !terms.contains(word)) {
        terms.add(word);
      }
    }

    return terms;
  }

  String formatFAQsForPrompt(List<FAQ> faqs) {
    if (faqs.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('\nRelevant FAQ information:');
    for (int i = 0; i < faqs.length && i < 3; i++) {
      final faq = faqs[i];
      buffer.writeln('Q: ${faq.question}');
      buffer.writeln('A: ${faq.answer}');
      if (i < faqs.length - 1) buffer.writeln('');
    }

    return buffer.toString();
  }

  String formatSpecsForPrompt(List<ProductSpecDetail> specs) {
    if (specs.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('\nProduct Specifications:');

    final groupedSpecs = <String, List<ProductSpecDetail>>{};
    for (final spec in specs) {
      final group = spec.groupName;
      if (!groupedSpecs.containsKey(group)) {
        groupedSpecs[group] = [];
      }
      groupedSpecs[group]!.add(spec);
    }

    for (final entry in groupedSpecs.entries.take(3)) {
      buffer.writeln('${entry.key}:');
      for (final spec in entry.value.take(5)) {
        buffer.writeln('  - ${spec.specName}: ${spec.specValue}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
