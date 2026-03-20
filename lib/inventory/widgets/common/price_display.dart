// lib/inventory/widgets/common/price_display.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class PriceDisplay extends StatelessWidget {
  final double price;
  final String? currency;
  final double? originalPrice;
  final double? discount;
  final bool showCurrency;
  final TextStyle? priceStyle;
  final bool compact;

  const PriceDisplay({
    super.key,
    required this.price,
    this.currency = 'MXN',
    this.originalPrice,
    this.discount,
    this.showCurrency = true,
    this.priceStyle,
    this.compact = false,
  });

  String get currencySymbol {
    return switch (currency) {
      'MXN' => '\$',
      'USD' => 'US\$',
      'EUR' => '€',
      _ => '\$',
    };
  }

  String get formattedPrice {
    final format = NumberFormat('#,##0.00', 'es_MX');
    return '$currencySymbol${format.format(price)}';
  }

  String get formattedOriginalPrice {
    if (originalPrice == null) return '';
    final format = NumberFormat('#,##0.00', 'es_MX');
    return '$currencySymbol${format.format(originalPrice!)}';
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Text(
        formattedPrice,
        style:
            priceStyle ??
            AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formattedPrice,
              style:
                  priceStyle ??
                  AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (showCurrency && currency != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  currency!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasDiscount) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                formattedOriginalPrice,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-${discountPercentage.toStringAsFixed(0)}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Widget para mostrar precio de compra y venta juntos
class PricePair extends StatelessWidget {
  final double purchasePrice;
  final double sellingPrice;
  final String? currency;

  const PricePair({
    super.key,
    required this.purchasePrice,
    required this.sellingPrice,
    this.currency = 'MXN',
  });

  double get margin => sellingPrice - purchasePrice;
  double get marginPercentage =>
      purchasePrice > 0 ? (margin / purchasePrice) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.00', 'es_MX');
    final isProfit = margin >= 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compra',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Text(
                '\$${format.format(purchasePrice)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Venta',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Text(
                '\$${format.format(sellingPrice)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Margen',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Text(
                '${isProfit ? '+' : ''}${marginPercentage.toStringAsFixed(1)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isProfit ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
