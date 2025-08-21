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
      final data = {
        'query': query,
        'result_count': resultCount,
        'user_id': userId,
        'filters': filters,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📊 Inserting search analytics: $data');

      final result = await supabase.from('search_analytics').insert(data);
      print('📊 Analytics insert result: $result');
    } catch (e) {
      print('❌ Error tracking search analytics: $e');
      print('❌ Error details: ${e.toString()}');
    }
  }

  Future<List<String>> getPopularSearches() async {
    try {
      final response = await supabase.from('search_analytics').select('query');

      Map<String, int> searchCounts = {};
      for (var search in response) {
        final query = search['query'] as String;
        searchCounts[query] = (searchCounts[query] ?? 0) + 1;
      }

      final sortedSearches =
          searchCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedSearches.take(5).map((e) => e.key).toList();
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
      // Fix end date to include the entire day
      DateTime? adjustedEndDate;
      if (endDate != null) {
        adjustedEndDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
      }

      print(
        '📊 Fetching analytics with filters: startDate=$startDate, endDate=$endDate (adjusted: $adjustedEndDate), sortBy=$sortBy',
      );

      // Get all searches with timestamps for detailed analysis
      var query = supabase
          .from('search_analytics')
          .select('query, result_count, timestamp, user_id');

      // Apply date filtering if provided
      if (startDate != null) {
        final startDateStr = startDate.toIso8601String();
        print('📊 Applying start date filter: $startDateStr');
        query = query.filter('timestamp', 'gte', startDateStr);
      }
      if (adjustedEndDate != null) {
        final endDateStr = adjustedEndDate.toIso8601String();
        print('📊 Applying end date filter: $endDateStr');
        query = query.filter('timestamp', 'lte', endDateStr);
      }

      final allSearchesResponse = await query.order(
        sortBy,
        ascending: ascending,
      );

      print('📊 Found ${allSearchesResponse.length} searches');

      // Debug: Print first few timestamps to help diagnose date issues
      if (allSearchesResponse.isNotEmpty &&
          (startDate != null || endDate != null)) {
        print('📊 Sample timestamps in results:');
        for (
          int i = 0;
          i < (allSearchesResponse.length > 3 ? 3 : allSearchesResponse.length);
          i++
        ) {
          print('📊   ${allSearchesResponse[i]['timestamp']}');
        }
      }

      // Get total count (same filters)
      var countQuery = supabase.from('search_analytics').select('id');
      if (startDate != null) {
        countQuery = countQuery.filter(
          'timestamp',
          'gte',
          startDate.toIso8601String(),
        );
      }
      if (adjustedEndDate != null) {
        countQuery = countQuery.filter(
          'timestamp',
          'lte',
          adjustedEndDate.toIso8601String(),
        );
      }

      final totalCountResponse = await countQuery.count(CountOption.exact);
      final totalCount = totalCountResponse.count;

      print('📊 Total count: $totalCount');

      // Calculate average results
      double avgResults = 0;
      if (allSearchesResponse.isNotEmpty) {
        final sum = (allSearchesResponse as List)
            .map((e) => e['result_count'] as int)
            .reduce((a, b) => a + b);
        avgResults = sum / allSearchesResponse.length;
      }

      // Get popular searches - aggregate manually
      Map<String, int> searchCounts = {};
      for (var search in allSearchesResponse) {
        final query = search['query'] as String;
        searchCounts[query] = (searchCounts[query] ?? 0) + 1;
      }

      final popularSearches =
          searchCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final popularSearchesResponse =
          popularSearches
              .take(10)
              .map((e) => {'query': e.key, 'count': e.value})
              .toList();

      // Get searches with no results
      final noResultsSearches =
          allSearchesResponse
              .where((search) => search['result_count'] == 0)
              .toList();

      Map<String, int> noResultsCounts = {};
      for (var search in noResultsSearches) {
        final query = search['query'] as String;
        noResultsCounts[query] = (noResultsCounts[query] ?? 0) + 1;
      }

      final noResultsSorted =
          noResultsCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final noResultsResponse =
          noResultsSorted
              .take(5)
              .map((e) => {'query': e.key, 'count': e.value})
              .toList();

      return {
        'total_searches': totalCount,
        'popular_searches': popularSearchesResponse,
        'no_results_searches': noResultsResponse,
        'avg_results': avgResults,
        'recent_searches':
            allSearchesResponse.take(20).toList(), // Add recent searches
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSearchesByDate() async {
    try {
      final response = await supabase
          .from('search_analytics')
          .select('timestamp');

      Map<String, int> dateCounts = {};
      for (var record in response) {
        final timestamp = DateTime.parse(record['timestamp']);
        final dateKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        dateCounts[dateKey] = (dateCounts[dateKey] ?? 0) + 1;
      }

      final sortedDates =
          dateCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      return sortedDates.map((e) => {'date': e.key, 'count': e.value}).toList();
    } catch (e) {
      print('Error fetching search trends: $e');
      return [];
    }
  }

  /// Get the date range of available search analytics data
  Future<Map<String, DateTime?>> getAvailableDateRange() async {
    try {
      final response = await supabase
          .from('search_analytics')
          .select('timestamp')
          .order('timestamp', ascending: true);

      if (response.isEmpty) {
        return {'earliest': null, 'latest': null};
      }

      final earliest = DateTime.parse(response.first['timestamp']);
      final latest = DateTime.parse(response.last['timestamp']);

      print('📊 Available data range: $earliest to $latest');

      return {'earliest': earliest, 'latest': latest};
    } catch (e) {
      print('Error getting date range: $e');
      return {'earliest': null, 'latest': null};
    }
  }
}
