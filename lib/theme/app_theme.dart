import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // App Colors
  static const Color primaryColor = Color(0xFF4A6CFF);
  static const Color secondaryColor = Color(0xFF00C9B8);
  static const Color accentColor = Color(0xFFFF8C42);
  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color darkBackgroundColor = Color(0xFF1A1F38);
  static const Color cardColor = Colors.white;
  static const Color darkCardColor = Color(0xFF252B43);
  static const Color textColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFF8F9FE);
  static const Color subTextColor = Color(0xFF757575);
  static const Color darkSubTextColor = Color(0xFFBBBBBB);
  static const Color successColor = Color(0xFF2ED573);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFFD76E);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: backgroundColor,
      surface: cardColor,
      onSurface: textColor,
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: backgroundColor,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.poppins(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.poppins(color: textColor),
      bodyMedium: GoogleFonts.poppins(color: textColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: darkBackgroundColor,
      surface: darkCardColor,
      onSurface: darkTextColor,
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: darkBackgroundColor,
      iconTheme: IconThemeData(color: darkTextColor),
      titleTextStyle: GoogleFonts.poppins(
        color: darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(color: darkTextColor, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.poppins(color: darkTextColor, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.poppins(color: darkTextColor, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.poppins(color: darkTextColor, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.poppins(color: darkTextColor, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.poppins(color: darkTextColor, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.poppins(color: darkTextColor),
      bodyMedium: GoogleFonts.poppins(color: darkTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}