import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language state.
///
/// The selected language is persisted so a cold start keeps the user's choice,
/// and [isRtl] drives the [Directionality] of every shell.
class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  static final AppLanguage instance = AppLanguage._();

  static const String _storageKey = 'orizzonte_language';

  String _lang = 'EN';
  String get lang => _lang;
  bool get isRtl => _lang == 'AR';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == 'EN' || stored == 'AR' || stored == 'FR') {
      _lang = stored!;
      notifyListeners();
    }
  }

  void setLang(String lang) {
    if (lang != 'EN' && lang != 'AR' && lang != 'FR') return;
    _lang = lang;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_storageKey, lang);
    });
  }
}

final appLanguage = AppLanguage.instance;
