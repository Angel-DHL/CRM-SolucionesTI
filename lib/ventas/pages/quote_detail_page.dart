// lib/ventas/pages/quote_detail_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/sale_quote.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';
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

class _QuoteDetailContent extends StatelessWidget {
  final SaleQuote quote;
  const _QuoteDetailContent({required this.quote});

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
                // Status & client header
                _buildHeader(context),
                const SizedBox(height: AppDimensions.lg),
                // Items table
                _buildItemsTable(),
                const SizedBox(height: AppDimensions.lg),
                // Financial summary
                _buildFinancialSummary(),
                const SizedBox(height: AppDimensions.lg),
                // Actions
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(quote.status.colorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text('${quote.status.emoji} ${quote.status.label}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(quote.status.colorValue))),
              ),
              const Spacer(),
              Text(quote.folio, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const Divider(),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente', style: AppTextStyles.caption),
                  Text(quote.clienteNombre, style: AppTextStyles.labelLarge),
                  if (quote.clienteEmpresa != null)
                    Text(quote.clienteEmpresa!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  if (quote.clienteRfc != null)
                    Text('RFC: ${quote.clienteRfc}', style: AppTextStyles.caption),
                ],
              )),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fecha', style: AppTextStyles.caption),
                  Text('${quote.createdAt.day}/${quote.createdAt.month}/${quote.createdAt.year}', style: AppTextStyles.labelLarge),
                  Text('Vigencia: ${quote.vigenciaDias} días', style: AppTextStyles.caption),
                ],
              )),
            ],
          ),
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
            child: Text('Productos / Servicios', style: AppTextStyles.labelLarge),
          ),
          const Divider(height: 1),
          ...quote.items.map((item) => ListTile(
            title: Text(item.nombre, style: AppTextStyles.bodyMedium),
            subtitle: Text('SKU: ${item.sku} • ${item.cantidad} ${item.unidad}', style: AppTextStyles.caption),
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
      child: Column(
        children: [
          _summaryRow('Subtotal', '\$${quote.subtotal.toStringAsFixed(2)}'),
          if (quote.descuentoGlobal > 0)
            _summaryRow('Descuento (${quote.descuentoGlobal}%)', '-\$${(quote.subtotal - quote.subtotalConDescuento).toStringAsFixed(2)}', color: AppColors.error),
          _summaryRow('IVA (${quote.ivaPorcentaje.toStringAsFixed(0)}%)', '\$${quote.ivaTotal.toStringAsFixed(2)}'),
          const Divider(),
          _summaryRow('Total', '\$${quote.total.toStringAsFixed(2)} ${quote.moneda}', isBold: true),
        ],
      ),
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

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.md,
      children: [
        if (quote.status.canSend)
          FilledButton.icon(
            onPressed: () async {
              await VentasService.instance.sendQuote(quote.id);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cotización enviada'), backgroundColor: AppColors.success));
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Enviar cotización'),
          ),
        if (quote.status.canAccept)
          FilledButton.icon(
            onPressed: () async {
              await VentasService.instance.acceptQuote(quote.id);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cotización aceptada'), backgroundColor: AppColors.success));
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Aceptar'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          ),
        if (quote.status.canAccept)
          OutlinedButton.icon(
            onPressed: () async {
              await VentasService.instance.rejectQuote(quote.id);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cotización rechazada'), backgroundColor: AppColors.error));
            },
            icon: const Icon(Icons.close_rounded),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
        if (quote.status.canConvert)
          FilledButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Convertir a Orden de Venta'),
                  content: Text('Se creará una orden de venta desde ${quote.folio} y se descontará el inventario.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Convertir')),
                  ],
                ),
              );
              if (confirm == true) {
                await VentasService.instance.convertQuoteToOrder(quote);
                if (context.mounted) {
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
