import 'package:flutter/cupertino.dart';

import 'package:biggar_braai_shop/services/dark_theme_prefs.dart';

class DarkThemeProvider with ChangeNotifier {
  DarkThemePrefs darkThemePrefs = DarkThemePrefs();
  bool _darkTheme = false;
  bool _disposed = false;

  bool get getDarkTheme => _darkTheme;

  set setDarkTheme(bool value) {
    if (_disposed) return;
    _darkTheme = value;
    darkThemePrefs.setDarkTheme(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
