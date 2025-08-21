import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if user is authenticated and return user ID
  /// Throws exception if user is not authenticated
  static String getCurrentUserId() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || currentUser.id.isEmpty) {
      throw Exception('User not authenticated. Please log in to continue.');
    }
    return currentUser.id;
  }

  /// Check if user is authenticated (returns boolean)
  static bool isAuthenticated() {
    final currentUser = _supabase.auth.currentUser;
    return currentUser != null && currentUser.id.isNotEmpty;
  }

  /// Get current user (can be null)
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Sign out user
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
