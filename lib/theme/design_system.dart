import 'package:flutter/material.dart';

enum DesignStyle { ios18, oneui7 }

class DesignSystem extends ChangeNotifier {
  DesignStyle _style = DesignStyle.ios18;
  DesignStyle get style => _style;

  void setStyle(DesignStyle s) {
    if (_style == s) return;
    _style = s;
    notifyListeners();
  }
}