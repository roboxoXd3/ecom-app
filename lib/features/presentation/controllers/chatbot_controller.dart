import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/product_search_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';
import 'auth_controller.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<Product>? products; // Add products for rich responses
  final String? messageType; // 'text', 'products', 'recommendations'

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.products,
    this.messageType = 'text',
  });

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
}

class ChatbotController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isTyping = false.obs;
  final RxBool isLoading = false.obs;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ProductSearchService _searchService = Get.find<ProductSearchService>();

  // Enhanced features
  final ChatRepository _chatRepository = ChatRepository();
  late final AuthController _authController;

  // Current conversation for persistence
  ChatConversation? currentConversation;
  final RxList<ChatConversation> conversations = <ChatConversation>[].obs;

  // Sample bot responses
  final Map<String, List<String>> botResponses = {
    'hello': [
      'Hello! Welcome to Be Smart Mall! How can I assist you today?',
      'Hi there! I\'m here to help with your shopping needs. What can I do for you?',
    ],
    'track order': [
      'I can help you track your order! Please provide your order number, and I\'ll check the status for you.',
      'To track your order, I\'ll need your order number. You can find it in your email confirmation.',
    ],
    'return item': [
      'I can help you with returns! Our return policy allows returns within 30 days of purchase.',
      'For returns, please ensure the item is unused and in original packaging. Would you like me to guide you through the process?',
    ],
    'size guide': [
      'Here\'s our size guide! For clothing, we recommend checking the size chart on each product page.',
      'Size guides vary by brand. I can help you find the right size for specific items. What are you looking for?',
    ],
    'support': [
      'I\'m here to provide support! What specific issue can I help you with?',
      'Our customer support team is available 24/7. How can I assist you today?',
    ],
    'find products': [
      'I can help you find products! What are you looking for today?',
      'Let me help you discover our amazing products. What category interests you?',
    ],
    'default': [
      'I understand you\'re looking for help. Could you please provide more details?',
      'Thanks for your message! I\'m here to help with shopping, orders, returns, and more. What would you like to know?',
      'I\'m not sure about that specific question, but I can help with product searches, order tracking, returns, and general shopping assistance!',
    ],
  };

  @override
  void onInit() {
    super.onInit();
    try {
      _authController = Get.find<AuthController>();
    } catch (e) {
      print('AuthController not found, some features may not work');
    }
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    isLoading.value = true;
    try {
      await _loadUserConversations();
      await _startNewConversationIfNeeded();
      _addWelcomeMessage();
      // Debug: Check what products we have
      _debugProducts();
      // Debug: Check auth status
      _debugAuth();
    } catch (e) {
      print('Error initializing chat: $e');
      _addWelcomeMessage(); // Fallback to welcome message
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserConversations() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final userConversations = await _chatRepository.getUserConversations(
          userId,
        );
        conversations.assignAll(userConversations);
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
  }

  Future<void> _startNewConversationIfNeeded() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null && conversations.isEmpty) {
        currentConversation = await _chatRepository.createConversation(
          userId: userId,
          title: 'Shopping Assistant Chat',
        );
        conversations.add(currentConversation!);
      } else if (conversations.isNotEmpty) {
        currentConversation = conversations.first;
      }
    } catch (e) {
      print('Error starting conversation: $e');
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _addWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      final welcomeMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Hello! I\'m your shopping assistant. I can help you with:\n\n• Finding products\n• Tracking orders\n• Returns & exchanges\n• Size guides\n• General support\n\nHow can I help you today?',
        isUser: false,
        createdAt: DateTime.now(),
      );
      messages.add(welcomeMessage);
      _scrollToBottom();
    });
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Check if user is logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      Get.snackbar(
        'Login Required',
        'Please log in to use the chat feature',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    final userId = currentUser.id;

    // Add user message to UI
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );
    messages.add(userMessage);
    messageController.clear();
    _scrollToBottom();

    // Save to database
    if (currentConversation != null) {
      try {
        await _chatRepository.addMessage(
          conversationId: currentConversation!.id,
          senderType: 'user',
          messageText: text,
        );

        // Track analytics
        await _chatRepository.trackChatAction(
          conversationId: currentConversation!.id,
          userId: userId,
          actionType: 'message_sent',
          actionData: {'message_type': 'user', 'message_length': text.length},
        );
      } catch (e) {
        print('Error saving message: $e');
      }
    }

    // Check if this is a product search query
    if (_isProductSearchQuery(text)) {
      await _handleProductSearch(text);
    } else {
      // Simulate bot typing and response
      _simulateBotResponse(text);
    }
  }

  bool _isProductSearchQuery(String text) {
    final productKeywords = [
      'find',
      'search',
      'looking for',
      'show me',
      'products',
      'shirts',
      'pants',
      'shoes',
      'bags',
      'dresses',
      'jackets',
      'watches',
      'phones',
      'laptops',
      'clothes',
      'buy',
      'purchase',
      'men',
      'women',
      'kids',
      'accessories',
      'sale',
      'cheap',
      'affordable',
    ];

    final lowerText = text.toLowerCase();
    return productKeywords.any((keyword) => lowerText.contains(keyword));
  }

  Future<void> _handleProductSearch(String query) async {
    isTyping.value = true;

    try {
      // Extract search terms
      final searchQuery = _extractSearchTerms(query);

      // Search for products
      List<Product> products = [];
      String responseText = '';

      if (searchQuery.isNotEmpty) {
        products = await _searchService.searchProducts(
          query: searchQuery,
          limit: 5,
        );

        if (products.isNotEmpty) {
          responseText = 'I found ${products.length} products for you:';
        } else {
          // Try semantic search if no direct results
          products = await _searchService.semanticSearch(
            query: searchQuery,
            limit: 5,
          );

          if (products.isNotEmpty) {
            responseText = 'Here are some similar products I found:';
          } else {
            responseText =
                'I couldn\'t find products matching "$searchQuery". Let me show you some popular items instead:';
            products = await _searchService.getTrendingProducts(limit: 5);
          }
        }
      } else {
        // Show trending products for general queries
        products = await _searchService.getTrendingProducts(limit: 5);
        responseText = 'Here are some popular products you might like:';
      }

      // Add bot response with products
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responseText,
        isUser: false,
        createdAt: DateTime.now(),
        products: products,
        messageType: 'products',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      isTyping.value = false;
      messages.add(botMessage);
      _scrollToBottom();
    } catch (e) {
      print('Error handling product search: $e');
      isTyping.value = false;
      _simulateBotResponse(query);
    }
  }

  String _extractSearchTerms(String query) {
    // Remove common words and extract product-related terms
    final commonWords = [
      'find',
      'search',
      'looking',
      'for',
      'show',
      'me',
      'i',
      'want',
      'need',
      'buy',
      'purchase',
    ];
    final words = query.toLowerCase().split(' ');
    final searchTerms = words
        .where((word) => !commonWords.contains(word))
        .join(' ');
    return searchTerms.trim();
  }

  void _simulateBotResponse(String userMessage) {
    isTyping.value = true;

    // Simulate typing delay
    Future.delayed(const Duration(milliseconds: 1500), () async {
      isTyping.value = false;

      final response = _generateBotResponse(userMessage);
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        createdAt: DateTime.now(),
      );

      messages.add(botMessage);
      _scrollToBottom();

      // Save bot response to database
      if (currentConversation != null) {
        try {
          await _chatRepository.addMessage(
            conversationId: currentConversation!.id,
            senderType: 'bot',
            messageText: response,
          );

          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await _chatRepository.trackChatAction(
              conversationId: currentConversation!.id,
              userId: userId,
              actionType: 'bot_response',
              actionData: {'message_type': 'text', 'response_type': 'general'},
            );
          }
        } catch (e) {
          print('Error saving bot message: $e');
        }
      }
    });
  }

  String _generateBotResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Check for keywords
    for (final entry in botResponses.entries) {
      if (message.contains(entry.key)) {
        final responses = entry.value;
        return responses[DateTime.now().millisecond % responses.length];
      }
    }

    // Check for common greetings
    if (message.contains('hi') ||
        message.contains('hello') ||
        message.contains('hey')) {
      return botResponses['hello']![0];
    }

    // Check for thanks
    if (message.contains('thank') || message.contains('thanks')) {
      return 'You\'re welcome! Is there anything else I can help you with?';
    }

    // Check for product searches
    if (message.contains('product') ||
        message.contains('buy') ||
        message.contains('shop')) {
      return 'I can help you find products! What specific item or category are you looking for?';
    }

    // Check for order related queries
    if (message.contains('order') ||
        message.contains('delivery') ||
        message.contains('shipping')) {
      return 'For order-related queries, I can help you track your order or provide shipping information. Do you have an order number?';
    }

    // Default response
    final defaultResponses = botResponses['default']!;
    return defaultResponses[DateTime.now().millisecond %
        defaultResponses.length];
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearChat() async {
    messages.clear();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _chatRepository.clearChatHistory(userId);
        conversations.clear();
        await _startNewConversationIfNeeded();
      } catch (e) {
        print('Error clearing chat: $e');
      }
    }
    _addWelcomeMessage();
    Get.snackbar(
      'Chat Cleared',
      'Your conversation history has been cleared',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  // New methods for specific product queries
  Future<void> showSaleProducts() async {
    isTyping.value = true;

    try {
      final saleProducts = await _searchService.getSaleProducts(limit: 5);

      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Here are our current sale items with great discounts:',
        isUser: false,
        createdAt: DateTime.now(),
        products: saleProducts,
        messageType: 'products',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      isTyping.value = false;
      messages.add(botMessage);
      _scrollToBottom();
    } catch (e) {
      print('Error getting sale products: $e');
      isTyping.value = false;
    }
  }

  Future<void> showTrendingProducts() async {
    isTyping.value = true;

    try {
      final trendingProducts = await _searchService.getTrendingProducts(
        limit: 5,
      );

      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Check out these trending products that customers love:',
        isUser: false,
        createdAt: DateTime.now(),
        products: trendingProducts,
        messageType: 'products',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      isTyping.value = false;
      messages.add(botMessage);
      _scrollToBottom();
    } catch (e) {
      print('Error getting trending products: $e');
      isTyping.value = false;
    }
  }

  Future<void> showCategoryProducts(String categoryName) async {
    isTyping.value = true;

    try {
      final categoryProducts = await _searchService.getProductsByCategory(
        categoryName,
      );

      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Here are some great $categoryName products:',
        isUser: false,
        createdAt: DateTime.now(),
        products: categoryProducts,
        messageType: 'products',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      isTyping.value = false;
      messages.add(botMessage);
      _scrollToBottom();
    } catch (e) {
      print('Error getting category products: $e');
      isTyping.value = false;
    }
  }

  void _debugProducts() async {
    try {
      final allProducts = await _searchService.getAllProducts();
      print('🐛 Debug: Found ${allProducts.length} products in database');
    } catch (e) {
      print('🐛 Debug error: $e');
    }
  }

  void _debugAuth() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    print('🔐 Debug Auth Status:');
    print('   - User logged in: ${currentUser != null}');
    print('   - User ID: ${currentUser?.id}');
    print('   - User Email: ${currentUser?.email}');
    print('   - Auth Controller found: ${_authController != null}');
  }
}
