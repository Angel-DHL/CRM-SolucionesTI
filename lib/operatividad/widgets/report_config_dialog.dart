// lib/operatividad/widgets/report_config_dialog.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/oper_activity.dart';
import '../services/pdf_report_service.dart';

class ReportConfigDialog extends StatefulWidget {
  final List<OperActivity> activities;

  const ReportConfigDialog({super.key, required this.activities});

  @override
  State<ReportConfigDialog> createState() => _ReportConfigDialogState();
}

class _ReportConfigDialogState extends State<ReportConfigDialog> {
  ReportPeriod _selectedPeriod = ReportPeriod.weekly;
  DateTime _customStart = DateTime.now().subtract(const Duration(days: 7));
  DateTime _customEnd = DateTime.now();

  bool _includeCharts = true;
  bool _includeDetails = true;
  bool _includeCollaborators = true;
  bool _generating = false;

  ReportConfig get _config {
    switch (_selectedPeriod) {
      case ReportPeriod.weekly:
        return ReportConfig.weekly();
      case ReportPeriod.monthly:
        return ReportConfig.monthly();
      case ReportPeriod.custom:
        return ReportConfig.custom(
          startDate: _customStart,
          endDate: _customEnd,
        );
    }
  }

  Future<void> _generate({bool share = false}) async {
    if (!mounted) return;
    setState(() => _generating = true);

    try {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';

      final config = ReportConfig(
        period: _selectedPeriod,
        startDate: _config.startDate,
        endDate: _config.endDate,
        title: _config.title,
        includeCharts: _includeCharts,
        includeDetails: _includeDetails,
        includeCollaborators: _includeCollaborators,
      );

      if (share) {
        await PdfReportService.generateAndShare(
          allActivities: widget.activities,
          config: config,
          generatedByEmail: email,
        );
      } else {
        await PdfReportService.generateAndPrint(
          allActivities: widget.activities,
          config: config,
          generatedByEmail: email,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar reporte: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _customStart : _customEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    setState(() {
      if (isStart) {
        _customStart = date;
        if (_customEnd.isBefore(_customStart)) {
          _customEnd = _customStart.add(const Duration(days: 7));
        }
      } else {
        _customEnd = date;
        if (_customEnd.isBefore(_customStart)) {
          _customStart = _customEnd.subtract(const Duration(days: 7));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generar reporte',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Configura y descarga tu reporte PDF',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textHint,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.xl),

              // Período
              Text(
                'Período del reporte',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),

              // Period options
              Wrap(
                spacing: AppDimensions.sm,
                children: [
                  _PeriodChip(
                    label: 'Semanal',
                    icon: Icons.view_week_rounded,
                    isSelected: _selectedPeriod == ReportPeriod.weekly,
                    onTap: () =>
                        setState(() => _selectedPeriod = ReportPeriod.weekly),
                  ),
                  _PeriodChip(
                    label: 'Mensual',
                    icon: Icons.calendar_month_rounded,
                    isSelected: _selectedPeriod == ReportPeriod.monthly,
                    onTap: () =>
                        setState(() => _selectedPeriod = ReportPeriod.monthly),
                  ),
                  _PeriodChip(
                    label: 'Personalizado',
                    icon: Icons.tune_rounded,
                    isSelected: _selectedPeriod == ReportPeriod.custom,
                    onTap: () =>
                        setState(() => _selectedPeriod = ReportPeriod.custom),
                  ),
                ],
              ),

              // Custom date range
              if (_selectedPeriod == ReportPeriod.custom) ...[
                const SizedBox(height: AppDimensions.md),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: true),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.md),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desde',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                              Text(
                                dateFormat.format(_customStart),
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.md),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hasta',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                              Text(
                                dateFormat.format(_customEnd),
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Preview del rango
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      color: AppColors.info,
                      size: 18,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        '${dateFormat.format(_config.startDate)} - ${dateFormat.format(_config.endDate)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.xl),

              // Opciones
              Text(
                'Incluir en el reporte',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),

              _ToggleOption(
                icon: Icons.table_chart_rounded,
                label: 'Detalle de actividades',
                subtitle: 'Tabla completa con todas las actividades',
                value: _includeDetails,
                onChanged: (v) => setState(() => _includeDetails = v),
              ),
              _ToggleOption(
                icon: Icons.people_rounded,
                label: 'Análisis por colaborador',
                subtitle: 'Rendimiento individual de cada persona',
                value: _includeCollaborators,
                onChanged: (v) => setState(() => _includeCollaborators = v),
              ),

              const SizedBox(height: AppDimensions.xl),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generating
                          ? null
                          : () => _generate(share: true),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Compartir'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _generating ? null : () => _generate(),
                      icon: _generating
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(_generating ? 'Generando...' : 'Generar PDF'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDimensions.animFast,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.xs),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: value ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: value
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: value ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: value
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
