import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../models/qa_model.dart';

class QAService {
  final _api = ApiClient.instance;

  Future<List<ProductQA>> getProductQA({
    required String productId,
    int page = 1,
    int limit = 20,
    String status = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    String? hasAnswer,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (hasAnswer != null && hasAnswer.isNotEmpty) {
        params['has_answer'] = hasAnswer == 'answered' ? 'true' : 'false';
      }

      final response = await _api.get(
        '/products/$productId/qa/',
        queryParameters: params,
      );

      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => ProductQA.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching Q&A: $e');
      rethrow;
    }
  }

  Future<ProductQA> submitQuestion({
    required String productId,
    required String question,
  }) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('Please sign in to ask a question');
      }

      final response = await _api.post(
        '/products/$productId/qa/',
        data: {'question': question},
      );

      return ProductQA.fromJson(response.data);
    } catch (e) {
      print('Error submitting question: $e');
      rethrow;
    }
  }

  Future<ProductQA> submitAnswer({
    required String questionId,
    required String answer,
    required String productId,
  }) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      final response = await _api.post(
        '/products/$productId/qa/$questionId/answer/',
        data: {'answer': answer},
      );

      return ProductQA.fromJson(response.data);
    } catch (e) {
      print('Error submitting answer: $e');
      rethrow;
    }
  }

  Future<void> markQAHelpful(String qaId, {required String productId}) async {
    try {
      await _api.post('/products/$productId/qa/$qaId/helpful/');
    } catch (e) {
      print('Error marking Q&A as helpful: $e');
      rethrow;
    }
  }

  Future<List<ProductQA>> searchQuestions({
    required String productId,
    required String searchTerm,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '/products/$productId/qa/',
        queryParameters: {
          'search': searchTerm,
          'page': page,
          'page_size': limit,
        },
      );

      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => ProductQA.fromJson(json)).toList();
    } catch (e) {
      print('Error searching questions: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getQAStats(String productId) async {
    try {
      // Get minimal data just to count
      final response = await _api.get(
        '/products/$productId/qa/',
        queryParameters: {'page_size': 1},
      );

      final data = response.data;
      final total = data is Map ? (data['count'] ?? 0) : 0;

      return {
        'total': total as int,
        'answered': 0,
        'unanswered': 0,
      };
    } catch (e) {
      print('Error fetching Q&A stats: $e');
      return {'total': 0, 'answered': 0, 'unanswered': 0};
    }
  }

  Future<void> reportQA(String qaId, String reason) async {
    try {
      print('Reported Q&A: $qaId, reason: $reason');
    } catch (e) {
      print('Error reporting Q&A: $e');
      rethrow;
    }
  }
}
