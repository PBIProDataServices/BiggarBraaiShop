import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dark_theme_provider.dart';

class Utils {
  BuildContext context;
  Utils(this.context);
  bool get getTheme => Provider.of<DarkThemeProvider>(context).getDarkTheme;
  Color get color => getTheme ? const Color(0xFFF5F5F5) : Colors.black;
  Color get secondaryColor =>
      getTheme ? const Color(0xFFE6E6E6) : Colors.black87;
  Size get getScreenSize => MediaQuery.of(context).size;
}
