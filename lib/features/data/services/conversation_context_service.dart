import 'package:supabase_flutter/supabase_flutter.dart';
import 'ujunwa_ai_service.dart';

/// Conversation Context Service
///
/// Manages conversation memory and context for UJUNWA AI Assistant.
/// This service handles:
/// - Storing conversation context in database
/// - Retrieving relevant conversation history
/// - Managing user preferences and learned information
/// - Context summarization for long conversations
class ConversationContextService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get conversation context for the current conversation
  Future<List<ConversationContext>> getConversationContext({
    required String conversationId,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('conversation_context')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => ConversationContext.fromJson(data))
          .toList();
    } catch (e) {
      print('❌ Error getting conversation context: $e');
      return [];
    }
  }

  /// Get user preferences learned from all conversations
  Future<UserPreferences> getUserPreferences(String userId) async {
    try {
      // Get recent conversation contexts to extract preferences
      final response = await _supabase
          .from('conversation_context')
          .select('extracted_info, intent_type, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50); // Look at recent 50 interactions

      final preferences = UserPreferences();

      for (final context in response) {
        final info = context['extracted_info'] as String? ?? '';
        final intentType = context['intent_type'] as String? ?? '';

        // Extract preferences from the information
        _extractPreferencesFromInfo(info, preferences);
        _updateIntentFrequency(intentType, preferences);
      }

      return preferences;
    } catch (e) {
      print('❌ Error getting user preferences: $e');
      return UserPreferences();
    }
  }

  /// Store conversation context
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
      await _supabase.from('conversation_context').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'user_message': userMessage,
        'intent_type': intentType,
        'intent_confidence': intentConfidence,
        'ai_response': aiResponse,
        'extracted_info': extractedInfo,
        'products_mentioned': productsMentioned,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error storing conversation context: $e');
      // Don't throw as this is not critical for user experience
    }
  }

  /// Get conversation summary for long conversations
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

      // Create a summary of the conversation
      final summary = StringBuffer();
      final mentionedProducts = <String>{};
      final userPreferences = <String>{};
      final mainTopics = <String>{};

      for (final context in contexts.reversed) {
        // Collect mentioned products
        mentionedProducts.addAll(context.productsMentioned);

        // Collect user preferences
        if (context.extractedInfo.isNotEmpty) {
          userPreferences.add(context.extractedInfo);
        }

        // Collect main topics based on intent
        mainTopics.add(context.intentType);
      }

      // Build summary
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
      print('❌ Error creating conversation summary: $e');
      return '';
    }
  }

  /// Clear old conversation contexts to manage storage
  Future<void> cleanupOldContexts({
    required String userId,
    int keepDays = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

      await _supabase
          .from('conversation_context')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate.toIso8601String());
    } catch (e) {
      print('❌ Error cleaning up old contexts: $e');
    }
  }

  /// Get similar conversations for better context
  Future<List<ConversationContext>> getSimilarConversations({
    required String userId,
    required String currentMessage,
    int limit = 5,
  }) async {
    try {
      // For now, get recent conversations with similar intent
      // In the future, this could use vector similarity
      final response = await _supabase
          .from('conversation_context')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit * 2); // Get more to filter

      final contexts =
          (response as List)
              .map((data) => ConversationContext.fromJson(data))
              .toList();

      // Simple similarity based on common words
      final currentWords = currentMessage.toLowerCase().split(' ');
      final scoredContexts = <MapEntry<ConversationContext, double>>[];

      for (final context in contexts) {
        final contextWords = context.userMessage.toLowerCase().split(' ');
        final commonWords =
            currentWords.where((word) => contextWords.contains(word)).length;

        final similarity = commonWords / currentWords.length;
        if (similarity > 0.2) {
          // At least 20% similarity
          scoredContexts.add(MapEntry(context, similarity));
        }
      }

      // Sort by similarity and return top results
      scoredContexts.sort((a, b) => b.value.compareTo(a.value));
      return scoredContexts.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      print('❌ Error getting similar conversations: $e');
      return [];
    }
  }

  /// Helper methods
  void _extractPreferencesFromInfo(String info, UserPreferences preferences) {
    if (info.isEmpty) return;

    final lowerInfo = info.toLowerCase();

    // Price preferences
    if (lowerInfo.contains('affordable') || lowerInfo.contains('cheap')) {
      preferences.pricePreference = 'affordable';
    } else if (lowerInfo.contains('premium') ||
        lowerInfo.contains('expensive')) {
      preferences.pricePreference = 'premium';
    }

    // Size preferences
    if (lowerInfo.contains('large') || lowerInfo.contains('xl')) {
      preferences.sizePreference = 'large';
    } else if (lowerInfo.contains('small') || lowerInfo.contains('xs')) {
      preferences.sizePreference = 'small';
    }

    // Activity preferences
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
  String? pricePreference; // 'affordable', 'premium', 'mid-range'
  String? sizePreference; // 'small', 'medium', 'large'
  Set<String> interests = {}; // 'fitness', 'professional', 'casual', etc.
  Map<String, int> intentFrequency = {}; // Track what user asks about most
  List<String> favoriteCategories = [];
  List<String> favoriteColors = [];

  /// Get a summary of user preferences as a string
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

    // Find most common intent
    if (intentFrequency.isNotEmpty) {
      final mostCommon = intentFrequency.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      summary.add('frequently asks about ${mostCommon.key}');
    }

    return summary.join(', ');
  }

  /// Check if user has specific preference
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
