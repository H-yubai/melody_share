import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperSettings extends ChangeNotifier {
  static const _keyBaseUrl = 'dev_base_url';
  static const _keyDebugMode = 'dev_debug_mode';
  static const _defaultBaseUrl = 'http://10.0.2.2:3000';

  String _baseUrl = _defaultBaseUrl;
  bool _debugMode = false;
  bool _loaded = false;

  String get baseUrl => _baseUrl;
  bool get debugMode => _debugMode;
  bool get loaded => _loaded;

  DeveloperSettings() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString(_keyBaseUrl) ?? _defaultBaseUrl;
      _debugMode = prefs.getBool(_keyDebugMode) ?? false;
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, url);
    } catch (_) {}
  }

  Future<void> resetBaseUrl() async {
    await setBaseUrl(_defaultBaseUrl);
  }

  Future<void> toggleDebugMode() async {
    _debugMode = !_debugMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDebugMode, _debugMode);
    } catch (_) {}
  }
}
