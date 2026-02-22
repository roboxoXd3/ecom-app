import '../../../core/network/api_client.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final _api = ApiClient.instance;

  Future<ChatConversation> createConversation({
    required String userId,
    String title = 'New Conversation',
  }) async {
    final response = await _api.post(
      '/support/chat/',
      data: {'title': title},
    );
    return ChatConversation.fromJson(response.data);
  }

  Future<List<ChatConversation>> getUserConversations(String userId) async {
    final response = await _api.get('/support/chat/');
    final data = response.data;
    final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
    return results.map((json) => ChatConversation.fromJson(json)).toList();
  }

  Future<ChatConversation?> getConversation(String conversationId) async {
    try {
      final response = await _api.get('/support/chat/$conversationId/');
      return ChatConversation.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateConversationTitle(String conversationId, String title) async {
    await _api.patch('/support/chat/$conversationId/', data: {'title': title});
  }

  Future<void> markConversationResolved(String conversationId) async {
    await _api.patch('/support/chat/$conversationId/', data: {'is_resolved': true});
  }

  Future<void> updateLastMessageTime(String conversationId) async {
    // Handled server-side when messages are added
  }

  Future<ChatMessage> addMessage({
    required String conversationId,
    required String senderType,
    required String messageText,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _api.post(
      '/support/chat/send/',
      data: {
        'conversation_id': conversationId,
        'message': messageText,
        'message_type': messageType,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return ChatMessage.fromJson(response.data);
  }

  Future<List<ChatMessage>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
    bool newestFirst = true,
  }) async {
    final response = await _api.get(
      '/support/chat/$conversationId/messages/',
      queryParameters: {
        'page_size': limit,
        'ordering': newestFirst ? '-created_at' : 'created_at',
      },
    );
    final data = response.data;
    final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
    return results.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<void> markMessagesAsRead(String conversationId, String senderType) async {
    try {
      await _api.post('/support/chat/$conversationId/messages/mark-read/');
    } catch (_) {}
  }

  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await _api.get('/support/chat/unread-count/');
      return response.data['count'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> trackChatAction({
    required String conversationId,
    required String userId,
    required String actionType,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      await _api.post('/support/chat/analytics/', data: {
        'conversation_id': conversationId,
        'action_type': actionType,
        if (actionData != null) 'action_data': actionData,
      });
    } catch (_) {}
  }

  Future<List<ChatAnalytics>> getChatAnalytics(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (fromDate != null) params['from_date'] = fromDate.toIso8601String();
      if (toDate != null) params['to_date'] = toDate.toIso8601String();

      final response = await _api.get('/support/chat/analytics/', queryParameters: params);
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => ChatAnalytics.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    await _api.delete('/support/chat/$conversationId/');
  }

  Future<void> clearChatHistory(String userId) async {
    try {
      await _api.post('/support/chat/clear-history/');
    } catch (_) {}
  }

  Future<List<ChatMessage>> searchMessages(
    String userId,
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '/support/chat/messages/search/',
        queryParameters: {'q': query, 'page_size': limit},
      );
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }
}
