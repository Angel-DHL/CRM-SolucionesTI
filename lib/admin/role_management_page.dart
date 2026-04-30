import 'package:flutter/material.dart';
import '../core/role.dart';
import '../core/role_access.dart';
import '../core/services/role_service.dart';
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

  @override
  void initState() {
    super.initState();
    _resetForm();
  }

  void _resetForm() {
    _editingRole = null;
    _labelCtrl.clear();
    _idCtrl.clear();
    _currentPermissions = {
      for (var m in RoleAccess.allModules) m.id: PermissionLevel.none
    };
    setState(() {});
  }

  void _editRole(UserRole role) {
    _editingRole = role;
    _labelCtrl.text = role.label;
    _idCtrl.text = role.id;
    _currentPermissions = Map.from(role.permissions);
    // Asegurar que todos los módulos estén presentes
    for (var m in RoleAccess.allModules) {
      _currentPermissions.putIfAbsent(m.id, () => PermissionLevel.none);
    }
    setState(() {});
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol guardado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles'),
        actions: [
          if (_editingRole != null)
            IconButton(
              onPressed: _resetForm,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Nuevo Rol',
            ),
        ],
      ),
      body: Row(
        children: [
          // Lista de Roles
          Expanded(
            flex: 2,
            child: StreamBuilder<List<UserRole>>(
              stream: RoleService.rolesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final roles = snapshot.data ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  itemCount: roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    final isEditing = _editingRole?.id == role.id;
                    return Card(
                      elevation: isEditing ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        side: BorderSide(
                          color: isEditing ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: ListTile(
                        title: Text(role.label, style: AppTextStyles.labelLarge),
                        subtitle: Text(role.id, style: AppTextStyles.bodySmall),
                        trailing: role.id == 'admin' 
                          ? const Icon(Icons.lock_rounded, size: 18, color: Colors.grey)
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => _deleteRole(role),
                            ),
                        onTap: () => _editRole(role),
                        selected: isEditing,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const VerticalDivider(width: 1),

          // Formulario y Matriz
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingRole == null ? 'Crear Nuevo Rol' : 'Editar Rol',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    TextFormField(
                      controller: _labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Rol',
                        hintText: 'Ej: Vendedor Senior',
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    TextFormField(
                      controller: _idCtrl,
                      enabled: _editingRole == null,
                      decoration: const InputDecoration(
                        labelText: 'ID del Rol',
                        hintText: 'ej: vendedor_senior',
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    Text('Permisos por Módulo', style: AppTextStyles.h3),
                    const SizedBox(height: AppDimensions.md),
                    _buildPermissionsMatrix(),
                    const SizedBox(height: AppDimensions.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _save,
                        child: _loading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar Rol'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsMatrix() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppColors.background),
            children: [
              _buildCell('Módulo', isHeader: true),
              _buildCell('Nivel de Acceso', isHeader: true),
            ],
          ),
          for (var module in RoleAccess.allModules)
            TableRow(
              children: [
                _buildCell(module.title),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton<PermissionLevel>(
                    value: _currentPermissions[module.id] ?? PermissionLevel.none,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: PermissionLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level.label, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (level) {
                      if (level != null) {
                        setState(() => _currentPermissions[module.id] = level);
                      }
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: isHeader ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
      ),
    );
  }

  Future<void> _deleteRole(UserRole role) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rol'),
        content: Text('¿Estás seguro de eliminar el rol "${role.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RoleService.deleteRole(role.id);
    }
  }
}
