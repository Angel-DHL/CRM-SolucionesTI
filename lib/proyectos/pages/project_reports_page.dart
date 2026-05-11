// lib/proyectos/pages/project_reports_page.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../services/project_report_service.dart';

class ProjectReportsPage extends StatefulWidget {
  final UserRole role;
  const ProjectReportsPage({super.key, required this.role});

  @override
  State<ProjectReportsPage> createState() => _ProjectReportsPageState();
}

class _ProjectReportsPageState extends State<ProjectReportsPage> {
  ProjectReportType _selectedReport = ProjectReportType.resumenEjecutivo;
  String? _selectedProjectId;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Selector de reporte
        Text('Tipo de Reporte', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppDimensions.md),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: ProjectReportType.values.map((type) => _ReportTypeCard(
            type: type,
            isSelected: _selectedReport == type,
            onTap: () => setState(() => _selectedReport = type),
          )).toList(),
        ),
        const SizedBox(height: AppDimensions.xl),

        // Selector de proyecto (si aplica)
        if (_selectedReport != ProjectReportType.listadoProyectos) ...[
          Text('Seleccionar Proyecto', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDimensions.md),
          StreamBuilder<List<Project>>(
            stream: ProjectService.instance.streamProjects(),
            builder: (ctx, snap) {
              final projects = snap.data ?? [];
              return DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'Proyecto',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
                items: projects.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.folio} — ${p.nombre}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => _selectedProjectId = v),
              );
            },
          ),
          const SizedBox(height: AppDimensions.xl),
        ],

        // Botón generar
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _canGenerate() ? _generate : null,
            icon: _generating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_generating ? 'Generando...' : 'Generar Reporte PDF'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppDimensions.md),

        // Info del reporte
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selectedReport.label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(_getReportDescription(_selectedReport), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ])),
          ]),
        ),
      ]),
    );
  }

  bool _canGenerate() {
    if (_generating) return false;
    if (_selectedReport == ProjectReportType.listadoProyectos) return true;
    return _selectedProjectId != null;
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final bytes = await ProjectReportService.instance.generateReport(
        _selectedReport,
        projectId: _selectedProjectId,
      );
      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) => bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar reporte: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _getReportDescription(ProjectReportType type) => switch (type) {
    ProjectReportType.fichaProyecto => 'Datos completos del proyecto: cliente, equipo, progreso, financieros y materiales.',
    ProjectReportType.estadoFinanciero => 'Desglose de ingresos, egresos, rentabilidad e indicadores financieros.',
    ProjectReportType.cronogramaTareas => 'Tabla completa de tareas con responsables, fechas y progreso.',
    ProjectReportType.historialTransacciones => 'Listado detallado de todas las transacciones financieras.',
    ProjectReportType.resumenEjecutivo => 'Resumen de KPIs para presentar al cliente o dirección.',
    ProjectReportType.listadoProyectos => 'Tabla de todos los proyectos con estado, valor y progreso.',
  };
}

class _ReportTypeCard extends StatelessWidget {
  final ProjectReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportTypeCard({required this.type, required this.isSelected, required this.onTap});

  IconData get _icon => switch (type) {
    ProjectReportType.fichaProyecto => Icons.description_rounded,
    ProjectReportType.estadoFinanciero => Icons.account_balance_rounded,
    ProjectReportType.cronogramaTareas => Icons.view_timeline_rounded,
    ProjectReportType.historialTransacciones => Icons.receipt_long_rounded,
    ProjectReportType.resumenEjecutivo => Icons.summarize_rounded,
    ProjectReportType.listadoProyectos => Icons.list_alt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primarySurface : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 2 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_icon, size: 28, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(type.label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
