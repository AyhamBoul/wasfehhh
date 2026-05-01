import 'package:flutter/material.dart';

const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFFEFF6FF);
const kSuccess = Color(0xFF10B981);
const kWarning = Color(0xFFF59E0B);
const kDanger = Color(0xFFEF4444);
const kBg = Color(0xFFF1F5F9);
const kTextPrimary = Color(0xFF1E293B);
const kTextSecondary = Color(0xFF64748B);
const kBorder = Color(0xFFE2E8F0);
const kCardBg = Colors.white;

const kGradient = LinearGradient(
  colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kBg,
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      elevation: 0,
      color: kCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kDanger, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: kTextSecondary),
      hintStyle:
          const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: kPrimary),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCardBg,
      foregroundColor: kTextPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: kTextPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kPrimary,
      unselectedItemColor: Color(0xFF94A3B8),
      backgroundColor: kCardBg,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(
      color: kBorder,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ),
  );
}
