import 'product_model.dart';

class ChatConversation {
  final String id;
  final String? userId;
  final String title;
  final DateTime lastMessageAt;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    this.userId,
    required this.title,
    required this.lastMessageAt,
    required this.isResolved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final userField = json['user_id'] ?? json['user'];
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      userId: userField?.toString(),
      title: json['title']?.toString() ?? 'Conversation',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : DateTime.now(),
      isResolved: json['is_resolved'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'last_message_at': lastMessageAt.toIso8601String(),
      'is_resolved': isResolved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderType; // 'user', 'bot', 'agent'
  final String messageText;
  final String messageType; // 'text', 'product', 'image', 'file'
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.messageText,
    this.messageType = 'text',
    this.metadata,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? 'bot',
      messageText: json['message_text']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata']
          : null,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_type': senderType,
      'message_text': messageText,
      'message_type': messageType,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get isUser => senderType == 'user';
  bool get isBot => senderType == 'bot';
  bool get isAgent => senderType == 'agent';

  String get timestamp {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Get product IDs from metadata for product messages
  List<String> get productIds {
    if (metadata != null && metadata!['product_ids'] != null) {
      return List<String>.from(metadata!['product_ids']);
    }
    return [];
  }
}

// UI Model for Chatbot Screen (simplified for display purposes)
class ChatbotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<Product>? products;
  final bool isTyping;

  // NEW: Image support
  final String? imagePath; // Local image path
  final String? imageUrl; // Remote image URL
  final bool hasImage; // Quick check for image presence

  ChatbotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.products,
    this.isTyping = false,

    // NEW: Image parameters
    this.imagePath,
    this.imageUrl,
    this.hasImage = false,
  });

  // Factory for image messages
  factory ChatbotMessage.withImage({
    required String id,
    required String text,
    required bool isUser,
    required DateTime createdAt,
    String? imagePath,
    String? imageUrl,
  }) {
    return ChatbotMessage(
      id: id,
      text: text,
      isUser: isUser,
      createdAt: createdAt,
      imagePath: imagePath,
      imageUrl: imageUrl,
      hasImage: imagePath != null || imageUrl != null,
    );
  }

  // Factory for product results
  factory ChatbotMessage.withProducts({
    required String id,
    required String text,
    required bool isUser,
    required DateTime createdAt,
    required List<Product> products,
  }) {
    return ChatbotMessage(
      id: id,
      text: text,
      isUser: isUser,
      createdAt: createdAt,
      products: products,
    );
  }

  // Factory for typing indicator
  factory ChatbotMessage.typing({required String id}) {
    return ChatbotMessage(
      id: id,
      text: '',
      isUser: false,
      createdAt: DateTime.now(),
      isTyping: true,
    );
  }
}

class ChatAnalytics {
  final String id;
  final String conversationId;
  final String userId;
  final String actionType;
  final Map<String, dynamic>? actionData;
  final DateTime createdAt;

  ChatAnalytics({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.actionType,
    this.actionData,
    required this.createdAt,
  });

  factory ChatAnalytics.fromJson(Map<String, dynamic> json) {
    return ChatAnalytics(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['user']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      actionData: json['action_data'] is Map<String, dynamic>
          ? json['action_data']
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'action_type': actionType,
      'action_data': actionData,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
