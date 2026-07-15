import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors (Orange)
  static const Color primary = Color(0xFFF97316); // Orange 500
  static const Color primaryLight = Color(0xFFFB923C); // Orange 400
  static const Color primaryDark = Color(0xFFEA580C); // Orange 600
  static const Color primaryContainer = Color(0xFFFFEDD5); // Orange 100

  // Secondary (Modern Teal/Cyan)
  static const Color secondary = Color(0xFF0891B2);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF164E63);
  static const Color secondaryContainer = Color(0xFFCFFAFE);

  // Accent / Tertiary
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentContainer = Color(0xFFEDE9FE);

  // Semantic Colors
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Neutral - Light Mode
  static const Color background = Color(0xFFF8FAFC); // Sangat terang/bersih
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFF8FAFC);

  // Text - Light Mode
  static const Color textPrimary = Color(0xFF0F172A); // Hampir hitam
  static const Color textSecondary = Color(0xFF475569); // Abu-abu gelap
  static const Color textTertiary = Color(0xFF94A3B8); // Abu-abu terang
  static const Color textInverse = Color(0xFFFFFFFF);

  // Neutral - Dark Mode (Sleek Midnight/True Dark)
  static const Color darkBackground = Color(0xFF09090B); // Linear-like pure dark
  static const Color darkSurface = Color(0xFF18181B);
  static const Color darkSurfaceVariant = Color(0xFF27272A);
  static const Color darkOutline = Color(0xFF3F3F46);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // Cluster Colors (ML)
  static const Color sangatMembutuhkan = Color(0xFFEF4444);
  static const Color membutuhkan = Color(0xFFF59E0B);
  static const Color cukupMampu = Color(0xFF10B981);
  static const Color mampu = Color(0xFF3B82F6);
  static const Color outlier = Color(0xFF8B5CF6);

  // Status Badges Colors
  static const Color statusMenunggu = Color(0xFFF59E0B);
  static const Color statusRevisi = Color(0xFF6366F1);
  static const Color statusDitolak = Color(0xFFEF4444);
  static const Color statusTerverifikasi = Color(0xFF10B981);
  static const Color statusSeleksi = Color(0xFF3B82F6);
  static const Color statusDiterima = Color(0xFF10B981);
  static const Color statusTidakDiterima = Color(0xFFEF4444);

  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFB923C), Color(0xFFF97316)], // Halus dan elegan (Orange)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF18181B), Color(0xFF09090B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
