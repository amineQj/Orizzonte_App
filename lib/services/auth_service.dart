import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';
import 'api_service.dart';
import 'auth_session.dart';

class AuthService {
  AuthService({ApiService? api}) : _api = api ?? ApiService() {
    // Whenever the backend returns 401, try to rotate the refresh token once.
    ApiService.onUnauthorized = refreshToken;
  }

  final ApiService _api;

  static const _kRefresh = 'refresh_token';

  Future<AuthResponse> login(String email, String password) async {
    final resp = await _api.login(email, password);
    await _persistSession(resp);
    return resp;
  }

  Future<AuthResponse> signup(
      String email, String password, String role) async {
    final resp = await _api.signup(email, password, role);
    return resp; // No tokens yet — caller should call login() afterwards.
  }

  Future<void> _persistSession(AuthResponse resp) async {
    await AuthSession.instance.setSession(
      token: resp.accessToken.isEmpty ? null : resp.accessToken,
      role: resp.user.role,
      userId: resp.user.id.toString(),
    );
    final prefs = await SharedPreferences.getInstance();
    if (resp.refreshToken.isNotEmpty) {
      await prefs.setString(_kRefresh, resp.refreshToken);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_kRefresh);
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _api.logout(refresh);
      } catch (_) {
        // Logging out locally must succeed even if the network fails.
      }
    }
    await prefs.remove(_kRefresh);
    await AuthSession.instance.clear();
  }

  /// Returns the new access token on success, or null.
  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_kRefresh);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      // Use a short-lived client without auth headers to avoid recursion.
      final fresh = ApiService();
      final data = await fresh.refreshAccessToken(refresh);
      final access = data['access']?.toString();
      if (access == null || access.isEmpty) return false;
      final newRefresh = data['refresh']?.toString();
      final role = AuthSession.instance.role ?? 'client';
      await AuthSession.instance.setSession(
        token: access,
        role: role,
        userId: AuthSession.instance.userId,
      );
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await prefs.setString(_kRefresh, newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getMe() => _api.getMe();

  Future<void> resendVerification(String email) =>
      _api.resendVerification(email);

  Future<void> verifyEmail(String uid, String token) =>
      _api.verifyEmail(uid, token);
}
