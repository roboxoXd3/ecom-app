import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/chatbot_controller.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../data/models/order_model.dart';

import 'package:cached_network_image/cached_network_image.dart';

class ChatbotScreen extends StatelessWidget {
  final ChatbotController chatController = Get.put(ChatbotController());

  ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Quick Actions - Responsive
          _buildQuickActionsSection(screenWidth, context),

          // Chat Messages - Expanded with proper constraints
          Expanded(
            child: _buildChatSection(screenWidth, screenHeight, context),
          ),

          // Typing Indicator - Fixed positioning
          _buildTypingIndicatorSection(context),

          // Input Field - Responsive with proper constraints
          _buildInputSection(screenWidth, context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.getSurface(context),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppTheme.getTextPrimary(context),
        ),
        onPressed: () => Get.back(),
        tooltip: 'Back',
      ),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withBlue(255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Shopping Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                    height: 1.2,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: AppTheme.getTextPrimary(context)),
          onPressed: () => _showOptionsMenu(context),
          tooltip: 'More options',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickActionsSection(double screenWidth, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.getOutline(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.getTextPrimary(context),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          // Responsive wrap with proper spacing
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip(
                'Track Order',
                Icons.local_shipping_outlined,
                context,
              ),
              _buildQuickActionChip(
                'Size Guide',
                Icons.straighten_outlined,
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (label == 'Track Order') {
            chatController.showTrackOrders();
          } else if (label == 'Size Guide') {
            chatController.showSizeGuide();
          } else {
            chatController.sendMessage(label);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.getOutline(context), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.getTextSecondary(context)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextSecondary(context),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection(
    double screenWidth,
    double screenHeight,
    BuildContext context,
  ) {
    return Obx(() {
      if (chatController.isLoading.value && chatController.messages.isEmpty) {
        return _buildLoadingState(context);
      }

      if (chatController.messages.isEmpty) {
        return _buildWelcomeMessage(screenWidth, context);
      }

      return Column(
        children: [
          // Top loading indicator for older messages
          if (chatController.isLoadingMoreMessages.value)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading older messages...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // No more messages indicator
          if (!chatController.hasMoreMessages.value &&
              chatController.messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No more messages',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.getTextSecondary(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Messages list
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: ListView.builder(
                controller: chatController.scrollController,
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = chatController.messages[index];
                  return _buildMessageBubble(message, screenWidth, context);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading chat history...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(double screenWidth, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hi! I\'m your shopping assistant',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextPrimary(context),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'I can help you find products, track orders,\nand answer any questions you have!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Responsive suggestion buttons
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth - 40),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionButton('Find products'),
                  _buildSuggestionButton('Check order status'),
                  _buildSuggestionButton('Size guide'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionButton(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (text == 'Size guide') {
            chatController.showSizeGuide();
          } else {
            chatController.sendMessage(text);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    double screenWidth,
    BuildContext context,
  ) {
    final isUser = message.isUser;
    final maxBubbleWidth = screenWidth * 0.75; // 75% of screen width max

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withBlue(255),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isUser
                              ? AppTheme.primaryColor
                              : AppTheme.getSurface(context),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NEW: Display image if present
                        if (message.hasImage && message.imagePath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(message.imagePath!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Message text (only show if not empty)
                        if (message.text.isNotEmpty)
                          _buildFormattedText(message.text, isUser, context),
                        const SizedBox(height: 6),
                        Text(
                          message.timestamp,
                          style: TextStyle(
                            color:
                                isUser
                                    ? Colors.white.withOpacity(0.8)
                                    : AppTheme.getTextSecondary(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.getOutline(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: AppTheme.getTextSecondary(context),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),

          // Product cards with proper constraints
          if (message.products != null && message.products!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 240, // Fixed height to prevent overflow
              margin: EdgeInsets.only(left: isUser ? 0 : 48),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 20),
                itemCount: message.products!.length,
                itemBuilder: (context, index) {
                  final product = message.products![index];
                  // Debug: Log product info
                  print(
                    '🛍️ Displaying product card: ${product.name} (ID: ${product.id})',
                  );
                  return _buildProductCard(product, screenWidth, context);
                },
              ),
            ),
          ] else if (message.messageType == 'products') ...[
            // Debug: Show if message type is products but no products found
            Container(
              margin: EdgeInsets.only(left: isUser ? 0 : 48),
              padding: const EdgeInsets.all(8),
              child: Text(
                '⚠️ Products should be displayed here but products list is empty',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],

          // Order cards for tracking
          if (message.orders != null && message.orders!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              margin: EdgeInsets.only(left: isUser ? 0 : 48),
              child: Column(
                children:
                    message.orders!.map((order) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildOrderCard(order, screenWidth, context),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductImageForChat(product) {
    String imageUrl = '';

    // Get the best available image URL
    if (product.primaryImage != null && product.primaryImage.isNotEmpty) {
      imageUrl = product.primaryImage;
    } else if (product.imageList != null && product.imageList.isNotEmpty) {
      imageUrl = product.imageList.first;
    }

    // If no valid image URL, show placeholder
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.grey[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 4),
                Text(
                  'No Image',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildProductCard(product, double screenWidth, BuildContext context) {
    final cardWidth = screenWidth * 0.4; // 40% of screen width

    return Container(
      width: cardWidth.clamp(140.0, 180.0), // Min 140, Max 180
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            print(
              '🖱️ Product card tapped: ${product.name} (ID: ${product.id})',
            );
            Get.toNamed('/product-details', arguments: product.id);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          highlightColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.getOutline(context), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image - Fixed height to prevent overflow
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildProductImageForChat(product),
                  ),
                ),

                // Product Info - Fixed height container to prevent overflow
                Container(
                  height: 100, // Fixed height
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name - Limited to 2 lines
                      Expanded(
                        flex: 2,
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.getTextPrimary(context),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Price and Rating Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Obx(
                              () => Text(
                                CurrencyUtils.formatAmount(
                                  product.price,
                                  decimalPlaces: 0,
                                ),
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    Order order,
    double screenWidth,
    BuildContext context,
  ) {
    return Material(
      color: AppTheme.getSurface(context),
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => Get.toNamed('/order-details', arguments: order.id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getOutline(context), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header with ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Placed on ${_formatDate(order.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse('0xFF${order.status.colorHex.substring(1)}'),
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(
                          int.parse(
                            '0xFF${order.status.colorHex.substring(1)}',
                          ),
                        ).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(
                                '0xFF${order.status.colorHex.substring(1)}',
                              ),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(
                              int.parse(
                                '0xFF${order.status.colorHex.substring(1)}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Order details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.status.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getTextSecondary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(
                        () => Text(
                          CurrencyUtils.formatAmount(
                            order.total,
                            decimalPlaces: 0,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action button
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        () =>
                            Get.toNamed('/order-details', arguments: order.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        'View Details & Track',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildTypingIndicatorSection(BuildContext context) {
    return Obx(() {
      if (!chatController.isTyping.value) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          border: Border(
            top: BorderSide(color: AppTheme.getOutline(context), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withBlue(255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 4),
                  _buildTypingDot(1),
                  const SizedBox(width: 4),
                  _buildTypingDot(2),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.getTextSecondary(context),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(double screenWidth, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 120,
                ), // Prevent overflow
                child: TextField(
                  controller: chatController.messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: AppTheme.getHintText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppTheme.getOutline(context),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppTheme.getOutline(context),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.camera_alt_outlined, // Changed icon to camera
                        color: AppTheme.getTextSecondary(context),
                        size: 20,
                      ),
                      onPressed: () async {
                        // NEW: Handle image search
                        await chatController.handleImageSearch();
                      },
                      tooltip: 'Search by image',
                    ),
                    filled: true,
                    fillColor: AppTheme.getBackground(context),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.getTextPrimary(context),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      chatController.sendMessage(text.trim());
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withBlue(255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final text = chatController.messageController.text.trim();
                    if (text.isNotEmpty) {
                      chatController.sendMessage(text);
                    }
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build formatted text with markdown support for proper UTF-8/emoji handling
  Widget _buildFormattedText(String text, bool isUser, BuildContext context) {
    final textColor = isUser ? Colors.white : AppTheme.getTextPrimary(context);
    final linkColor = isUser ? Colors.white70 : AppTheme.primaryColor;

    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
        strong: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
        listBullet: TextStyle(color: textColor),
        listIndent: 24.0,
        h1: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        a: TextStyle(color: linkColor, decoration: TextDecoration.underline),
        code: TextStyle(
          backgroundColor: textColor.withOpacity(0.1),
          color: textColor,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: textColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        blockquote: TextStyle(
          color: textColor.withOpacity(0.8),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: textColor.withOpacity(0.3), width: 4),
          ),
        ),
      ),
      shrinkWrap: true,
      selectable: true, // Allow text selection for better UX
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: AppTheme.getSurface(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.getOutline(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildOptionTile(
                  context: context,
                  icon: Icons.delete_outline,
                  title: 'Clear Chat',
                  onTap: () {
                    Get.back();
                    chatController.clearChat();
                  },
                ),
                _buildOptionTile(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help & FAQ',
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Coming Soon',
                      'Help & FAQ section will be available soon!',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
                _buildOptionTile(
                  context: context,
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Coming Soon',
                      'Feedback feature will be available soon!',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppTheme.getTextSecondary(context)),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
