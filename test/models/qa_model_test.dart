import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/features/data/models/qa_model.dart';

void main() {
  group('ProductQA.fromJson', () {
    test('parses a complete Q&A item', () {
      final json = {
        'id': 'qa-1',
        'product_id': 'prod-1',
        'user_id': 'user-1',
        'question': 'Is this waterproof?',
        'answer': 'Yes, it is IPX7 rated.',
        'answered_by': 'vendor-1',
        'answered_at': '2026-02-10T10:00:00.000Z',
        'is_helpful_count': 5,
        'is_verified': true,
        'status': 'published',
        'created_at': '2026-02-01T12:00:00.000Z',
        'updated_at': '2026-02-01T12:00:00.000Z',
        'vendor_response': 'Confirmed waterproof.',
        'vendor_response_date': '2026-02-11T10:00:00.000Z',
        'vendor_id': 'vendor-1',
      };

      final qa = ProductQA.fromJson(json);

      expect(qa.id, 'qa-1');
      expect(qa.question, 'Is this waterproof?');
      expect(qa.answer, 'Yes, it is IPX7 rated.');
      expect(qa.isHelpfulCount, 5);
      expect(qa.isVerified, isTrue);
      expect(qa.status, 'published');
      expect(qa.vendorResponse, 'Confirmed waterproof.');
    });

    test('handles unanswered question', () {
      final json = {
        'id': 'qa-2',
        'product_id': 'prod-2',
        'user_id': 'user-2',
        'question': 'What material is this?',
        'status': 'pending',
        'created_at': '2026-02-01T12:00:00.000Z',
        'updated_at': '2026-02-01T12:00:00.000Z',
      };

      final qa = ProductQA.fromJson(json);

      expect(qa.answer, isNull);
      expect(qa.hasAnswer, isFalse);
      expect(qa.isHelpfulCount, 0);
      expect(qa.status, 'pending');
    });
  });

  group('ProductQA computed properties', () {
    test('hasAnswer returns true when answer is non-empty', () {
      final qa = _makeQA(answer: 'Some answer');
      expect(qa.hasAnswer, isTrue);
    });

    test('hasAnswer returns false when answer is null', () {
      final qa = _makeQA(answer: null);
      expect(qa.hasAnswer, isFalse);
    });

    test('hasAnswer returns false when answer is empty', () {
      final qa = _makeQA(answer: '');
      expect(qa.hasAnswer, isFalse);
    });

    test('displayAnswer prefers vendor response over answer', () {
      final qa = _makeQA(
        answer: 'Community answer',
        vendorResponse: 'Official vendor answer',
      );
      expect(qa.displayAnswer, 'Official vendor answer');
    });

    test('displayAnswer falls back to answer if no vendor response', () {
      final qa = _makeQA(answer: 'Community answer', vendorResponse: null);
      expect(qa.displayAnswer, 'Community answer');
    });

    test('displayAnsweredBy returns Vendor when vendor responded', () {
      final qa = _makeQA(vendorResponse: 'Yes');
      expect(qa.displayAnsweredBy, 'Vendor');
    });

    test('displayAnsweredBy returns answeredBy when no vendor response', () {
      final qa = _makeQA(vendorResponse: null, answeredBy: 'John');
      expect(qa.displayAnsweredBy, 'John');
    });

    test('displayAnsweredBy returns Community when no answerer', () {
      final qa = _makeQA(vendorResponse: null, answeredBy: null);
      expect(qa.displayAnsweredBy, 'Community');
    });
  });

  group('ProductQA.toJson round-trip', () {
    test('survives serialization', () {
      final original = _makeQA(
        answer: 'Test answer',
        vendorResponse: 'Vendor says yes',
      );

      final json = original.toJson();
      final restored = ProductQA.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.question, original.question);
      expect(restored.answer, original.answer);
      expect(restored.vendorResponse, original.vendorResponse);
    });
  });
}

ProductQA _makeQA({
  String? answer,
  String? vendorResponse,
  String? answeredBy,
}) {
  return ProductQA(
    id: 'qa-test',
    productId: 'prod-test',
    userId: 'user-test',
    question: 'Test question?',
    answer: answer,
    answeredBy: answeredBy,
    answeredAt: null,
    isHelpfulCount: 0,
    isVerified: false,
    status: 'published',
    createdAt: DateTime(2026, 2, 1),
    updatedAt: DateTime(2026, 2, 1),
    vendorResponse: vendorResponse,
    vendorResponseDate: null,
    vendorId: null,
  );
}
