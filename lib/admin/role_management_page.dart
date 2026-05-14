import 'package:flutter/material.dart';
import '../core/role.dart';
import '../core/role_access.dart';
import '../core/services/role_service.dart';
import '../core/services/user_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});
  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  UserRole? _editingRole;
  Map<String, PermissionLevel> _currentPermissions = {};
  bool _loading = false;
  Map<String, int> _roleCounts = {};

  @override
  void initState() {
    super.initState();
    _resetForm();
    _loadRoleCounts();
  }

  Future<void> _loadRoleCounts() async {
    final stats = await UserService.getUserStats();
    if (mounted) setState(() => _roleCounts = stats);
  }

  void _resetForm() {
    _editingRole = null;
    _labelCtrl.clear();
    _idCtrl.clear();
    _currentPermissions = {for (var m in RoleAccess.allModules) m.id: PermissionLevel.none};
    setState(() {});
  }

  void _editRole(UserRole role) {
    _editingRole = role;
    _labelCtrl.text = role.label;
    _idCtrl.text = role.id;
    _currentPermissions = Map.from(role.permissions);
    for (var m in RoleAccess.allModules) {
      _currentPermissions.putIfAbsent(m.id, () => PermissionLevel.none);
    }
    setState(() {});
  }

  void _duplicateRole(UserRole role) {
    _editingRole = null;
    _labelCtrl.text = '${role.label} (Copia)';
    _idCtrl.text = '${role.id}_copia';
    _currentPermissions = Map.from(role.permissions);
    for (var m in RoleAccess.allModules) {
      _currentPermissions.putIfAbsent(m.id, () => PermissionLevel.none);
    }
    setState(() {});
  }

  void _setAllPermissions(PermissionLevel level) {
    setState(() {
      for (var m in RoleAccess.allModules) {
        _currentPermissions[m.id] = level;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final role = UserRole(
        id: _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
        label: _labelCtrl.text.trim(),
        permissions: _currentPermissions,
      );
      await RoleService.saveRole(role);
      _resetForm();
      _loadRoleCounts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Rol guardado exitosamente'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Roles y Permisos'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_editingRole != null)
            TextButton.icon(onPressed: _resetForm, icon: const Icon(Icons.add_rounded), label: const Text('Nuevo Rol')),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        // Left: Role list
        SizedBox(width: 320, child: Container(
          decoration: BoxDecoration(color: AppColors.surface, border: Border(right: BorderSide(color: AppColors.divider))),
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(AppDimensions.md), child: Row(children: [
              Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Roles del Sistema', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            ])),
            const Divider(height: 1),
            Expanded(child: StreamBuilder<List<UserRole>>(
              stream: RoleService.rolesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final roles = snapshot.data ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  itemCount: roles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    final isEditing = _editingRole?.id == role.id;
                    final userCount = _roleCounts[role.id] ?? 0;
                    final permCount = role.permissions.values.where((p) => p != PermissionLevel.none).length;

                    return Card(
                      elevation: isEditing ? 2 : 0,
                      color: isEditing ? AppColors.primarySurface : AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        side: BorderSide(color: isEditing ? AppColors.primary : AppColors.divider),
                      ),
                      child: InkWell(
                        onTap: () => _editRole(role),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: role.id == 'admin' ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(role.id == 'admin' ? Icons.admin_panel_settings : Icons.shield_outlined,
                              color: role.id == 'admin' ? AppColors.warning : AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(role.label, style: AppTextStyles.labelLarge),
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.people_rounded, size: 12, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text('$userCount usuarios', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11)),
                              const SizedBox(width: 8),
                              Icon(Icons.key_rounded, size: 12, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text('$permCount módulos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11)),
                            ]),
                          ])),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 18, color: AppColors.textHint),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Editar')])),
                              const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy_rounded, size: 16), SizedBox(width: 8), Text('Duplicar')])),
                              if (role.id != 'admin')
                                const PopupMenuItem(value: 'delete', child: Row(children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error), SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: AppColors.error))])),
                            ],
                            onSelected: (v) {
                              if (v == 'edit') _editRole(role);
                              if (v == 'duplicate') _duplicateRole(role);
                              if (v == 'delete') _deleteRole(role);
                            },
                          ),
                        ])),
                      ),
                    );
                  },
                );
              },
            )),
          ]),
        )),

        // Right: Form + permissions matrix
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Icon(_editingRole == null ? Icons.add_circle_rounded : Icons.edit_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(_editingRole == null ? 'Crear Nuevo Rol' : 'Editar: ${_editingRole!.label}', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: AppDimensions.lg),

            // Name and ID
            Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
              child: Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Column(children: [
                TextFormField(controller: _labelCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Rol', hintText: 'Ej: Vendedor Senior', prefixIcon: Icon(Icons.badge_rounded)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: AppDimensions.md),
                TextFormField(controller: _idCtrl, enabled: _editingRole == null,
                  decoration: const InputDecoration(labelText: 'ID del Rol (único)', hintText: 'ej: vendedor_senior', prefixIcon: Icon(Icons.key_rounded)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              ]))),
            const SizedBox(height: AppDimensions.xl),

            // Permissions header with quick actions
            Row(children: [
              Text('Permisos por Módulo', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(onPressed: () => _setAllPermissions(PermissionLevel.total),
                icon: const Icon(Icons.check_circle_rounded, size: 16), label: const Text('Todo'),
                style: TextButton.styleFrom(foregroundColor: AppColors.success)),
              TextButton.icon(onPressed: () => _setAllPermissions(PermissionLevel.read),
                icon: const Icon(Icons.visibility_rounded, size: 16), label: const Text('Solo lectura'),
                style: TextButton.styleFrom(foregroundColor: AppColors.info)),
              TextButton.icon(onPressed: () => _setAllPermissions(PermissionLevel.none),
                icon: const Icon(Icons.block_rounded, size: 16), label: const Text('Ninguno'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error)),
            ]),
            const SizedBox(height: AppDimensions.md),

            // Permissions grid
            ...RoleAccess.allModules.map((module) {
              final level = _currentPermissions[module.id] ?? PermissionLevel.none;
              return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  side: BorderSide(color: level == PermissionLevel.none ? AppColors.divider : _permColor(level).withValues(alpha: 0.3))),
                color: level == PermissionLevel.none ? null : _permColor(level).withValues(alpha: 0.03),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Icon(_moduleIcon(module), size: 20, color: level == PermissionLevel.none ? AppColors.textHint : _permColor(level)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(module.title, style: AppTextStyles.labelLarge)),
                    SegmentedButton<PermissionLevel>(
                      segments: PermissionLevel.values.map((l) => ButtonSegment(value: l, label: Text(l.label, style: const TextStyle(fontSize: 12)))).toList(),
                      selected: {level},
                      onSelectionChanged: (s) => setState(() => _currentPermissions[module.id] = s.first),
                      style: ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ])),
              );
            }),
            const SizedBox(height: AppDimensions.xl),

            // Save button
            SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
              label: Text(_editingRole == null ? 'Crear Rol' : 'Guardar Cambios'),
            )),
          ])),
        )),
      ]),
    );
  }

  Color _permColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.none: return AppColors.textHint;
      case PermissionLevel.read: return AppColors.info;
      case PermissionLevel.edit: return AppColors.warning;
      case PermissionLevel.total: return AppColors.success;
    }
  }

  IconData _moduleIcon(AppModule module) {
    switch (module) {
      case AppModule.operatividad: return Icons.dashboard_customize_rounded;
      case AppModule.crm: return Icons.people_rounded;
      case AppModule.inventario: return Icons.inventory_2_rounded;
      case AppModule.ventas: return Icons.point_of_sale_rounded;
      case AppModule.marketing: return Icons.campaign_rounded;
      case AppModule.soporte: return Icons.support_agent_rounded;
      case AppModule.proyectos: return Icons.folder_special_rounded;
    }
  }

  Future<void> _deleteRole(UserRole role) async {
    // Check if role has users
    final count = await UserService.countUsersByRole(role.id);
    if (count > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se puede eliminar: $count usuario(s) tienen este rol. Reasígnalos primero.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rol'),
        content: Text('¿Estás seguro de eliminar el rol "${role.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await RoleService.deleteRole(role.id);
      _loadRoleCounts();
    }
  }
}
