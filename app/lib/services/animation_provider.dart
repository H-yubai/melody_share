import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimationProvider extends ChangeNotifier {
  static const _key = 'animation_index';

  int _index = 0;
  bool _loaded = false;

  int get index => _index;
  bool get loaded => _loaded;

  String get assetPath => 'assets/animations/lottie/wave${_index + 1}.json';

  AnimationProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _index = prefs.getInt(_key) ?? 0;
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  void setIndex(int index) {
    _index = index;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, _index);
    } catch (_) {}
  }
}
