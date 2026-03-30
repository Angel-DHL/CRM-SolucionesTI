// lib/inventory/pages/inventory_categories_page.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/inventory_category.dart';
import '../services/inventory_category_service.dart';
import '../widgets/cards/category_card.dart';
import '../widgets/forms/category_form.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/common/inventory_loading.dart';
import '../widgets/common/inventory_empty_state.dart';
import '../widgets/common/inventory_error_view.dart';

class InventoryCategoriesPage extends StatefulWidget {
  final UserRole role;

  const InventoryCategoriesPage({super.key, required this.role});

  @override
  State<InventoryCategoriesPage> createState() =>
      _InventoryCategoriesPageState();
}

class _InventoryCategoriesPageState extends State<InventoryCategoriesPage> {
  final _categoryService = InventoryCategoryService.instance;

  String _searchQuery = '';
  bool _showInactive = false;
  String? _selectedCategoryId;

  // Controla qué categorías están expandidas en la vista de árbol
  final Set<String> _expandedIds = {};

  bool get _isAdmin => widget.role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        // ═══════════════════════════════════════════════════════
        // BARRA SUPERIOR
        // ═══════════════════════════════════════════════════════
        _buildToolbar(isMobile),

        // ═══════════════════════════════════════════════════════
        // CONTENIDO
        // ═══════════════════════════════════════════════════════
        Expanded(
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOOLBAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildToolbar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Búsqueda
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar categoría...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),

          // Mostrar inactivas
          FilterChip(
            label: const Text('Inactivas'),
            selected: _showInactive,
            onSelected: (v) => setState(() => _showInactive = v),
            avatar: Icon(
              Icons.visibility_off_rounded,
              size: 16,
              color: _showInactive ? AppColors.primary : AppColors.textHint,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),

          // Expandir / Colapsar todo
          IconButton(
            onPressed: _toggleExpandAll,
            tooltip: _expandedIds.isEmpty ? 'Expandir todo' : 'Colapsar todo',
            icon: Icon(
              _expandedIds.isEmpty
                  ? Icons.unfold_more_rounded
                  : Icons.unfold_less_rounded,
            ),
          ),

          // Botón crear
          if (_isAdmin) ...[
            const SizedBox(width: AppDimensions.sm),
            FilledButton.icon(
              onPressed: () => _showCategoryForm(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: isMobile
                  ? const SizedBox.shrink()
                  : const Text('Nueva Categoría'),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LAYOUTS
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return _buildCategoryTree();
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Árbol de categorías
        Expanded(flex: 3, child: _buildCategoryTree()),

        // Panel lateral de detalle
        if (_selectedCategoryId != null)
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(left: BorderSide(color: AppColors.divider)),
            ),
            child: _buildDetailPanel(),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ÁRBOL DE CATEGORÍAS
  // ═══════════════════════════════════════════════════════════

  Widget _buildCategoryTree() {
    return StreamBuilder<List<InventoryCategory>>(
      stream: _categoryService.streamCategories(activeOnly: !_showInactive),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InventoryLoading(message: 'Cargando categorías...');
        }

        if (snapshot.hasError) {
          return InventoryErrorView.loadError(
            errorMessage: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final allCategories = snapshot.data ?? [];

        if (allCategories.isEmpty) {
          return InventoryEmptyState.categories(
            onAddCategory: _isAdmin ? () => _showCategoryForm(context) : null,
          );
        }

        // Filtrar por búsqueda
        final filtered = _searchQuery.isEmpty
            ? allCategories
            : allCategories.where((c) {
                final q = _searchQuery.toLowerCase();
                return c.name.toLowerCase().contains(q) ||
                    (c.description?.toLowerCase().contains(q) ?? false);
              }).toList();

        if (filtered.isEmpty) {
          return InventoryEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Sin resultados',
            subtitle: 'No hay categorías que coincidan con "$_searchQuery"',
          );
        }

        // Agrupar: raíz y luego hijas por parentId
        final rootCategories = filtered
            .where((c) => c.parentId == null)
            .toList();
        final childrenMap = <String, List<InventoryCategory>>{};
        for (final c in filtered.where((c) => c.parentId != null)) {
          childrenMap.putIfAbsent(c.parentId!, () => []).add(c);
        }

        // ✅ CORRECCIÓN: Usar CustomScrollView en lugar de ListView.builder
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildCategoryNode(
                      rootCategories[index],
                      childrenMap,
                      allCategories,
                    );
                  }, childCount: rootCategories.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryNode(
    InventoryCategory category,
    Map<String, List<InventoryCategory>> childrenMap,
    List<InventoryCategory> allCategories,
  ) {
    final children = childrenMap[category.id] ?? [];
    final isExpanded = _expandedIds.contains(category.id);
    final hasChildren = children.isNotEmpty;

    // ✅ Usar Column con crossAxisAlignment en lugar de Stack
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ IMPORTANTE
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta de la categoría
        Padding(
          padding: EdgeInsets.only(left: category.level * 24.0),
          child: Row(
            children: [
              // Botón expandir
              if (hasChildren)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIds.remove(category.id);
                      } else {
                        _expandedIds.add(category.id);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),

              // Card
              Expanded(
                child: CategoryCard(
                  category: category,
                  compact: true,
                  isSelected: _selectedCategoryId == category.id,
                  showActions: _isAdmin,
                  onTap: () {
                    setState(() => _selectedCategoryId = category.id);
                    if (hasChildren) {
                      setState(() {
                        if (isExpanded) {
                          _expandedIds.remove(category.id);
                        } else {
                          _expandedIds.add(category.id);
                        }
                      });
                    }
                  },
                  onEdit: _isAdmin
                      ? () => _showCategoryForm(context, category: category)
                      : null,
                  onDelete: _isAdmin ? () => _confirmDelete(category) : null,
                ),
              ),
            ],
          ),
        ),

        // Hijos expandidos
        if (isExpanded && hasChildren)
          // ✅ Usar spread operator directamente sin Column adicional
          ...children.map(
            (child) => _buildCategoryNode(child, childrenMap, allCategories),
          ),
      ],
    );
  }
  // ═══════════════════════════════════════════════════════════
  // PANEL LATERAL DE DETALLE
  // ═══════════════════════════════════════════════════════════

  Widget _buildDetailPanel() {
    return FutureBuilder<InventoryCategory?>(
      future: _categoryService.getCategoryById(_selectedCategoryId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const InventoryLoading(fullScreen: false);
        }

        final category = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cerrar
              Row(
                children: [
                  Text('Detalle', style: AppTextStyles.h4),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _selectedCategoryId = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppDimensions.md),

              // Icono y nombre
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: category.color.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Icon(
                        category.icon.icon,
                        color: category.color.color,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      category.name,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    if (category.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppDimensions.xs),
                        child: Text(
                          category.description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Estadísticas
              _DetailStatRow(
                label: 'Items',
                value: '${category.itemCount}',
                icon: Icons.inventory_2_rounded,
              ),
              _DetailStatRow(
                label: 'Subcategorías',
                value: '${category.childCategoryCount}',
                icon: Icons.folder_rounded,
              ),
              _DetailStatRow(
                label: 'Nivel',
                value: '${category.level}',
                icon: Icons.layers_rounded,
              ),
              _DetailStatRow(
                label: 'Ruta',
                value: category.fullPath,
                icon: Icons.route_rounded,
              ),
              _DetailStatRow(
                label: 'Estado',
                value: category.isActive ? 'Activa' : 'Inactiva',
                icon: Icons.circle,
                valueColor: category.isActive
                    ? AppColors.success
                    : AppColors.error,
              ),

              const SizedBox(height: AppDimensions.lg),

              // Tipos permitidos
              Text(
                'Tipos permitidos',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Wrap(
                spacing: AppDimensions.sm,
                children: [
                  if (category.allowProducts)
                    const Chip(
                      avatar: Icon(Icons.inventory_2_rounded, size: 16),
                      label: Text('Productos'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (category.allowServices)
                    const Chip(
                      avatar: Icon(
                        Icons.miscellaneous_services_rounded,
                        size: 16,
                      ),
                      label: Text('Servicios'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (category.allowAssets)
                    const Chip(
                      avatar: Icon(Icons.business_center_rounded, size: 16),
                      label: Text('Activos'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.xl),

              // Acciones
              if (_isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCategoryForm(
                      context,
                      parentCategoryId: category.id,
                    ),
                    icon: const Icon(Icons.create_new_folder_rounded),
                    label: const Text('Crear subcategoría'),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showCategoryForm(context, category: category),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar categoría'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════

  void _toggleExpandAll() {
    setState(() {
      if (_expandedIds.isEmpty) {
        // Expandir todo: obtener todos los IDs que tienen hijos
        // Usamos un FutureBuilder arriba, aquí simplemente
        // marcamos un "expandAll" flag
        _expandedIds.add('__all__');
      } else {
        _expandedIds.clear();
      }
    });
  }

  void _showCategoryForm(
    BuildContext context, {
    InventoryCategory? category,
    String? parentCategoryId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => CategoryForm(
          category: category,
          parentCategoryId: parentCategoryId,
          onSaved: () {
            Navigator.pop(context);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  category != null
                      ? 'Categoría actualizada'
                      : 'Categoría creada',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(InventoryCategory category) async {
    if (category.hasChildren || category.hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar: tiene subcategorías o items'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ConfirmDeleteDialog.show(
      context,
      title: 'Eliminar categoría',
      message: '¿Estás seguro de eliminar esta categoría?',
      itemName: category.name,
      onConfirm: () async {
        await _categoryService.deleteCategory(category.id);
        if (mounted) {
          setState(() {
            if (_selectedCategoryId == category.id) {
              _selectedCategoryId = null;
            }
          });
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════

class _DetailStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailStatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
