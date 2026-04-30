// lib/inventory/widgets/forms/item_form_sections/pricing_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class PricingSection extends StatelessWidget {
  final TextEditingController purchasePriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController rentalPriceController;
  final TextEditingController taxRateController;
  final TextEditingController discountController;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final bool showRentalPrice;

  const PricingSection({
    super.key,
    required this.purchasePriceController,
    required this.sellingPriceController,
    required this.rentalPriceController,
    required this.taxRateController,
    required this.discountController,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.showRentalPrice = false,
  });

  static const List<String> currencies = ['MXN', 'USD', 'EUR'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(icon: Icons.attach_money_rounded, title: 'Precios'),
        const SizedBox(height: AppDimensions.lg),

        // Currency selector
        DropdownButtonFormField<String>(
          value: selectedCurrency,
          decoration: InputDecoration(
            labelText: 'Moneda',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.currency_exchange_rounded),
          ),
          items: currencies.map((currency) {
            final symbol = switch (currency) {
              'MXN' => '\$ MXN',
              'USD' => 'US\$ USD',
              'EUR' => '€ EUR',
              _ => currency,
            };
            return DropdownMenuItem(value: currency, child: Text(symbol));
          }).toList(),
          onChanged: (value) {
            if (value != null) onCurrencyChanged(value);
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // Purchase and selling prices
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: purchasePriceController,
                decoration: InputDecoration(
                  labelText: 'Precio de compra',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Precio inválido';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: sellingPriceController,
                decoration: InputDecoration(
                  labelText: 'Precio de venta',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Precio inválido';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        // Rental price (optional)
        if (showRentalPrice) ...[
          const SizedBox(height: AppDimensions.md),
          TextFormField(
            controller: rentalPriceController,
            decoration: InputDecoration(
              labelText: 'Precio de renta (opcional)',
              prefixText: '\$ ',
              hintText: 'Por día/mes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
        ],

        const SizedBox(height: AppDimensions.md),

        // Tax and discount
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: taxRateController,
                decoration: InputDecoration(
                  labelText: 'Impuesto',
                  suffixText: '%',
                  hintText: '16',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: discountController,
                decoration: InputDecoration(
                  labelText: 'Descuento',
                  suffixText: '%',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.md),

        // Margin calculator
        _MarginCalculator(
          purchasePriceController: purchasePriceController,
          sellingPriceController: sellingPriceController,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppDimensions.sm),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MarginCalculator extends StatefulWidget {
  final TextEditingController purchasePriceController;
  final TextEditingController sellingPriceController;

  const _MarginCalculator({
    required this.purchasePriceController,
    required this.sellingPriceController,
  });

  @override
  State<_MarginCalculator> createState() => _MarginCalculatorState();
}

class _MarginCalculatorState extends State<_MarginCalculator> {
  double _margin = 0;
  double _marginPercentage = 0;

  @override
  void initState() {
    super.initState();
    widget.purchasePriceController.addListener(_calculate);
    widget.sellingPriceController.addListener(_calculate);
    _calculate();
  }

  void _calculate() {
    final purchase = double.tryParse(widget.purchasePriceController.text) ?? 0;
    final selling = double.tryParse(widget.sellingPriceController.text) ?? 0;

    setState(() {
      _margin = selling - purchase;
      _marginPercentage = purchase > 0 ? (_margin / purchase) * 100 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = _margin >= 0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: (isProfit ? AppColors.success : AppColors.error).withOpacity(
          0.1,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: (isProfit ? AppColors.success : AppColors.error).withOpacity(
            0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isProfit ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Margen de ganancia',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '\$${_margin.toStringAsFixed(2)} (${_marginPercentage.toStringAsFixed(1)}%)',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isProfit ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
