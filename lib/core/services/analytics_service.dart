import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService extends GetxService {
  final supabase = Supabase.instance.client;

  Future<void> trackSearch({
    required String query,
    required int resultCount,
    required String userId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      await supabase.from('search_analytics').insert({
        'query': query,
        'result_count': resultCount,
        'user_id': userId,
        'filters': filters,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error tracking search analytics: $e');
    }
  }

  Future<List<String>> getPopularSearches() async {
    try {
      final response = await supabase
          .from('search_analytics')
          .select('query, count')
          .order('count', ascending: false)
          .limit(5);

      return (response as List).map((e) => e['query'] as String).toList();
    } catch (e) {
      print('Error getting popular searches: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSearchAnalytics() async {
    try {
      // Get total searches count
      final totalCount = await supabase.rpc('get_total_searches');

      // Get average results using rpc
      final avgResults = await supabase.rpc('get_average_results');

      // Get popular searches
      final popularSearches = await supabase.rpc(
        'get_popular_searches',
        params: {'limit_count': 10},
      );

      // Get searches with no results
      final noResults = await supabase.rpc(
        'get_no_results_searches',
        params: {'limit_count': 5},
      );

      return {
        'total_searches': totalCount,
        'popular_searches': popularSearches,
        'no_results_searches': noResults,
        'avg_results': avgResults ?? 0,
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSearchesByDate() async {
    try {
      final response = await supabase.rpc('get_searches_by_date');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching search trends: $e');
      return [];
    }
  }
}
