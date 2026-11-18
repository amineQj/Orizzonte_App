import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal auth/session holder for demo + backend-ready JWT storage.
///
/// TODO: Replace fake demo session assignment in [AuthFlow] with a real
/// POST /api/token/ (or equivalent) call when backend auth is connected.
class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _kToken = 'auth_token';
  static const _kRole = 'auth_role';
  static const _kUserId = 'auth_user_id';

  String? _token;
  String? _role;
  String? _userId;
  bool _loaded = false;

  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _role = prefs.getString(_kRole);
    _userId = prefs.getString(_kUserId);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSession({
    required String? token,
    required String role,
    String? userId,
  }) async {
    _token = token;
    _role = role;
    _userId = userId;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_kToken);
    } else {
      await prefs.setString(_kToken, token);
    }
    await prefs.setString(_kRole, role);
    if (userId == null) {
      await prefs.remove(_kUserId);
    } else {
      await prefs.setString(_kUserId, userId);
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _role = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kRole);
    await prefs.remove(_kUserId);
    notifyListeners();
  }

  bool isBoss() => _role == 'boss';

  String? getToken() => _token;
}
