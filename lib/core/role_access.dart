import 'role.dart';

enum AppModule {
  operatividad,
  crm,
  inventario,
  ventas,
  marketing,
  soporte,
  proyectos,
}

extension AppModuleX on AppModule {
  String get id => name.toLowerCase();

  String get title {
    switch (this) {
      case AppModule.operatividad:
        return 'Operatividad';
      case AppModule.crm:
        return 'CRM';
      case AppModule.inventario:
        return 'Inventario';
      case AppModule.ventas:
        return 'Ventas';
      case AppModule.marketing:
        return 'Marketing';
      case AppModule.soporte:
        return 'Soporte';
      case AppModule.proyectos:
        return 'Proyectos';
    }
  }
}

class RoleAccess {
  static const allModules = [
    AppModule.operatividad,
    AppModule.crm,
    AppModule.inventario,
    AppModule.ventas,
    AppModule.marketing,
    AppModule.soporte,
    AppModule.proyectos,
  ];

  /// Verifica si el rol tiene acceso (al menos lectura) al módulo
  static bool canAccess(UserRole role, AppModule module) {
    final permission = role.permissions[module.name.toLowerCase()] ??
        role.permissions[module.id] ??
        PermissionLevel.none;
    return permission != PermissionLevel.none;
  }

  /// Verifica si el rol tiene un nivel específico de permiso
  static bool hasPermission(
    UserRole role,
    AppModule module,
    PermissionLevel required,
  ) {
    final level = role.permissions[module.id] ?? PermissionLevel.none;
    return level.index >= required.index;
  }
}
