import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daef/config/constants.dart';
import 'package:daef/models/user.dart';
import 'package:daef/services/api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;
  final _storage = const FlutterSecureStorage();

  // ── Register ─────────────────────────────────────────────────────────────────

  Future<User> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'email': email,
      'password': password,
      'username': username,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Login — stores token on success ──────────────────────────────────────────

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final token = response.data['access_token'] as String;
    await _storage.write(key: AppConstants.tokenKey, value: token);

    return getMe();
  }

  // ── Get current user ─────────────────────────────────────────────────────────

  Future<User> getMe() async {
    final response = await _client.get('/auth/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Logout — clears stored token ─────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // ── Update profile ────────────────────────────────────────────────────────────

  Future<User> updateProfile({
    String? fullName,
    String? googleApiKey,
    bool? notificationsEnabled,
    String? themeMode,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (googleApiKey != null) data['google_api_key'] = googleApiKey;
    if (notificationsEnabled != null) data['notifications_enabled'] = notificationsEnabled;
    if (themeMode != null) data['theme_mode'] = themeMode;
    final response = await _client.patch('/users/profile', data: data);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Get another user's public profile ────────────────────────────────────────

  Future<User> getUserById(String userId) async {
    final response = await _client.get('/users/profile/$userId');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Check if a token is persisted (used on app start) ────────────────────────

  Future<bool> hasToken() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
}
