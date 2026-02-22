import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/qa_model.dart';
import '../../controllers/qa_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/auth_service.dart';

class QASection extends StatefulWidget {
  final String productId;

  const QASection({super.key, required this.productId});

  @override
  State<QASection> createState() => _QASectionState();
}

class _QASectionState extends State<QASection> {
  final QAController qaController = Get.put(QAController());
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load Q&A when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      qaController.loadQA(widget.productId);
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions & Answers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (qaController.qaStats.isNotEmpty)
                  Text(
                    '${qaController.qaStats['total'] ?? 0} Questions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Ask Question Section
            _buildAskQuestionSection(),

            const SizedBox(height: 16),

            // Sort Options
            _buildSortOptions(),

            const SizedBox(height: 16),

            // Questions List
            _buildQuestionsList(),
          ],
        );
      }),
    );
  }

  Widget _buildAskQuestionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Have a question about this product?',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              TextField(
                controller: _questionController,
                maxLines: 3,
                maxLength: 1000,
                onChanged: (value) {
                  // Trigger rebuild to update character counter
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Ask your question here... (minimum 10 characters)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '${_questionController.text.length}/1000',
                  helperText: 'Be specific and clear to get better answers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => ElevatedButton(
                    onPressed:
                        qaController.isLoading.value
                            ? null
                            : () {
                              _submitQuestion();
                            },
                    child:
                        qaController.isLoading.value
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Ask Question'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  _searchQuestions();
                },
                child: const Text('Search Q&A'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Row(
      children: [
        const Text(
          'Sort by: ',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        DropdownButton<String>(
          value: qaController.sortBy.value,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(
              value: 'is_helpful_count',
              child: Text('Most Helpful'),
            ),
            DropdownMenuItem(value: 'created_at', child: Text('Most Recent')),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
          ],
          onChanged: (value) {
            if (value != null) {
              qaController.changeSorting(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    if (qaController.isLoading.value && qaController.questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (qaController.error.value.isNotEmpty && qaController.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Failed to load Q&A',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    () => qaController.loadQA(widget.productId, refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (qaController.questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.help_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No questions yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Be the first to ask a question!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...qaController.questions.map((qa) => _buildQACard(qa)),

        // Load More Button
        if (qaController.hasMoreQuestions.value) ...[
          const SizedBox(height: 16),
          Center(
            child:
                qaController.isLoadingMore.value
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                      onPressed: qaController.loadMoreQuestions,
                      child: const Text('Load More Questions'),
                    ),
          ),
        ],
      ],
    );
  }

  Widget _buildQACard(ProductQA qa) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qa.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Asked ${qa.timeAgo}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (qa.status == 'pending') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Pending Review',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Answer (if available)
          if (qa.hasAnswer) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.question_answer,
                      size: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qa.displayAnswer,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Answered by ${qa.displayAnsweredBy}${qa.displayAnsweredAt != null ? ' • ${_formatDate(qa.displayAnsweredAt!)}' : ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'No answer yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              InkWell(
                onTap: () {
                  qaController.markQAHelpful(qa.id);
                  SnackbarUtils.showInfo('Thank you for your feedback!');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${qa.isHelpfulCount})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!qa.hasAnswer)
                InkWell(
                  onTap: () {
                    _answerQuestion(qa.id);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.reply, size: 16),
                      SizedBox(width: 4),
                      Text('Answer', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              const Spacer(),
              InkWell(
                onTap: () {
                  _showReportQADialog(qa.id);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined, size: 16),
                    SizedBox(width: 4),
                    Text('Report', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitQuestion() async {
    final question = _questionController.text.trim();

    // Validation checks
    if (question.isEmpty) {
      SnackbarUtils.showWarning('Please enter a question');
      return;
    }

    if (question.length < 10) {
      SnackbarUtils.showWarning('Question must be at least 10 characters long');
      return;
    }

    if (question.length > 1000) {
      SnackbarUtils.showWarning('Question cannot exceed 1000 characters');
      return;
    }

    if (!AuthService.isAuthenticated()) {
      SnackbarUtils.showError('Please sign in to ask a question');
      Future.delayed(const Duration(seconds: 1), () {
        Get.toNamed('/login');
      });
      return;
    }

    // Show loading state
    final success = await qaController.submitQuestion(
      productId: widget.productId,
      question: question,
    );

    if (success) {
      _questionController.clear();
      SnackbarUtils.showSuccess(
        'Question submitted successfully! It will be reviewed shortly.',
      );
    }
  }

  void _searchQuestions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search Questions'),
            content: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search existing questions...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final searchTerm = _searchController.text.trim();
                  if (searchTerm.isNotEmpty) {
                    qaController.searchQuestions(
                      productId: widget.productId,
                      searchTerm: searchTerm,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }

  void _answerQuestion(String questionId) {
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Answer Question'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: answerController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Type your answer...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum 10 characters required',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    Obx(
                      () => TextButton(
                        onPressed:
                            qaController.isLoading.value
                                ? null
                                : () async {
                                  final answer = answerController.text.trim();

                                  if (answer.isEmpty) {
                                    SnackbarUtils.showWarning(
                                      'Please enter an answer',
                                    );
                                    return;
                                  }

                                  if (answer.length < 10) {
                                    SnackbarUtils.showWarning(
                                      'Answer must be at least 10 characters long',
                                    );
                                    return;
                                  }

                                  final success = await qaController
                                      .submitAnswer(
                                        questionId: questionId,
                                        answer: answer,
                                      );

                                  if (success) {
                                    Navigator.pop(context);
                                    SnackbarUtils.showSuccess(
                                      'Answer submitted successfully!',
                                    );
                                  }
                                },
                        child:
                            qaController.isLoading.value
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showReportQADialog(String qaId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report Q&A'),
            content: const Text(
              'Why are you reporting this question or answer?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  qaController.reportQA(qaId, 'Inappropriate content');
                  SnackbarUtils.showInfo(
                    'Content reported. Thank you for helping keep our community safe.',
                  );
                },
                child: const Text('Report'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
