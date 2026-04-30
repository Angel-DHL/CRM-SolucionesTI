// lib/ventas/pages/order_detail_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/sale_order.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SaleOrder?>(
      stream: VentasService.instance.streamOrder(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final order = snapshot.data;
        if (order == null) {
          return Scaffold(appBar: AppBar(title: const Text('Orden')), body: const Center(child: Text('Orden no encontrada')));
        }
        return _OrderContent(order: order);
      },
    );
  }
}

class _OrderContent extends StatelessWidget {
  final SaleOrder order;
  const _OrderContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(order.folio, style: AppTextStyles.h3),
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
                _buildItems(),
                const SizedBox(height: AppDimensions.lg),
                _buildPaymentInfo(context),
                const SizedBox(height: AppDimensions.lg),
                _buildActions(context),
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
                color: Color(order.status.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text('${order.status.emoji} ${order.status.label}',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(order.status.colorValue))),
            ),
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(order.paymentStatus.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(order.paymentStatus.label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(order.paymentStatus.colorValue))),
            ),
            const Spacer(),
            Text(order.folio, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: AppDimensions.md),
          const Divider(),
          const SizedBox(height: AppDimensions.md),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cliente', style: AppTextStyles.caption),
              Text(order.clienteNombre, style: AppTextStyles.labelLarge),
              if (order.clienteEmpresa != null) Text(order.clienteEmpresa!, style: AppTextStyles.bodySmall),
            ])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cotización origen', style: AppTextStyles.caption),
              Text(order.quoteFolio, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            ])),
          ]),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(AppDimensions.md), child: Text('Productos', style: AppTextStyles.labelLarge)),
          const Divider(height: 1),
          ...order.items.map((item) => ListTile(
            title: Text(item.nombre, style: AppTextStyles.bodyMedium),
            subtitle: Text('${item.cantidad} ${item.unidad} × \$${item.precioUnitario.toStringAsFixed(2)}', style: AppTextStyles.caption),
            trailing: Text('\$${item.subtotal.toStringAsFixed(2)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: AppTextStyles.h4),
              Text('\$${order.total.toStringAsFixed(2)} ${order.moneda}', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
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
          Text('Pagos', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total pagado', style: AppTextStyles.bodyMedium),
            Text('\$${order.totalPagado.toStringAsFixed(2)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.success)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Saldo pendiente', style: AppTextStyles.bodyMedium),
            Text('\$${order.saldoPendiente.toStringAsFixed(2)}',
              style: AppTextStyles.labelLarge.copyWith(color: order.saldoPendiente > 0 ? AppColors.error : AppColors.success)),
          ]),
          if (order.pagos.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            const Divider(),
            ...order.pagos.map((p) => ListTile(
              dense: true,
              leading: Icon(Icons.payment_rounded, size: 18, color: AppColors.success),
              title: Text('\$${p.monto.toStringAsFixed(2)} — ${p.metodo.label}', style: AppTextStyles.bodySmall),
              subtitle: p.referencia != null ? Text('Ref: ${p.referencia}', style: AppTextStyles.caption) : null,
              trailing: Text('${p.fecha.day}/${p.fecha.month}/${p.fecha.year}', style: AppTextStyles.caption),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.md,
      children: [
        if (!order.isPaidInFull)
          FilledButton.icon(
            onPressed: () => _showPaymentDialog(context),
            icon: const Icon(Icons.payment_rounded),
            label: const Text('Registrar pago'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          ),
        if (order.status != OrderStatus.completada && order.status != OrderStatus.cancelada)
          FilledButton.icon(
            onPressed: () async {
              await VentasService.instance.completeOrder(order.id);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Orden completada'), backgroundColor: AppColors.success),
              );
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Marcar como completada'),
          ),
      ],
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final montoCtrl = TextEditingController(text: order.saldoPendiente.toStringAsFixed(2));
    final refCtrl = TextEditingController();
    PaymentMethod metodo = PaymentMethod.transferencia;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Registrar pago'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto', prefixIcon: Icon(Icons.attach_money_rounded)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppDimensions.md),
                DropdownButtonFormField<PaymentMethod>(
                  value: metodo,
                  decoration: const InputDecoration(labelText: 'Método de pago'),
                  items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
                  onChanged: (v) => setDState(() => metodo = v ?? PaymentMethod.transferencia),
                ),
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Referencia (opcional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final monto = double.tryParse(montoCtrl.text) ?? 0;
                if (monto <= 0) return;
                Navigator.pop(ctx);
                await VentasService.instance.registerPayment(
                  orderId: order.id,
                  monto: monto,
                  metodo: metodo,
                  referencia: refCtrl.text.isNotEmpty ? refCtrl.text : null,
                );
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Pago registrado'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
