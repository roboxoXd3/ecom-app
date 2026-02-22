import 'package:get/get.dart';
import '../network/api_client.dart';

class AnalyticsService extends GetxService {
  final _api = ApiClient.instance;

  Future<void> trackSearch({
    required String query,
    required int resultCount,
    required String userId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      await _api.post('/analytics/search/', data: {
        'query': query,
        'result_count': resultCount,
        'user_id': userId,
        'filters': filters,
      });
    } catch (e) {
      print('Error tracking search analytics: $e');
    }
  }

  Future<List<String>> getPopularSearches() async {
    try {
      final response = await _api.get(
        '/analytics/search/popular/',
        queryParameters: {'limit': 5},
      );
      final data = response.data;
      if (data is List) {
        return data.map((e) => e['query'].toString()).toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).map((e) => e['query'].toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error getting popular searches: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSearchAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'timestamp',
    bool ascending = false,
  }) async {
    try {
      final params = <String, dynamic>{
        'sort_by': sortBy,
        'ascending': ascending.toString(),
      };
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) {
        final adjusted = DateTime(
          endDate.year, endDate.month, endDate.day, 23, 59, 59, 999,
        );
        params['end_date'] = adjusted.toIso8601String();
      }

      final response = await _api.get('/analytics/search/', queryParameters: params);
      return response.data is Map ? Map<String, dynamic>.from(response.data) : {};
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSearchesByDate() async {
    try {
      final response = await _api.get('/analytics/search/by-date/');
      final data = response.data;
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
      return [];
    } catch (e) {
      print('Error fetching search trends: $e');
      return [];
    }
  }

  Future<Map<String, DateTime?>> getAvailableDateRange() async {
    try {
      final response = await _api.get('/analytics/search/date-range/');
      final data = response.data;
      return {
        'earliest': data['earliest'] != null ? DateTime.parse(data['earliest']) : null,
        'latest': data['latest'] != null ? DateTime.parse(data['latest']) : null,
      };
    } catch (e) {
      print('Error getting date range: $e');
      return {'earliest': null, 'latest': null};
    }
  }
}
