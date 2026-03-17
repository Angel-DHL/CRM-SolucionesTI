import 'package:flutter/material.dart';
import 'app_dimensions.dart';

/// Tipos de dispositivo según ancho de pantalla.
enum DeviceType { mobile, tablet, desktop }

/// Helper para construir layouts responsivos.
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppDimensions.desktopMin) return DeviceType.desktop;
    if (width >= AppDimensions.mobileMax) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      deviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;

  /// Padding horizontal adaptativo.
  static EdgeInsets horizontalPadding(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: AppDimensions.xxl);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: AppDimensions.lg);
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: AppDimensions.md);
    }
  }

  /// Número de columnas para grids.
  static int gridColumns(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return 4;
      case DeviceType.tablet:
        return 3;
      case DeviceType.mobile:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = deviceType(context);

    if (type == DeviceType.desktop && desktop != null) {
      return desktop!;
    }
    if (type == DeviceType.tablet && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}
