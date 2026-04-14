// lib/crm/widgets/crm_leads_inbox.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../services/crm_service.dart';

/// Widget de inbox de leads del sitio web con opción de convertir
class CrmLeadsInbox extends StatelessWidget {
  final int? limit;

  const CrmLeadsInbox({super.key, this.limit});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CrmService.instance.streamLeads(onlyUnread: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 32),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Error cargando leads',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          );
        }

        var leads = snapshot.data ?? [];
        if (limit != null && leads.length > limit!) {
          leads = leads.take(limit!).toList();
        }

        if (leads.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: AppColors.textHint.withOpacity(0.5)),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    'No hay leads pendientes',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leads.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
          itemBuilder: (context, index) {
            final lead = leads[index];
            return _LeadCard(lead: lead);
          },
        );
      },
    );
  }
}

class _LeadCard extends StatefulWidget {
  final Map<String, dynamic> lead;

  const _LeadCard({required this.lead});

  @override
  State<_LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<_LeadCard> {
  bool _converting = false;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final nombre = '${lead['nombre'] ?? ''} ${lead['apellidos'] ?? ''}'.trim();
    final email = (lead['email'] ?? '').toString();
    final telefono = (lead['telefono'] ?? '').toString();
    final mensaje = (lead['mensaje'] ?? '').toString();
    final leido = lead['leido'] == true;
    final estado = (lead['estado'] ?? '').toString();
    final isConverted = estado == 'convertido';

    DateTime? createdAt;
    if (lead['createdAt'] is Timestamp) {
      createdAt = (lead['createdAt'] as Timestamp).toDate().toLocal();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: !leido ? AppColors.info.withOpacity(0.4) : AppColors.divider,
          width: !leido ? 2 : 1,
        ),
        boxShadow: !leido
            ? [
                BoxShadow(
                  color: AppColors.info.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // New badge
                if (!leido)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: AppDimensions.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      'NUEVO',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),

                // Name
                Expanded(
                  child: Text(
                    nombre.isNotEmpty ? nombre : 'Sin nombre',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Date
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),

            const SizedBox(height: AppDimensions.sm),

            // Contact info
            Row(
              children: [
                if (email.isNotEmpty) ...[
                  Icon(Icons.email_outlined, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      email,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                ],
                if (telefono.isNotEmpty) ...[
                  Icon(Icons.phone_outlined, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    telefono,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),

            // Message preview
            if (mensaje.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  mensaje,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: AppDimensions.md),

            // Actions
            Row(
              children: [
                // Status indicator
                if (isConverted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Convertido',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (estado.isNotEmpty && estado != 'nuevo')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      estado,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const Spacer(),

                // Convert button
                if (!isConverted)
                  SizedBox(
                    height: 32,
                    child: FilledButton.icon(
                      onPressed: _converting ? null : _convertLead,
                      icon: _converting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_rounded, size: 16),
                      label: Text(
                        _converting ? 'Convirtiendo...' : 'Convertir',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertLead() async {
    final leadId = widget.lead['id'] as String?;
    if (leadId == null) return;

    setState(() => _converting = true);
    try {
      await CrmService.instance.convertLeadToContact(leadId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Lead convertido a contacto CRM'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}
