import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory session mirror backed by platform-secure storage.
///
/// Tokens live in [FlutterSecureStorage]. Legacy SharedPreferences values are
/// migrated once on [load] and then removed. SharedPreferences is only used as
/// a fallback when the secure-storage plugin is unavailable (for example in
/// some widget tests).
class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _secure = FlutterSecureStorage();

  static const _kToken = 'auth_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'auth_role';
  static const _kUserId = 'auth_user_id';

  String? _token;
  String? _refreshToken;
  String? _role;
  String? _userId;
  bool _loaded = false;
  bool _secureUsable = true;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get role => _role;
  String? get userId => _userId;
  bool get isLoaded => _loaded;

  Future<String?> _read(String key) async {
    if (_secureUsable) {
      try {
        final value = await _secure.read(key: key);
        if (value != null) return value;
      } catch (_) {
        _secureUsable = false;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key);
    if (legacy != null && _secureUsable) {
      try {
        await _secure.write(key: key, value: legacy);
        await prefs.remove(key);
      } catch (_) {
        _secureUsable = false;
      }
    }
    return legacy;
  }

  Future<void> _write(String? value, String key) async {
    if (_secureUsable) {
      try {
        if (value == null) {
          await _secure.delete(key: key);
        } else {
          await _secure.write(key: key, value: value);
        }
      } catch (_) {
        _secureUsable = false;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    // Never leave a plaintext copy behind, even when the write above failed.
    await prefs.remove(key);
    if (!_secureUsable && value != null) {
      await prefs.setString(key, value);
    }
  }

  Future<void> load() async {
    _token = await _read(_kToken);
    _refreshToken = await _read(_kRefresh);
    _role = await _read(_kRole);
    _userId = await _read(_kUserId);
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
    await _write(token, _kToken);
    await _write(role, _kRole);
    await _write(userId, _kUserId);
    notifyListeners();
  }

  Future<String?> getRefreshToken() => _read(_kRefresh);

  Future<void> setRefreshToken(String? token) async {
    _refreshToken = token;
    await _write(token, _kRefresh);
  }

  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    _role = null;
    _userId = null;
    await _write(null, _kToken);
    await _write(null, _kRefresh);
    await _write(null, _kRole);
    await _write(null, _kUserId);
    notifyListeners();
  }

  bool isBoss() => _role == 'boss';

  String? getToken() => _token;
}
