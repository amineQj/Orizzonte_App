import '../models/api_models.dart';
import 'api_service.dart';
import 'auth_session.dart';

/// Authentication orchestration and the single 401 handler.
class AuthService {
  AuthService({ApiService? api}) : _api = api ?? ApiService() {
    _installUnauthorizedHandler();
  }

  AuthService._() : _api = ApiService() {
    _installUnauthorizedHandler();
  }

  /// Use this in app startup; ad-hoc instances still share one 401 handler.
  static final AuthService instance = AuthService._();

  final ApiService _api;

  static void _installUnauthorizedHandler() {
    // `??=` guarantees only the first installed handler is ever used, even if
    // a caller constructs another AuthService with a test client.
    ApiService.onUnauthorized ??= () => instance.refreshToken();
  }

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
    if (resp.refreshToken.isNotEmpty) {
      await AuthSession.instance.setRefreshToken(resp.refreshToken);
    }
  }

  /// Best-effort backend logout, then always delete both local tokens.
  Future<void> logout() async {
    final refresh = await AuthSession.instance.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _api.logout(refresh);
      } catch (_) {
        // Local sign-out must succeed even when the network fails.
      }
    }
    await AuthSession.instance.clear();
  }

  /// Returns true when a fresh access token was stored.
  Future<bool> refreshToken() async {
    final refresh = await AuthSession.instance.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      // A fresh client without auth headers avoids recursive 401 handling.
      final fresh = ApiService();
      final data = await fresh.refreshAccessToken(refresh);
      final access = data['access']?.toString();
      if (access == null || access.isEmpty) return false;
      final newRefresh = data['refresh']?.toString();
      final role = AuthSession.instance.role;
      if (role == null || role.isEmpty) return false;
      await AuthSession.instance.setSession(
        token: access,
        role: role,
        userId: AuthSession.instance.userId,
      );
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await AuthSession.instance.setRefreshToken(newRefresh);
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
