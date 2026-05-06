// lib/ventas/pages/quote_detail_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/sale_quote.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';
import '../services/quote_pdf_generator.dart';
import 'quote_form_page.dart';

class QuoteDetailPage extends StatelessWidget {
  final String quoteId;
  const QuoteDetailPage({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SaleQuote?>(
      stream: VentasService.instance.streamQuote(quoteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final quote = snapshot.data;
        if (quote == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cotización')),
            body: const Center(child: Text('Cotización no encontrada')),
          );
        }
        return _QuoteDetailContent(quote: quote);
      },
    );
  }
}

class _QuoteDetailContent extends StatefulWidget {
  final SaleQuote quote;
  const _QuoteDetailContent({required this.quote});

  @override
  State<_QuoteDetailContent> createState() => _QuoteDetailContentState();
}

class _QuoteDetailContentState extends State<_QuoteDetailContent> {
  SaleQuote get quote => widget.quote;
  bool _generatingPdf = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(quote.folio, style: AppTextStyles.h3),
        actions: [
          if (quote.canEdit)
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteFormPage(quote: quote))),
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimensions.lg),
                _buildItemsTable(),
                const SizedBox(height: AppDimensions.lg),
                _buildFinancialSummary(),
                if (quote.condicionesPago != null || quote.notas != null) ...[
                  const SizedBox(height: AppDimensions.lg),
                  _buildConditions(),
                ],
                if (quote.hasBeenEmailed) ...[
                  const SizedBox(height: AppDimensions.lg),
                  _buildEmailStatus(),
                ],
                const SizedBox(height: AppDimensions.lg),
                _buildDocumentActions(),
                const SizedBox(height: AppDimensions.lg),
                _buildStatusActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(quote.status.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text('${quote.status.emoji} ${quote.status.label}',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(quote.status.colorValue))),
            ),
            if (quote.version > 1) ...[
              const SizedBox(width: 8),
              Chip(label: Text('V${quote.version}', style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
            ],
            if (quote.porVencer) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
                child: Text('⚠️ ${quote.diasRestantes} días restantes', style: const TextStyle(fontSize: 11, color: AppColors.warning)),
              ),
            ],
            const Spacer(),
            Text(quote.folio, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cliente', style: AppTextStyles.caption),
              Text(quote.clienteNombre, style: AppTextStyles.labelLarge),
              if (quote.clienteEmpresa != null) Text(quote.clienteEmpresa!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              if (quote.clienteRfc != null) Text('RFC: ${quote.clienteRfc}', style: AppTextStyles.caption),
              if (quote.clienteEmail != null) Text(quote.clienteEmail!, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              if (quote.clienteDireccion != null) Text(quote.clienteDireccion!, style: AppTextStyles.caption),
            ])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fecha', style: AppTextStyles.caption),
              Text('${quote.createdAt.day}/${quote.createdAt.month}/${quote.createdAt.year}', style: AppTextStyles.labelLarge),
              Text('Vigencia: ${quote.vigenciaDias} días', style: AppTextStyles.caption),
              if (quote.fechaExpiracion != null)
                Text('Vence: ${quote.fechaExpiracion!.day}/${quote.fechaExpiracion!.month}/${quote.fechaExpiracion!.year}', style: AppTextStyles.caption),
            ])),
          ]),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Text('Productos / Servicios (${quote.totalItems})', style: AppTextStyles.labelLarge),
          ),
          const Divider(height: 1),
          ...quote.items.map((item) => ListTile(
            title: Text(item.nombre, style: AppTextStyles.bodyMedium),
            subtitle: Text('SKU: ${item.sku} • ${item.cantidad.toStringAsFixed(0)} ${item.unidad}${item.descuento > 0 ? ' • Desc: ${item.descuento.toStringAsFixed(0)}%' : ''}', style: AppTextStyles.caption),
            trailing: Text('\$${item.subtotal.toStringAsFixed(2)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          )),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        _summaryRow('Subtotal', '\$${quote.subtotal.toStringAsFixed(2)}'),
        if (quote.descuentoGlobal > 0)
          _summaryRow('Descuento (${quote.descuentoGlobal.toStringAsFixed(0)}%)', '-\$${(quote.subtotal - quote.subtotalConDescuento).toStringAsFixed(2)}', color: AppColors.error),
        _summaryRow('IVA (${quote.ivaPorcentaje.toStringAsFixed(0)}%)', '\$${quote.ivaTotal.toStringAsFixed(2)}'),
        const Divider(),
        _summaryRow('Total', '\$${quote.total.toStringAsFixed(2)} ${quote.moneda}', isBold: true),
      ]),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
          Text(value, style: (isBold ? AppTextStyles.h4 : AppTextStyles.labelLarge).copyWith(color: color ?? AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildConditions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Condiciones', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        if (quote.condicionesPago != null) Text(quote.condicionesPago!, style: AppTextStyles.bodySmall),
        if (quote.notas != null) ...[
          const SizedBox(height: AppDimensions.sm),
          Text('Notas: ${quote.notas!}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ]),
    );
  }

  Widget _buildEmailStatus() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(children: [
        const Icon(Icons.mark_email_read_rounded, color: AppColors.info),
        const SizedBox(width: AppDimensions.sm),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enviada por email', style: AppTextStyles.labelMedium.copyWith(color: AppColors.info)),
          Text('A: ${quote.emailEnviadoA ?? ""}  •  ${quote.emailEnviadoAt?.day}/${quote.emailEnviadoAt?.month}/${quote.emailEnviadoAt?.year}', style: AppTextStyles.caption),
        ]),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DOCUMENT ACTIONS — PDF, Email, Duplicar
  // ═══════════════════════════════════════════════════════════

  Widget _buildDocumentActions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acciones del documento', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          Wrap(
            spacing: AppDimensions.md,
            runSpacing: AppDimensions.md,
            children: [
              // Descargar / Imprimir PDF
              OutlinedButton.icon(
                onPressed: _generatingPdf ? null : _downloadPdf,
                icon: _generatingPdf
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Descargar PDF'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              ),

              // Vista previa PDF
              OutlinedButton.icon(
                onPressed: _generatingPdf ? null : _previewPdf,
                icon: const Icon(Icons.preview_rounded),
                label: const Text('Vista previa'),
              ),

              // Enviar por email
              if (quote.clienteEmail != null && quote.clienteEmail!.isNotEmpty)
                FilledButton.icon(
                  onPressed: _generatingPdf ? null : () => _sendEmail(context),
                  icon: const Icon(Icons.email_rounded),
                  label: const Text('Enviar por email'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.info),
                ),

              // Duplicar cotización
              OutlinedButton.icon(
                onPressed: () => _duplicateQuote(context),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Duplicar'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _generatingPdf = true);
    try {
      final pdfBytes = await QuotePdfGenerator.generate(quote);
      await Printing.sharePdf(bytes: pdfBytes, filename: '${quote.folio}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generando PDF: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _previewPdf() async {
    setState(() => _generatingPdf = true);
    try {
      final pdfBytes = await QuotePdfGenerator.generate(quote);
      if (!mounted) return;
      setState(() => _generatingPdf = false);
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Vista previa — ${quote.folio}')),
          body: PdfPreview(
            build: (_) async => pdfBytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
          ),
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _generatingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final email = quote.clienteEmail ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📧 Enviar cotización por email'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Se generará el PDF y se enviará por correo electrónico a:'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.email_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(email, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary))),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Cotización: ${quote.folio}', style: AppTextStyles.caption),
          Text('Total: \$${quote.total.toStringAsFixed(2)} ${quote.moneda}', style: AppTextStyles.caption),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _generatingPdf = true);
    try {
      // 1. Generar PDF
      final pdfBytes = await QuotePdfGenerator.generate(quote);
      final pdfBase64 = base64Encode(pdfBytes);

      // 2. Obtener token de autenticación
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');
      final token = await user.getIdToken();

      // 3. Llamar Cloud Function para enviar email
      final uri = Uri.parse(
        'https://us-central1-crm-solucionesti.cloudfunctions.net/sendQuoteEmail',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'quoteId': quote.id,
          'toEmail': email,
          'toName': quote.clienteNombre,
          'pdfBase64': pdfBase64,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Cotización enviada por email exitosamente'),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error enviando email: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _duplicateQuote(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📋 Duplicar cotización'),
        content: Text('Se creará una nueva cotización como borrador basada en ${quote.folio} (versión ${quote.version + 1}).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Duplicar')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    try {
      await VentasService.instance.duplicateQuote(quote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cotización duplicada'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS ACTIONS
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatusActions() {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.md,
      children: [
        if (quote.status.canSend)
          FilledButton.icon(
            onPressed: () async {
              await VentasService.instance.sendQuote(quote.id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cotización enviada'), backgroundColor: AppColors.success));
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Marcar como enviada'),
          ),
        if (quote.status.canAccept)
          FilledButton.icon(
            onPressed: () async {
              await VentasService.instance.acceptQuote(quote.id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cotización aceptada'), backgroundColor: AppColors.success));
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Aceptar'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          ),
        if (quote.status.canAccept)
          OutlinedButton.icon(
            onPressed: () async {
              await VentasService.instance.rejectQuote(quote.id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cotización rechazada'), backgroundColor: AppColors.error));
            },
            icon: const Icon(Icons.close_rounded),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
        if (quote.canConvert)
          FilledButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Convertir a Orden de Venta'),
                  content: Text('Se creará una orden desde ${quote.folio} y se descontará inventario.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Convertir')),
                  ],
                ),
              );
              if (confirm == true) {
                await VentasService.instance.convertQuoteToOrder(quote);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Orden de venta creada'), backgroundColor: AppColors.success));
                  Navigator.pop(context);
                }
              }
            },
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Convertir a Orden'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7E57C2)),
          ),
      ],
    );
  }
}
