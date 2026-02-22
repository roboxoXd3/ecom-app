import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/features/data/models/review_model.dart';

void main() {
  group('Review.fromJson', () {
    test('parses a complete review correctly', () {
      final json = {
        'id': 'rev-1',
        'product_id': 'prod-1',
        'user_id': 'user-1',
        'order_id': 'order-1',
        'rating': 5,
        'title': 'Great product',
        'content': 'Really loved it',
        'images': ['https://img1.jpg', 'https://img2.jpg'],
        'verified_purchase': true,
        'helpful_count': 12,
        'reported_count': 0,
        'status': 'published',
        'vendor_response': 'Thank you!',
        'vendor_response_date': '2026-02-10T10:00:00.000Z',
        'created_at': '2026-02-01T12:00:00.000Z',
        'updated_at': '2026-02-01T12:00:00.000Z',
      };

      final review = Review.fromJson(json);

      expect(review.id, 'rev-1');
      expect(review.productId, 'prod-1');
      expect(review.rating, 5);
      expect(review.title, 'Great product');
      expect(review.content, 'Really loved it');
      expect(review.images, hasLength(2));
      expect(review.verifiedPurchase, isTrue);
      expect(review.helpfulCount, 12);
      expect(review.status, 'published');
      expect(review.vendorResponse, 'Thank you!');
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'id': 'rev-2',
        'product_id': 'prod-2',
        'user_id': 'user-2',
        'rating': 3,
        'created_at': '2026-02-01T12:00:00.000Z',
        'updated_at': '2026-02-01T12:00:00.000Z',
      };

      final review = Review.fromJson(json);

      expect(review.title, '');
      expect(review.content, '');
      expect(review.images, isEmpty);
      expect(review.verifiedPurchase, isFalse);
      expect(review.helpfulCount, 0);
      expect(review.reportedCount, 0);
      expect(review.status, 'pending');
      expect(review.orderId, isNull);
      expect(review.vendorResponse, isNull);
      expect(review.vendorResponseDate, isNull);
    });

    test('handles images as comma-separated string', () {
      final json = {
        'id': 'rev-3',
        'product_id': 'prod-3',
        'user_id': 'user-3',
        'rating': 4,
        'images': 'img1.jpg, img2.jpg',
        'created_at': '2026-02-01T12:00:00.000Z',
        'updated_at': '2026-02-01T12:00:00.000Z',
      };

      final review = Review.fromJson(json);
      expect(review.images, hasLength(2));
      expect(review.images[0], 'img1.jpg');
      expect(review.images[1], 'img2.jpg');
    });

    test('handles null images', () {
      final json = {
        'id': 'rev-4',
        'product_id': 'prod-4',
        'user_id': 'user-4',
        'rating': 2,
        'images': null,
        'created_at': '2026-02-01T12:00:00.000Z',
        'updated_at': '2026-02-01T12:00:00.000Z',
      };

      final review = Review.fromJson(json);
      expect(review.images, isEmpty);
    });
  });

  group('Review.toJson', () {
    test('round-trips correctly', () {
      final original = Review(
        id: 'rev-5',
        productId: 'prod-5',
        userId: 'user-5',
        orderId: 'order-5',
        rating: 4,
        title: 'Good',
        content: 'Nice quality',
        images: ['img.jpg'],
        verifiedPurchase: true,
        helpfulCount: 3,
        reportedCount: 0,
        status: 'published',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final json = original.toJson();
      final restored = Review.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.rating, original.rating);
      expect(restored.title, original.title);
      expect(restored.images, original.images);
    });
  });

  group('ReviewsSummary.fromJson', () {
    test('parses Django summary response', () {
      final json = {
        'average_rating': 4.5,
        'total_reviews': 23,
        'histogram': [1, 2, 3, 5, 12],
      };

      final summary = ReviewsSummary.fromJson(json);

      expect(summary.averageRating, 4.5);
      expect(summary.totalReviews, 23);
      expect(summary.histogram, [1, 2, 3, 5, 12]);
      expect(summary.histogram, hasLength(5));
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final summary = ReviewsSummary.fromJson(json);

      expect(summary.averageRating, 0.0);
      expect(summary.totalReviews, 0);
      expect(summary.histogram, [0, 0, 0, 0, 0]);
    });
  });
}
