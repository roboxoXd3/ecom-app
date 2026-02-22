import '../../../core/network/api_client.dart';
import '../models/support_models.dart';

class SupportRepository {
  final _api = ApiClient.instance;

  Future<List<FAQ>> getFAQs() async {
    try {
      final response = await _api.get('/content/faqs/');
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => FAQ.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching FAQs: $e');
      return [];
    }
  }

  Future<List<FAQ>> searchFAQs(String query) async {
    try {
      final response = await _api.get(
        '/content/faqs/',
        queryParameters: {'search': query},
      );
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => FAQ.fromJson(json)).toList();
    } catch (e) {
      print('Error searching FAQs: $e');
      return [];
    }
  }

  Future<List<SupportInfo>> getQuickHelp() async {
    try {
      final response = await _api.get(
        '/content/support-info/',
        queryParameters: {'type': 'quick_help'},
      );
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => SupportInfo.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching quick help: $e');
      return [];
    }
  }

  Future<List<SupportInfo>> getContactOptions() async {
    try {
      final response = await _api.get(
        '/content/support-info/',
        queryParameters: {'type': 'contact'},
      );
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => SupportInfo.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching contact options: $e');
      return [];
    }
  }
}
