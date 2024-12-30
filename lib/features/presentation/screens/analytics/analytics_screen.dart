import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/analytics_controller.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this package to pubspec.yaml

class AnalyticsScreen extends StatelessWidget {
  final AnalyticsController controller = Get.find();

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
            onPressed: () => controller.loadAnalytics(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadAnalytics(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(),
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
              child: LineChart(
                // Implement chart using fl_chart package
                // This is just a basic example
                LineChartData(
                  // Configure chart data here
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
