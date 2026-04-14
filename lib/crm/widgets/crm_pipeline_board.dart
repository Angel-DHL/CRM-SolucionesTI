// lib/crm/widgets/crm_pipeline_board.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/crm_contact.dart';
import '../models/crm_enums.dart';
import '../services/crm_service.dart';
import 'crm_contact_card.dart';

/// Vista Kanban del pipeline CRM con columnas por estatus
class CrmPipelineBoard extends StatelessWidget {
  final List<CrmContact> contacts;
  final ValueChanged<CrmContact>? onContactTap;

  const CrmPipelineBoard({
    super.key,
    required this.contacts,
    this.onContactTap,
  });

  static const _pipelineStatuses = [
    ContactStatus.lead,
    ContactStatus.prospecto,
    ContactStatus.clientePotencial,
    ContactStatus.cliente,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth > 900
            ? (constraints.maxWidth - (AppDimensions.md * 3)) / 4
            : 280.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _pipelineStatuses.map((status) {
              final columnContacts = contacts
                  .where((c) => c.status == status)
                  .toList();

              return Container(
                width: columnWidth,
                margin: const EdgeInsets.only(right: AppDimensions.md),
                child: _PipelineColumn(
                  status: status,
                  contacts: columnContacts,
                  onContactTap: onContactTap,
                  onStatusChange: (contact, newStatus) {
                    CrmService.instance.updateStatus(contact.id, newStatus);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _PipelineColumn extends StatelessWidget {
  final ContactStatus status;
  final List<CrmContact> contacts;
  final ValueChanged<CrmContact>? onContactTap;
  final void Function(CrmContact contact, ContactStatus newStatus)? onStatusChange;

  const _PipelineColumn({
    required this.status,
    required this.contacts,
    this.onContactTap,
    this.onStatusChange,
  });

  Color get _headerColor => switch (status) {
    ContactStatus.lead => AppColors.info,
    ContactStatus.prospecto => AppColors.warning,
    ContactStatus.clientePotencial => const Color(0xFFE67E22),
    ContactStatus.cliente => AppColors.success,
    ContactStatus.inactivo => AppColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: _headerColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusMd),
              ),
              border: Border(
                bottom: BorderSide(color: _headerColor.withOpacity(0.2), width: 2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _headerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    status.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _headerColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _headerColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    '${contacts.length}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: _headerColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Center(
                child: Text(
                  'Sin contactos',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.sm),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                  child: _PipelineCard(
                    contact: contact,
                    onTap: () => onContactTap?.call(contact),
                    onAdvance: status.canAdvance && status.nextStatus != null
                        ? () => onStatusChange?.call(contact, status.nextStatus!)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final CrmContact contact;
  final VoidCallback? onTap;
  final VoidCallback? onAdvance;

  const _PipelineCard({
    required this.contact,
    this.onTap,
    this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        contact.iniciales,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
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
                        if (contact.empresa != null)
                          Text(
                            contact.empresa!,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              if (contact.email.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        contact.email,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Advance button
              if (onAdvance != null) ...[
                const SizedBox(height: AppDimensions.sm),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: OutlinedButton.icon(
                    onPressed: onAdvance,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text(
                      'Avanzar a ${contact.status.nextStatus?.label ?? ''}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
