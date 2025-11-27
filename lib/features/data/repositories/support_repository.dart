import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_models.dart';

class SupportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FAQ>> getFAQs() async {
    final response = await _supabase.from('faqs').select().order('order_index');

    return (response as List).map((json) => FAQ.fromJson(json)).toList();
  }

  Future<List<FAQ>> searchFAQs(String query) async {
    // Search both question and answer fields using case-insensitive pattern matching
    final response = await _supabase
        .from('faqs')
        .select()
        .or('question.ilike.%$query%,answer.ilike.%$query%')
        .order('order_index');

    return (response as List).map((json) => FAQ.fromJson(json)).toList();
  }

  Future<List<SupportInfo>> getQuickHelp() async {
    final response = await _supabase
        .from('support_info')
        .select()
        .eq('type', 'quick_help')
        .order('order_index');

    return (response as List)
        .map((json) => SupportInfo.fromJson(json))
        .toList();
  }

  Future<List<SupportInfo>> getContactOptions() async {
    final response = await _supabase
        .from('support_info')
        .select()
        .eq('type', 'contact')
        .order('order_index');

    return (response as List)
        .map((json) => SupportInfo.fromJson(json))
        .toList();
  }
}
