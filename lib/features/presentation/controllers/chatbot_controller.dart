import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/product_search_service.dart';
import '../../data/services/ujunwa_ai_service.dart';
import '../../data/services/conversation_context_service.dart';
import '../../data/services/size_guide_service.dart';

import '../../data/models/product_model.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<Product>? products; // Add products for rich responses
  final List<Order>? orders; // Add orders for order tracking responses
  final String? messageType; // 'text', 'products', 'orders', 'recommendations'
  // final UjunwaResponse? ujunwaResponse; // TODO: Add structured response data

  // NEW: Image support
  final String? imagePath; // Local image path
  final String? imageUrl; // Remote image URL
  final bool hasImage; // Quick check for image presence

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.products,
    this.orders,
    this.messageType = 'text',
    // this.ujunwaResponse, // TODO: Include structured response
    // NEW: Image parameters
    this.imagePath,
    this.imageUrl,
    this.hasImage = false,
  });

  // Factory for image messages
  factory ChatMessage.withImage({
    required String id,
    required String text,
    required bool isUser,
    required DateTime createdAt,
    String? imagePath,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      createdAt: createdAt,
      imagePath: imagePath,
      imageUrl: imageUrl,
      hasImage: imagePath != null || imageUrl != null,
    );
  }

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

  // NEW: UJUNWA AI Services
  final UjunwaAIService _ujunwaService = UjunwaAIService();
  final ConversationContextService _contextService =
      ConversationContextService();
  final SizeGuideService _sizeGuideService = SizeGuideService();

  // NEW: Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  // Enhanced features
  final ChatRepository _chatRepository = ChatRepository();
  final OrderRepository _orderRepository = OrderRepository();

  // Current conversation for persistence
  ChatConversation? currentConversation;
  final RxList<ChatConversation> conversations = <ChatConversation>[].obs;

  // Sample bot responses
  final Map<String, List<String>> botResponses = {
    'hello': [
      'Hello! Welcome to Be Smart! How can I assist you today?',
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
      'I can help you with detailed size guides! Let me get you comprehensive sizing information.',
      'Size guides are important for the perfect fit. I\'ll show you detailed measurement guides and tips.',
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
            'Hello! I\'m UJUNWA, your intelligent shopping assistant! 🛍️\n\nI can help you with:\n• Finding the perfect products\n• Smart recommendations\n• Order tracking & support\n• Product comparisons\n• Size guides & details\n• And much more!\n\nWhat can I help you discover today?',
        isUser: false,
        createdAt: DateTime.now(),
      );
      messages.add(welcomeMessage);
      _scrollToBottom();
    });
  }

  /// NEW: Handle UJUNWA AI responses
  Future<void> _handleUjunwaResponse(String userMessage) async {
    isTyping.value = true;

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final userId = currentUser.id;
      final lowerMessage = userMessage.toLowerCase();

      // Check for size guide requests first
      if (_isSizeGuideRequest(lowerMessage)) {
        isTyping.value = false;
        await showSizeGuide(query: userMessage);
        return;
      }

      // Get conversation context
      List<ConversationContext>? context;
      if (currentConversation != null) {
        context = await _contextService.getConversationContext(
          conversationId: currentConversation!.id,
          limit: 5, // Last 5 interactions for context
        );
      }

      // Generate UJUNWA response
      final ujunwaResponse = await _ujunwaService.generateResponse(
        userMessage: userMessage,
        userId: userId,
        conversationId: currentConversation?.id,
        context: context,
      );

      // Create bot message
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: ujunwaResponse.text,
        isUser: false,
        createdAt: DateTime.now(),
        products: ujunwaResponse.products,
        messageType: ujunwaResponse.products.isNotEmpty ? 'products' : 'text',
        // ujunwaResponse: ujunwaResponse, // TODO: Add structured response support
      );

      // Add typing delay for natural feel
      await Future.delayed(const Duration(milliseconds: 1500));
      isTyping.value = false;
      messages.add(botMessage);
      _scrollToBottom();

      // Save bot response to database
      if (currentConversation != null) {
        try {
          await _chatRepository.addMessage(
            conversationId: currentConversation!.id,
            senderType: 'bot',
            messageText: ujunwaResponse.text,
            metadata: {
              'intent_type': ujunwaResponse.intent?.type.toString(),
              'intent_confidence': ujunwaResponse.intent?.confidence,
              'products_count': ujunwaResponse.products.length,
              'suggestions': ujunwaResponse.suggestions,
            },
          );

          // Track analytics
          await _chatRepository.trackChatAction(
            conversationId: currentConversation!.id,
            userId: userId,
            actionType: 'ujunwa_response',
            actionData: {
              'intent_type': ujunwaResponse.intent?.type.toString(),
              'intent_confidence': ujunwaResponse.intent?.confidence,
              'response_length': ujunwaResponse.text.length,
              'products_shown': ujunwaResponse.products.length,
            },
          );
        } catch (e) {
          print('Error saving UJUNWA response: $e');
        }
      }

      // Show suggestions if available
      if (ujunwaResponse.suggestions.isNotEmpty) {
        _showSuggestions(ujunwaResponse.suggestions);
      }
    } catch (e) {
      print('❌ Error in UJUNWA response: $e');
      isTyping.value = false;

      // Fallback to simple response
      final fallbackMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'I apologize, but I\'m having trouble processing your request right now. Please try again or ask me something else!',
        isUser: false,
        createdAt: DateTime.now(),
      );

      messages.add(fallbackMessage);
      _scrollToBottom();
    }
  }

  /// Check if the message is a size guide request
  bool _isSizeGuideRequest(String message) {
    final sizeGuideKeywords = [
      'size guide',
      'size chart',
      'sizing',
      'measurements',
      'how to measure',
      'what size',
      'size help',
      'fit guide',
      'size recommendation',
      'measure for',
    ];

    return sizeGuideKeywords.any((keyword) => message.contains(keyword));
  }

  /// Show suggestions as quick action buttons
  void _showSuggestions(List<String> suggestions) {
    // For now, we'll just print them. In the future, we can show them as quick action buttons
    print('💡 UJUNWA Suggestions: ${suggestions.join(', ')}');
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

    // Use UJUNWA AI for intelligent responses
    await _handleUjunwaResponse(text);
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

  /// Show user's undelivered orders for tracking
  Future<void> showTrackOrders() async {
    isTyping.value = true;

    try {
      // Get user's orders
      final allOrders = await _orderRepository.getUserOrders();

      // Filter for undelivered orders (pending, processing, shipped)
      final undeliveredOrders =
          allOrders.where((order) {
            return order.status == OrderStatus.pending ||
                order.status == OrderStatus.processing ||
                order.status == OrderStatus.shipped;
          }).toList();

      String responseText;
      if (undeliveredOrders.isEmpty) {
        responseText =
            'You don\'t have any orders currently being processed or shipped. 📦\n\n'
            'All your orders have been delivered or completed! 🎉\n\n'
            'Would you like to:\n'
            '• Browse new products\n'
            '• Check your order history\n'
            '• Contact support for help';
      } else {
        final count = undeliveredOrders.length;
        responseText =
            'Here ${count == 1 ? 'is' : 'are'} your $count active order${count == 1 ? '' : 's'} to track: 📦\n\n'
            'Tap on any order card below to see detailed tracking information and status updates.';
      }

      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responseText,
        isUser: false,
        createdAt: DateTime.now(),
        orders: undeliveredOrders.isNotEmpty ? undeliveredOrders : null,
        messageType: undeliveredOrders.isNotEmpty ? 'orders' : 'text',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      isTyping.value = false;
      messages.add(botMessage);
      _scrollToBottom();
    } catch (e) {
      print('Error getting user orders: $e');

      // Show error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'I\'m having trouble accessing your order information right now. 😔\n\n'
            'This could be because:\n'
            '• You\'re not logged in\n'
            '• There\'s a connection issue\n'
            '• The service is temporarily unavailable\n\n'
            'Please try again in a moment or contact support if the issue persists.',
        isUser: false,
        createdAt: DateTime.now(),
        messageType: 'text',
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      isTyping.value = false;
      messages.add(errorMessage);
      _scrollToBottom();
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

  /// Show comprehensive size guide information
  Future<void> showSizeGuide({
    String? categoryId,
    String? productId,
    String? query,
  }) async {
    isTyping.value = true;

    try {
      // Get comprehensive size guide information
      final sizeGuideResponse = await _sizeGuideService.getSizeGuideInfo(
        categoryId: categoryId,
        productId: productId,
        query: query,
      );

      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: sizeGuideResponse.toFormattedString(),
        isUser: false,
        createdAt: DateTime.now(),
        messageType: 'text',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      isTyping.value = false;
      messages.add(botMessage);
      _scrollToBottom();

      // If there's a specific size chart, offer to show it
      if (sizeGuideResponse.hasSpecificChart &&
          sizeGuideResponse.sizeChart != null) {
        _showSizeChartOption(sizeGuideResponse.sizeChart!);
      }
    } catch (e) {
      print('Error getting size guide: $e');

      // Fallback message
      final fallbackMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'I\'m here to help with sizing! 📏\n\n'
            'I can provide:\n'
            '• Measurement guides for different categories\n'
            '• Size recommendations\n'
            '• Tips for finding the right fit\n\n'
            'Try asking me about specific products like "size guide for shirts" '
            'or "how to measure for dresses"!',
        isUser: false,
        createdAt: DateTime.now(),
        messageType: 'text',
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      isTyping.value = false;
      messages.add(fallbackMessage);
      _scrollToBottom();
    }
  }

  /// Show size chart option as a follow-up message
  void _showSizeChartOption(dynamic sizeChart) {
    Future.delayed(const Duration(milliseconds: 2000), () {
      final chartMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            '📊 Would you like to see the detailed size chart? '
            'I can show you the exact measurements for each size.',
        isUser: false,
        createdAt: DateTime.now(),
        messageType: 'text',
      );

      messages.add(chartMessage);
      _scrollToBottom();
    });
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
    print('   - Auth Controller found: true');
  }

  /// NEW: Handle image selection and search
  Future<void> handleImageSearch() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Create user message with image
      final userMessage = ChatMessage.withImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Find products similar to this image',
        isUser: true,
        createdAt: DateTime.now(),
        imagePath: pickedFile.path,
      );

      messages.add(userMessage);
      _scrollToBottom();

      // Show typing indicator
      isTyping.value = true;

      // Process image search
      await _processImageSearch(File(pickedFile.path));
    } catch (e) {
      print('❌ Error in image search: $e');
      Get.snackbar(
        'Image Search Error',
        'Failed to process image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isTyping.value = false;
    }
  }

  /// NEW: Process image search and show results
  Future<void> _processImageSearch(File imageFile) async {
    try {
      // Search products using image
      final products = await _searchService.searchByImage(
        imageFile: imageFile,
        limit: 5,
      );

      // Create bot response
      String responseText;
      List<Product> productsToShow;

      if (products.isNotEmpty) {
        responseText =
            'I found ${products.length} products similar to your image:';
        productsToShow = products;
      } else {
        responseText =
            'I couldn\'t find products matching your image. Here are some popular items instead:';
        // Fallback to trending products
        productsToShow = await _searchService.getTrendingProducts(limit: 5);
      }

      // Add bot response with products (following the existing pattern)
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responseText,
        isUser: false,
        createdAt: DateTime.now(),
        products: productsToShow,
        messageType: 'products',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      messages.add(botMessage);
      _scrollToBottom();
    } catch (e) {
      print('❌ Error processing image search: $e');

      // Add simple error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Sorry, I had trouble analyzing your image. Please try again or describe what you\'re looking for.',
        isUser: false,
        createdAt: DateTime.now(),
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      messages.add(errorMessage);
      _scrollToBottom();
    }
  }

  /// NEW: Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog() async {
    return await Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }
}
