import 'package:flutter/material.dart';

class AppLanguage extends ChangeNotifier {
  String _lang = 'EN';
  String get lang => _lang;
  bool get isRtl => _lang == 'AR';

  void setLang(String lang) {
    _lang = lang;
    notifyListeners();
  }
}

final appLanguage = AppLanguage();
