// lib/operatividad/services/pdf_report_service.dart

import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../models/oper_activity.dart';

enum ReportPeriod { weekly, monthly, custom }

class ReportConfig {
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final bool includeCharts;
  final bool includeDetails;
  final bool includeCollaborators;

  const ReportConfig({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.title,
    this.includeCharts = true,
    this.includeDetails = true,
    this.includeCollaborators = true,
  });

  factory ReportConfig.weekly() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return ReportConfig(
      period: ReportPeriod.weekly,
      startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      endDate: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
      title: 'Reporte Semanal de Operatividad',
    );
  }

  factory ReportConfig.monthly() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return ReportConfig(
      period: ReportPeriod.monthly,
      startDate: monthStart,
      endDate: monthEnd,
      title: 'Reporte Mensual de Operatividad',
    );
  }

  factory ReportConfig.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return ReportConfig(
      period: ReportPeriod.custom,
      startDate: startDate,
      endDate: endDate,
      title: 'Reporte de Operatividad',
    );
  }
}

class PdfReportService {
  // Colores del tema convertidos a PdfColor
  static final _primaryColor = PdfColor.fromInt(AppColors.primary.value);
  static final _primaryDark = PdfColor.fromInt(AppColors.primaryDark.value);
  static final _primaryLight = PdfColor.fromInt(AppColors.primaryLight.value);
  static final _successColor = PdfColor.fromInt(AppColors.success.value);
  static final _warningColor = PdfColor.fromInt(AppColors.warning.value);
  static final _errorColor = PdfColor.fromInt(AppColors.error.value);
  static final _infoColor = PdfColor.fromInt(AppColors.info.value);
  static final _textPrimary = PdfColor.fromInt(AppColors.textPrimary.value);
  static final _textSecondary = PdfColor.fromInt(AppColors.textSecondary.value);
  static final _textHint = PdfColor.fromInt(AppColors.textHint.value);
  static final _divider = PdfColor.fromInt(AppColors.divider.value);
  static final _background = PdfColor.fromInt(AppColors.background.value);
  static final _surface = PdfColors.white;

  /// Genera y muestra el diálogo de impresión/descarga del PDF
  static Future<void> generateAndPrint({
    required List<OperActivity> allActivities,
    required ReportConfig config,
    required String generatedByEmail,
  }) async {
    final pdfData = await _buildReport(
      allActivities: allActivities,
      config: config,
      generatedByEmail: generatedByEmail,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: _getFileName(config),
    );
  }

  /// Genera y comparte el PDF
  static Future<void> generateAndShare({
    required List<OperActivity> allActivities,
    required ReportConfig config,
    required String generatedByEmail,
  }) async {
    final pdfData = await _buildReport(
      allActivities: allActivities,
      config: config,
      generatedByEmail: generatedByEmail,
    );

    await Printing.sharePdf(bytes: pdfData, filename: _getFileName(config));
  }

  static String _getFileName(ReportConfig config) {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    switch (config.period) {
      case ReportPeriod.weekly:
        return 'reporte_semanal_$dateStr.pdf';
      case ReportPeriod.monthly:
        return 'reporte_mensual_$dateStr.pdf';
      case ReportPeriod.custom:
        return 'reporte_operatividad_$dateStr.pdf';
    }
  }

  /// Construye el documento PDF completo
  static Future<Uint8List> _buildReport({
    required List<OperActivity> allActivities,
    required ReportConfig config,
    required String generatedByEmail,
  }) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
        boldItalic: await PdfGoogleFonts.nunitoBoldItalic(),
        italic: await PdfGoogleFonts.nunitoItalic(),
      ),
    );

    // Filtrar actividades del período
    final activities = _filterByPeriod(allActivities, config);

    // Calcular estadísticas
    final stats = _calculateStats(activities, allActivities);

    // Página 1: Portada + Resumen ejecutivo
    doc.addPage(_buildCoverPage(config, stats, generatedByEmail));

    // Página 2: KPIs y distribución
    doc.addPage(_buildKPIsPage(config, stats, activities));

    // Página 3: Análisis por colaborador
    if (config.includeCollaborators) {
      doc.addPage(_buildCollaboratorsPage(config, activities));
    }

    // Página 4+: Detalle de actividades
    if (config.includeDetails) {
      final detailPages = _buildDetailPages(config, activities);
      for (final page in detailPages) {
        doc.addPage(page);
      }
    }

    return doc.save();
  }

  // ══════════════════════════════════════════════════════════
  // FILTROS Y CÁLCULOS
  // ══════════════════════════════════════════════════════════

  static List<OperActivity> _filterByPeriod(
    List<OperActivity> activities,
    ReportConfig config,
  ) {
    return activities.where((a) {
      // Incluir si la actividad se solapa con el período
      return a.plannedStartAt.isBefore(config.endDate) &&
          a.plannedEndAt.isAfter(config.startDate);
    }).toList()..sort((a, b) => a.plannedStartAt.compareTo(b.plannedStartAt));
  }

  static _ReportStats _calculateStats(
    List<OperActivity> periodActivities,
    List<OperActivity> allActivities,
  ) {
    final total = periodActivities.length;

    final completed = periodActivities
        .where(
          (a) => a.status == OperStatus.done || a.status == OperStatus.verified,
        )
        .length;

    final inProgress = periodActivities
        .where((a) => a.status == OperStatus.inProgress)
        .length;

    final planned = periodActivities
        .where((a) => a.status == OperStatus.planned)
        .length;

    final blocked = periodActivities
        .where((a) => a.status == OperStatus.blocked)
        .length;

    final overdue = periodActivities.where((a) => a.isOverdue).length;

    // Horas
    double totalEstimatedHours = 0;
    double totalActualHours = 0;

    for (final a in periodActivities) {
      totalEstimatedHours += a.estimatedHours;
      if (a.workDurationHours != null) {
        totalActualHours += a.workDurationHours!;
      }
    }

    // Completadas a tiempo
    final completedActivities = periodActivities.where(
      (a) => a.status == OperStatus.done || a.status == OperStatus.verified,
    );

    int onTimeCount = 0;
    for (final a in completedActivities) {
      final completedDate = a.workEndAt ?? a.actualEndAt ?? a.updatedAt;
      if (!completedDate.isAfter(a.plannedEndAt)) {
        onTimeCount++;
      }
    }

    final complianceRate = total > 0 ? completed / total : 0.0;
    final onTimeRate = completedActivities.isNotEmpty
        ? onTimeCount / completedActivities.length
        : 0.0;

    // Promedio de progreso
    final avgProgress = total > 0
        ? periodActivities.fold<int>(0, (sum, a) => sum + a.progress) / total
        : 0.0;

    return _ReportStats(
      totalActivities: total,
      completedActivities: completed,
      inProgressActivities: inProgress,
      plannedActivities: planned,
      blockedActivities: blocked,
      overdueActivities: overdue,
      onTimeDeliveries: onTimeCount,
      complianceRate: complianceRate,
      onTimeRate: onTimeRate,
      averageProgress: avgProgress,
      totalEstimatedHours: totalEstimatedHours,
      totalActualHours: totalActualHours,
    );
  }

  // ══════════════════════════════════════════════════════════
  // PÁGINAS DEL REPORTE
  // ══════════════════════════════════════════════════════════

  static pw.Page _buildCoverPage(
    ReportConfig config,
    _ReportStats stats,
    String generatedByEmail,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Column(
          children: [
            // Header con gradiente
            pw.Container(
              width: double.infinity,
              height: 220,
              decoration: pw.BoxDecoration(color: _primaryDark),
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'CRM Soluciones TI',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    config.title,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${dateFormat.format(config.startDate)} - ${dateFormat.format(config.endDate)}',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#A8B89A'),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Resumen ejecutivo
                    pw.Text(
                      'Resumen Ejecutivo',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // KPIs principales en grid
                    pw.Row(
                      children: [
                        _buildCoverKPI(
                          'Total Actividades',
                          stats.totalActivities.toString(),
                          _primaryColor,
                        ),
                        pw.SizedBox(width: 16),
                        _buildCoverKPI(
                          'Completadas',
                          stats.completedActivities.toString(),
                          _successColor,
                        ),
                        pw.SizedBox(width: 16),
                        _buildCoverKPI(
                          'En Progreso',
                          stats.inProgressActivities.toString(),
                          _warningColor,
                        ),
                        pw.SizedBox(width: 16),
                        _buildCoverKPI(
                          'Bloqueadas',
                          stats.blockedActivities.toString(),
                          _errorColor,
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 30),

                    // Métricas clave
                    pw.Text(
                      'Métricas Clave',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    _buildMetricRow(
                      'Tasa de cumplimiento',
                      '${(stats.complianceRate * 100).toStringAsFixed(1)}%',
                      stats.complianceRate >= 0.8
                          ? _successColor
                          : stats.complianceRate >= 0.5
                          ? _warningColor
                          : _errorColor,
                    ),
                    _buildMetricRow(
                      'Entregas a tiempo',
                      '${(stats.onTimeRate * 100).toStringAsFixed(1)}%',
                      stats.onTimeRate >= 0.8
                          ? _successColor
                          : stats.onTimeRate >= 0.5
                          ? _warningColor
                          : _errorColor,
                    ),
                    _buildMetricRow(
                      'Progreso promedio',
                      '${stats.averageProgress.toStringAsFixed(1)}%',
                      _infoColor,
                    ),
                    _buildMetricRow(
                      'Actividades vencidas',
                      stats.overdueActivities.toString(),
                      stats.overdueActivities > 0 ? _errorColor : _successColor,
                    ),

                    if (stats.totalEstimatedHours > 0) ...[
                      pw.SizedBox(height: 4),
                      _buildMetricRow(
                        'Horas estimadas',
                        '${stats.totalEstimatedHours.toStringAsFixed(1)}h',
                        _infoColor,
                      ),
                      _buildMetricRow(
                        'Horas reales',
                        '${stats.totalActualHours.toStringAsFixed(1)}h',
                        stats.totalActualHours > stats.totalEstimatedHours
                            ? _errorColor
                            : _successColor,
                      ),
                    ],

                    pw.Spacer(),

                    // Footer
                    pw.Divider(color: _divider),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Generado por: $generatedByEmail',
                          style: pw.TextStyle(fontSize: 10, color: _textHint),
                        ),
                        pw.Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}',
                          style: pw.TextStyle(fontSize: 10, color: _textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static pw.Page _buildKPIsPage(
    ReportConfig config,
    _ReportStats stats,
    List<OperActivity> activities,
  ) {
    // Distribución por estado
    final statusCounts = <OperStatus, int>{};
    for (final status in OperStatus.values) {
      statusCounts[status] = activities.where((a) => a.status == status).length;
    }

    // Distribución por prioridad
    final priorityCounts = <String, int>{
      'high': activities.where((a) => a.priority == 'high').length,
      'medium': activities.where((a) => a.priority == 'medium').length,
      'low': activities
          .where((a) => a.priority == 'low' || a.priority == null)
          .length,
    };

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader(config.title, 'Distribución y Análisis'),
            pw.SizedBox(height: 24),

            // Distribución por estado
            pw.Text(
              'Distribución por Estado',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            pw.SizedBox(height: 12),

            ...statusCounts.entries.map((entry) {
              final count = entry.value;
              final percentage = stats.totalActivities > 0
                  ? (count / stats.totalActivities * 100)
                  : 0.0;

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: _getStatusPdfColor(entry.key),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.SizedBox(
                      width: 100,
                      child: pw.Text(
                        entry.key.label,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Stack(
                        children: [
                          pw.Container(
                            height: 16,
                            decoration: pw.BoxDecoration(
                              color: _divider,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                          pw.Container(
                            height: 16,
                            width: percentage * 3,
                            decoration: pw.BoxDecoration(
                              color: _getStatusPdfColor(entry.key),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.SizedBox(
                      width: 60,
                      child: pw.Text(
                        '$count (${percentage.toStringAsFixed(0)}%)',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _textPrimary,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 24),

            // Distribución por prioridad
            pw.Text(
              'Distribución por Prioridad',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            pw.SizedBox(height: 12),

            pw.Row(
              children: [
                _buildPriorityBox(
                  'Alta',
                  priorityCounts['high'] ?? 0,
                  _errorColor,
                ),
                pw.SizedBox(width: 12),
                _buildPriorityBox(
                  'Media',
                  priorityCounts['medium'] ?? 0,
                  _warningColor,
                ),
                pw.SizedBox(width: 12),
                _buildPriorityBox(
                  'Baja',
                  priorityCounts['low'] ?? 0,
                  _infoColor,
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Actividades vencidas
            if (stats.overdueActivities > 0) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FDECEC'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _errorColor, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '⚠ Actividades Vencidas (${stats.overdueActivities})',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _errorColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    ...activities.where((a) => a.isOverdue).take(5).map((a) {
                      final daysOverdue = DateTime.now()
                          .difference(a.plannedEndAt)
                          .inDays;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                a.title,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            pw.Text(
                              'Vencida hace $daysOverdue días',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: _errorColor,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            pw.Spacer(),
            _buildPageFooter(context),
          ],
        );
      },
    );
  }

  static pw.Page _buildCollaboratorsPage(
    ReportConfig config,
    List<OperActivity> activities,
  ) {
    // Calcular datos por colaborador
    final collabMap = <String, _CollabStats>{};

    for (final activity in activities) {
      for (int i = 0; i < activity.assigneesEmails.length; i++) {
        final email = activity.assigneesEmails[i];
        final name = email.split('@').first;

        collabMap.putIfAbsent(
          email,
          () => _CollabStats(name: name, email: email),
        );
        final collab = collabMap[email]!;

        collab.totalActivities++;

        if (activity.status == OperStatus.done ||
            activity.status == OperStatus.verified) {
          collab.completedActivities++;
        }
        if (activity.isOverdue) {
          collab.overdueActivities++;
        }

        collab.totalEstimatedHours += activity.estimatedHours;
        if (activity.workDurationHours != null) {
          collab.totalActualHours += activity.workDurationHours!;
        }
      }
    }

    final collaborators = collabMap.values.toList()
      ..sort((a, b) => b.totalActivities.compareTo(a.totalActivities));

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader(config.title, 'Análisis por Colaborador'),
            pw.SizedBox(height: 24),

            // Tabla de colaboradores
            pw.Table(
              border: pw.TableBorder.all(color: _divider, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _primaryDark),
                  children: [
                    _tableHeader('Colaborador'),
                    _tableHeader('Total'),
                    _tableHeader('Completadas'),
                    _tableHeader('Vencidas'),
                    _tableHeader('Cumplimiento'),
                    _tableHeader('Horas'),
                  ],
                ),
                // Rows
                ...collaborators.map((c) {
                  final rate = c.totalActivities > 0
                      ? c.completedActivities / c.totalActivities
                      : 0.0;

                  return pw.TableRow(
                    children: [
                      _tableCell(c.name, bold: true),
                      _tableCell(c.totalActivities.toString(), center: true),
                      _tableCell(
                        c.completedActivities.toString(),
                        center: true,
                      ),
                      _tableCell(
                        c.overdueActivities.toString(),
                        center: true,
                        color: c.overdueActivities > 0 ? _errorColor : null,
                      ),
                      _tableCell(
                        '${(rate * 100).toStringAsFixed(0)}%',
                        center: true,
                        color: rate >= 0.8
                            ? _successColor
                            : rate >= 0.5
                            ? _warningColor
                            : _errorColor,
                        bold: true,
                      ),
                      _tableCell(
                        '${c.totalActualHours.toStringAsFixed(1)}h',
                        center: true,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.Spacer(),
            _buildPageFooter(context),
          ],
        );
      },
    );
  }

  static List<pw.Page> _buildDetailPages(
    ReportConfig config,
    List<OperActivity> activities,
  ) {
    final pages = <pw.Page>[];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final itemsPerPage = 12;

    for (int i = 0; i < activities.length; i += itemsPerPage) {
      final pageActivities = activities.skip(i).take(itemsPerPage).toList();
      final pageNum = (i ~/ itemsPerPage) + 1;
      final totalPages = (activities.length / itemsPerPage).ceil();

      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPageHeader(
                  config.title,
                  'Detalle de Actividades ($pageNum/$totalPages)',
                ),
                pw.SizedBox(height: 16),

                // Tabla
                pw.Table(
                  border: pw.TableBorder.all(color: _divider, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: _primaryDark),
                      children: [
                        _tableHeader('Actividad'),
                        _tableHeader('Estado'),
                        _tableHeader('Progreso'),
                        _tableHeader('Inicio'),
                        _tableHeader('Fin'),
                        _tableHeader('Responsable'),
                      ],
                    ),
                    ...pageActivities.map((a) {
                      return pw.TableRow(
                        decoration: a.isOverdue
                            ? pw.BoxDecoration(
                                color: PdfColor.fromHex('#FFF0F0'),
                              )
                            : null,
                        children: [
                          _tableCell(a.title, bold: true),
                          _tableCell(
                            a.status.label,
                            center: true,
                            color: _getStatusPdfColor(a.status),
                            bold: true,
                          ),
                          _tableCell('${a.progress}%', center: true),
                          _tableCell(
                            dateFormat.format(a.plannedStartAt),
                            fontSize: 8,
                          ),
                          _tableCell(
                            dateFormat.format(a.plannedEndAt),
                            fontSize: 8,
                            color: a.isOverdue ? _errorColor : null,
                          ),
                          _tableCell(
                            a.assigneesEmails
                                .map((e) => e.split('@').first)
                                .join(', '),
                            fontSize: 8,
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.Spacer(),
                _buildPageFooter(context),
              ],
            );
          },
        ),
      );
    }

    return pages;
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS DE PDF
  // ══════════════════════════════════════════════════════════

  static pw.Widget _buildPageHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'CRM Soluciones TI',
              style: pw.TextStyle(
                fontSize: 10,
                color: _primaryColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(title, style: pw.TextStyle(fontSize: 10, color: _textHint)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          subtitle,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _primaryColor, thickness: 2),
      ],
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'CRM Soluciones TI - Reporte de Operatividad',
          style: pw.TextStyle(fontSize: 8, color: _textHint),
        ),
        pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: _textHint),
        ),
      ],
    );
  }

  static pw.Widget _buildCoverKPI(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _divider, width: 0.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: _textSecondary),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildMetricRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 20,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPriorityBox(String label, int count, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              count.toString(),
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
    bool center = false,
    PdfColor? color,
    double fontSize = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : null,
          color: color ?? _textPrimary,
        ),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: 2,
      ),
    );
  }

  static PdfColor _getStatusPdfColor(OperStatus status) {
    switch (status) {
      case OperStatus.planned:
        return _infoColor;
      case OperStatus.inProgress:
        return _warningColor;
      case OperStatus.done:
        return _successColor;
      case OperStatus.verified:
        return _primaryColor;
      case OperStatus.blocked:
        return _errorColor;
    }
  }
}

// ══════════════════════════════════════════════════════════
// MODELOS INTERNOS
// ══════════════════════════════════════════════════════════

class _ReportStats {
  final int totalActivities;
  final int completedActivities;
  final int inProgressActivities;
  final int plannedActivities;
  final int blockedActivities;
  final int overdueActivities;
  final int onTimeDeliveries;
  final double complianceRate;
  final double onTimeRate;
  final double averageProgress;
  final double totalEstimatedHours;
  final double totalActualHours;

  const _ReportStats({
    required this.totalActivities,
    required this.completedActivities,
    required this.inProgressActivities,
    required this.plannedActivities,
    required this.blockedActivities,
    required this.overdueActivities,
    required this.onTimeDeliveries,
    required this.complianceRate,
    required this.onTimeRate,
    required this.averageProgress,
    required this.totalEstimatedHours,
    required this.totalActualHours,
  });
}

class _CollabStats {
  final String name;
  final String email;
  int totalActivities;
  int completedActivities;
  int overdueActivities;
  double totalEstimatedHours;
  double totalActualHours;

  _CollabStats({
    required this.name,
    required this.email,
    this.totalActivities = 0,
    this.completedActivities = 0,
    this.overdueActivities = 0,
    this.totalEstimatedHours = 0,
    this.totalActualHours = 0,
  });
}
