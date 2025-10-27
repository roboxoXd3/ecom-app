import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/models/chat_models.dart';
import '../../data/services/ujunwa_ai_service.dart';
import '../../data/models/product_model.dart';
import '../../../core/theme/app_theme.dart';

class EnhancedChatMessageWidget extends StatelessWidget {
  final ChatbotMessage message;
  final double screenWidth;
  final UjunwaResponse? ujunwaResponse;
  final VoidCallback? onProductTap;
  final Function(String)? onSuggestionTap;

  const EnhancedChatMessageWidget({
    super.key,
    required this.message,
    required this.screenWidth,
    this.ujunwaResponse,
    this.onProductTap,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxBubbleWidth = screenWidth * 0.85;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Main message bubble
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[_buildBotAvatar(), const SizedBox(width: 12)],
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: _buildMessageBubble(context, isUser),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                _buildUserAvatar(context),
              ],
            ],
          ),

          // Enhanced content based on response type
          if (!isUser && ujunwaResponse != null) ...[
            const SizedBox(height: 12),
            _buildEnhancedContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withBlue(255)],
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
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.getOutline(context),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline,
        color: AppTheme.getTextSecondary(context),
        size: 22,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.primaryColor : AppTheme.getSurface(context),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(isUser ? 24 : 8),
          bottomRight: Radius.circular(isUser ? 8 : 24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image if present
          if (message.hasImage && message.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(message.imagePath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Message text with enhanced formatting
          if (message.text.isNotEmpty) _buildFormattedText(context, isUser),

          // Timestamp
          const SizedBox(height: 8),
          Text(
            _formatTimestamp(message.createdAt),
            style: TextStyle(
              color:
                  isUser
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.getTextSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(BuildContext context, bool isUser) {
    final text = message.text;
    final textColor = isUser ? Colors.white : AppTheme.getTextPrimary(context);

    // Enhanced text formatting for markdown-like content
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        children: _parseFormattedText(text, textColor),
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        // Bold text
        spans.add(
          TextSpan(
            text: line.substring(2, line.length - 2),
            style: TextStyle(fontWeight: FontWeight.w700, color: baseColor),
          ),
        );
      } else if (line.startsWith('• ')) {
        // Bullet points
        spans.add(
          TextSpan(
            text: line,
            style: TextStyle(
              color: baseColor.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else if (line.contains('**')) {
        // Inline bold text
        _parseInlineBold(line, baseColor, spans);
      } else {
        // Regular text
        spans.add(TextSpan(text: line));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  void _parseInlineBold(String line, Color baseColor, List<TextSpan> spans) {
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      // Add text before bold
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }

      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(fontWeight: FontWeight.w700, color: baseColor),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }
  }

  Widget _buildEnhancedContent(BuildContext context) {
    if (ujunwaResponse == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 52), // Align with message
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product cards
          if (ujunwaResponse!.products.isNotEmpty) ...[
            _buildProductSection(context),
            const SizedBox(height: 16),
          ],

          // Suggestions
          if (ujunwaResponse!.suggestions.isNotEmpty)
            _buildSuggestionsSection(context),
        ],
      ),
    );
  }

  Widget _buildProductSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 20),
            itemCount: ujunwaResponse!.products.length,
            itemBuilder: (context, index) {
              return _buildEnhancedProductCard(
                context,
                ujunwaResponse!.products[index],
                index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProductCard(
    BuildContext context,
    Product product,
    int index,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onProductTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: AppTheme.getOutline(context).withOpacity(0.1),
                  child:
                      product.images.isNotEmpty
                          ? Image.network(
                            product.images[0],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildImagePlaceholder(context),
                          )
                          : _buildImagePlaceholder(context),
                ),
              ),

              // Product details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        product.name,
                        style: TextStyle(
                          color: AppTheme.getTextPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Rating and reviews
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating}',
                            style: TextStyle(
                              color: AppTheme.getTextSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviews})',
                            style: TextStyle(
                              color: AppTheme.getTextSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Price
                      Text(
                        '₹${product.price}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      color: AppTheme.getOutline(context).withOpacity(0.1),
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: AppTheme.getTextSecondary(context),
      ),
    );
  }

  Widget _buildSuggestionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ujunwaResponse!.suggestions.map((suggestion) {
                return _buildSuggestionChip(context, suggestion);
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onSuggestionTap?.call(suggestion),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            suggestion,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
