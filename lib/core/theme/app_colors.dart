import 'package:flutter/material.dart';

/// Paleta de colores centralizada del CRM Soluciones TI.
///
/// Basada en los colores de marca #ACC952 y #44562C,
/// expandida para cubrir todas las necesidades de UI.
class AppColors {
  AppColors._(); // No instanciable

  // ─── PRIMARIOS ──────────────────────────────────────────
  static const Color primaryDark = Color(0xFF2E3D1E);
  static const Color primary = Color(0xFF44562C);
  static const Color primaryMedium = Color(0xFF5A7A3A);
  static const Color primaryLight = Color(0xFFACC952);
  static const Color primaryPale = Color(0xFFD4E88B);
  static const Color primarySurface = Color(0xFFF0F5E4);

  // ─── NEUTROS ────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1F16);
  static const Color textSecondary = Color(0xFF3D4A35);
  static const Color textHint = Color(0xFF8B9A78);
  static const Color border = Color(0xFFC8D1BC);
  static const Color divider = Color(0xFFE8EDE0);
  static const Color background = Color(0xFFF5F8F0);
  static const Color surface = Color(0xFFFFFFFF);

  // ─── SEMÁNTICOS ─────────────────────────────────────────
  static const Color error = Color(0xFFD94F4F);
  static const Color errorLight = Color(0xFFFDECEC);
  static const Color warning = Color(0xFFE8A838);
  static const Color warningLight = Color(0xFFFFF4E0);
  static const Color info = Color(0xFF4A90D9);
  static const Color infoLight = Color(0xFFE8F0FB);
  static const Color success = Color(0xFF52B788);
  static const Color successLight = Color(0xFFE6F7EF);

  // ─── DARK MODE ──────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121A0D);
  static const Color darkSurface = Color(0xFF1E2A15);
  static const Color darkSurfaceHigh = Color(0xFF2A3A1E);
  static const Color darkBorder = Color(0xFF3D4A35);
  static const Color darkTextPrimary = Color(0xFFE8EDE0);
  static const Color darkTextSecondary = Color(0xFFA8B89A);
  static const Color darkTextHint = Color(0xFF6B7A5E);

  // ─── GRADIENTES ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryMedium],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMedium, primaryLight],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, Color(0xFF3A5C22)],
  );
}
