// lib/ventas/pages/orders_list_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/sale_order.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';
import 'order_detail_page.dart';

class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SaleOrder>>(
      stream: VentasService.instance.streamOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: AppDimensions.md),
                Text('No hay órdenes de venta', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
                const SizedBox(height: AppDimensions.sm),
                Text('Las órdenes se crean al aceptar cotizaciones', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppDimensions.md),
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Color(o.status.colorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Center(child: Text(o.status.emoji, style: const TextStyle(fontSize: 20))),
                ),
                title: Row(
                  children: [
                    Text(o.folio, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    const SizedBox(width: AppDimensions.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(o.paymentStatus.colorValue).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(o.paymentStatus.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(o.paymentStatus.colorValue))),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(o.clienteNombre, style: AppTextStyles.bodyMedium),
                    Text('Desde: ${o.quoteFolio} • ${o.totalItems} productos',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${o.total.toStringAsFixed(0)}', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                    if (o.saldoPendiente > 0)
                      Text('Saldo: \$${o.saldoPendiente.toStringAsFixed(0)}', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                  ],
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id))),
              ),
            );
          },
        );
      },
    );
  }
}
