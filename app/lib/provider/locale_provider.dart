import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'locale';

  Locale _locale = const Locale('zh');
  bool _loaded = false;

  Locale get locale => _locale;
  bool get loaded => _loaded;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_key) ?? 'zh';
      _locale = Locale(val);
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _locale.languageCode);
    } catch (_) {}
  }
}
