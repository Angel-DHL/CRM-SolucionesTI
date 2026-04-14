// lib/crm/widgets/crm_contact_card.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/crm_contact.dart';
import 'crm_status_chip.dart';

class CrmContactCard extends StatelessWidget {
  final CrmContact contact;
  final VoidCallback? onTap;
  final bool compact;

  const CrmContactCard({
    super.key,
    required this.contact,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: EdgeInsets.all(compact ? AppDimensions.sm : AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: compact ? _buildCompact() : _buildFull(),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Row(
      children: [
        _Avatar(initials: contact.iniciales, size: 36),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.nombreCompleto,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (contact.empresa != null && contact.empresa!.isNotEmpty)
                Text(
                  contact.empresa!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        CrmStatusChip(status: contact.status, compact: true, showEmoji: false),
      ],
    );
  }

  Widget _buildFull() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            _Avatar(initials: contact.iniciales, size: 44),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.nombreCompleto,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (contact.empresa != null && contact.empresa!.isNotEmpty)
                    Text(
                      contact.empresa!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            CrmStatusChip(status: contact.status),
          ],
        ),

        const SizedBox(height: AppDimensions.md),
        const Divider(height: 1),
        const SizedBox(height: AppDimensions.md),

        // Info rows
        Row(
          children: [
            Expanded(
              child: _InfoRow(
                icon: Icons.email_outlined,
                text: contact.email,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _InfoRow(
                icon: Icons.phone_outlined,
                text: contact.telefono,
              ),
            ),
          ],
        ),

        if (contact.isFromWeb) ...[
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              CrmSourceChip(source: contact.source),
              const Spacer(),
              Text(
                _formatDate(contact.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;

  const _Avatar({required this.initials, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: Text(
            text.isNotEmpty ? text : '—',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
