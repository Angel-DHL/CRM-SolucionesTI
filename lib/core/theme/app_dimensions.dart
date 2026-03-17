/// Constantes de espaciado, bordes y breakpoints responsivos.
class AppDimensions {
  AppDimensions._();

  // ─── SPACING ────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ─── BORDER RADIUS ─────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // ─── ELEVACIONES ────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 3;
  static const double elevationHigh = 6;

  // ─── ICONOS ─────────────────────────────────────────────
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ─── BREAKPOINTS RESPONSIVOS ────────────────────────────
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double desktopMin = 1025;

  // ─── ANCHOS MÁXIMOS ─────────────────────────────────────
  static const double maxContentWidth = 1200;
  static const double maxFormWidth = 500;
  static const double sidebarWidth = 280;
  static const double sidebarCollapsedWidth = 72;

  // ─── DURACIÓN DE ANIMACIONES ────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}
