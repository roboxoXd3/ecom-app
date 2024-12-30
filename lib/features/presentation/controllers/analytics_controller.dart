import 'package:get/get.dart';
import '../../../core/services/analytics_service.dart';

class AnalyticsController extends GetxController {
  final AnalyticsService _analyticsService = Get.find();

  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>> analyticsData = Rx<Map<String, dynamic>>({});
  final RxList<Map<String, dynamic>> searchTrends =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    try {
      isLoading.value = true;
      analyticsData.value = await _analyticsService.getSearchAnalytics();
      searchTrends.value = await _analyticsService.getSearchesByDate();
    } catch (e) {
      print('Error loading analytics: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
