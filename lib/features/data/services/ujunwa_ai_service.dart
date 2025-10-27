import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

import 'product_search_service.dart';

/// UJUNWA Response Model
class UjunwaResponse {
  final String text;
  final List<Product> products;
  final List<String> suggestions;
  final UserIntent? intent; // Add intent back for analytics

  UjunwaResponse({
    required this.text,
    this.products = const [],
    this.suggestions = const [],
    this.intent,
  });
}

/// UJUNWA AI Service - The Brain of the AI Shopping Assistant
///
/// This service handles all AI-powered interactions including:
/// - Intent recognition and classification
/// - Context-aware response generation
/// - Product knowledge integration
/// - Conversation memory management
class UjunwaAIService {
  static const String _openAiApiUrl =
      'https://api.openai.com/v1/chat/completions';

  final SupabaseClient _supabase = Supabase.instance.client;
  final ProductSearchService _productSearchService = ProductSearchService();

  /// Generate intelligent response using OpenAI GPT with structured templates
  Future<UjunwaResponse> generateResponse({
    required String userMessage,
    required String userId,
    String? conversationId,
    List<ConversationContext>? context,
  }) async {
    try {
      print('🤖 UJUNWA: Processing message: "$userMessage"');

      // Step 1: Recognize user intent
      final intent = await _recognizeIntent(userMessage);
      print('🧠 Intent recognized: ${intent.type}');

      // Step 2: Gather relevant context and data
      final contextData = await _gatherContextData(
        intent: intent,
        userMessage: userMessage,
        userId: userId,
        conversationContext: context,
      );

      // Step 3: Generate structured response based on intent
      final structuredResponse = await _generateStructuredResponse(
        userMessage: userMessage,
        intent: intent,
        contextData: contextData,
        conversationContext: context,
      );

      // Step 4: Store conversation context for future use
      await _storeConversationContext(
        userId: userId,
        conversationId: conversationId,
        userMessage: userMessage,
        intent: intent,
        aiResponse: structuredResponse,
      );

      return structuredResponse;
    } catch (e) {
      print('❌ UJUNWA Error: $e');
      return UjunwaResponse(
        text:
            'I apologize, but I\'m having trouble processing your request right now. Please try again or ask me something else!',
        suggestions: [
          'Try asking about products',
          'Check order status',
          'Get help with returns',
          'Browse categories',
        ],
      );
    }
  }

  /// Recognize user intent using OpenAI for intelligent classification
  Future<UserIntent> _recognizeIntent(String message) async {
    try {
      // Use OpenAI for smart intent recognition
      return await _recognizeIntentWithAI(message);
    } catch (e) {
      print('❌ AI intent recognition failed: $e');
      // Fallback to simple keyword-based recognition
      return _recognizeIntentWithKeywords(message);
    }
  }

  /// AI-powered intent recognition using OpenAI
  Future<UserIntent> _recognizeIntentWithAI(String message) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content':
              '''You are an expert e-commerce intent classifier. Analyze user messages and classify their intent.

Return ONLY a JSON object with this exact format:
{
  "intent": "intent_type",
  "confidence": 0.95,
  "entities": ["extracted", "entities"]
}

Intent types (use exactly these values):
- "product_search": Looking for products, asking about availability, wanting to buy something
- "order_inquiry": Asking about orders, delivery, tracking, shipping status
- "product_info": Asking for product details, specifications, features, prices
- "comparison": Comparing products, asking which is better
- "recommendation": Asking for suggestions, recommendations, what to buy
- "support": Need help, returns, refunds, issues, problems
- "greeting": Hello, hi, general greetings
- "general": Everything else

Examples:
"dont you have any yoga pant" → {"intent": "product_search", "confidence": 0.95, "entities": ["yoga", "pant"]}
"show me running shoes" → {"intent": "product_search", "confidence": 0.98, "entities": ["running", "shoes"]}
"track my order" → {"intent": "order_inquiry", "confidence": 0.97, "entities": ["order", "track"]}''',
        },
        {'role': 'user', 'content': 'Classify this message: $message'},
      ],
      'temperature': 0.1, // Low temperature for consistent results
      'max_tokens': 100,
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiResponse =
          data['choices'][0]['message']['content'].toString().trim();

      // Parse the JSON response
      final result = jsonDecode(aiResponse);

      final intentType = _mapStringToIntentType(result['intent']);
      final confidence = (result['confidence'] as num).toDouble();

      print('🤖 AI Intent: ${result['intent']} (confidence: $confidence)');

      return UserIntent(
        type: intentType,
        confidence: confidence,
        parameters: {
          'entities': result['entities'] ?? [],
          'ai_classified': true,
        },
      );
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  /// Fallback keyword-based intent recognition (simplified)
  UserIntent _recognizeIntentWithKeywords(String message) {
    final lowerMessage = message.toLowerCase();

    // Simplified keyword matching for fallback
    if (_containsAny(lowerMessage, [
      'find',
      'search',
      'show',
      'need',
      'want',
      'buy',
      'have',
      'got',
      'any',
      'yoga',
      'pant',
      'shoes',
      'clothes',
    ])) {
      return UserIntent(type: IntentType.productSearch, confidence: 0.7);
    }

    if (_containsAny(lowerMessage, [
      'order',
      'track',
      'delivery',
      'shipping',
    ])) {
      return UserIntent(type: IntentType.orderInquiry, confidence: 0.7);
    }

    if (_containsAny(lowerMessage, ['hello', 'hi', 'hey'])) {
      return UserIntent(type: IntentType.greeting, confidence: 0.8);
    }

    if (_containsAny(lowerMessage, ['help', 'support', 'problem', 'return'])) {
      return UserIntent(type: IntentType.support, confidence: 0.7);
    }

    return UserIntent(type: IntentType.general, confidence: 0.5);
  }

  /// Map string intent to IntentType enum
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

  /// Gather relevant context data based on intent
  Future<ContextData> _gatherContextData({
    required UserIntent intent,
    required String userMessage,
    required String userId,
    List<ConversationContext>? conversationContext,
  }) async {
    final contextData = ContextData();

    try {
      // For product-related intents, search for relevant products
      if (intent.type == IntentType.productSearch ||
          intent.type == IntentType.productInfo ||
          intent.type == IntentType.recommendation) {
        // Extract search terms from user message
        String searchTerms = _extractSearchTerms(userMessage);

        // Handle context-aware queries (e.g., "yoga pant that can go with this")
        if (_isContextAwareQuery(userMessage) && conversationContext != null) {
          searchTerms = _enhanceSearchWithContext(
            searchTerms,
            conversationContext,
          );
        }

        if (searchTerms.isNotEmpty) {
          print('🔍 Enhanced search terms: "$searchTerms"');

          // Use hybrid search for best results
          contextData.products = await _productSearchService.hybridSearch(
            query: searchTerms,
            limit: 5,
          );

          // If no results, try semantic search with lower threshold
          if (contextData.products.isEmpty) {
            contextData.products = await _productSearchService.semanticSearch(
              query: searchTerms,
              limit: 5,
              threshold: 0.05,
            );
          }

          // If still no results, try broader search terms
          if (contextData.products.isEmpty) {
            final broadSearchTerms = _getBroaderSearchTerms(userMessage);
            if (broadSearchTerms != searchTerms) {
              print('🔍 Trying broader search: "$broadSearchTerms"');
              contextData.products = await _productSearchService.hybridSearch(
                query: broadSearchTerms,
                limit: 5,
              );
            }
          }
        }
      }

      // For order inquiries, we would fetch order data (placeholder for now)
      if (intent.type == IntentType.orderInquiry) {
        // TODO: Implement order fetching
        contextData.orderInfo = 'Order tracking functionality coming soon';
      }

      // Get user preferences from conversation history
      if (conversationContext != null && conversationContext.isNotEmpty) {
        contextData.userPreferences = _extractUserPreferences(
          conversationContext,
        );
      }
    } catch (e) {
      print('❌ Error gathering context data: $e');
    }

    return contextData;
  }

  /// Check if the query references previous context
  bool _isContextAwareQuery(String message) {
    final contextIndicators = [
      'this',
      'that',
      'it',
      'them',
      'go with',
      'match',
      'pair with',
      'complement',
      'coordinate',
      'wear with',
      'similar to',
      'like the',
      'same as',
    ];

    final lowerMessage = message.toLowerCase();
    return contextIndicators.any(
      (indicator) => lowerMessage.contains(indicator),
    );
  }

  /// Enhance search terms with context from previous conversation
  String _enhanceSearchWithContext(
    String searchTerms,
    List<ConversationContext> context,
  ) {
    // Look for recently mentioned products in conversation
    final recentProducts = <String>[];

    for (final ctx in context.take(3)) {
      // Check last 3 interactions
      if (ctx.productsMentioned.isNotEmpty) {
        // Add product categories or types from recent mentions
        // This is a simplified approach - in a full implementation,
        // you'd fetch actual product details and extract categories
        recentProducts.addAll(ctx.productsMentioned);
      }
    }

    // If we found recent products, we can enhance the search
    if (recentProducts.isNotEmpty) {
      print(
        '🔗 Found context from recent products: ${recentProducts.join(', ')}',
      );
      // For now, just return the original search terms
      // In a full implementation, you'd analyze the recent products
      // and add complementary search terms
    }

    return searchTerms;
  }

  /// Generate structured response based on intent and context
  Future<UjunwaResponse> _generateStructuredResponse({
    required String userMessage,
    required UserIntent intent,
    required ContextData contextData,
    List<ConversationContext>? conversationContext,
  }) async {
    switch (intent.type) {
      case IntentType.productSearch:
        if (contextData.products.isEmpty) {
          return UjunwaResponse(
            text:
                "I couldn't find any products matching \"$userMessage\" right now. 😔\n\nBut don't worry! Here are some suggestions:\n\n• Try using different keywords\n• Browse our trending products\n• Check out our sale items\n• Contact our support team for personalized help\n\nI'm here to help you find exactly what you need! 🛍️",
            suggestions: [
              'Browse all products',
              'Show trending items',
              'View sale products',
              'Help me search better',
            ],
            intent: intent,
          );
        } else {
          final count = contextData.products.length;
          final firstProduct = contextData.products.first;
          String text;
          if (count == 1) {
            text =
                "Perfect! I found exactly what you're looking for. Check out our **${firstProduct.name}** priced at ₹${firstProduct.price}.\n\n${firstProduct.description.length > 100 ? '${firstProduct.description.substring(0, 100)}...' : firstProduct.description}\n\n⭐ **Rating:** ${firstProduct.rating}/5 (${firstProduct.reviews} reviews)";
          } else {
            text =
                "Great! I found **$count products** matching your search. Here are some top picks:\n\n• **${firstProduct.name}** - ₹${firstProduct.price} (${firstProduct.rating}⭐)\n${count > 1 ? '• **${contextData.products[1].name}** - ₹${contextData.products[1].price} (${contextData.products[1].rating}⭐)' : ''}\n\nSwipe through the product cards below to explore all options! 👆";
          }
          return UjunwaResponse(
            text: text,
            products: contextData.products,
            suggestions: [
              'Show me more details',
              'Find similar products',
              'Compare these items',
              'Check availability',
            ],
            intent: intent,
          );
        }

      case IntentType.productInfo:
        if (contextData.products.isNotEmpty) {
          final product = contextData.products.first;
          return UjunwaResponse(
            text:
                "Here are the details for **${product.name}**:\n\n💰 **Price:** ₹${product.price}\n⭐ **Rating:** ${product.rating}/5 (${product.reviews} reviews)\n📦 **Stock:** ${product.inStock ? 'In Stock' : 'Out of Stock'}\n🏷️ **Brand:** ${product.brand}\n\n**Description:**\n${product.description}",
            products: [product],
            suggestions: [
              'Show me similar products',
              'Check customer reviews',
              'View size guide',
              'Add to cart',
            ],
            intent: intent,
          );
        }
        break;

      case IntentType.greeting:
        return UjunwaResponse(
          text:
              "Hello there! 👋 Welcome to **Be Smart**!\n\nI'm **UJUNWA**, your personal shopping assistant. I'm here to help you:\n\n🔍 **Find products** you're looking for\n📦 **Track your orders** and deliveries\n💡 **Get recommendations** based on your preferences\n🛠️ **Answer questions** about products and services\n\nWhat can I help you with today? 😊",
          suggestions: [
            'Show me trending products',
            'Find products on sale',
            'Browse categories',
            'Track my order',
          ],
          intent: intent,
        );

      case IntentType.orderInquiry:
        return UjunwaResponse(
          text:
              "I'd be happy to help you with your order! Could you please provide your order number or email address so I can look up your order details?",
          suggestions: [
            'Track another order',
            'Contact support',
            'View order history',
            'Return an item',
          ],
          intent: intent,
        );

      case IntentType.support:
        return UjunwaResponse(
          text:
              "I'm here to help! What specific issue are you experiencing? I can assist with:\n\n• Product questions\n• Order issues\n• Returns and refunds\n• Account problems\n• Technical support",
          suggestions: [
            'Contact live support',
            'View FAQ',
            'Return policy',
            'Shipping information',
          ],
          intent: intent,
        );

      case IntentType.general:
      default:
        // For general queries, use AI to generate a contextual response
        final aiText = await _generateAIResponse(
          userMessage: userMessage,
          intent: intent,
          contextData: contextData,
          conversationContext: conversationContext,
        );
        return UjunwaResponse(
          text: aiText.text,
          products: contextData.products,
          suggestions: aiText.suggestions,
          intent: intent,
        );
    }

    // Fallback to general response
    return UjunwaResponse(
      text:
          "I understand you're looking for information. How can I help you today?",
      suggestions: [
        'Browse products',
        'Check offers',
        'Contact support',
        'Track order',
      ],
      intent: intent,
    );
  }

  /// Generate AI response using OpenAI GPT (fallback for complex queries)
  Future<UjunwaResponse> _generateAIResponse({
    required String userMessage,
    required UserIntent intent,
    required ContextData contextData,
    List<ConversationContext>? conversationContext,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found in environment variables');
    }

    // Build the system prompt that defines UJUNWA's personality and capabilities
    final systemPrompt = _buildSystemPrompt(intent, contextData);

    // Build the user prompt with context
    final userPrompt = _buildUserPrompt(
      userMessage: userMessage,
      intent: intent,
      contextData: contextData,
      conversationContext: conversationContext,
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini', // Cost-effective and fast
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': 300,
      'temperature': 0.7, // Balanced creativity and consistency
    });

    try {
      final response = await http.post(
        Uri.parse(_openAiApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText =
            data['choices'][0]['message']['content'].toString().trim();

        // Generate suggestions based on intent
        final suggestions = _generateSuggestions(intent, contextData);

        return UjunwaResponse(
          text: aiText,
          products: contextData.products,
          suggestions: suggestions,
          intent: intent,
        );
      } else {
        print('❌ OpenAI API Error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling OpenAI API: $e');
      rethrow;
    }
  }

  /// Build system prompt that defines UJUNWA's personality
  String _buildSystemPrompt(UserIntent intent, ContextData contextData) {
    return '''
You are UJUNWA, an intelligent AI shopping assistant for Be Smart e-commerce platform. You are helpful, friendly, knowledgeable, and professional.

Your capabilities include:
- Helping customers find products
- Providing detailed product information
- Making personalized recommendations
- Assisting with orders and support
- Comparing products
- Answering questions about policies

Your personality:
- Warm and approachable
- Expert knowledge about products
- Patient and understanding
- Proactive in offering help
- Always honest about limitations

Current context:
- User intent: ${intent.type}
- Available products: ${contextData.products.length}
- Order info: ${contextData.orderInfo ?? 'None'}

Guidelines:
- Keep responses conversational and natural
- If showing products, mention their key features
- Always offer to help further
- If you don't know something, be honest and offer alternatives
- Use emojis sparingly and appropriately
''';
  }

  /// Build user prompt with context
  String _buildUserPrompt({
    required String userMessage,
    required UserIntent intent,
    required ContextData contextData,
    List<ConversationContext>? conversationContext,
  }) {
    final prompt = StringBuffer();

    prompt.writeln('User message: "$userMessage"');

    // Add product context if available
    if (contextData.products.isNotEmpty) {
      prompt.writeln('\nRelevant products found:');
      for (int i = 0; i < contextData.products.length && i < 3; i++) {
        final product = contextData.products[i];
        prompt.writeln(
          '${i + 1}. ${product.name} - ₹${product.price} (Rating: ${product.rating}/5)',
        );
        if (product.description.isNotEmpty) {
          prompt.writeln(
            '   Description: ${product.description.length > 100 ? '${product.description.substring(0, 100)}...' : product.description}',
          );
        }
      }
    } else if (intent.type == IntentType.productSearch) {
      prompt.writeln('\nNo products found for this specific search.');
      prompt.writeln(
        'Please provide a helpful response explaining this and suggest alternatives.',
      );
    }

    // Add conversation context if available
    if (conversationContext != null && conversationContext.isNotEmpty) {
      prompt.writeln('\nRecent conversation context:');
      for (final context in conversationContext.take(3)) {
        prompt.writeln('- User mentioned: ${context.userMessage}');
        if (context.extractedInfo.isNotEmpty) {
          prompt.writeln('  Preferences: ${context.extractedInfo}');
        }
      }
    }

    // Add user preferences if available
    if (contextData.userPreferences.isNotEmpty) {
      prompt.writeln('\nUser preferences: ${contextData.userPreferences}');
    }

    prompt.writeln('\nPlease provide a helpful, natural response as UJUNWA.');

    return prompt.toString();
  }

  /// Generate contextual suggestions
  List<String> _generateSuggestions(
    UserIntent intent,
    ContextData contextData,
  ) {
    switch (intent.type) {
      case IntentType.productSearch:
        if (contextData.products.isNotEmpty) {
          return [
            'Show me more details about these products',
            'Find similar products',
            'Compare these products',
            'Check if these are in stock',
          ];
        } else {
          return [
            'Browse all products',
            'Show me trending items',
            'Find products in different categories',
            'Help me refine my search',
          ];
        }

      case IntentType.productInfo:
        return [
          'Show me similar products',
          'Check customer reviews',
          'Find products in my size',
          'Add to wishlist',
        ];

      case IntentType.recommendation:
        return [
          'Tell me more about your preferences',
          'Show me products in different price ranges',
          'Find trending products',
          'Browse by category',
        ];

      case IntentType.orderInquiry:
        return [
          'Track another order',
          'View order history',
          'Contact customer support',
          'Return or exchange item',
        ];

      case IntentType.support:
        return [
          'View return policy',
          'Contact customer service',
          'Check shipping information',
          'Browse help articles',
        ];

      default:
        return [
          'Find products',
          'Track my orders',
          'Get recommendations',
          'Browse categories',
        ];
    }
  }

  /// Store conversation context for future reference
  Future<void> _storeConversationContext({
    required String userId,
    String? conversationId,
    required String userMessage,
    required UserIntent intent,
    required UjunwaResponse aiResponse,
  }) async {
    try {
      if (conversationId == null) return;

      // Extract key information from the conversation
      final extractedInfo = _extractKeyInformation(userMessage, intent);

      // Store in conversation_context table
      await _supabase.from('conversation_context').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'user_message': userMessage,
        'intent_type': intent.type.toString(),
        'intent_confidence': intent.confidence,
        'ai_response': aiResponse.text,
        'extracted_info': extractedInfo,
        'products_mentioned': aiResponse.products.map((p) => p.id).toList(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error storing conversation context: $e');
      // Don't throw error as this is not critical for user experience
    }
  }

  /// Helper methods
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String _extractSearchTerms(String message) {
    // Use AI-extracted entities if available, otherwise use improved keyword extraction

    // Priority product keywords that should always be included
    final productKeywords = [
      'shoes',
      'shoe',
      'sneakers',
      'sneaker',
      'boots',
      'sandals',
      'footwear',
      'shirt',
      'shirts',
      't-shirt',
      'tshirt',
      'pants',
      'pant',
      'jeans',
      'dress',
      'jacket',
      'coat',
      'sweater',
      'hoodie',
      'shorts',
      'skirt',
      'top',
      'blouse',
      'yoga',
      'running',
      'workout',
      'fitness',
      'gym',
      'sports',
      'athletic',
      'phone',
      'laptop',
      'tablet',
      'headphones',
      'earbuds',
      'watch',
      'smartwatch',
      'bag',
      'purse',
      'wallet',
      'belt',
      'hat',
      'cap',
      'sunglasses',
      'glasses',
      'black',
      'white',
      'blue',
      'red',
      'green',
      'yellow',
      'pink',
      'purple',
      'gray',
      'brown',
      'small',
      'medium',
      'large',
      'xl',
      'xxl',
      'xs',
      'comfortable',
      'stylish',
      'casual',
      'formal',
      'premium',
      'affordable',
      'cheap',
    ];

    // Words to remove (but keep product-specific terms)
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
      'get',
      'can',
      'you',
      'please',
      'do',
      'dont',
      'have',
      'got',
      'any',
      'some',
      'good',
      'nice',
      'great',
      'best',
      'the',
      'a',
      'an',
      'is',
      'are',
      'that',
      'this',
      'with',
      'go',
      'and',
      'or',
      'but',
      'to',
      'from',
      'in',
      'on',
      'at',
      'by',
    ];

    final words = message.toLowerCase().split(' ');

    // First, collect all product-related keywords
    final productTerms =
        words
            .where((word) => productKeywords.contains(word) && word.length > 2)
            .toList();

    // Then, add other meaningful words that aren't common words
    final otherTerms =
        words
            .where(
              (word) =>
                  !commonWords.contains(word) &&
                  !productKeywords.contains(word) &&
                  word.length > 2,
            )
            .toList();

    // Combine product terms first (higher priority) then other terms
    final allTerms = [...productTerms, ...otherTerms];

    // If we have product terms, prioritize them
    if (productTerms.isNotEmpty) {
      return productTerms.join(' ');
    }

    return allTerms.join(' ').trim();
  }

  /// Get broader search terms when specific search fails
  String _getBroaderSearchTerms(String message) {
    final lowerMessage = message.toLowerCase();

    // Map specific terms to broader categories
    if (lowerMessage.contains('running') || lowerMessage.contains('footwear')) {
      return 'shoes';
    }
    if (lowerMessage.contains('workout') ||
        lowerMessage.contains('fitness') ||
        lowerMessage.contains('gym')) {
      return 'athletic sports';
    }
    if (lowerMessage.contains('yoga')) {
      return 'yoga fitness';
    }
    if (lowerMessage.contains('shirt') || lowerMessage.contains('clothing')) {
      return 'clothes';
    }
    if (lowerMessage.contains('phone') || lowerMessage.contains('mobile')) {
      return 'electronics';
    }

    // Extract just the main product category
    final words = message.toLowerCase().split(' ');
    final productWords =
        words
            .where(
              (word) => [
                'shoes',
                'clothes',
                'electronics',
                'accessories',
                'bags',
                'watches',
              ].contains(word),
            )
            .toList();

    return productWords.isNotEmpty ? productWords.first : message;
  }

  String _extractUserPreferences(List<ConversationContext> context) {
    final preferences = <String>[];

    for (final ctx in context) {
      if (ctx.extractedInfo.isNotEmpty) {
        preferences.add(ctx.extractedInfo);
      }
    }

    return preferences.join(', ');
  }

  String _extractKeyInformation(String userMessage, UserIntent intent) {
    final lowerMessage = userMessage.toLowerCase();
    final info = <String>[];

    // Extract price preferences
    if (lowerMessage.contains('cheap') || lowerMessage.contains('affordable')) {
      info.add('prefers affordable options');
    }
    if (lowerMessage.contains('premium') ||
        lowerMessage.contains('expensive')) {
      info.add('interested in premium products');
    }

    // Extract size preferences
    if (lowerMessage.contains('large') || lowerMessage.contains('xl')) {
      info.add('prefers large sizes');
    }
    if (lowerMessage.contains('small') || lowerMessage.contains('xs')) {
      info.add('prefers small sizes');
    }

    // Extract activity preferences
    if (lowerMessage.contains('workout') || lowerMessage.contains('gym')) {
      info.add('interested in fitness products');
    }
    if (lowerMessage.contains('work') || lowerMessage.contains('office')) {
      info.add('needs professional/work items');
    }

    return info.join(', ');
  }
}

/// Data Models for UJUNWA AI Service

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

  // Helper method to parse string lists from various data structures
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];

    try {
      if (data is List) {
        return data.map((item) => item.toString()).toList();
      } else if (data is Map<String, dynamic>) {
        return data.keys.toList();
      } else if (data is String) {
        // Handle comma-separated string
        return data
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing string list: $e');
      return [];
    }
  }

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
      intentConfidence: json['intent_confidence']?.toDouble() ?? 0.0,
      aiResponse: json['ai_response'],
      extractedInfo: json['extracted_info'] ?? '',
      productsMentioned: _parseStringList(json['products_mentioned']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
