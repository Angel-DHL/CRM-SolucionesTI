// lib/crm/widgets/crm_pipeline_board.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/crm_contact.dart';
import '../models/crm_enums.dart';
import '../services/crm_service.dart';

/// Vista Kanban del pipeline CRM con Drag & Drop
class CrmPipelineBoard extends StatefulWidget {
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
  State<CrmPipelineBoard> createState() => _CrmPipelineBoardState();
}

class _CrmPipelineBoardState extends State<CrmPipelineBoard> {
  ContactStatus? _draggingOverStatus;

  Color _headerColor(ContactStatus status) => switch (status) {
    ContactStatus.lead => AppColors.info,
    ContactStatus.prospecto => AppColors.warning,
    ContactStatus.clientePotencial => const Color(0xFFE67E22),
    ContactStatus.cliente => AppColors.success,
    ContactStatus.inactivo => AppColors.textHint,
  };

  void _onStatusChange(CrmContact contact, ContactStatus newStatus) async {
    if (contact.status == newStatus) return;

    try {
      await CrmService.instance.updateStatus(contact.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${contact.nombreCompleto} movido a ${newStatus.label}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
            children: CrmPipelineBoard._pipelineStatuses.map((status) {
              final columnContacts = widget.contacts
                  .where((c) => c.status == status)
                  .toList();

              return Container(
                width: columnWidth,
                margin: const EdgeInsets.only(right: AppDimensions.md),
                child: _PipelineColumn(
                  status: status,
                  contacts: columnContacts,
                  headerColor: _headerColor(status),
                  isDragOver: _draggingOverStatus == status,
                  onContactTap: widget.onContactTap,
                  onStatusChange: _onStatusChange,
                  onDragOverChanged: (isOver) {
                    setState(() {
                      _draggingOverStatus = isOver ? status : null;
                    });
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

// ═══════════════════════════════════════════════════════════
// PIPELINE COLUMN — DragTarget
// ═══════════════════════════════════════════════════════════

class _PipelineColumn extends StatelessWidget {
  final ContactStatus status;
  final List<CrmContact> contacts;
  final Color headerColor;
  final bool isDragOver;
  final ValueChanged<CrmContact>? onContactTap;
  final void Function(CrmContact contact, ContactStatus newStatus) onStatusChange;
  final ValueChanged<bool> onDragOverChanged;

  const _PipelineColumn({
    required this.status,
    required this.contacts,
    required this.headerColor,
    required this.isDragOver,
    this.onContactTap,
    required this.onStatusChange,
    required this.onDragOverChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<CrmContact>(
      onWillAcceptWithDetails: (details) {
        final contact = details.data;
        if (contact.status == status) return false;
        onDragOverChanged(true);
        return true;
      },
      onLeave: (_) => onDragOverChanged(false),
      onAcceptWithDetails: (details) {
        onDragOverChanged(false);
        onStatusChange(details.data, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isAccepting = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isAccepting
                ? headerColor.withOpacity(0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isAccepting
                  ? headerColor.withOpacity(0.5)
                  : AppColors.divider,
              width: isAccepting ? 2.0 : 1.0,
            ),
            boxShadow: isAccepting
                ? [
                    BoxShadow(
                      color: headerColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══ HEADER ═══
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusMd),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: headerColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: headerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        status.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: headerColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: headerColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${contacts.length}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: headerColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ═══ DROP ZONE INDICATOR ═══
              if (isAccepting)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.move_down_rounded,
                        size: 16,
                        color: headerColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Soltar aquí',
                        style: AppTextStyles.caption.copyWith(
                          color: headerColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // ═══ CARDS ═══
              if (contacts.isEmpty && !isAccepting)
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
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.sm,
                      ),
                      child: _DraggablePipelineCard(
                        contact: contact,
                        headerColor: headerColor,
                        onTap: () => onContactTap?.call(contact),
                        onAdvance: status.canAdvance &&
                                status.nextStatus != null
                            ? () => onStatusChange(
                                contact,
                                status.nextStatus!,
                              )
                            : null,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DRAGGABLE PIPELINE CARD
// ═══════════════════════════════════════════════════════════

class _DraggablePipelineCard extends StatelessWidget {
  final CrmContact contact;
  final Color headerColor;
  final VoidCallback? onTap;
  final VoidCallback? onAdvance;

  const _DraggablePipelineCard({
    required this.contact,
    required this.headerColor,
    this.onTap,
    this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<CrmContact>(
      data: contact,
      delay: const Duration(milliseconds: 150),
      hapticFeedbackOnStart: true,
      // ═══ FEEDBACK MIENTRAS ARRASTRA ═══
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        shadowColor: headerColor.withOpacity(0.4),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: headerColor.withOpacity(0.5), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSm,
                  ),
                ),
                child: Center(
                  child: Text(
                    contact.iniciales,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contact.nombreCompleto,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
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
              Icon(
                Icons.drag_indicator_rounded,
                color: headerColor.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
      // ═══ PLACEHOLDER CUANDO SE ARRASTRA ═══
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _PipelineCardContent(
          contact: contact,
          onTap: null,
          onAdvance: null,
        ),
      ),
      // ═══ CARD NORMAL ═══
      child: _PipelineCardContent(
        contact: contact,
        onTap: onTap,
        onAdvance: onAdvance,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PIPELINE CARD CONTENT
// ═══════════════════════════════════════════════════════════

class _PipelineCardContent extends StatelessWidget {
  final CrmContact contact;
  final VoidCallback? onTap;
  final VoidCallback? onAdvance;

  const _PipelineCardContent({
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
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
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
                  // Drag hint icon
                  Icon(
                    Icons.drag_indicator_rounded,
                    size: 16,
                    color: AppColors.textHint.withOpacity(0.4),
                  ),
                ],
              ),

              if (contact.email.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 12,
                      color: AppColors.textHint,
                    ),
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

              // Priority & value badges
              if (contact.prioridad != null || contact.valorEstimado != null) ...[
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    if (contact.prioridad != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(contact.prioridad!.colorValue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${contact.prioridad!.emoji} ${contact.prioridad!.label}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(contact.prioridad!.colorValue),
                          ),
                        ),
                      ),
                    if (contact.prioridad != null &&
                        contact.valorEstimado != null)
                      const SizedBox(width: 4),
                    if (contact.valorEstimado != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          '\$${contact.valorEstimado!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
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
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
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
