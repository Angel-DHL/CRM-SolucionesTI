// lib/inventory/widgets/filters/inventory_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class InventorySearchBar extends StatefulWidget {
  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final int activeFiltersCount;
  final Duration debounceDelay;

  const InventorySearchBar({
    super.key,
    this.initialValue,
    this.hintText = 'Buscar en inventario...',
    required this.onChanged,
    this.onFilterTap,
    this.activeFiltersCount = 0,
    this.debounceDelay = const Duration(milliseconds: 300),
  });

  @override
  State<InventorySearchBar> createState() => _InventorySearchBarState();
}

class _InventorySearchBarState extends State<InventorySearchBar> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDelay, () {
      widget.onChanged(value);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.sm,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      onPressed: _clear,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: AppDimensions.sm),
            Badge(
              isLabelVisible: widget.activeFiltersCount > 0,
              label: Text(widget.activeFiltersCount.toString()),
              child: IconButton(
                onPressed: widget.onFilterTap,
                icon: Icon(
                  Icons.tune_rounded,
                  color: widget.activeFiltersCount > 0
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: widget.activeFiltersCount > 0
                      ? AppColors.primarySurface
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
