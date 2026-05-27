import 'package:flutter/material.dart';

class AnimationProvider extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  String get assetPath {
    return 'assets/animations/lottie/wave${_index + 1}.json';
  }

  void setIndex(int index) {
    _index = index;
    notifyListeners();
  }
}
