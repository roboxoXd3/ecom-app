import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/analytics_controller.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this package to pubspec.yaml

class AnalyticsScreen extends StatelessWidget {
  final AnalyticsController controller = Get.find();

  AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAnalytics();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAnalytics(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshAnalytics(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if filters are applied but no data found
          final hasFilters =
              controller.startDate.value != null ||
              controller.endDate.value != null ||
              controller.sortBy.value != 'timestamp';
          final totalSearches =
              controller.analyticsData.value['total_searches'] ?? 0;

          if (hasFilters && totalSearches == 0) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFiltersCard(),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Data Found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No search analytics found for the selected date range.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          Obx(() {
                            final earliest = controller.earliestDate.value;
                            final latest = controller.latestDate.value;
                            if (earliest != null && latest != null) {
                              return Text(
                                'Available data: ${_formatDate(earliest)} - ${_formatDate(latest)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => controller.clearFilters(),
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFiltersCard(),
                const SizedBox(height: 16),
                _buildOverviewCard(),
                const SizedBox(height: 16),
                _buildRecentSearchesCard(),
                const SizedBox(height: 16),
                _buildPopularSearchesCard(),
                const SizedBox(height: 16),
                _buildNoResultsCard(),
                const SizedBox(height: 16),
                _buildSearchTrendsChart(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters & Sorting',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Obx(
                      () => DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.sortBy.value,
                          isExpanded: true,
                          hint: const Text('Sort by'),
                          items: const [
                            DropdownMenuItem(
                              value: 'timestamp',
                              child: Text('Date'),
                            ),
                            DropdownMenuItem(
                              value: 'query',
                              child: Text('Search Term'),
                            ),
                            DropdownMenuItem(
                              value: 'result_count',
                              child: Text('Results Count'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              controller.setSorting(
                                value,
                                controller.ascending.value,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => IconButton(
                    icon: Icon(
                      controller.ascending.value
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    onPressed: () {
                      controller.setSorting(
                        controller.sortBy.value,
                        !controller.ascending.value,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () => _selectDateRange(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(
                              () => Text(
                                controller.startDate.value != null
                                    ? 'Date: ${_formatDate(controller.startDate.value!)} - ${controller.endDate.value != null ? _formatDate(controller.endDate.value!) : "Now"}'
                                    : 'All Dates',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => controller.clearFilters(),
                    child: const Text('Clear Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchesCard() {
    final recentSearches =
        controller.analyticsData.value['recent_searches'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (recentSearches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No recent searches found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        recentSearches
                            .take(10)
                            .map(
                              (search) => Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        search['result_count'] > 0
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                    child: Icon(
                                      search['result_count'] > 0
                                          ? Icons.check
                                          : Icons.close,
                                      color:
                                          search['result_count'] > 0
                                              ? Colors.green
                                              : Colors.red,
                                      size: 14,
                                    ),
                                  ),
                                  title: Text(
                                    search['query'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${search['result_count']} results • ${_formatDateTime(search['timestamp'])}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    _formatTime(search['timestamp']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final data = controller.analyticsData.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Total Searches',
                  data['total_searches']?.toString() ?? '0',
                ),
                _buildStatItem(
                  'Avg Results',
                  (data['avg_results'] ?? 0).toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPopularSearchesCard() {
    final popularSearches =
        controller.analyticsData.value['popular_searches'] as List? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Popular Searches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (popularSearches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No popular searches yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...popularSearches.map(
                (search) => ListTile(
                  title: Text(search['query']),
                  trailing: Text(search['count'].toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsCard() {
    final noResults =
        controller.analyticsData.value['no_results_searches'] as List? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Searches with No Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (noResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No failed searches yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...noResults.map(
                (search) => ListTile(
                  title: Text(search['query']),
                  trailing: Text(search['count'].toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTrendsChart() {
    return Obx(() {
      final searchTrends = controller.searchTrends;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search Trends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child:
                    searchTrends.isEmpty
                        ? const Center(
                          child: Text(
                            'No search trend data available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < searchTrends.length) {
                                      final dateStr =
                                          searchTrends[value.toInt()]['date']
                                              as String;
                                      final date = DateTime.parse(dateStr);
                                      return Text(
                                        '${date.month}/${date.day}',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots:
                                    searchTrends
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => FlSpot(
                                            entry.key.toDouble(),
                                            (entry.value['count'] as int)
                                                .toDouble(),
                                          ),
                                        )
                                        .toList(),
                                isCurved: true,
                                color: Theme.of(Get.context!).primaryColor,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Utility methods for date formatting and selection
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateRange() async {
    // Get available date range
    final earliestDate = controller.earliestDate.value;
    final latestDate = controller.latestDate.value;

    // Show info about available data if no data exists
    if (earliestDate == null || latestDate == null) {
      Get.snackbar(
        'No Data Available',
        'No search analytics data found. Try searching for some products first.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: earliestDate,
      lastDate: latestDate,
      initialDateRange:
          controller.startDate.value != null && controller.endDate.value != null
              ? DateTimeRange(
                start: controller.startDate.value!,
                end: controller.endDate.value!,
              )
              : DateTimeRange(start: earliestDate, end: latestDate),
      helpText: 'Select Date Range for Analytics',
      confirmText: 'Apply Filter',
      cancelText: 'Cancel',
      fieldStartHintText: 'Start Date',
      fieldEndHintText: 'End Date',
      errorFormatText: 'Invalid date format',
      errorInvalidText: 'Date out of range',
      errorInvalidRangeText: 'Invalid date range',
      builder: (context, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Available data: ${_formatDate(earliestDate)} - ${_formatDate(latestDate)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: child!),
          ],
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }
}
