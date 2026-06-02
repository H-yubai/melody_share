import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDark {
    if (_mode == ThemeMode.dark) return true;
    if (_mode == ThemeMode.light) return false;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  void setTheme(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void toggle() {
    _mode = switch (_mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
    notifyListeners();
  }
}
