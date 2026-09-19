import 'package:flutter/material.dart';

class Styles {
  static const Color _darkText = Color(0xFFF5F5F5);
  static const Color _darkMutedText = Color(0xFFE6E6E6);

  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    final colorScheme = isDarkTheme
        ? const ColorScheme.dark(
            primary: Color(0xFF90CAF9),
            secondary: Color(0xFF1E3A5F),
            surface: Color(0xFF1E1E1E),
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: _darkText,
          )
        : const ColorScheme.light(
            primary: Colors.blue,
            secondary: Color(0xFFE8FDFD),
            surface: Color(0xFFF2FDFD),
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onSurface: Colors.black,
          );

    final base = isDarkTheme ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: isDarkTheme ? const Color(0xFF90CAF9) : Colors.blue,
      scaffoldBackgroundColor:
          isDarkTheme ? const Color(0xFF121212) : Colors.white,
      cardColor: isDarkTheme ? const Color(0xFF1E1E1E) : const Color(0xFFF2FDFD),
      canvasColor: isDarkTheme ? const Color(0xFF121212) : Colors.grey[50],
      dividerColor: isDarkTheme ? Colors.white24 : Colors.black12,
      textTheme: base.textTheme.apply(
        bodyColor: isDarkTheme ? _darkText : Colors.black,
        displayColor: isDarkTheme ? _darkText : Colors.black,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: isDarkTheme ? _darkText : Colors.black,
        displayColor: isDarkTheme ? _darkText : Colors.black,
      ),
      iconTheme: IconThemeData(
        color: isDarkTheme ? _darkText : Colors.black87,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDarkTheme ? _darkText : Colors.black87,
        textColor: isDarkTheme ? _darkText : Colors.black,
        subtitleTextStyle: TextStyle(
          color: isDarkTheme ? _darkMutedText : Colors.black87,
          fontSize: 14,
        ),
        titleTextStyle: TextStyle(
          color: isDarkTheme ? _darkText : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: isDarkTheme ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDarkTheme ? _darkText : Colors.black,
        iconTheme: IconThemeData(
          color: isDarkTheme ? _darkText : Colors.black,
        ),
        titleTextStyle: TextStyle(
          color: isDarkTheme ? _darkText : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDarkTheme ? _darkText : Colors.blue,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDarkTheme ? const Color(0xFF1565C0) : Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: isDarkTheme ? _darkText : Colors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: isDarkTheme ? const Color(0xFF2A2A2A) : Colors.grey[100],
        filled: true,
        labelStyle: TextStyle(
          color: isDarkTheme ? _darkMutedText : Colors.grey[800],
        ),
        hintStyle: TextStyle(
          color: isDarkTheme ? const Color(0xFFD0D0D0) : Colors.grey[600],
        ),
        prefixIconColor: isDarkTheme ? _darkMutedText : Colors.grey[700],
        suffixIconColor: isDarkTheme ? _darkMutedText : Colors.grey[700],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkTheme ? Colors.white38 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkTheme ? const Color(0xFF90CAF9) : Colors.blue,
            width: 2,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return isDarkTheme ? const Color(0xFF90CAF9) : Colors.blue;
          }
          return isDarkTheme ? Colors.white70 : Colors.grey;
        }),
      ),
    );
  }
}
