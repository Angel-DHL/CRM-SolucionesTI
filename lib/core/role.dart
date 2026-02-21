enum UserRole {
  admin,
  soporteTecnico,
  soporteSistemas;

  String get claim {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.soporteTecnico:
        return 'soporte_tecnico';
      case UserRole.soporteSistemas:
        return 'soporte_sistemas';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.soporteTecnico:
        return 'Soporte Técnico';
      case UserRole.soporteSistemas:
        return 'Soporte Sistemas';
    }
  }

  static UserRole fromClaim(String? claim) {
    switch (claim) {
      case 'admin':
        return UserRole.admin;
      case 'soporte_tecnico':
        return UserRole.soporteTecnico;
      case 'soporte_sistemas':
        return UserRole.soporteSistemas;
      default:
        // Por seguridad: si no viene rol, lo tratamos como soporte (o puedes bloquear)
        return UserRole.soporteTecnico;
    }
  }
}
