import 'package:get/get.dart';
import '../../data/models/qa_model.dart';
import '../../data/services/qa_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class QAController extends GetxController {
  final QAService _qaService = QAService();

  // Observable state
  final RxList<ProductQA> questions = <ProductQA>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxString sortBy = 'created_at'.obs;
  final RxString sortOrder = 'desc'.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreQuestions = true.obs;
  final RxMap<String, int> qaStats = <String, int>{}.obs;

  // Current product ID
  String? _currentProductId;

  // Load Q&A for a product
  Future<void> loadQA(String productId, {bool refresh = false}) async {
    try {
      if (refresh || _currentProductId != productId) {
        _currentProductId = productId;
        currentPage.value = 1;
        hasMoreQuestions.value = true;
        questions.clear();
      }

      if (!hasMoreQuestions.value && !refresh) return;

      isLoading.value = refresh || questions.isEmpty;
      isLoadingMore.value = !refresh && questions.isNotEmpty;
      error.value = '';

      print(
        '❓ Loading Q&A for product: $productId, page: ${currentPage.value}',
      );

      // Load Q&A and stats in parallel
      final futures = [
        _qaService.getProductQA(
          productId: productId,
          page: currentPage.value,
          sortBy: sortBy.value,
          sortOrder: sortOrder.value,
        ),
        if (refresh || qaStats.isEmpty) _qaService.getQAStats(productId),
      ];

      final results = await Future.wait(futures);
      final newQuestions = results[0] as List<ProductQA>;

      if (results.length > 1) {
        qaStats.value = results[1] as Map<String, int>;
      }

      if (refresh) {
        questions.value = newQuestions;
      } else {
        questions.addAll(newQuestions);
      }

      // Check if there are more questions to load
      hasMoreQuestions.value = newQuestions.length >= 20;

      if (hasMoreQuestions.value) {
        currentPage.value++;
      }

      print(
        '✅ Loaded ${newQuestions.length} questions, total: ${questions.length}',
      );
    } catch (e) {
      error.value = 'Failed to load Q&A: $e';
      print('❌ Error loading Q&A: $e');

      if (questions.isEmpty) {
        SnackbarUtils.showError('Failed to load Q&A');
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Load more questions (pagination)
  Future<void> loadMoreQuestions() async {
    if (_currentProductId != null &&
        hasMoreQuestions.value &&
        !isLoadingMore.value) {
      await loadQA(_currentProductId!, refresh: false);
    }
  }

  // Change sorting and reload Q&A
  Future<void> changeSorting(String newSortBy) async {
    if (sortBy.value != newSortBy && _currentProductId != null) {
      sortBy.value = newSortBy;

      // Determine sort order based on sort type
      if (newSortBy == 'helpful') {
        sortOrder.value = 'desc'; // Most helpful first
      } else if (newSortBy == 'created_at') {
        sortOrder.value = 'desc'; // Most recent first
      } else {
        sortOrder.value = 'asc'; // Oldest first
      }

      await loadQA(_currentProductId!, refresh: true);
    }
  }

  // Submit a new question
  Future<bool> submitQuestion({
    required String productId,
    required String question,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('❓ Submitting question for product: $productId');

      final newQuestion = await _qaService.submitQuestion(
        productId: productId,
        question: question,
      );

      // Add the new question to the top of the list
      questions.insert(0, newQuestion);

      // Update stats
      final currentStats = Map<String, int>.from(qaStats);
      currentStats['total'] = (currentStats['total'] ?? 0) + 1;
      currentStats['unanswered'] = (currentStats['unanswered'] ?? 0) + 1;
      qaStats.value = currentStats;

      // Success message handled in UI
      print('✅ Question submitted successfully');

      return true;
    } catch (e) {
      error.value = 'Failed to submit question: $e';
      print('❌ Error submitting question: $e');
      SnackbarUtils.showError('Failed to submit question');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Submit an answer to a question
  Future<bool> submitAnswer({
    required String questionId,
    required String answer,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('💬 Submitting answer for question: $questionId');

      final updatedQA = await _qaService.submitAnswer(
        questionId: questionId,
        answer: answer,
        productId: _currentProductId!,
      );

      // Update the question in the list
      final questionIndex = questions.indexWhere((q) => q.id == questionId);
      if (questionIndex != -1) {
        questions[questionIndex] = updatedQA;
      }

      // Update stats
      final currentStats = Map<String, int>.from(qaStats);
      currentStats['answered'] = (currentStats['answered'] ?? 0) + 1;
      currentStats['unanswered'] = (currentStats['unanswered'] ?? 1) - 1;
      qaStats.value = currentStats;

      // Success message handled in UI
      print('✅ Answer submitted successfully');

      return true;
    } catch (e) {
      error.value = 'Failed to submit answer: $e';
      print('❌ Error submitting answer: $e');
      SnackbarUtils.showError('Failed to submit answer');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Mark Q&A as helpful
  Future<void> markQAHelpful(String qaId) async {
    try {
      await _qaService.markQAHelpful(qaId, productId: _currentProductId!);

      // Update the local Q&A
      final qaIndex = questions.indexWhere((q) => q.id == qaId);
      if (qaIndex != -1) {
        final updatedQA = ProductQA.fromJson({
          ...questions[qaIndex].toJson(),
          'is_helpful_count': questions[qaIndex].isHelpfulCount + 1,
        });
        questions[qaIndex] = updatedQA;
      }

      // Success message handled in UI
    } catch (e) {
      print('❌ Error marking Q&A as helpful: $e');
      SnackbarUtils.showError('Failed to mark as helpful');
    }
  }

  // Search questions
  Future<void> searchQuestions({
    required String productId,
    required String searchTerm,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('🔍 Searching questions: $searchTerm');

      final searchResults = await _qaService.searchQuestions(
        productId: productId,
        searchTerm: searchTerm,
      );

      questions.value = searchResults;
      print('🔍 Found ${searchResults.length} matching questions');
    } catch (e) {
      error.value = 'Failed to search questions: $e';
      print('❌ Error searching questions: $e');
      SnackbarUtils.showError('Failed to search questions');
    } finally {
      isLoading.value = false;
    }
  }

  // Report a Q&A
  Future<void> reportQA(String qaId, String reason) async {
    try {
      await _qaService.reportQA(qaId, reason);
      // Success message handled in UI
    } catch (e) {
      print('❌ Error reporting Q&A: $e');
      SnackbarUtils.showError('Failed to report Q&A');
    }
  }

  // Get answered questions only
  List<ProductQA> get answeredQuestions {
    return questions.where((qa) => qa.hasAnswer).toList();
  }

  // Get unanswered questions only
  List<ProductQA> get unansweredQuestions {
    return questions.where((qa) => !qa.hasAnswer).toList();
  }

  // Get questions sorted by helpfulness
  List<ProductQA> get questionsByHelpfulness {
    final sortedQuestions = List<ProductQA>.from(questions);
    sortedQuestions.sort(
      (a, b) => b.isHelpfulCount.compareTo(a.isHelpfulCount),
    );
    return sortedQuestions;
  }

  // Reset controller state
  void reset() {
    questions.clear();
    isLoading.value = false;
    isLoadingMore.value = false;
    error.value = '';
    sortBy.value = 'created_at';
    sortOrder.value = 'desc';
    currentPage.value = 1;
    hasMoreQuestions.value = true;
    qaStats.clear();
    _currentProductId = null;
  }
}
