import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qa_model.dart';

class QAService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get Q&A for a specific product
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
      print('❓ Fetching Q&A for product: $productId');

      var query = _supabase
          .from('product_qa')
          .select('*')
          .eq('product_id', productId);

      // Apply status filter (show published questions and answered questions)
      if (status != 'all') {
        query = query.eq('status', status);
      } else {
        // Show published, pending questions, or questions with answers
        query = query.or(
          'status.eq.published,status.eq.pending,answer.not.is.null,vendor_response.not.is.null',
        );
      }

      // Apply hasAnswer filter
      if (hasAnswer != null && hasAnswer.isNotEmpty) {
        if (hasAnswer == 'answered') {
          query = query.or('answer.not.is.null,vendor_response.not.is.null');
        }
        // For unanswered, we'll filter in the client side for now
      }

      // Apply sorting and pagination
      final offset = (page - 1) * limit;
      final response = await query
          .order(sortBy, ascending: sortOrder == 'asc')
          .range(offset, offset + limit - 1);

      print('❓ Found ${response.length} Q&A items');

      return response.map((json) => ProductQA.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching Q&A: $e');
      rethrow;
    }
  }

  // Submit a new question
  Future<ProductQA> submitQuestion({
    required String productId,
    required String question,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final user = _supabase.auth.currentUser;

      print('🔐 Current user: ${user?.id}');
      print('🔐 User email: ${user?.email}');
      print('🔐 User authenticated: ${user != null}');

      if (userId == null) {
        throw Exception('Please sign in to ask a question');
      }

      print('❓ Submitting question for product: $productId with user: $userId');

      final questionData = {
        'product_id': productId,
        'user_id': userId,
        'question': question,
        'status': 'pending', // Questions start as pending for moderation
      };

      final response =
          await _supabase
              .from('product_qa')
              .insert(questionData)
              .select()
              .single();

      print('✅ Question submitted successfully');

      return ProductQA.fromJson(response);
    } catch (e) {
      print('❌ Error submitting question: $e');
      rethrow;
    }
  }

  // Submit an answer to a question
  Future<ProductQA> submitAnswer({
    required String questionId,
    required String answer,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('💬 Submitting answer for question: $questionId');

      final updateData = {
        'answer': answer,
        'answered_by': userId,
        'answered_at': DateTime.now().toIso8601String(),
        'status': 'answered',
      };

      final response =
          await _supabase
              .from('product_qa')
              .update(updateData)
              .eq('id', questionId)
              .select()
              .single();

      print('✅ Answer submitted successfully');

      return ProductQA.fromJson(response);
    } catch (e) {
      print('❌ Error submitting answer: $e');
      rethrow;
    }
  }

  // Mark Q&A as helpful
  Future<void> markQAHelpful(String qaId) async {
    try {
      await _supabase.rpc('increment_qa_helpful', params: {'qa_id': qaId});

      print('👍 Marked Q&A as helpful: $qaId');
    } catch (e) {
      print('❌ Error marking Q&A as helpful: $e');
      rethrow;
    }
  }

  // Search questions
  Future<List<ProductQA>> searchQuestions({
    required String productId,
    required String searchTerm,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print(
        '🔍 Searching questions for product: $productId, term: $searchTerm',
      );

      final offset = (page - 1) * limit;

      final response = await _supabase
          .from('product_qa')
          .select('*')
          .eq('product_id', productId)
          .or(
            'status.eq.published,answer.not.is.null,vendor_response.not.is.null',
          )
          .or(
            'question.ilike.%$searchTerm%,answer.ilike.%$searchTerm%,vendor_response.ilike.%$searchTerm%',
          )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('🔍 Found ${response.length} matching questions');

      return response.map((json) => ProductQA.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error searching questions: $e');
      rethrow;
    }
  }

  // Get Q&A statistics for a product
  Future<Map<String, int>> getQAStats(String productId) async {
    try {
      print('📊 Fetching Q&A stats for product: $productId');

      final response = await _supabase
          .from('product_qa')
          .select('answer, vendor_response')
          .eq('product_id', productId)
          .or(
            'status.eq.published,answer.not.is.null,vendor_response.not.is.null',
          );

      final totalQuestions = response.length;
      final answeredQuestions =
          response
              .where(
                (qa) => qa['answer'] != null || qa['vendor_response'] != null,
              )
              .length;
      final unansweredQuestions = totalQuestions - answeredQuestions;

      print('📊 Q&A stats: $totalQuestions total, $answeredQuestions answered');

      return {
        'total': totalQuestions,
        'answered': answeredQuestions,
        'unanswered': unansweredQuestions,
      };
    } catch (e) {
      print('❌ Error fetching Q&A stats: $e');
      rethrow;
    }
  }

  // Report a question or answer
  Future<void> reportQA(String qaId, String reason) async {
    try {
      // For now, just log the report. In a real app, you'd store this in a reports table
      print('🚩 Reported Q&A: $qaId, reason: $reason');

      // You could implement this by creating a reports table or updating a flag
      // await _supabase.from('qa_reports').insert({
      //   'qa_id': qaId,
      //   'reason': reason,
      //   'reported_by': _supabase.auth.currentUser?.id,
      // });
    } catch (e) {
      print('❌ Error reporting Q&A: $e');
      rethrow;
    }
  }
}
