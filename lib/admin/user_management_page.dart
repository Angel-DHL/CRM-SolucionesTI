import 'package:flutter/material.dart';
import '../core/services/user_service.dart';
import '../core/services/role_service.dart';
import '../core/role.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import 'create_user_page.dart';
import 'role_management_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = '';
  String _filterRole = 'all';
  String _filterStatus = 'all';
  Map<String, int>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await UserService.getUserStats();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleManagementPage())),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Gestionar Roles',
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserPage())),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Nuevo Usuario'),
          ),
          const SizedBox(width: AppDimensions.md),
        ],
      ),
      body: Column(children: [
        // Stats bar
        if (_stats != null) _buildStatsBar(),
        // Search and filters
        _buildSearchBar(),
        // User list
        Expanded(child: _buildUserList()),
      ]),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        _StatChip(label: 'Total', value: '${_stats!['total'] ?? 0}', icon: Icons.people_rounded, color: AppColors.primary),
        const SizedBox(width: 12),
        _StatChip(label: 'Activos', value: '${_stats!['active'] ?? 0}', icon: Icons.check_circle_rounded, color: AppColors.success),
        const SizedBox(width: 12),
        _StatChip(label: 'Inactivos', value: '${_stats!['inactive'] ?? 0}', icon: Icons.block_rounded, color: AppColors.error),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        Expanded(child: SizedBox(height: 44, child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o email...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull), borderSide: BorderSide(color: AppColors.border)),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ))),
        const SizedBox(width: 12),
        // Role filter
        StreamBuilder<List<UserRole>>(
          stream: RoleService.rolesStream,
          builder: (context, snap) {
            final roles = snap.data ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: _filterRole,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Todos los roles')),
                  ...roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.label))),
                ],
                onChanged: (v) => setState(() => _filterRole = v ?? 'all'),
              )),
            );
          },
        ),
        const SizedBox(width: 12),
        // Status filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _filterStatus,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Todos')),
              DropdownMenuItem(value: 'active', child: Text('Activos')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactivos')),
            ],
            onChanged: (v) => setState(() => _filterStatus = v ?? 'all'),
          )),
        ),
      ]),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: UserService.usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var users = snapshot.data ?? [];
        if (users.isEmpty) return _buildEmptyState();

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          users = users.where((u) {
            final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }
        if (_filterRole != 'all') {
          users = users.where((u) => u['role'] == _filterRole).toList();
        }
        if (_filterStatus == 'active') {
          users = users.where((u) => u['active'] != false).toList();
        } else if (_filterStatus == 'inactive') {
          users = users.where((u) => u['active'] == false).toList();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _UserCard(
            user: users[index],
            onRefresh: _loadStats,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textHint),
      const SizedBox(height: 16),
      Text('No hay usuarios registrados', style: AppTextStyles.h3),
      const SizedBox(height: 24),
      FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserPage())),
        child: const Text('Crear el primer usuario')),
    ]));
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(value, style: AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
      ]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;
  const _UserCard({required this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final String uid = user['uid'] ?? '';
    final String email = user['email'] ?? 'Sin correo';
    final String roleId = user['role'] ?? 'soporte_tecnico';
    final String firstName = user['firstName'] ?? '';
    final String lastName = user['lastName'] ?? '';
    final String photoUrl = user['photoURL'] ?? '';
    final String jobTitle = user['jobTitle'] ?? '';
    final String phone = user['phone'] ?? '';
    final bool active = user['active'] ?? true;

    final displayName = (firstName.isEmpty && lastName.isEmpty)
        ? email.split('@')[0]
        : '$firstName $lastName'.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: active ? AppColors.divider : AppColors.error.withOpacity(0.3))),
      color: active ? AppColors.surface : AppColors.error.withOpacity(0.03),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primarySurface,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? Text(displayName.substring(0, 1).toUpperCase(), style: AppTextStyles.h4.copyWith(color: AppColors.primary)) : null,
        ),
        title: Row(children: [
          Expanded(child: Text(displayName, style: AppTextStyles.labelLarge)),
          if (!active) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
            child: Text('INACTIVO', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 4),
          _RoleBadge(roleId: roleId),
        ]),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          // Detail grid
          Row(children: [
            Expanded(child: _DetailItem(icon: Icons.work_outline, label: 'Cargo', value: jobTitle.isEmpty ? 'Sin asignar' : jobTitle)),
            Expanded(child: _DetailItem(icon: Icons.phone_outlined, label: 'Teléfono', value: phone.isEmpty ? 'Sin registrar' : phone)),
          ]),
          const SizedBox(height: 16),
          // Actions
          Row(children: [
            Switch(value: active, onChanged: (v) { UserService.toggleUserStatus(uid, v); onRefresh(); }, activeColor: AppColors.success),
            Text(active ? 'Activo' : 'Inactivo', style: AppTextStyles.labelSmall),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _showRolePicker(context, uid, roleId),
              icon: const Icon(Icons.badge_rounded, size: 16),
              label: const Text('Cambiar Rol'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary.withOpacity(0.3))),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, uid, displayName),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Eliminar'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withOpacity(0.3))),
            ),
          ]),
        ],
      ),
    );
  }

  void _showRolePicker(BuildContext context, String uid, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StreamBuilder<List<UserRole>>(
        stream: RoleService.rolesStream,
        builder: (context, snapshot) {
          final roles = snapshot.data ?? [];
          return Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Seleccionar Nuevo Rol', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              ...roles.map((role) => ListTile(
                leading: Icon(Icons.shield_rounded, color: role.id == currentRole ? AppColors.primary : AppColors.textHint),
                title: Text(role.label),
                selected: role.id == currentRole,
                trailing: role.id == currentRole ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () { UserService.updateRole(uid, role.id); Navigator.pop(context); onRefresh(); },
              )),
            ]),
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
            onPressed: () { UserService.deleteUserFirestore(uid); Navigator.pop(context); onRefresh(); },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textHint),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
        Text(value, style: AppTextStyles.bodySmall),
      ]),
    ]);
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
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
          child: Text(label.toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
        );
      },
    );
  }
}
