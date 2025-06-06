import 'package:get/get.dart';
import '../../data/models/support_models.dart';
import '../../data/repositories/support_repository.dart';

class SupportController extends GetxController {
  final SupportRepository _repository = SupportRepository();
  final RxList<FAQ> faqs = <FAQ>[].obs;
  final RxList<SupportInfo> quickHelp = <SupportInfo>[].obs;
  final RxList<SupportInfo> contactOptions = <SupportInfo>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      await Future.wait([fetchFAQs(), fetchQuickHelp(), fetchContactOptions()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFAQs() async {
    try {
      final results = await _repository.getFAQs();
      faqs.assignAll(results);
    } catch (e) {
      print('Error fetching FAQs: $e');
    }
  }

  Future<void> searchFAQs(String query) async {
    try {
      isLoading.value = true;
      searchQuery.value = query;
      if (query.isEmpty) {
        await fetchFAQs();
      } else {
        final results = await _repository.searchFAQs(query);
        faqs.assignAll(results);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchQuickHelp() async {
    try {
      final results = await _repository.getQuickHelp();
      quickHelp.assignAll(results);
    } catch (e) {
      print('Error fetching quick help: $e');
    }
  }

  Future<void> fetchContactOptions() async {
    try {
      final results = await _repository.getContactOptions();
      contactOptions.assignAll(results);
    } catch (e) {
      print('Error fetching contact options: $e');
    }
  }

  void handleSupportAction(SupportInfo info) {
    switch (info.actionType) {
      case 'url':
        // TODO: Implement URL launching
        break;
      case 'email':
        // TODO: Implement email launching
        break;
      case 'phone':
        // TODO: Implement phone calling
        break;
      default:
        print('Unknown action type: ${info.actionType}');
    }
  }
}
