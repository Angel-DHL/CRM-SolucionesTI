import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Configuración completa de temas Light y Dark para el CRM.
class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ══════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primarios
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryPale,
      onPrimaryContainer: AppColors.primaryDark,
      // Secundarios
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.primaryDark,
      secondaryContainer: AppColors.primarySurface,
      onSecondaryContainer: AppColors.primary,
      // Terciarios
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.infoLight,
      onTertiaryContainer: Color(0xFF1A3A5C),
      // Error
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: Color(0xFF5C1A1A),
      // Superficies
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.divider,
      onSurfaceVariant: AppColors.textSecondary,
      // Otros
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: Colors.black.withOpacity(0.08),
      scrim: Colors.black.withOpacity(0.3),
      inverseSurface: AppColors.primaryDark,
      onInverseSurface: AppColors.primarySurface,
      inversePrimary: AppColors.primaryPale,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // ─── SYSTEM UI ──────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.border.withOpacity(0.3),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.25,
        ),
      ),

      // ─── CARDS ──────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── ELEVATED BUTTON ───────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ─── FILLED BUTTON ─────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ─── OUTLINED BUTTON ───────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          side: BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ─── TEXT BUTTON ────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ─── FAB ────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      // ─── INPUT DECORATION ──────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
        hintStyle: TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.textHint,
        suffixIconColor: AppColors.textHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ─── CHIPS ──────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        ),
      ),

      // ─── DIALOG ─────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),

      // ─── BOTTOM SHEET ───────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        dragHandleSize: const Size(40, 4),
      ),

      // ─── SNACKBAR ───────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ─── NAVIGATION BAR (Bottom) ───────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySurface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 70,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: AppColors.textHint, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: AppColors.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // ─── NAVIGATION RAIL (Tablet/Desktop) ──────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySurface,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textHint),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ─── DRAWER ─────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),

      // ─── DIVIDER ───────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ─── TABS ──────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: AppColors.divider,
      ),

      // ─── TOOLTIP ────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        ),
      ),

      // ─── PROGRESS INDICATOR ─────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.primarySurface,
        circularTrackColor: AppColors.primarySurface,
      ),

      // ─── SWITCH / CHECKBOX / RADIO ──────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),

      // ─── LIST TILE ──────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        iconColor: AppColors.textHint,
      ),

      // ─── DATA TABLE ────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        dataTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        headingRowColor: WidgetStateProperty.all(AppColors.primarySurface),
        dividerThickness: 1,
      ),

      // ─── PAGE TRANSITIONS ──────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ─── VISUAL DENSITY ────────────────────────────────
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DARK THEME
  // ══════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.primaryDark,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.primaryPale,
      secondary: AppColors.primaryPale,
      onSecondary: AppColors.primaryDark,
      secondaryContainer: AppColors.primaryDark,
      onSecondaryContainer: AppColors.primaryPale,
      tertiary: Color(0xFF7AB8E8),
      onTertiary: Color(0xFF0A2A4A),
      tertiaryContainer: Color(0xFF1A3A5C),
      onTertiaryContainer: Color(0xFFBBDCF5),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF3C0A0A),
      errorContainer: Color(0xFF5C1A1A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: Color(0xFF2A3A1E),
      shadow: Colors.black.withOpacity(0.3),
      scrim: Colors.black.withOpacity(0.6),
      inverseSurface: AppColors.primaryPale,
      onInverseSurface: AppColors.primaryDark,
      inversePrimary: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.darkSurface,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          side: BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
        hintStyle: TextStyle(color: AppColors.darkTextHint, fontSize: 14),
        labelStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(color: AppColors.primaryLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.3),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primaryLight);
          }
          return IconThemeData(color: AppColors.darkTextHint);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(color: AppColors.darkTextHint, fontSize: 12);
        }),
      ),

      dividerTheme: DividerThemeData(color: AppColors.darkBorder, thickness: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceHigh,
        contentTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
