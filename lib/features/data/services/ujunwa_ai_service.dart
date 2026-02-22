import '../models/product_model.dart';
import '../../../core/network/api_client.dart';
import 'conversation_context_service.dart';

/// UJUNWA Response Model
class UjunwaResponse {
  final String text;
  final List<Product> products;
  final List<String> suggestions;
  final UserIntent? intent;

  UjunwaResponse({
    required this.text,
    this.products = const [],
    this.suggestions = const [],
    this.intent,
  });
}

/// UJUNWA AI Service
///
/// All AI processing (intent recognition, response generation) happens
/// server-side via POST /api/ai/chat/. The OpenAI API key never ships
/// in the APK.
class UjunwaAIService {
  final _api = ApiClient.instance;
  final ConversationContextService _contextService = ConversationContextService();

  /// Send a message to the backend and get an AI-powered response.
  Future<UjunwaResponse> generateResponse({
    required String userMessage,
    required String userId,
    String? conversationId,
    List<ConversationContext>? context,
  }) async {
    try {
      print('🤖 UJUNWA: Sending to backend: "$userMessage"');

      final contextList = context
          ?.take(5)
          .map((c) => {
                'user_message': c.userMessage,
                'ai_response': c.aiResponse,
                'intent_type': c.intentType,
              })
          .toList();

      final response = await _api.post(
        '/ai/chat/',
        data: {
          'message': userMessage,
          if (contextList != null && contextList.isNotEmpty)
            'conversation_context': contextList,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final text = data['text'] as String? ?? '';
      final suggestions = (data['suggestions'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [];

      final rawProducts = data['products'] as List<dynamic>? ?? [];
      final products = rawProducts
          .map((p) => _productFromMap(p as Map<String, dynamic>))
          .whereType<Product>()
          .toList();

      final intentData = data['intent'] as Map<String, dynamic>?;
      final intent = intentData != null
          ? UserIntent(
              type: _mapStringToIntentType(
                  intentData['intent'] as String? ?? 'general'),
              confidence:
                  (intentData['confidence'] as num?)?.toDouble() ?? 0.5,
              parameters: {'entities': intentData['entities'] ?? []},
            )
          : null;

      if (intent != null) {
        await _storeConversationContext(
          userId: userId,
          conversationId: conversationId,
          userMessage: userMessage,
          intent: intent,
          aiResponse:
              UjunwaResponse(text: text, products: products, suggestions: suggestions),
        );
      }

      print('🤖 UJUNWA: Response received (${products.length} products)');
      return UjunwaResponse(
          text: text, products: products, suggestions: suggestions, intent: intent);
    } catch (e) {
      print('❌ UJUNWA Error: $e');
      return UjunwaResponse(
        text:
            "I apologize, but I'm having trouble processing your request right now. Please try again or ask me something else!",
        suggestions: [
          'Try asking about products',
          'Check order status',
          'Get help with returns',
          'Browse categories',
        ],
      );
    }
  }

  Product? _productFromMap(Map<String, dynamic> map) {
    try {
      return Product.fromJson(map);
    } catch (e) {
      print('⚠️ UJUNWA: Could not parse product: $e');
      return null;
    }
  }

  IntentType _mapStringToIntentType(String intentString) {
    switch (intentString) {
      case 'product_search':
        return IntentType.productSearch;
      case 'order_inquiry':
        return IntentType.orderInquiry;
      case 'product_info':
        return IntentType.productInfo;
      case 'comparison':
        return IntentType.comparison;
      case 'recommendation':
        return IntentType.recommendation;
      case 'support':
        return IntentType.support;
      case 'greeting':
        return IntentType.greeting;
      default:
        return IntentType.general;
    }
  }

  Future<void> _storeConversationContext({
    required String userId,
    String? conversationId,
    required String userMessage,
    required UserIntent intent,
    required UjunwaResponse aiResponse,
  }) async {
    try {
      if (conversationId == null) return;

      final info = _extractKeyInformation(userMessage, intent);

      await _contextService.storeConversationContext(
        conversationId: conversationId,
        userId: userId,
        userMessage: userMessage,
        intentType: intent.type.toString(),
        intentConfidence: intent.confidence,
        aiResponse: aiResponse.text,
        extractedInfo: info,
        productsMentioned: aiResponse.products.map((p) => p.id).toList(),
      );
    } catch (e) {
      print('❌ Error storing conversation context: $e');
    }
  }

  String _extractKeyInformation(String userMessage, UserIntent intent) {
    final lower = userMessage.toLowerCase();
    final info = <String>[];

    if (lower.contains('cheap') || lower.contains('affordable')) {
      info.add('prefers affordable options');
    }
    if (lower.contains('premium') || lower.contains('expensive')) {
      info.add('interested in premium products');
    }
    if (lower.contains('large') || lower.contains('xl')) {
      info.add('prefers large sizes');
    }
    if (lower.contains('small') || lower.contains('xs')) {
      info.add('prefers small sizes');
    }
    if (lower.contains('workout') || lower.contains('gym')) {
      info.add('interested in fitness products');
    }
    if (lower.contains('work') || lower.contains('office')) {
      info.add('needs professional/work items');
    }

    return info.join(', ');
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

enum IntentType {
  productSearch,
  productInfo,
  orderInquiry,
  comparison,
  recommendation,
  support,
  greeting,
  general,
}

class UserIntent {
  final IntentType type;
  final double confidence;
  final Map<String, dynamic>? parameters;

  UserIntent({required this.type, required this.confidence, this.parameters});
}

class ContextData {
  List<Product> products = [];
  String? orderInfo;
  String userPreferences = '';
  Map<String, dynamic> additionalData = {};
}

class ConversationContext {
  final String id;
  final String conversationId;
  final String userId;
  final String userMessage;
  final String intentType;
  final double intentConfidence;
  final String aiResponse;
  final String extractedInfo;
  final List<String> productsMentioned;
  final DateTime createdAt;

  ConversationContext({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.userMessage,
    required this.intentType,
    required this.intentConfidence,
    required this.aiResponse,
    required this.extractedInfo,
    required this.productsMentioned,
    required this.createdAt,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      id: json['id'],
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      userMessage: json['user_message'],
      intentType: json['intent_type'],
      intentConfidence: (json['intent_confidence'] as num?)?.toDouble() ?? 0.0,
      aiResponse: json['ai_response'],
      extractedInfo: json['extracted_info'] ?? '',
      productsMentioned: _parseStringList(json['products_mentioned']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is String) {
      return data.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }
}
