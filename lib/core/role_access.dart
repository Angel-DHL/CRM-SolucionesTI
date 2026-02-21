import 'role.dart';

enum AppModule {
  operatividad,
  ventas,
  inventario,
  marketing,
  soporte,
  proyectos,
}

extension AppModuleX on AppModule {
  String get title {
    switch (this) {
      case AppModule.operatividad:
        return 'Operatividad';
      case AppModule.ventas:
        return 'Ventas';
      case AppModule.inventario:
        return 'Inventario';
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
    AppModule.ventas,
    AppModule.inventario,
    AppModule.marketing,
    AppModule.soporte,
    AppModule.proyectos,
  ];

  static bool canAccess(UserRole role, AppModule module) {
    switch (role) {
      case UserRole.admin:
        return true;

      case UserRole.soporteTecnico:
        return module == AppModule.soporte || module == AppModule.operatividad;

      case UserRole.soporteSistemas:
        return module == AppModule.soporte ||
            module == AppModule.proyectos ||
            module == AppModule.inventario ||
            module == AppModule.operatividad;
    }
  }
}
