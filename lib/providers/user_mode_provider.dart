import 'package:flutter/material.dart';

class UserModeProvider with ChangeNotifier {

  bool _isDriverMode = false;
  bool get isDriverMode => _isDriverMode;

  void setDriverMode(bool isDriver) {
    _isDriverMode = isDriver;
    notifyListeners(); 
  }

  void toggleMode() {
    _isDriverMode = !_isDriverMode;
    notifyListeners();
  }
}