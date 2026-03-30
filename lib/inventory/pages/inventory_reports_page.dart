// lib/inventory/pages/inventory_reports_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../services/inventory_report_service.dart';

class InventoryReportsPage extends StatefulWidget {
  final UserRole role;

  const InventoryReportsPage({super.key, required this.role});

  @override
  State<InventoryReportsPage> createState() => _InventoryReportsPageState();
}

class _InventoryReportsPageState extends State<InventoryReportsPage> {
  final _reportService = InventoryReportService.instance;

  ReportType? _selectedReport;
  DateTimeRange? _dateRange;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    // ✅ CAMBIO: Usar ListView en lugar de SingleChildScrollView + Column
    return ListView(
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.xl),
      children: [
        // Header
        Text(
          'Reportes de Inventario',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Genera reportes en PDF o CSV para análisis',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.xl),

        // Rango de fechas global
        _buildDateRangeSelector(),
        const SizedBox(height: AppDimensions.xl),

        // Grid de reportes
        if (isMobile) ..._buildReportListMobile() else _buildReportGrid(),

        // Generación activa
        if (_isGenerating) ...[
          const SizedBox(height: AppDimensions.xl),
          _buildGeneratingIndicator(),
        ],

        // Espacio final
        const SizedBox(height: AppDimensions.xl),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RANGO DE FECHAS
  // ═══════════════════════════════════════════════════════════

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppColors.primary),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rango de fechas', style: AppTextStyles.labelMedium),
                    Text(
                      _dateRange != null
                          ? '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}'
                          : 'Sin rango seleccionado (se incluye todo)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dateRange != null ? 'Cambiar' : 'Seleccionar'),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: AppDimensions.sm),
                IconButton(
                  onPressed: () => setState(() => _dateRange = null),
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Limpiar rango',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GRID DE REPORTES (Desktop)
  // ═══════════════════════════════════════════════════════════

  Widget _buildReportGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: AppDimensions.md,
      mainAxisSpacing: AppDimensions.md,
      childAspectRatio: 1.4,
      children: _getReportCards(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LISTA DE REPORTES (Mobile) - ✅ CORREGIDO
  // ═══════════════════════════════════════════════════════════

  List<Widget> _buildReportListMobile() {
    return _getReportCards().map((card) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.md),
        child: card,
      );
    }).toList();
  }

  List<Widget> _getReportCards() {
    return [
      _ReportCard(
        type: ReportType.inventoryList,
        icon: Icons.list_alt_rounded,
        color: AppColors.primary,
        description: 'Lista completa de todos los items del inventario',
        isGenerating:
            _isGenerating && _selectedReport == ReportType.inventoryList,
        onGenerate: () => _generateReport(ReportType.inventoryList),
        onShare: () => _shareReport(ReportType.inventoryList),
      ),
      _ReportCard(
        type: ReportType.lowStock,
        icon: Icons.warning_rounded,
        color: AppColors.error,
        description: 'Items por debajo del stock mínimo',
        isGenerating: _isGenerating && _selectedReport == ReportType.lowStock,
        onGenerate: () => _generateReport(ReportType.lowStock),
        onShare: () => _shareReport(ReportType.lowStock),
      ),
      _ReportCard(
        type: ReportType.valuation,
        icon: Icons.attach_money_rounded,
        color: AppColors.success,
        description: 'Valor monetario del inventario actual',
        isGenerating: _isGenerating && _selectedReport == ReportType.valuation,
        onGenerate: () => _generateReport(ReportType.valuation),
        onShare: () => _shareReport(ReportType.valuation),
      ),
      _ReportCard(
        type: ReportType.movements,
        icon: Icons.swap_horiz_rounded,
        color: AppColors.info,
        description: 'Historial de entradas y salidas',
        isGenerating: _isGenerating && _selectedReport == ReportType.movements,
        onGenerate: () => _generateReport(ReportType.movements),
        onShare: () => _shareReport(ReportType.movements),
      ),
      _ReportCard(
        type: ReportType.byCategory,
        icon: Icons.category_rounded,
        color: const Color(0xFF9C27B0),
        description: 'Distribución de items por categoría',
        isGenerating: _isGenerating && _selectedReport == ReportType.byCategory,
        onGenerate: () => _generateReport(ReportType.byCategory),
        onShare: () => _shareReport(ReportType.byCategory),
      ),
      _ReportCard(
        type: ReportType.byLocation,
        icon: Icons.location_on_rounded,
        color: const Color(0xFF009688),
        description: 'Distribución por ubicación/almacén',
        isGenerating: _isGenerating && _selectedReport == ReportType.byLocation,
        onGenerate: () => _generateReport(ReportType.byLocation),
        onShare: () => _shareReport(ReportType.byLocation),
      ),
      _ReportCard(
        type: ReportType.bySupplier,
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFFFF9800),
        description: 'Productos agrupados por proveedor',
        isGenerating: _isGenerating && _selectedReport == ReportType.bySupplier,
        onGenerate: () => _generateReport(ReportType.bySupplier),
        onShare: () => _shareReport(ReportType.bySupplier),
      ),
      _ReportCard(
        type: ReportType.expiring,
        icon: Icons.event_busy_rounded,
        color: const Color(0xFFF44336),
        description: 'Productos próximos a vencer',
        isGenerating: _isGenerating && _selectedReport == ReportType.expiring,
        onGenerate: () => _generateReport(ReportType.expiring),
        onShare: () => _shareReport(ReportType.expiring),
      ),
      _ReportCard(
        type: ReportType.assets,
        icon: Icons.business_center_rounded,
        color: const Color(0xFF607D8B),
        description: 'Inventario de activos fijos de la empresa',
        isGenerating: _isGenerating && _selectedReport == ReportType.assets,
        onGenerate: () => _generateReport(ReportType.assets),
        onShare: () => _shareReport(ReportType.assets),
      ),
    ];
  }

  Widget _buildGeneratingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppDimensions.md),
          Text(
            'Generando reporte...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _generateReport(ReportType type) async {
    setState(() {
      _isGenerating = true;
      _selectedReport = type;
    });

    try {
      final config = ReportConfig(
        type: type,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      );

      await _reportService.previewReport(context, config);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando reporte: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _selectedReport = null;
        });
      }
    }
  }

  Future<void> _shareReport(ReportType type) async {
    setState(() {
      _isGenerating = true;
      _selectedReport = type;
    });

    try {
      final config = ReportConfig(
        type: type,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      );

      await _reportService.shareReport(config);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error compartiendo reporte: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _selectedReport = null;
        });
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET DE TARJETA DE REPORTE - ✅ CORREGIDO
// ══════════════════════════════════════════════════════════════

class _ReportCard extends StatelessWidget {
  final ReportType type;
  final IconData icon;
  final Color color;
  final String description;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback onShare;

  const _ReportCard({
    required this.type,
    required this.icon,
    required this.color,
    required this.description,
    this.isGenerating = false,
    required this.onGenerate,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ IMPORTANTE
          children: [
            // Ícono y título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Text(
                    type.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),

            // Descripción
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.md),

            // Botones
            if (isGenerating)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onGenerate,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Ver'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Compartir',
                    style: IconButton.styleFrom(
                      backgroundColor: color.withOpacity(0.1),
                      foregroundColor: color,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
