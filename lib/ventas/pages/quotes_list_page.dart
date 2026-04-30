// lib/ventas/pages/quotes_list_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/sale_quote.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';
import 'quote_form_page.dart';
import 'quote_detail_page.dart';

class QuotesListPage extends StatelessWidget {
  const QuotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SaleQuote>>(
      stream: VentasService.instance.streamQuotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final quotes = snapshot.data ?? [];

        if (quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.request_quote_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: AppDimensions.md),
                Text('No hay cotizaciones', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
                const SizedBox(height: AppDimensions.md),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteFormPage())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear cotización'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final q = quotes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppDimensions.md),
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Color(q.status.colorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Center(child: Text(q.status.emoji, style: const TextStyle(fontSize: 20))),
                ),
                title: Row(
                  children: [
                    Text(q.folio, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    const SizedBox(width: AppDimensions.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(q.status.colorValue).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(q.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(q.status.colorValue))),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(q.clienteNombre, style: AppTextStyles.bodyMedium),
                    Text('${q.totalItems} productos • \$${q.total.toStringAsFixed(2)} ${q.moneda}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                trailing: Text('\$${q.total.toStringAsFixed(0)}', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteDetailPage(quoteId: q.id))),
              ),
            );
          },
        );
      },
    );
  }
}
