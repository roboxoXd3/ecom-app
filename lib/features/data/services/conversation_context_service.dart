import '../../../core/network/api_client.dart';
import 'ujunwa_ai_service.dart';

/// Conversation Context Service
///
/// Manages conversation memory and context for UJUNWA AI Assistant.
/// This service handles:
/// - Storing conversation context via API
/// - Retrieving relevant conversation history
/// - Managing user preferences and learned information
/// - Context summarization for long conversations
class ConversationContextService {
  final _api = ApiClient.instance;

  Future<List<ConversationContext>> getConversationContext({
    required String conversationId,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/support/chat/$conversationId/context/',
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((data) => ConversationContext.fromJson(data)).toList();
    } catch (e) {
      print('Error getting conversation context: $e');
      return [];
    }
  }

  Future<UserPreferences> getUserPreferences(String userId) async {
    try {
      final response = await _api.get('/support/chat/preferences/');
      final data = response.data;

      final preferences = UserPreferences();
      if (data is Map) {
        preferences.pricePreference = data['price_preference'];
        preferences.sizePreference = data['size_preference'];
        if (data['interests'] is List) {
          preferences.interests = Set<String>.from(data['interests']);
        }
        if (data['intent_frequency'] is Map) {
          preferences.intentFrequency = Map<String, int>.from(
            data['intent_frequency'].map((k, v) => MapEntry(k, v as int)),
          );
        }
      }
      return preferences;
    } catch (e) {
      print('Error getting user preferences: $e');
      return UserPreferences();
    }
  }

  Future<void> storeConversationContext({
    required String conversationId,
    required String userId,
    required String userMessage,
    required String intentType,
    required double intentConfidence,
    required String aiResponse,
    required String extractedInfo,
    required List<String> productsMentioned,
  }) async {
    try {
      await _api.post('/support/chat/$conversationId/context/', data: {
        'user_message': userMessage,
        'intent_type': intentType,
        'intent_confidence': intentConfidence,
        'ai_response': aiResponse,
        'extracted_info': extractedInfo,
        'products_mentioned': productsMentioned,
      });
    } catch (e) {
      print('Error storing conversation context: $e');
    }
  }

  Future<String> getConversationSummary({
    required String conversationId,
    int contextLimit = 20,
  }) async {
    try {
      final contexts = await getConversationContext(
        conversationId: conversationId,
        limit: contextLimit,
      );

      if (contexts.isEmpty) return '';

      final summary = StringBuffer();
      final mentionedProducts = <String>{};
      final userPreferences = <String>{};
      final mainTopics = <String>{};

      for (final context in contexts.reversed) {
        mentionedProducts.addAll(context.productsMentioned);
        if (context.extractedInfo.isNotEmpty) {
          userPreferences.add(context.extractedInfo);
        }
        mainTopics.add(context.intentType);
      }

      if (mainTopics.isNotEmpty) {
        summary.writeln('Main topics discussed: ${mainTopics.join(', ')}');
      }
      if (userPreferences.isNotEmpty) {
        summary.writeln('User preferences: ${userPreferences.join(', ')}');
      }
      if (mentionedProducts.isNotEmpty && mentionedProducts.length <= 5) {
        summary.writeln('Products discussed: ${mentionedProducts.join(', ')}');
      } else if (mentionedProducts.length > 5) {
        summary.writeln('${mentionedProducts.length} products were discussed');
      }

      return summary.toString().trim();
    } catch (e) {
      print('Error creating conversation summary: $e');
      return '';
    }
  }

  Future<void> cleanupOldContexts({
    required String userId,
    int keepDays = 30,
  }) async {
    try {
      await _api.post('/support/chat/cleanup-contexts/', data: {
        'keep_days': keepDays,
      });
    } catch (e) {
      print('Error cleaning up old contexts: $e');
    }
  }

  Future<List<ConversationContext>> getSimilarConversations({
    required String userId,
    required String currentMessage,
    int limit = 5,
  }) async {
    try {
      final response = await _api.get(
        '/support/chat/similar/',
        queryParameters: {'message': currentMessage, 'limit': limit},
      );
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((data) => ConversationContext.fromJson(data)).toList();
    } catch (e) {
      print('Error getting similar conversations: $e');
      return [];
    }
  }

  void _extractPreferencesFromInfo(String info, UserPreferences preferences) {
    if (info.isEmpty) return;

    final lowerInfo = info.toLowerCase();

    if (lowerInfo.contains('affordable') || lowerInfo.contains('cheap')) {
      preferences.pricePreference = 'affordable';
    } else if (lowerInfo.contains('premium') || lowerInfo.contains('expensive')) {
      preferences.pricePreference = 'premium';
    }

    if (lowerInfo.contains('large') || lowerInfo.contains('xl')) {
      preferences.sizePreference = 'large';
    } else if (lowerInfo.contains('small') || lowerInfo.contains('xs')) {
      preferences.sizePreference = 'small';
    }

    if (lowerInfo.contains('fitness') || lowerInfo.contains('workout')) {
      preferences.interests.add('fitness');
    }
    if (lowerInfo.contains('work') || lowerInfo.contains('professional')) {
      preferences.interests.add('professional');
    }
    if (lowerInfo.contains('casual')) {
      preferences.interests.add('casual');
    }
  }

  void _updateIntentFrequency(String intentType, UserPreferences preferences) {
    preferences.intentFrequency[intentType] =
        (preferences.intentFrequency[intentType] ?? 0) + 1;
  }
}

/// User Preferences Model
class UserPreferences {
  String? pricePreference;
  String? sizePreference;
  Set<String> interests = {};
  Map<String, int> intentFrequency = {};
  List<String> favoriteCategories = [];
  List<String> favoriteColors = [];

  String getSummary() {
    final summary = <String>[];

    if (pricePreference != null) {
      summary.add('prefers $pricePreference products');
    }
    if (sizePreference != null) {
      summary.add('usually needs $sizePreference sizes');
    }
    if (interests.isNotEmpty) {
      summary.add('interested in ${interests.join(', ')}');
    }
    if (favoriteCategories.isNotEmpty) {
      summary.add('likes ${favoriteCategories.join(', ')} products');
    }
    if (intentFrequency.isNotEmpty) {
      final mostCommon = intentFrequency.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      summary.add('frequently asks about ${mostCommon.key}');
    }

    return summary.join(', ');
  }

  bool hasPreference(String type, String value) {
    switch (type) {
      case 'price':
        return pricePreference == value;
      case 'size':
        return sizePreference == value;
      case 'interest':
        return interests.contains(value);
      case 'category':
        return favoriteCategories.contains(value);
      default:
        return false;
    }
  }
}
