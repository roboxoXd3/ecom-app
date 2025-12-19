import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Conversation methods
  Future<ChatConversation> createConversation({
    required String userId,
    String title = 'New Conversation',
  }) async {
    final response =
        await _supabase
            .from('chat_conversations')
            .insert({'user_id': userId, 'title': title})
            .select()
            .single();

    return ChatConversation.fromJson(response);
  }

  Future<List<ChatConversation>> getUserConversations(String userId) async {
    final response = await _supabase
        .from('chat_conversations')
        .select()
        .eq('user_id', userId)
        .order('last_message_at', ascending: false);

    return (response as List)
        .map((json) => ChatConversation.fromJson(json))
        .toList();
  }

  Future<ChatConversation?> getConversation(String conversationId) async {
    final response =
        await _supabase
            .from('chat_conversations')
            .select()
            .eq('id', conversationId)
            .maybeSingle();

    return response != null ? ChatConversation.fromJson(response) : null;
  }

  Future<void> updateConversationTitle(
    String conversationId,
    String title,
  ) async {
    await _supabase
        .from('chat_conversations')
        .update({
          'title': title,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  Future<void> markConversationResolved(String conversationId) async {
    await _supabase
        .from('chat_conversations')
        .update({
          'is_resolved': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  Future<void> updateLastMessageTime(String conversationId) async {
    await _supabase
        .from('chat_conversations')
        .update({
          'last_message_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  // Message methods
  Future<ChatMessage> addMessage({
    required String conversationId,
    required String senderType,
    required String messageText,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    final response =
        await _supabase
            .from('chat_messages')
            .insert({
              'conversation_id': conversationId,
              'sender_type': senderType,
              'message_text': messageText,
              'message_type': messageType,
              'metadata': metadata,
            })
            .select()
            .single();

    // Update conversation last message time
    await updateLastMessageTime(conversationId);

    return ChatMessage.fromJson(response);
  }

  Future<List<ChatMessage>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
    bool newestFirst = true, // NEW: Order by newest first for easier pagination
  }) async {
    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: !newestFirst)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  Future<void> markMessagesAsRead(
    String conversationId,
    String senderType,
  ) async {
    await _supabase
        .from('chat_messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('sender_type', senderType);
  }

  Future<int> getUnreadMessageCount(String userId) async {
    // First get user's conversation IDs
    final conversationsResponse = await _supabase
        .from('chat_conversations')
        .select('id')
        .eq('user_id', userId);

    final conversationIds =
        (conversationsResponse as List).map((c) => c['id'] as String).toList();

    if (conversationIds.isEmpty) return 0;

    final response = await _supabase
        .from('chat_messages')
        .select('id')
        .eq('is_read', false)
        .neq('sender_type', 'user')
        .filter('conversation_id', 'in', '(${conversationIds.join(',')})');

    return (response as List).length;
  }

  // Analytics methods
  Future<void> trackChatAction({
    required String conversationId,
    required String userId,
    required String actionType,
    Map<String, dynamic>? actionData,
  }) async {
    await _supabase.from('chat_analytics').insert({
      'conversation_id': conversationId,
      'user_id': userId,
      'action_type': actionType,
      'action_data': actionData,
    });
  }

  Future<List<ChatAnalytics>> getChatAnalytics(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _supabase.from('chat_analytics').select().eq('user_id', userId);

    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }

    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => ChatAnalytics.fromJson(json))
        .toList();
  }

  // Helper methods
  Future<void> deleteConversation(String conversationId) async {
    await _supabase
        .from('chat_conversations')
        .delete()
        .eq('id', conversationId);
  }

  Future<void> clearChatHistory(String userId) async {
    // Get all user conversation IDs
    final conversations = await getUserConversations(userId);
    final conversationIds = conversations.map((c) => c.id).toList();

    if (conversationIds.isNotEmpty) {
      // Delete messages first (due to foreign key constraints)
      await _supabase
          .from('chat_messages')
          .delete()
          .filter('conversation_id', 'in', '(${conversationIds.join(',')})');

      // Delete conversations
      await _supabase.from('chat_conversations').delete().eq('user_id', userId);

      // Delete analytics
      await _supabase.from('chat_analytics').delete().eq('user_id', userId);
    }
  }

  // Search functionality
  Future<List<ChatMessage>> searchMessages(
    String userId,
    String query, {
    int limit = 20,
  }) async {
    final response = await _supabase
        .from('chat_messages')
        .select('*, chat_conversations!inner(user_id)')
        .textSearch('message_text', query)
        .eq('chat_conversations.user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }
}
