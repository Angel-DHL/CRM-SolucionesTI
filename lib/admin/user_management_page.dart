import 'package:flutter/material.dart';
import '../core/services/user_service.dart';
import '../core/services/role_service.dart';
import '../core/role.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import 'create_user_page.dart';
import 'role_management_page.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleManagementPage()),
            ),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Gestionar Roles',
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateUserPage()),
            ),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Nuevo Usuario'),
          ),
          const SizedBox(width: AppDimensions.md),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: UserService.usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(user: user);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No hay usuarios registrados', style: AppTextStyles.h3),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateUserPage()),
            ),
            child: const Text('Crear el primer usuario'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final String uid = user['uid'] ?? '';
    final String email = user['email'] ?? 'Sin correo';
    final String roleId = user['role'] ?? 'soporte_tecnico';
    final String firstName = user['firstName'] ?? '';
    final String lastName = user['lastName'] ?? '';
    final String photoUrl = user['photoURL'] ?? '';
    final bool active = user['active'] ?? true;

    final displayName = (firstName.isEmpty && lastName.isEmpty)
        ? email.split('@')[0]
        : '$firstName $lastName'.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: AppTextStyles.labelLarge),
                  Text(email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: 4),
                  _RoleBadge(roleId: roleId),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: active,
                  onChanged: (v) => UserService.toggleUserStatus(uid, v),
                  activeColor: AppColors.success,
                ),
                Text(active ? 'Activo' : 'Inactivo', style: AppTextStyles.labelSmall),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit_role',
                  child: Row(
                    children: [
                      Icon(Icons.badge_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Cambiar Rol'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit_role') _showRolePicker(context, uid, roleId);
                if (val == 'delete') _confirmDelete(context, uid, displayName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRolePicker(BuildContext context, String uid, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StreamBuilder<List<UserRole>>(
        stream: RoleService.rolesStream,
        builder: (context, snapshot) {
          final roles = snapshot.data ?? [];
          return Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Seleccionar Nuevo Rol', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ...roles.map((role) => ListTile(
                  title: Text(role.label),
                  selected: role.id == currentRole,
                  trailing: role.id == currentRole ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    UserService.updateRole(uid, role.id);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar a $name? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              UserService.deleteUserFirestore(uid);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String roleId;
  const _RoleBadge({required this.roleId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: RoleService.getRole(roleId),
      builder: (context, snapshot) {
        final label = snapshot.data?.label ?? roleId;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
