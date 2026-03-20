// lib/inventory/widgets/dialogs/confirm_delete_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class ConfirmDeleteDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? itemName;
  final String confirmText;
  final bool requireConfirmation;
  final Future<void> Function() onConfirm;

  const ConfirmDeleteDialog({
    super.key,
    this.title = 'Confirmar eliminación',
    required this.message,
    this.itemName,
    this.confirmText = 'Eliminar',
    this.requireConfirmation = false,
    required this.onConfirm,
  });

  static Future<bool> show(
    BuildContext context, {
    String title = 'Confirmar eliminación',
    required String message,
    String? itemName,
    String confirmText = 'Eliminar',
    bool requireConfirmation = false,
    required Future<void> Function() onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        title: title,
        message: message,
        itemName: itemName,
        confirmText: confirmText,
        requireConfirmation: requireConfirmation,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _canConfirm = !widget.requireConfirmation;
    if (widget.requireConfirmation) {
      _confirmController.addListener(_checkConfirmation);
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _checkConfirmation() {
    final matches =
        _confirmController.text.toLowerCase() ==
        (widget.itemName?.toLowerCase() ?? 'eliminar');
    if (matches != _canConfirm) {
      setState(() => _canConfirm = matches);
    }
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);

    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.itemName != null) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      widget.itemName!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.requireConfirmation) ...[
            const SizedBox(height: AppDimensions.lg),
            Text(
              'Escribe "${widget.itemName ?? "eliminar"}" para confirmar:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: widget.itemName ?? 'eliminar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_canConfirm && !_isLoading) ? _handleConfirm : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(widget.confirmText),
        ),
      ],
    );
  }
}
