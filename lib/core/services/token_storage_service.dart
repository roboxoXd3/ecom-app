import 'package:get_storage/get_storage.dart';

/// Persists JWT tokens and user ID for API authentication.
class TokenStorageService {
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';

  final _storage = GetStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await _storage.write(_keyAccessToken, accessToken);
    await _storage.write(_keyRefreshToken, refreshToken);
    if (userId != null) {
      await _storage.write(_keyUserId, userId);
    }
  }

  String? getAccessToken() => _storage.read<String>(_keyAccessToken);
  String? getRefreshToken() => _storage.read<String>(_keyRefreshToken);
  String? getUserId() => _storage.read<String>(_keyUserId);

  Future<void> clearTokens() async {
    await _storage.remove(_keyAccessToken);
    await _storage.remove(_keyRefreshToken);
    await _storage.remove(_keyUserId);
  }

  bool get hasTokens => getAccessToken() != null && getRefreshToken() != null;
}
