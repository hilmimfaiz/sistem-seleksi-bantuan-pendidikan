import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _rememberLoginKey = 'remember_login';
  static const String _themeModeKey = 'theme_mode';

  // Access Token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  // Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // User Data
  static Future<void> saveUserData({
    required String userId,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userRoleKey, value: role);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  // Remember Login
  static Future<void> setRememberLogin(bool remember) async {
    await _storage.write(
        key: _rememberLoginKey, value: remember.toString());
  }

  static Future<bool> getRememberLogin() async {
    final value = await _storage.read(key: _rememberLoginKey);
    return value == 'true';
  }

  // Theme Mode
  static Future<void> setThemeMode(String themeMode) async {
    await _storage.write(key: _themeModeKey, value: themeMode);
  }

  static Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeModeKey);
  }

  // Save complete auth data
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String role,
    bool rememberLogin = true,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveUserData(userId: userId, email: email, role: role);
    await setRememberLogin(rememberLogin);
  }

  // Clear all auth data (Logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if has valid session
  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    final remember = await getRememberLogin();
    return token != null && remember;
  }
}
