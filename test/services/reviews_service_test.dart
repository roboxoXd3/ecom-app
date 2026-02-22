import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/features/data/services/reviews_service.dart';
import 'package:ecom_app/features/data/models/review_model.dart';
import '../helpers/mock_api_client.dart';

void main() {
  late ReviewsService service;
  late MockDioHelper mockDio;

  setUp(() {
    mockDio = MockDioHelper();
    service = ReviewsService();
  });

  group('getProductReviews', () {
    test('returns list of reviews from paginated response', () async {
      mockDio.addGetResponse('/products/prod-1/reviews/', {
        'count': 2,
        'results': [
          {
            'id': 'rev-1',
            'product_id': 'prod-1',
            'user_id': 'user-1',
            'rating': 5,
            'title': 'Excellent',
            'content': 'Great quality',
            'images': [],
            'verified_purchase': true,
            'helpful_count': 3,
            'reported_count': 0,
            'status': 'published',
            'created_at': '2026-02-01T12:00:00.000Z',
            'updated_at': '2026-02-01T12:00:00.000Z',
          },
          {
            'id': 'rev-2',
            'product_id': 'prod-1',
            'user_id': 'user-2',
            'rating': 4,
            'title': 'Good',
            'content': 'Nice product',
            'images': [],
            'verified_purchase': false,
            'helpful_count': 0,
            'reported_count': 0,
            'status': 'published',
            'created_at': '2026-02-02T12:00:00.000Z',
            'updated_at': '2026-02-02T12:00:00.000Z',
          },
        ],
      });
      mockDio.install();

      final reviews = await service.getProductReviews(productId: 'prod-1');

      expect(reviews, hasLength(2));
      expect(reviews[0].id, 'rev-1');
      expect(reviews[0].rating, 5);
      expect(reviews[1].rating, 4);
    });

    test('returns empty list when no reviews exist', () async {
      mockDio.addGetResponse('/products/prod-2/reviews/', {
        'count': 0,
        'results': [],
      });
      mockDio.install();

      final reviews = await service.getProductReviews(productId: 'prod-2');
      expect(reviews, isEmpty);
    });
  });

  group('getReviewsSummary', () {
    test('parses summary from reviews response', () async {
      mockDio.addGetResponse('/products/prod-1/reviews/', {
        'count': 10,
        'results': [],
        'summary': {
          'average_rating': 4.2,
          'total_reviews': 10,
          'histogram': [0, 1, 2, 3, 4],
        },
      });
      mockDio.install();

      final summary = await service.getReviewsSummary('prod-1');

      expect(summary.averageRating, 4.2);
      expect(summary.totalReviews, 10);
      expect(summary.histogram, [0, 1, 2, 3, 4]);
    });

    test('returns empty summary on error', () async {
      mockDio.addErrorResponse('/products/prod-3/reviews/', 500, {'error': 'Server error'});
      mockDio.install();

      final summary = await service.getReviewsSummary('prod-3');

      expect(summary.averageRating, 0.0);
      expect(summary.totalReviews, 0);
    });
  });

  group('getReviewsWithMedia', () {
    test('passes has_media parameter', () async {
      mockDio.addGetResponse('/products/prod-1/reviews/', {
        'count': 1,
        'results': [
          {
            'id': 'rev-media',
            'product_id': 'prod-1',
            'user_id': 'user-1',
            'rating': 5,
            'title': 'With photo',
            'content': 'Look at this!',
            'images': ['https://img.jpg'],
            'verified_purchase': true,
            'helpful_count': 0,
            'reported_count': 0,
            'status': 'published',
            'created_at': '2026-02-01T12:00:00.000Z',
            'updated_at': '2026-02-01T12:00:00.000Z',
          },
        ],
      });
      mockDio.install();

      final reviews = await service.getReviewsWithMedia(productId: 'prod-1');

      expect(reviews, hasLength(1));
      expect(reviews[0].images, isNotEmpty);
    });
  });
}
