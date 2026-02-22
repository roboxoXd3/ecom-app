import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/features/data/services/qa_service.dart';
import 'package:ecom_app/features/data/models/qa_model.dart';
import '../helpers/mock_api_client.dart';

void main() {
  late QAService service;
  late MockDioHelper mockDio;

  setUp(() {
    mockDio = MockDioHelper();
    service = QAService();
  });

  group('getProductQA', () {
    test('returns list of Q&A from paginated response', () async {
      mockDio.addGetResponse('/products/prod-1/qa/', {
        'count': 1,
        'results': [
          {
            'id': 'qa-1',
            'product_id': 'prod-1',
            'user_id': 'user-1',
            'question': 'Is this durable?',
            'answer': 'Very durable, yes.',
            'answered_by': 'vendor-1',
            'answered_at': '2026-02-05T10:00:00.000Z',
            'is_helpful_count': 3,
            'is_verified': false,
            'status': 'published',
            'created_at': '2026-02-01T12:00:00.000Z',
            'updated_at': '2026-02-05T10:00:00.000Z',
          },
        ],
      });
      mockDio.install();

      final qaList = await service.getProductQA(productId: 'prod-1');

      expect(qaList, hasLength(1));
      expect(qaList[0].question, 'Is this durable?');
      expect(qaList[0].answer, 'Very durable, yes.');
      expect(qaList[0].hasAnswer, isTrue);
    });

    test('returns empty list when no Q&A exists', () async {
      mockDio.addGetResponse('/products/prod-2/qa/', {
        'count': 0,
        'results': [],
      });
      mockDio.install();

      final qaList = await service.getProductQA(productId: 'prod-2');
      expect(qaList, isEmpty);
    });
  });

  group('searchQuestions', () {
    test('passes search parameter and returns results', () async {
      mockDio.addGetResponse('/products/prod-1/qa/', {
        'count': 1,
        'results': [
          {
            'id': 'qa-search-1',
            'product_id': 'prod-1',
            'user_id': 'user-1',
            'question': 'What is the battery life?',
            'is_helpful_count': 2,
            'is_verified': false,
            'status': 'published',
            'created_at': '2026-02-01T12:00:00.000Z',
            'updated_at': '2026-02-01T12:00:00.000Z',
          },
        ],
      });
      mockDio.install();

      final results = await service.searchQuestions(
        productId: 'prod-1',
        searchTerm: 'battery',
      );

      expect(results, hasLength(1));
      expect(results[0].question, contains('battery'));
    });
  });

  group('getQAStats', () {
    test('returns total count from paginated response', () async {
      mockDio.addGetResponse('/products/prod-1/qa/', {
        'count': 15,
        'results': [],
      });
      mockDio.install();

      final stats = await service.getQAStats('prod-1');

      expect(stats['total'], 15);
    });

    test('returns zero on error', () async {
      mockDio.addErrorResponse('/products/prod-3/qa/', 500, {'error': 'fail'});
      mockDio.install();

      final stats = await service.getQAStats('prod-3');

      expect(stats['total'], 0);
    });
  });
}
