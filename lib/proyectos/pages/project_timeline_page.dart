// lib/proyectos/pages/project_timeline_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/project.dart';
import '../models/project_audit_log.dart';
import '../services/project_service.dart';

class ProjectTimelinePage extends StatefulWidget {
  final UserRole role;
  const ProjectTimelinePage({super.key, required this.role});

  @override
  State<ProjectTimelinePage> createState() => _ProjectTimelinePageState();
}

class _ProjectTimelinePageState extends State<ProjectTimelinePage> {
  String? _selectedProjectId; // null = todos los proyectos

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildProjectFilter(),
      Expanded(child: _buildTimeline()),
    ]);
  }

  Widget _buildProjectFilter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: StreamBuilder<List<Project>>(
        stream: ProjectService.instance.streamProjects(),
        builder: (ctx, snap) {
          final projects = snap.data ?? [];
          return Row(children: [
            const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por proyecto',
                  prefixIcon: Icon(Icons.folder_rounded),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos los proyectos', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  ...projects.map((p) => DropdownMenuItem<String?>(
                    value: p.id,
                    child: Text('${p.folio} — ${p.nombre}', overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
            ),
            if (_selectedProjectId != null) ...[
              const SizedBox(width: AppDimensions.sm),
              IconButton(
                onPressed: () => setState(() => _selectedProjectId = null),
                icon: const Icon(Icons.clear_rounded, size: 18),
                tooltip: 'Limpiar filtro',
                style: IconButton.styleFrom(backgroundColor: AppColors.primarySurface),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _buildTimeline() {
    return StreamBuilder<List<ProjectAuditLog>>(
      stream: ProjectService.instance.streamAuditLogs(
        projectId: _selectedProjectId,
        limit: 100,
      ),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.timeline_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: AppDimensions.md),
            Text(
              _selectedProjectId != null
                  ? 'Sin actividad registrada para este proyecto'
                  : 'Sin actividad registrada',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            ),
          ]));
        }

        // Agrupar por fecha
        final grouped = <String, List<ProjectAuditLog>>{};
        for (final log in logs) {
          final key = DateFormat('dd MMMM yyyy', 'es_MX').format(log.timestamp);
          grouped.putIfAbsent(key, () => []).add(log);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.lg),
          itemCount: grouped.length,
          itemBuilder: (ctx, i) {
            final date = grouped.keys.elementAt(i);
            final dayLogs = grouped[date]!;

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Date header
              Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.sm, top: AppDimensions.md),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(date, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              // Day logs
              ...dayLogs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Timeline connector
                  SizedBox(width: 40, child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: log.actionColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(log.actionIcon, size: 14, color: log.actionColor),
                    ),
                  ])),
                  // Content
                  Expanded(child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(log.actionDescription, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500))),
                        Text(DateFormat('HH:mm').format(log.timestamp), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                      ]),
                      if (log.details != null && log.details!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(log.details!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.person_rounded, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(log.userDisplayName, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          if (log.projectName != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.folder_rounded, size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Flexible(child: Text(log.projectName!, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis)),
                          ],
                        ]),
                      ),
                    ]),
                  )),
                ]),
              )),
            ]);
          },
        );
      },
    );
  }
}
