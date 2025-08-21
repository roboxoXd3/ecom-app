import 'package:get/get.dart';
import '../../../core/services/analytics_service.dart';

class AnalyticsController extends GetxController {
  final AnalyticsService _analyticsService = Get.find();

  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>> analyticsData = Rx<Map<String, dynamic>>({});
  final RxList<Map<String, dynamic>> searchTrends =
      <Map<String, dynamic>>[].obs;

  // Filter options
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString sortBy = 'timestamp'.obs;
  final RxBool ascending = false.obs;

  // Available date range for data
  final Rx<DateTime?> earliestDate = Rx<DateTime?>(null);
  final Rx<DateTime?> latestDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
    _loadAvailableDateRange();
  }

  Future<void> _loadAvailableDateRange() async {
    try {
      final dateRange = await _analyticsService.getAvailableDateRange();
      earliestDate.value = dateRange['earliest'];
      latestDate.value = dateRange['latest'];
    } catch (e) {
      print('Error loading date range: $e');
    }
  }

  Future<void> loadAnalytics() async {
    try {
      isLoading.value = true;
      analyticsData.value = await _analyticsService.getSearchAnalytics(
        startDate: startDate.value,
        endDate: endDate.value,
        sortBy: sortBy.value,
        ascending: ascending.value,
      );
      searchTrends.value = await _analyticsService.getSearchesByDate();
    } catch (e) {
      print('Error loading analytics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAnalytics() async {
    await _loadAvailableDateRange();
    await loadAnalytics();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    loadAnalytics();
  }

  void setSorting(String newSortBy, bool newAscending) {
    sortBy.value = newSortBy;
    ascending.value = newAscending;
    loadAnalytics();
  }

  void clearFilters() {
    startDate.value = null;
    endDate.value = null;
    sortBy.value = 'timestamp';
    ascending.value = false;
    loadAnalytics();
  }
}
