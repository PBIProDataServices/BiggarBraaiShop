import 'package:flutter/material.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor:
          isDarkTheme ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
      primaryColor: isDarkTheme ? Colors.blue[700] : Colors.blue,
      colorScheme: ThemeData().colorScheme.copyWith(
            primary: isDarkTheme ? Colors.blue[700] : Colors.blue,
            secondary: isDarkTheme ? const Color(0xFF1E3A5F) : const Color(0xFFE8FDFD),
            brightness: isDarkTheme ? Brightness.dark : Brightness.light,
          ),
      cardColor: isDarkTheme ? const Color(0xFF1E1E1E) : const Color(0xFFF2FDFD),
      canvasColor: isDarkTheme ? Colors.black : Colors.grey[50],
      buttonTheme: Theme.of(context).buttonTheme.copyWith(
        colorScheme: isDarkTheme ? const ColorScheme.dark() : const ColorScheme.light(),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: isDarkTheme ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDarkTheme ? Colors.white : Colors.blue,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkTheme ? Colors.blue[700] : Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: isDarkTheme ? const Color(0xFF2A2A2A) : Colors.grey[100],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkTheme ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkTheme ? Colors.blue[700]! : Colors.blue,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isDarkTheme ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }
}
