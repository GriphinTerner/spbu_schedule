import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // Основные цвета приложения
  static const Color _primaryLight = Color(0xFF007AFF); // iOS синий
  static const Color _primaryDark = Color(0xFF0A84FF);
  
  static const Color _secondaryLight = Color(0xFF5E5CE6); // iOS индиго
  static const Color _secondaryDark = Color(0xFF5E5CE6);
  
  static const Color _backgroundLight = Color(0xFFF2F2F7); // iOS светлый фон
  static const Color _backgroundDark = Color(0xFF1C1C1E); // iOS темный фон
  
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF2C2C2E);
  
  static const Color _errorLight = Color(0xFFFF3B30); // iOS красный
  static const Color _errorDark = Color(0xFFFF453A);
  
  static const Color _onBackgroundLight = Color(0xFF000000);
  static const Color _onBackgroundDark = Color(0xFFFFFFFF);
  
  static const Color _onSurfaceLight = Color(0xFF000000);
  static const Color _onSurfaceDark = Color(0xFFFFFFFF);
  
  // Дополнительные цвета iOS
  static const Color _greenLight = Color(0xFF34C759);
  static const Color _greenDark = Color(0xFF30D158);
  
  static const Color _orangeLight = Color(0xFFFF9500);
  static const Color _orangeDark = Color(0xFFFF9F0A);
  
  static const Color _yellowLight = Color(0xFFFFCC00);
  static const Color _yellowDark = Color(0xFFFFD60A);
  
  static const Color _purpleLight = Color(0xFFAF52DE);
  static const Color _purpleDark = Color(0xFFBF5AF2);
  
  static const Color _tealLight = Color(0xFF5AC8FA);
  static const Color _tealDark = Color(0xFF64D2FF);
  
  // Цвета для карточек и разделителей
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF2C2C2E);
  
  static const Color _dividerLight = Color(0xFFC6C6C8);
  static const Color _dividerDark = Color(0xFF38383A);
  
  // Светлая тема
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryLight,
      secondary: _secondaryLight,
      surface: _surfaceLight,
      error: _errorLight,
      onSurface: _onSurfaceLight,
    ),
    scaffoldBackgroundColor: _backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceLight,
      foregroundColor: _primaryLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _onSurfaceLight),
    ),
    cardTheme: const CardThemeData(
      color: _cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceLight,
      selectedItemColor: _primaryLight,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _surfaceLight,
      selectedColor: _primaryLight.withOpacity(0.2),
      labelStyle: TextStyle(fontSize: 14, color: _onSurfaceLight),
      secondaryLabelStyle: TextStyle(fontSize: 14, color: Colors.white),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    dividerTheme: DividerThemeData(
      color: _dividerLight,
      thickness: 0.5,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: _onSurfaceLight),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _onSurfaceLight),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _onSurfaceLight),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _onSurfaceLight),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _onSurfaceLight),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _onSurfaceLight),
      bodyLarge: TextStyle(fontSize: 16, color: _onSurfaceLight),
      bodyMedium: TextStyle(fontSize: 14, color: _onSurfaceLight),
      bodySmall: TextStyle(fontSize: 12, color: _onSurfaceLight.withOpacity(0.7)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryLight,
    ),
  );
  
  // Темная тема
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primaryDark,
      secondary: _secondaryDark,
      surface: _surfaceDark,
      error: _errorDark,
      onSurface: _onBackgroundDark,
    ),
    scaffoldBackgroundColor: _backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceDark,
      foregroundColor: _primaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _onBackgroundDark),
    ),
    cardTheme: const CardThemeData(
      color: _cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceDark,
      selectedItemColor: _primaryDark,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _surfaceDark,
      selectedColor: _primaryDark.withOpacity(0.2),
      labelStyle: TextStyle(fontSize: 14, color: _onBackgroundDark),
      secondaryLabelStyle: TextStyle(fontSize: 14, color: Colors.white),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: _dividerDark,
      thickness: 0.5,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: _onBackgroundDark),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _onBackgroundDark),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _onBackgroundDark),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _onBackgroundDark),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _onBackgroundDark),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _onBackgroundDark),
      bodyLarge: TextStyle(fontSize: 16, color: _onBackgroundDark),
      bodyMedium: TextStyle(fontSize: 14, color: _onBackgroundDark),
      bodySmall: TextStyle(fontSize: 12, color: _onBackgroundDark.withOpacity(0.7)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryDark,
    ),
  );
}