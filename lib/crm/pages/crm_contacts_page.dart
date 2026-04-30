// lib/crm/pages/crm_contacts_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/crm_contact.dart';
import '../models/crm_enums.dart';
import '../services/crm_service.dart';
import '../widgets/crm_contact_card.dart';
import '../widgets/crm_pipeline_board.dart';
import 'crm_contact_detail_page.dart';
import 'crm_contact_form_page.dart';

enum _ViewMode { list, pipeline }

class CrmContactsPage extends StatefulWidget {
  final UserRole role;

  const CrmContactsPage({super.key, required this.role});

  @override
  State<CrmContactsPage> createState() => _CrmContactsPageState();
}

class _CrmContactsPageState extends State<CrmContactsPage> {
  _ViewMode _viewMode = _ViewMode.list;
  ContactStatus? _statusFilter;
  ContactSource? _sourceFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _sourceFilter = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  CrmFilters get _filters => CrmFilters(
    searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    status: _statusFilter,
    source: _sourceFilter,
  );

  bool get _hasActiveFilters =>
      _statusFilter != null || _sourceFilter != null || _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        // ═══ TOOLBAR ═══
        _buildToolbar(isMobile),

        // ═══ CONTENT ═══
        Expanded(
          child: StreamBuilder<List<CrmContact>>(
            stream: CrmService.instance.streamContacts(filters: _filters),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'Error cargando contactos',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                      ),
                      Text(
                        '${snapshot.error}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                );
              }

              final contacts = snapshot.data ?? [];

              if (contacts.isEmpty) {
                return _buildEmptyState();
              }

              if (_viewMode == _ViewMode.pipeline) {
                return CrmPipelineBoard(
                  contacts: contacts,
                  onContactTap: (c) => _openContactDetail(c),
                );
              }

              return _buildListView(contacts, isMobile);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppDimensions.sm : AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar contactos...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.sm),

              // View toggle
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewToggle(
                      icon: Icons.list_rounded,
                      isSelected: _viewMode == _ViewMode.list,
                      onTap: () => setState(() => _viewMode = _ViewMode.list),
                    ),
                    _ViewToggle(
                      icon: Icons.view_kanban_rounded,
                      isSelected: _viewMode == _ViewMode.pipeline,
                      onTap: () => setState(() => _viewMode = _ViewMode.pipeline),
                    ),
                  ],
                ),
              ),

              if (!isMobile) ...[
                const SizedBox(width: AppDimensions.sm),

                // Create button
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CrmContactFormPage()),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Nuevo contacto'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimensions.sm),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filter
                _FilterChip(
                  label: _statusFilter?.label ?? 'Estatus',
                  isActive: _statusFilter != null,
                  onTap: () => _showStatusFilter(context),
                ),
                const SizedBox(width: AppDimensions.sm),

                // Source filter
                _FilterChip(
                  label: _sourceFilter?.label ?? 'Fuente',
                  isActive: _sourceFilter != null,
                  onTap: () => _showSourceFilter(context),
                ),

                if (_hasActiveFilters) ...[
                  const SizedBox(width: AppDimensions.sm),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<CrmContact> contacts, bool isMobile) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? AppDimensions.sm : AppDimensions.md),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: CrmContactCard(
            contact: contact,
            compact: isMobile,
            onTap: () => _openContactDetail(contact),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasActiveFilters ? Icons.filter_list_off_rounded : Icons.people_outline_rounded,
              size: 64,
              color: AppColors.textHint.withOpacity(0.4),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              _hasActiveFilters
                  ? 'No se encontraron contactos'
                  : 'Sin contactos aún',
              style: AppTextStyles.h3.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              _hasActiveFilters
                  ? 'Intenta ajustar los filtros de búsqueda'
                  : 'Convierte leads o crea contactos manualmente',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: AppDimensions.lg),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openContactDetail(CrmContact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrmContactDetailPage(contactId: contact.id),
      ),
    );
  }

  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Text('Filtrar por estatus', style: AppTextStyles.h4),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.all_inclusive_rounded),
                    title: const Text('Todos'),
                    selected: _statusFilter == null,
                    onTap: () {
                      setState(() => _statusFilter = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...ContactStatus.values.map((s) {
                    return ListTile(
                      leading: Text(s.emoji, style: const TextStyle(fontSize: 20)),
                      title: Text(s.label),
                      selected: _statusFilter == s,
                      onTap: () {
                        setState(() => _statusFilter = s);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const SizedBox(height: AppDimensions.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSourceFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Text('Filtrar por fuente', style: AppTextStyles.h4),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.all_inclusive_rounded),
                    title: const Text('Todas'),
                    selected: _sourceFilter == null,
                    onTap: () {
                      setState(() => _sourceFilter = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...ContactSource.values.map((s) {
                    return ListTile(
                      title: Text(s.label),
                      selected: _sourceFilter == s,
                      onTap: () {
                        setState(() => _sourceFilter = s);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const SizedBox(height: AppDimensions.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}


// ══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Container(
          width: 40,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.primarySurface : AppColors.background,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
