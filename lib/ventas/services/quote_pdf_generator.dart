// lib/ventas/services/quote_pdf_generator.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/sale_quote.dart';
import '../models/ventas_enums.dart';

/// Generador de PDF profesional para cotizaciones
class QuotePdfGenerator {
  QuotePdfGenerator._();

  // Colores institucionales Soluciones TI
  static final _primaryDark = PdfColor.fromHex('#44562C');
  static final _primaryMedium = PdfColor.fromHex('#5A7A3A');
  static final _primaryLight = PdfColor.fromHex('#ACC952');
  static final _primaryPale = PdfColor.fromHex('#F0F5E4');
  static final _textPrimary = PdfColor.fromHex('#1A1F16');
  static final _textSecondary = PdfColor.fromHex('#3D4A35');
  static final _textHint = PdfColor.fromHex('#8B9A78');
  static final _divider = PdfColor.fromHex('#E8EDE0');
  static final _background = PdfColor.fromHex('#F5F8F0');
  static final _white = PdfColors.white;
  static final _error = PdfColor.fromHex('#D94F4F');

  static final _nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  static final _df = DateFormat('dd/MM/yyyy', 'es_MX');

  /// Genera el PDF de una cotización
  static Future<Uint8List> generate(SaleQuote quote) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );

    // Cargar logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/branding/logo.jpg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // Logo no disponible
    }

    final isDraft = quote.status == QuoteStatus.borrador;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, quote, logoImage),
        footer: (context) => _buildFooter(context, quote),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildClientInfo(quote),
          pw.SizedBox(height: 16),
          _buildItemsTable(quote),
          pw.SizedBox(height: 16),
          _buildFinancialSummary(quote),
          pw.SizedBox(height: 16),
          _buildConditions(quote),
          if (isDraft) ...[
            pw.SizedBox(height: 24),
            _buildWatermark('BORRADOR'),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _buildHeader(pw.Context context, SaleQuote quote, pw.MemoryImage? logo) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _primaryDark,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo y nombre de empresa
              pw.Expanded(
                flex: 3,
                child: pw.Row(
                  children: [
                    if (logo != null)
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          color: _white,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Soluciones TI',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: _white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Tecnología e Innovación',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _primaryLight,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        _headerDetail('📍', 'Fuente de Ebro 301 A, Col. Las Fuentes'),
                        _headerDetail('📞', '442 807 0229'),
                        _headerDetail('✉️', 'ventas@solucionesti.com.mx'),
                      ],
                    ),
                  ],
                ),
              ),
              // Info de la cotización
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _primaryMedium,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('COTIZACIÓN',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryLight,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _quoteMeta('Folio:', quote.folio),
                      _quoteMeta('Fecha:', _df.format(quote.createdAt)),
                      _quoteMeta('Vigencia:', '${quote.vigenciaDias} días'),
                      if (quote.fechaExpiracion != null)
                        _quoteMeta('Vence:', _df.format(quote.fechaExpiracion!)),
                      if (quote.version > 1)
                        _quoteMeta('Versión:', 'V${quote.version}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        // Barra decorativa verde claro
        pw.Container(
          height: 3,
          decoration: pw.BoxDecoration(
            color: _primaryLight,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  static pw.Widget _headerDetail(String icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1),
      child: pw.Text('$icon $text',
        style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#C8D1BC')),
      ),
    );
  }

  static pw.Widget _quoteMeta(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label,
            style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#C8D1BC')),
          ),
          pw.SizedBox(width: 4),
          pw.Text(value,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CLIENT INFO
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _buildClientInfo(SaleQuote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _primaryPale,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DATOS DEL CLIENTE',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryDark, letterSpacing: 1),
                ),
                pw.SizedBox(height: 6),
                pw.Text(quote.clienteNombre,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _textPrimary),
                ),
                if (quote.clienteEmpresa != null && quote.clienteEmpresa!.isNotEmpty)
                  pw.Text(quote.clienteEmpresa!,
                    style: pw.TextStyle(fontSize: 10, color: _textSecondary),
                  ),
                if (quote.clienteRfc != null && quote.clienteRfc!.isNotEmpty)
                  pw.Text('RFC: ${quote.clienteRfc}',
                    style: pw.TextStyle(fontSize: 9, color: _textSecondary),
                  ),
                if (quote.clienteRazonSocial != null && quote.clienteRazonSocial!.isNotEmpty)
                  pw.Text('Razón Social: ${quote.clienteRazonSocial}',
                    style: pw.TextStyle(fontSize: 9, color: _textSecondary),
                  ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CONTACTO',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryDark, letterSpacing: 1),
                ),
                pw.SizedBox(height: 6),
                if (quote.clienteEmail != null && quote.clienteEmail!.isNotEmpty)
                  _clientDetail('Email:', quote.clienteEmail!),
                if (quote.clienteTelefono != null && quote.clienteTelefono!.isNotEmpty)
                  _clientDetail('Tel:', quote.clienteTelefono!),
                if (quote.clienteDireccion != null && quote.clienteDireccion!.isNotEmpty)
                  _clientDetail('Dir:', quote.clienteDireccion!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _clientDetail(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: '$label ', style: pw.TextStyle(fontSize: 9, color: _textHint)),
          pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 9, color: _textPrimary)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ITEMS TABLE
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _buildItemsTable(SaleQuote quote) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),  // #
        1: const pw.FlexColumnWidth(3),     // Descripción
        2: const pw.FlexColumnWidth(0.8),   // Cant.
        3: const pw.FlexColumnWidth(0.8),   // Unidad
        4: const pw.FlexColumnWidth(1.2),   // P. Unit.
        5: const pw.FlexColumnWidth(0.8),   // Desc.
        6: const pw.FlexColumnWidth(1.3),   // Subtotal
      },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _divider, width: 0.5),
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: _primaryDark,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
          ),
          children: [
            _tableHeader('#'),
            _tableHeader('Descripción'),
            _tableHeader('Cant.'),
            _tableHeader('Unidad'),
            _tableHeader('P. Unit.'),
            _tableHeader('Desc.'),
            _tableHeader('Subtotal'),
          ],
        ),
        // Items
        ...quote.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isEven = i % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? _white : _background,
            ),
            children: [
              _tableCell('${i + 1}', align: pw.TextAlign.center),
              _tableCellProduct(item.nombre, item.sku, item.descripcion),
              _tableCell(item.cantidad.toStringAsFixed(item.cantidad == item.cantidad.roundToDouble() ? 0 : 2), align: pw.TextAlign.center),
              _tableCell(item.unidad, align: pw.TextAlign.center),
              _tableCell(_nf.format(item.precioUnitario), align: pw.TextAlign.right),
              _tableCell(item.descuento > 0 ? '${item.descuento.toStringAsFixed(0)}%' : '-', align: pw.TextAlign.center),
              _tableCell(_nf.format(item.subtotal), align: pw.TextAlign.right, bold: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _white),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(text,
        style: pw.TextStyle(
          fontSize: 8,
          color: _textPrimary,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _tableCellProduct(String nombre, String sku, String? descripcion) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(nombre,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textPrimary),
          ),
          pw.Text('SKU: $sku',
            style: pw.TextStyle(fontSize: 7, color: _textHint),
          ),
          if (descripcion != null && descripcion.isNotEmpty)
            pw.Text(descripcion,
              style: pw.TextStyle(fontSize: 7, color: _textSecondary),
              maxLines: 2,
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FINANCIAL SUMMARY
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _buildFinancialSummary(SaleQuote quote) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Espacio vacío a la izquierda o info adicional
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _background,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _divider),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RESUMEN',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primaryDark, letterSpacing: 1),
                ),
                pw.SizedBox(height: 4),
                pw.Text('${quote.totalItems} producto(s) — ${quote.totalCantidad.toStringAsFixed(0)} unidad(es)',
                  style: pw.TextStyle(fontSize: 8, color: _textSecondary),
                ),
                pw.SizedBox(height: 2),
                pw.Text('Moneda: ${quote.moneda}',
                  style: pw.TextStyle(fontSize: 8, color: _textSecondary),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        // Resumen financiero
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _primaryDark, width: 1.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _summaryRow('Subtotal', _nf.format(quote.subtotal)),
                if (quote.descuentoGlobal > 0) ...[
                  pw.SizedBox(height: 4),
                  _summaryRow('Descuento (${quote.descuentoGlobal.toStringAsFixed(0)}%)',
                    '-${_nf.format(quote.subtotal - quote.subtotalConDescuento)}',
                    color: _error,
                  ),
                ],
                pw.SizedBox(height: 4),
                _summaryRow('IVA (${quote.ivaPorcentaje.toStringAsFixed(0)}%)', _nf.format(quote.ivaTotal)),
                pw.SizedBox(height: 6),
                pw.Divider(color: _primaryDark, thickness: 1),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _primaryDark,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _white),
                      ),
                      pw.Text('${_nf.format(quote.total)} ${quote.moneda}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, String value, {PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _textSecondary)),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color ?? _textPrimary)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONDITIONS
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _buildConditions(SaleQuote quote) {
    final hasConditions = (quote.condicionesPago != null && quote.condicionesPago!.isNotEmpty) ||
        (quote.notas != null && quote.notas!.isNotEmpty);

    if (!hasConditions) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _background,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TÉRMINOS Y CONDICIONES',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryDark, letterSpacing: 1),
          ),
          pw.SizedBox(height: 8),
          if (quote.condicionesPago != null && quote.condicionesPago!.isNotEmpty) ...[
            pw.Text('Condiciones de pago:',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textSecondary),
            ),
            pw.SizedBox(height: 2),
            pw.Text(quote.condicionesPago!,
              style: pw.TextStyle(fontSize: 8, color: _textPrimary),
            ),
            pw.SizedBox(height: 6),
          ],
          if (quote.notas != null && quote.notas!.isNotEmpty) ...[
            pw.Text('Notas:',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textSecondary),
            ),
            pw.SizedBox(height: 2),
            pw.Text(quote.notas!,
              style: pw.TextStyle(fontSize: 8, color: _textPrimary),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            'Esta cotización tiene una vigencia de ${quote.vigenciaDias} días a partir de su fecha de emisión. '
            'Los precios están expresados en ${quote.moneda} e incluyen IVA del ${quote.ivaPorcentaje.toStringAsFixed(0)}%. '
            'Precios sujetos a cambio sin previo aviso después de la fecha de vigencia.',
            style: pw.TextStyle(fontSize: 7, color: _textHint, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _buildFooter(pw.Context context, SaleQuote quote) {
    return pw.Column(
      children: [
        pw.Container(
          height: 2,
          decoration: pw.BoxDecoration(
            color: _primaryLight,
            borderRadius: pw.BorderRadius.circular(1),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Soluciones TI',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primaryDark),
                ),
                pw.Text('ventas@solucionesti.com.mx | 442 807 0229',
                  style: pw.TextStyle(fontSize: 7, color: _textHint),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('${quote.folio} ${quote.version > 1 ? "V${quote.version}" : ""}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primaryDark),
                ),
                pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: _textHint),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WATERMARK
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _buildWatermark(String text) {
    return pw.Center(
      child: pw.Transform.rotate(
        angle: -0.3,
        child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: 60,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#DDDDDD'),
          ),
        ),
      ),
    );
  }
}
