import 'package:get_storage/get_storage.dart';

/// Lightweight auth helper.
/// Stores and reads session data from local GetStorage — no Supabase dependency.
/// Login/register/logout go through Django API (see AuthController).
class AuthService {
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';
  static const _userMetaKey = 'user_metadata';

  static final GetStorage _box = GetStorage();

  /// Save session data after login
  static Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required String userId,
    required String email,
    String? fullName,
    Map<String, dynamic>? userMetadata,
  }) async {
    await _box.write(_tokenKey, accessToken);
    if (refreshToken != null) await _box.write(_refreshTokenKey, refreshToken);
    await _box.write(_userIdKey, userId);
    await _box.write(_userEmailKey, email);
    if (fullName != null) await _box.write(_userNameKey, fullName);
    if (userMetadata != null) await _box.write(_userMetaKey, userMetadata);
  }

  /// Clear all session data on logout
  static Future<void> clearSession() async {
    await _box.remove(_tokenKey);
    await _box.remove(_refreshTokenKey);
    await _box.remove(_userIdKey);
    await _box.remove(_userEmailKey);
    await _box.remove(_userNameKey);
    await _box.remove(_userMetaKey);
  }

  /// Get the current access token
  static String? getAccessToken() {
    return _box.read<String>(_tokenKey);
  }

  /// Get the refresh token
  static String? getRefreshToken() {
    return _box.read<String>(_refreshTokenKey);
  }

  /// Update the access token (after a refresh)
  static Future<void> updateAccessToken(String token) async {
    await _box.write(_tokenKey, token);
  }

  /// Update the refresh token (after a refresh rotation)
  static Future<void> updateRefreshToken(String token) async {
    await _box.write(_refreshTokenKey, token);
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    final token = _box.read<String>(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get the current user ID or throw if not authenticated
  static String getCurrentUserId() {
    final userId = _box.read<String>(_userIdKey);
    if (userId == null || userId.isEmpty) {
      throw Exception('User not authenticated. Please log in to continue.');
    }
    return userId;
  }

  /// Get current user email (can be null)
  static String? getUserEmail() {
    return _box.read<String>(_userEmailKey);
  }

  /// Get current user display name
  static String getUserName() {
    return _box.read<String>(_userNameKey) ??
        _box.read<String>(_userEmailKey)?.split('@')[0] ??
        'User';
  }

  /// Get user metadata map
  static Map<String, dynamic>? getUserMetadata() {
    final data = _box.read(_userMetaKey);
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
