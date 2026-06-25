import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _loaded = false;

  ThemeMode get mode => _mode;
  bool get loaded => _loaded;

  bool get isDark {
    if (_mode == ThemeMode.dark) return true;
    if (_mode == ThemeMode.light) return false;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getInt(_key) ?? 0;
      _mode = ThemeMode.values[val];
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
    _persist();
  }

  void toggle() {
    _mode = switch (_mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, _mode.index);
    } catch (_) {}
  }
}
