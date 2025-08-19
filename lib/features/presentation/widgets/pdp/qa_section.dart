import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class QASection extends StatefulWidget {
  final String productId;

  const QASection({super.key, required this.productId});

  @override
  State<QASection> createState() => _QASectionState();
}

class _QASectionState extends State<QASection> {
  final TextEditingController _questionController = TextEditingController();
  String _sortBy = 'helpful';

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions & Answers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      ),
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
          TextField(
            controller: _questionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ask your question here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _submitQuestion();
                  },
                  child: const Text('Ask Question'),
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
          value: _sortBy,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'helpful', child: Text('Most Helpful')),
            DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
          ],
          onChanged: (value) {
            setState(() {
              _sortBy = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    final mockQuestions = _getMockQuestions();

    return Column(
      children: mockQuestions.map((qa) => _buildQACard(qa)).toList(),
    );
  }

  Widget _buildQACard(Map<String, dynamic> qa) {
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
                      qa['question'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asked by ${qa['askedBy']} on ${qa['askedDate']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Answer (if available)
          if (qa['answer'] != null) ...[
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
                          qa['answer'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Answered by ${qa['answeredBy']} on ${qa['answeredDate']}',
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
                  // Mark as helpful
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${qa['helpful']})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (qa['answer'] == null)
                InkWell(
                  onTap: () {
                    _answerQuestion(qa['id']);
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
                  // Report question
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

  void _submitQuestion() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a question')));
      return;
    }

    // TODO: Submit question to API
    _questionController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question submitted successfully!')),
    );
  }

  void _searchQuestions() {
    // TODO: Implement search functionality
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search Questions'),
            content: TextField(
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }

  void _answerQuestion(String questionId) {
    // TODO: Implement answer functionality
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Answer Question'),
            content: TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type your answer...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Answer submitted!')),
                  );
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  List<Map<String, dynamic>> _getMockQuestions() {
    return [
      {
        'id': '1',
        'question': 'What is the maximum weight capacity of this scale?',
        'askedBy': 'Rahul M.',
        'askedDate': '3 days ago',
        'answer':
            'The maximum weight capacity is 180 kg. It has a graduation of 100g for accurate measurements.',
        'answeredBy': 'Product Expert',
        'answeredDate': '2 days ago',
        'helpful': 15,
      },
      {
        'id': '2',
        'question': 'Does this scale work without batteries?',
        'askedBy': 'Sneha K.',
        'askedDate': '1 week ago',
        'answer':
            'No, this scale requires 2 AAA batteries to operate. The batteries are not included in the box.',
        'answeredBy': 'Vendor',
        'answeredDate': '6 days ago',
        'helpful': 8,
      },
      {
        'id': '3',
        'question': 'Is the display backlit for use in dark rooms?',
        'askedBy': 'Arjun P.',
        'askedDate': '2 weeks ago',
        'answer': null,
        'answeredBy': null,
        'answeredDate': null,
        'helpful': 3,
      },
    ];
  }
}
