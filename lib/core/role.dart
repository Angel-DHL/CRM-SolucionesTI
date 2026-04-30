enum PermissionLevel {
  none,
  read,
  edit,
  total;

  static PermissionLevel fromString(String? value) {
    switch (value) {
      case 'read':
        return PermissionLevel.read;
      case 'edit':
        return PermissionLevel.edit;
      case 'total':
        return PermissionLevel.total;
      default:
        return PermissionLevel.none;
    }
  }

  String get id => name;

  String get label {
    switch (this) {
      case PermissionLevel.none:
        return 'Sin acceso';
      case PermissionLevel.read:
        return 'Lectura';
      case PermissionLevel.edit:
        return 'Edición';
      case PermissionLevel.total:
        return 'Total';
    }
  }
}

class UserRole {
  final String id;
  final String label;
  final Map<String, PermissionLevel> permissions;

  const UserRole({
    required this.id,
    required this.label,
    required this.permissions,
  });

  // Roles predefinidos (para fallback y compatibilidad)
  static const UserRole admin = UserRole(
    id: 'admin',
    label: 'Administrador',
    permissions: {
      'operatividad': PermissionLevel.total,
      'crm': PermissionLevel.total,
      'inventario': PermissionLevel.total,
      'ventas': PermissionLevel.total,
      'marketing': PermissionLevel.total,
      'soporte': PermissionLevel.total,
      'proyectos': PermissionLevel.total,
    },
  );

  static const UserRole soporteTecnico = UserRole(
    id: 'soporte_tecnico',
    label: 'Soporte Técnico',
    permissions: {
      'operatividad': PermissionLevel.edit,
      'soporte': PermissionLevel.edit,
    },
  );

  static const UserRole soporteSistemas = UserRole(
    id: 'soporte_sistemas',
    label: 'Soporte Sistemas',
    permissions: {
      'operatividad': PermissionLevel.total,
      'crm': PermissionLevel.edit,
      'inventario': PermissionLevel.total,
      'soporte': PermissionLevel.total,
      'proyectos': PermissionLevel.total,
    },
  );

  String get claim => id;

  static UserRole fromMap(Map<String, dynamic> map) {
    final permsMap = map['permissions'] as Map<String, dynamic>? ?? {};
    return UserRole(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      permissions: permsMap.map(
        (key, value) =>
            MapEntry(key, PermissionLevel.fromString(value.toString())),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'permissions': permissions.map((key, value) => MapEntry(key, value.id)),
    };
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
        return UserRole.soporteTecnico;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRole && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
