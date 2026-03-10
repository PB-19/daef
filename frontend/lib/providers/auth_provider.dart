import 'package:flutter/foundation.dart';
import 'package:daef/models/api_response.dart';
import 'package:daef/models/user.dart';
import 'package:daef/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ── Called on app start — tries to restore session ────────────────────────────

  Future<void> tryRestoreSession() async {
    final hasToken = await AuthService.instance.hasToken();
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await AuthService.instance.getMe();
      _status = AuthStatus.authenticated;
    } on ApiError {
      // Token is invalid or expired
      await AuthService.instance.logout();
      _status = AuthStatus.unauthenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _user = await AuthService.instance.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    _setLoading(true);
    try {
      await AuthService.instance.register(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );
      // Auto-login after registration
      return login(email: email, password: password);
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthService.instance.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  // ── Update profile via API ────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? fullName,
    String? googleApiKey,
    bool? notificationsEnabled,
    String? themeMode,
  }) async {
    _setLoading(true);
    try {
      _user = await AuthService.instance.updateProfile(
        fullName: fullName,
        googleApiKey: googleApiKey,
        notificationsEnabled: notificationsEnabled,
        themeMode: themeMode,
      );
      _error = null;
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update local user after profile edit ──────────────────────────────────────

  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
