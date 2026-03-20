// lib/inventory/services/inventory_report_service.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/inventory_enums.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import '../models/inventory_movement.dart';
import '../models/inventory_supplier.dart';
import '../models/inventory_location.dart';
import 'inventory_service.dart';
import 'inventory_category_service.dart';
import 'inventory_movement_service.dart';
import 'inventory_supplier_service.dart';
import 'inventory_location_service.dart';

/// Tipo de reporte
enum ReportType {
  inventoryList('Lista de Inventario'),
  lowStock('Stock Bajo'),
  movements('Movimientos'),
  valuation('Valorización'),
  byCategory('Por Categoría'),
  byLocation('Por Ubicación'),
  bySupplier('Por Proveedor'),
  expiring('Próximos a Vencer'),
  assets('Activos Fijos');

  final String label;
  const ReportType(this.label);
}

/// Formato de exportación
enum ExportFormat { pdf, csv, excel }

/// Configuración del reporte
class ReportConfig {
  final ReportType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final String? locationId;
  final String? supplierId;
  final InventoryItemType? itemType;
  final bool includeInactive;
  final bool includeImages;
  final String? title;
  final String? subtitle;

  const ReportConfig({
    required this.type,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.locationId,
    this.supplierId,
    this.itemType,
    this.includeInactive = false,
    this.includeImages = false,
    this.title,
    this.subtitle,
  });
}

class InventoryReportService {
  InventoryReportService._();
  static final InventoryReportService instance = InventoryReportService._();

  final _inventoryService = InventoryService.instance;
  final _categoryService = InventoryCategoryService.instance;
  final _movementService = InventoryMovementService.instance;
  final _supplierService = InventorySupplierService.instance;
  final _locationService = InventoryLocationService.instance;

  // Formateadores
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final _dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');
  final _numberFormat = NumberFormat('#,##0', 'es_MX');

  // ═══════════════════════════════════════════════════════════
  // GENERACIÓN DE REPORTES PDF
  // ═══════════════════════════════════════════════════════════

  /// Generar reporte PDF
  Future<Uint8List> generatePdfReport(ReportConfig config) async {
    final pdf = pw.Document();

    // Obtener datos según tipo de reporte
    final data = await _getReportData(config);

    // Agregar páginas según tipo
    switch (config.type) {
      case ReportType.inventoryList:
        await _addInventoryListPages(pdf, data, config);
        break;
      case ReportType.lowStock:
        await _addLowStockPages(pdf, data, config);
        break;
      case ReportType.movements:
        await _addMovementsPages(pdf, data, config);
        break;
      case ReportType.valuation:
        await _addValuationPages(pdf, data, config);
        break;
      case ReportType.byCategory:
        await _addByCategoryPages(pdf, data, config);
        break;
      case ReportType.byLocation:
        await _addByLocationPages(pdf, data, config);
        break;
      case ReportType.bySupplier:
        await _addBySupplierPages(pdf, data, config);
        break;
      case ReportType.expiring:
        await _addExpiringPages(pdf, data, config);
        break;
      case ReportType.assets:
        await _addAssetsPages(pdf, data, config);
        break;
    }

    return pdf.save();
  }

  /// Obtener datos del reporte
  Future<Map<String, dynamic>> _getReportData(ReportConfig config) async {
    final data = <String, dynamic>{};

    // Obtener estadísticas generales
    data['stats'] = await _inventoryService.getStats();

    // Obtener items según filtros
    var items = await _getFilteredItems(config);
    data['items'] = items;

    // Datos específicos según tipo
    switch (config.type) {
      case ReportType.movements:
        data['movements'] = await _getFilteredMovements(config);
        data['movementSummary'] = await _movementService.getMovementSummary(
          startDate: config.startDate,
          endDate: config.endDate,
        );
        break;
      case ReportType.byCategory:
        data['categories'] = await _getCategoriesWithItems(items);
        break;
      case ReportType.byLocation:
        data['locations'] = await _getLocationsWithItems(items);
        break;
      case ReportType.bySupplier:
        data['suppliers'] = await _getSuppliersWithItems(items);
        break;
      case ReportType.lowStock:
        data['items'] = items.where((i) => i.isStockLow).toList();
        break;
      case ReportType.expiring:
        data['items'] = items.where((i) {
          if (i.expirationDate == null) return false;
          final daysUntilExpiry = i.expirationDate!
              .difference(DateTime.now())
              .inDays;
          return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
        }).toList();
        break;
      case ReportType.assets:
        data['items'] = items
            .where((i) => i.type == InventoryItemType.asset)
            .toList();
        break;
      default:
        break;
    }

    return data;
  }

  Future<List<InventoryItem>> _getFilteredItems(ReportConfig config) async {
    final filters = InventoryFilters(
      type: config.itemType,
      categoryId: config.categoryId,
      locationId: config.locationId,
      supplierId: config.supplierId,
      isActive: config.includeInactive ? null : true,
    );

    final result = await _inventoryService.getItemsPaginated(
      filters: filters,
      pageSize: 1000, // Límite alto para reportes
    );

    return result.items;
  }

  Future<List<InventoryMovement>> _getFilteredMovements(
    ReportConfig config,
  ) async {
    final result = await _movementService.getMovementsPaginated(pageSize: 1000);

    var movements = result.movements;

    // Filtrar por fechas
    if (config.startDate != null) {
      movements = movements
          .where((m) => m.createdAt.isAfter(config.startDate!))
          .toList();
    }
    if (config.endDate != null) {
      movements = movements
          .where((m) => m.createdAt.isBefore(config.endDate!))
          .toList();
    }

    return movements;
  }

  Future<Map<String, List<InventoryItem>>> _getCategoriesWithItems(
    List<InventoryItem> items,
  ) async {
    final grouped = <String, List<InventoryItem>>{};

    for (final item in items) {
      final category = await _categoryService.getCategoryById(item.categoryId);
      final categoryName = category?.name ?? 'Sin categoría';
      grouped.putIfAbsent(categoryName, () => []).add(item);
    }

    return grouped;
  }

  Future<Map<String, List<InventoryItem>>> _getLocationsWithItems(
    List<InventoryItem> items,
  ) async {
    final grouped = <String, List<InventoryItem>>{};

    for (final item in items) {
      if (item.defaultLocationId == null) {
        grouped.putIfAbsent('Sin ubicación', () => []).add(item);
      } else {
        final location = await _locationService.getLocationById(
          item.defaultLocationId!,
        );
        final locationName = location?.name ?? 'Ubicación desconocida';
        grouped.putIfAbsent(locationName, () => []).add(item);
      }
    }

    return grouped;
  }

  Future<Map<String, List<InventoryItem>>> _getSuppliersWithItems(
    List<InventoryItem> items,
  ) async {
    final grouped = <String, List<InventoryItem>>{};

    for (final item in items) {
      if (item.primarySupplierId == null) {
        grouped.putIfAbsent('Sin proveedor', () => []).add(item);
      } else {
        final supplier = await _supplierService.getSupplierById(
          item.primarySupplierId!,
        );
        final supplierName = supplier?.name ?? 'Proveedor desconocido';
        grouped.putIfAbsent(supplierName, () => []).add(item);
      }
    }

    return grouped;
  }

  // ═══════════════════════════════════════════════════════════
  // PÁGINAS DEL PDF
  // ═══════════════════════════════════════════════════════════

  pw.Widget _buildHeader(String title, String? subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado el ${_dateTimeFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  Future<void> _addInventoryListPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final items = data['items'] as List<InventoryItem>;
    final stats = data['stats'] as InventoryStats;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Lista de Inventario',
          config.subtitle ?? 'Reporte completo de items',
        ),
        footer: _buildFooter,
        build: (context) => [
          // Resumen
          _buildSummaryBox(stats),
          pw.SizedBox(height: 20),

          // Tabla de items
          _buildItemsTable(items),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBox(InventoryStats stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Items',
            _numberFormat.format(stats.totalItems),
          ),
          _buildSummaryItem(
            'Productos',
            _numberFormat.format(stats.totalProducts),
          ),
          _buildSummaryItem(
            'Servicios',
            _numberFormat.format(stats.totalServices),
          ),
          _buildSummaryItem('Activos', _numberFormat.format(stats.totalAssets)),
          _buildSummaryItem(
            'Stock Bajo',
            _numberFormat.format(stats.lowStockItems),
          ),
          _buildSummaryItem(
            'Valor Total',
            _currencyFormat.format(stats.totalInventoryValue),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<InventoryItem> items) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      headers: ['SKU', 'Nombre', 'Tipo', 'Stock', 'Precio', 'Valor'],
      data: items
          .map(
            (item) => [
              item.sku,
              item.name.length > 30
                  ? '${item.name.substring(0, 30)}...'
                  : item.name,
              item.type.label,
              _numberFormat.format(item.stock),
              _currencyFormat.format(item.sellingPrice),
              _currencyFormat.format(item.totalInventoryValue),
            ],
          )
          .toList(),
    );
  }

  Future<void> _addLowStockPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final items = data['items'] as List<InventoryItem>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Reporte de Stock Bajo',
          'Items que requieren reabastecimiento',
        ),
        footer: _buildFooter,
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '⚠️ ${items.length} items con stock bajo',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildLowStockTable(items),
        ],
      ),
    );
  }

  pw.Widget _buildLowStockTable(List<InventoryItem> items) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.red700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: [
        'SKU',
        'Nombre',
        'Stock Actual',
        'Stock Mínimo',
        'Diferencia',
        'Proveedor',
      ],
      data: items
          .map(
            (item) => [
              item.sku,
              item.name.length > 25
                  ? '${item.name.substring(0, 25)}...'
                  : item.name,
              _numberFormat.format(item.stock),
              _numberFormat.format(item.minStock),
              _numberFormat.format(item.minStock - item.stock),
              '-', // Proveedor
            ],
          )
          .toList(),
    );
  }

  Future<void> _addMovementsPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final movements = data['movements'] as List<InventoryMovement>;
    final summary = data['movementSummary'] as MovementSummary;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Reporte de Movimientos',
          _buildDateRangeSubtitle(config),
        ),
        footer: _buildFooter,
        build: (context) => [
          // Resumen de movimientos
          _buildMovementSummaryBox(summary),
          pw.SizedBox(height: 20),
          // Tabla de movimientos
          _buildMovementsTable(movements),
        ],
      ),
    );
  }

  String _buildDateRangeSubtitle(ReportConfig config) {
    if (config.startDate == null && config.endDate == null) {
      return 'Todos los movimientos';
    }
    if (config.startDate != null && config.endDate != null) {
      return 'Del ${_dateFormat.format(config.startDate!)} al ${_dateFormat.format(config.endDate!)}';
    }
    if (config.startDate != null) {
      return 'Desde ${_dateFormat.format(config.startDate!)}';
    }
    return 'Hasta ${_dateFormat.format(config.endDate!)}';
  }

  pw.Widget _buildMovementSummaryBox(MovementSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Movimientos',
            _numberFormat.format(summary.totalMovements),
          ),
          _buildSummaryItem('Entradas', _numberFormat.format(summary.totalIn)),
          _buildSummaryItem('Salidas', _numberFormat.format(summary.totalOut)),
          _buildSummaryItem(
            'Cambio Neto',
            _numberFormat.format(summary.netChange),
          ),
          _buildSummaryItem(
            'Valor Entradas',
            _currencyFormat.format(summary.totalValueIn),
          ),
          _buildSummaryItem(
            'Valor Salidas',
            _currencyFormat.format(summary.totalValueOut),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMovementsTable(List<InventoryMovement> movements) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headers: [
        'Fecha',
        'Número',
        'Tipo',
        'Item',
        'Cantidad',
        'Anterior',
        'Nuevo',
        'Razón',
      ],
      data: movements
          .take(100)
          .map(
            (m) => [
              _dateFormat.format(m.createdAt),
              m.movementNumber,
              m.type.label,
              m.itemName.length > 20
                  ? '${m.itemName.substring(0, 20)}...'
                  : m.itemName,
              '${m.type.isIncoming ? '+' : '-'}${m.quantity}',
              _numberFormat.format(m.previousStock),
              _numberFormat.format(m.newStock),
              m.reason.length > 25
                  ? '${m.reason.substring(0, 25)}...'
                  : m.reason,
            ],
          )
          .toList(),
    );
  }

  Future<void> _addValuationPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final items = data['items'] as List<InventoryItem>;
    final stats = data['stats'] as InventoryStats;

    // Ordenar por valor de inventario
    items.sort(
      (a, b) => b.totalInventoryValue.compareTo(a.totalInventoryValue),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Reporte de Valorización',
          'Valor del inventario por item',
        ),
        footer: _buildFooter,
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.amber200),
            ),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Valor Total del Inventario',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _currencyFormat.format(stats.totalInventoryValue),
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          _buildValuationTable(items),
        ],
      ),
    );
  }

  pw.Widget _buildValuationTable(List<InventoryItem> items) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.amber700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      headers: [
        'SKU',
        'Nombre',
        'Stock',
        'Costo Unit.',
        'Precio Venta',
        'Valor Total',
      ],
      data: items
          .map(
            (item) => [
              item.sku,
              item.name.length > 30
                  ? '${item.name.substring(0, 30)}...'
                  : item.name,
              _numberFormat.format(item.stock),
              _currencyFormat.format(item.purchasePrice),
              _currencyFormat.format(item.sellingPrice),
              _currencyFormat.format(item.totalInventoryValue),
            ],
          )
          .toList(),
    );
  }

  Future<void> _addByCategoryPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final categories = data['categories'] as Map<String, List<InventoryItem>>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Inventario por Categoría',
          'Distribución de items por categoría',
        ),
        footer: _buildFooter,
        build: (context) {
          final widgets = <pw.Widget>[];

          categories.forEach((categoryName, items) {
            final totalValue = items.fold<double>(
              0,
              (sum, item) => sum + item.totalInventoryValue,
            );
            final totalStock = items.fold<int>(
              0,
              (sum, item) => sum + item.stock,
            );

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          categoryName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${items.length} items | Stock: ${_numberFormat.format(totalStock)} | Valor: ${_currencyFormat.format(totalValue)}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });

          return widgets;
        },
      ),
    );
  }

  Future<void> _addByLocationPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final locations = data['locations'] as Map<String, List<InventoryItem>>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Inventario por Ubicación',
          'Distribución de items por ubicación',
        ),
        footer: _buildFooter,
        build: (context) {
          final widgets = <pw.Widget>[];

          locations.forEach((locationName, items) {
            final totalValue = items.fold<double>(
              0,
              (sum, item) => sum + item.totalInventoryValue,
            );
            final totalStock = items.fold<int>(
              0,
              (sum, item) => sum + item.stock,
            );

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      locationName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${items.length} items | ${_numberFormat.format(totalStock)} unidades | ${_currencyFormat.format(totalValue)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          });

          return widgets;
        },
      ),
    );
  }

  Future<void> _addBySupplierPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final suppliers = data['suppliers'] as Map<String, List<InventoryItem>>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Inventario por Proveedor',
          'Productos por proveedor',
        ),
        footer: _buildFooter,
        build: (context) {
          final widgets = <pw.Widget>[];

          suppliers.forEach((supplierName, items) {
            final totalValue = items.fold<double>(
              0,
              (sum, item) => sum + item.totalInventoryValue,
            );

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      supplierName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${items.length} productos | ${_currencyFormat.format(totalValue)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          });

          return widgets;
        },
      ),
    );
  }

  Future<void> _addExpiringPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final items = data['items'] as List<InventoryItem>;

    // Ordenar por fecha de vencimiento
    items.sort((a, b) {
      if (a.expirationDate == null) return 1;
      if (b.expirationDate == null) return -1;
      return a.expirationDate!.compareTo(b.expirationDate!);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Productos Próximos a Vencer',
          'Items que vencen en los próximos 30 días',
        ),
        footer: _buildFooter,
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '⏰ ${items.length} items próximos a vencer',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildExpiringTable(items),
        ],
      ),
    );
  }

  pw.Widget _buildExpiringTable(List<InventoryItem> items) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: [
        'SKU',
        'Nombre',
        'Lote',
        'Stock',
        'Fecha Vencimiento',
        'Días Restantes',
      ],
      data: items.map((item) {
        final daysLeft =
            item.expirationDate?.difference(DateTime.now()).inDays ?? 0;
        return [
          item.sku,
          item.name.length > 25
              ? '${item.name.substring(0, 25)}...'
              : item.name,
          item.batchNumber ?? '-',
          _numberFormat.format(item.stock),
          item.expirationDate != null
              ? _dateFormat.format(item.expirationDate!)
              : '-',
          '$daysLeft días',
        ];
      }).toList(),
    );
  }

  Future<void> _addAssetsPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    ReportConfig config,
  ) async {
    final items = data['items'] as List<InventoryItem>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          config.title ?? 'Reporte de Activos Fijos',
          'Inventario de activos de la empresa',
        ),
        footer: _buildFooter,
        build: (context) => [_buildAssetsTable(items)],
      ),
    );
  }

  pw.Widget _buildAssetsTable(List<InventoryItem> items) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headers: [
        'SKU',
        'Nombre',
        'Marca/Modelo',
        'Serie',
        'Condición',
        'Asignado a',
        'F. Compra',
        'Garantía',
        'Valor',
      ],
      data: items
          .map(
            (item) => [
              item.sku,
              item.name.length > 20
                  ? '${item.name.substring(0, 20)}...'
                  : item.name,
              '${item.brand ?? ''} ${item.model ?? ''}'.trim(),
              item.serialNumber ?? '-',
              item.assetCondition?.label ?? '-',
              item.assignedToUserId ?? '-',
              item.purchaseDate != null
                  ? _dateFormat.format(item.purchaseDate!)
                  : '-',
              item.warrantyExpiryDate != null
                  ? _dateFormat.format(item.warrantyExpiryDate!)
                  : '-',
              _currencyFormat.format(item.purchasePrice),
            ],
          )
          .toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // IMPRIMIR Y COMPARTIR
  // ═══════════════════════════════════════════════════════════

  /// Imprimir reporte
  Future<void> printReport(ReportConfig config) async {
    final pdfBytes = await generatePdfReport(config);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  /// Compartir reporte
  Future<void> shareReport(ReportConfig config) async {
    final pdfBytes = await generatePdfReport(config);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: _generateFileName(config),
    );
  }

  /// Previsualizar reporte
  Future<void> previewReport(BuildContext context, ReportConfig config) async {
    final pdfBytes = await generatePdfReport(config);

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(config.title ?? config.type.label),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => shareReport(config),
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => printReport(config),
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) async => pdfBytes,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
          ),
        ),
      ),
    );
  }

  String _generateFileName(ReportConfig config) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final typeName = config.type.name.replaceAll('_', '-');
    return 'inventario_${typeName}_$timestamp.pdf';
  }

  // ═══════════════════════════════════════════════════════════
  // EXPORTAR CSV
  // ═══════════════════════════════════════════════════════════

  /// Exportar a CSV
  Future<String> exportToCsv(ReportConfig config) async {
    final data = await _getReportData(config);
    final items = data['items'] as List<InventoryItem>;

    final buffer = StringBuffer();

    // Encabezados
    buffer.writeln(
      'SKU,Nombre,Tipo,Categoría,Stock,Stock Mínimo,Precio Compra,Precio Venta,Valor Total,Estado',
    );

    // Datos
    for (final item in items) {
      buffer.writeln(
        [
          _escapeCsvField(item.sku),
          _escapeCsvField(item.name),
          item.type.label,
          item.categoryId,
          item.stock,
          item.minStock,
          item.purchasePrice,
          item.sellingPrice,
          item.totalInventoryValue,
          item.status.label,
        ].join(','),
      );
    }

    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
