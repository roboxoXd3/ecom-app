import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart';

class ImageSearchService {
  static const String _openAiApiUrl =
      'https://api.openai.com/v1/chat/completions';

  /// Main method to search products by image
  Future<String> analyzeImageForProductSearch(File imageFile) async {
    try {
      print('🖼️ Starting image analysis for product search...');

      // Convert image to base64
      final base64Image = await _convertImageToBase64(imageFile);

      // Analyze with OpenAI Vision
      final description = await _analyzeImageWithOpenAI(base64Image);

      print('🧠 Image analysis result: $description');
      return description;
    } catch (e) {
      print('❌ Error analyzing image: $e');
      throw Exception('Failed to analyze image: $e');
    }
  }

  /// Convert image file to base64 string
  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final base64String = base64Encode(bytes);

      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  /// Analyze image using OpenAI Vision API
  Future<String> _analyzeImageWithOpenAI(String base64Image) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found in environment variables');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini', // Most cost-effective vision model
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '''Analyze this image and describe what product the user is looking for. 
              Focus on:
              - Product type (clothing, electronics, shoes, etc.)
              - Key features (color, style, material, brand if visible)
              - Specific details that would help find similar products
              
              Provide a concise description in 1-2 sentences that would work well for product search.
              Example: "Black leather boots with zipper closure and medium heel"
              ''',
            },
            {
              'type': 'image_url',
              'image_url': {'url': base64Image},
            },
          ],
        },
      ],
      'max_tokens': 100, // Keep it concise for cost efficiency
      'temperature': 0.3, // Lower temperature for consistent results
    });

    try {
      final response = await http.post(
        Uri.parse(_openAiApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final description =
            data['choices'][0]['message']['content'].toString().trim();
        return description;
      } else {
        print('❌ OpenAI API Error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI API request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to call OpenAI API: $e');
    }
  }

  /// Validate image file
  bool isValidImageFile(File file) {
    final mimeType = lookupMimeType(file.path);
    return mimeType != null && mimeType.startsWith('image/');
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }
}
