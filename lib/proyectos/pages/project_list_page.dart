// lib/proyectos/pages/project_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/project.dart';
import '../models/project_enums.dart';
import '../services/project_service.dart';
import 'project_form_page.dart';
import 'project_detail_page.dart';

class ProjectListPage extends StatefulWidget {
  final UserRole role;
  const ProjectListPage({super.key, required this.role});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  final _searchController = TextEditingController();
  ProjectStatus? _statusFilter;
  ProjectType? _typeFilter;
  ProjectPriority? _priorityFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ProjectFilters get _filters => ProjectFilters(
    status: _statusFilter,
    type: _typeFilter,
    priority: _priorityFilter,
    searchQuery: _searchController.text,
  );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildFilters(),
      Expanded(child: _buildList()),
    ]);
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Wrap(
        spacing: AppDimensions.sm,
        runSpacing: AppDimensions.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar proyectos...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide(color: AppColors.border)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          _buildFilterChip<ProjectStatus>(
            label: 'Estado', value: _statusFilter,
            items: ProjectStatus.values, getLabel: (s) => s.label,
            onChanged: (v) => setState(() => _statusFilter = v),
          ),
          _buildFilterChip<ProjectType>(
            label: 'Tipo', value: _typeFilter,
            items: ProjectType.values, getLabel: (t) => t.label,
            onChanged: (v) => setState(() => _typeFilter = v),
          ),
          _buildFilterChip<ProjectPriority>(
            label: 'Prioridad', value: _priorityFilter,
            items: ProjectPriority.values, getLabel: (p) => p.label,
            onChanged: (v) => setState(() => _priorityFilter = v),
          ),
          if (_statusFilter != null || _typeFilter != null || _priorityFilter != null)
            TextButton.icon(
              onPressed: () => setState(() { _statusFilter = null; _typeFilter = null; _priorityFilter = null; }),
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Limpiar'),
            ),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectFormPage())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nuevo Proyecto'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip<T>({
    required String label, required T? value,
    required List<T> items, required String Function(T) getLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return PopupMenuButton<T?>(
      onSelected: onChanged,
      initialValue: value,
      itemBuilder: (ctx) => [
        PopupMenuItem<T?>(value: null, child: Text('Todos')),
        ...items.map((i) => PopupMenuItem<T?>(value: i, child: Text(getLabel(i)))),
      ],
      child: Chip(
        label: Text(value != null ? getLabel(value) : label),
        avatar: value != null ? const Icon(Icons.check, size: 14) : null,
        deleteIcon: value != null ? const Icon(Icons.close, size: 14) : null,
        onDeleted: value != null ? () => onChanged(null) : null,
        backgroundColor: value != null ? AppColors.primarySurface : null,
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<Project>>(
      stream: ProjectService.instance.streamProjects(filters: _filters),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error al cargar proyectos', style: AppTextStyles.h4),
                const SizedBox(height: 8),
                Text(snap.error.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = snap.data ?? [];
        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No se encontraron proyectos', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: projects.length,
          itemBuilder: (ctx, i) => _ProjectCard(
            project: projects[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: projects[i].id))),
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final df = DateFormat('dd MMM yyyy', 'es_MX');

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: project.estaAtrasado ? AppColors.error.withOpacity(0.3) : AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: project.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(project.status.icon, size: 14, color: project.status.color),
                    const SizedBox(width: 4),
                    Text(project.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: project.status.color)),
                  ]),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: project.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(project.type.label, style: TextStyle(fontSize: 10, color: project.type.color, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                Text(project.folio, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: AppDimensions.sm),

              // Title
              Text(project.nombre, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.person_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(child: Text(project.clienteNombre, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (project.fechaFinEstimada != null) ...[
                  Icon(Icons.calendar_today_rounded, size: 12, color: project.estaAtrasado ? AppColors.error : AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(df.format(project.fechaFinEstimada!), style: TextStyle(fontSize: 11, color: project.estaAtrasado ? AppColors.error : AppColors.textHint)),
                ],
              ]),
              const SizedBox(height: AppDimensions.sm),

              // Progress bar
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progreso / 100,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(project.salud.color),
                    minHeight: 6,
                  ),
                )),
                const SizedBox(width: AppDimensions.sm),
                Text('${project.progreso}%', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
              const SizedBox(height: AppDimensions.sm),

              // Footer
              Row(children: [
                Icon(Icons.attach_money_rounded, size: 14, color: AppColors.textHint),
                Text(nf.format(project.valorProyecto), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(project.priority.icon, size: 14, color: project.priority.color),
                const SizedBox(width: 4),
                Text(project.priority.label, style: TextStyle(fontSize: 11, color: project.priority.color)),
                const SizedBox(width: AppDimensions.md),
                Icon(Icons.task_alt_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text('${project.tareasCompletadas}/${project.tareasTotal}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
