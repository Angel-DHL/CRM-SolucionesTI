// lib/crm/pages/crm_contact_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/crm_contact.dart';
import '../models/crm_activity_log.dart';
import '../models/crm_enums.dart';
import '../services/crm_service.dart';
import '../widgets/crm_status_chip.dart';
import '../widgets/crm_activity_tile.dart';
import 'crm_contact_form_page.dart';

class CrmContactDetailPage extends StatelessWidget {
  final String contactId;

  const CrmContactDetailPage({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CrmContact?>(
      stream: CrmService.instance.streamContact(contactId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final contact = snapshot.data;
        if (contact == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Contacto')),
            body: const Center(child: Text('Contacto no encontrado')),
          );
        }

        return _ContactDetailView(contact: contact);
      },
    );
  }
}

class _ContactDetailView extends StatelessWidget {
  final CrmContact contact;

  const _ContactDetailView({required this.contact});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActivityDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar nota'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
      title: Text(
        contact.nombreCompleto,
        style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
      ),
      actions: [
        if (contact.status.canAdvance)
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: FilledButton.icon(
              onPressed: () => _advanceStatus(context),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Avanzar a ${contact.status.nextStatus?.label ?? ''}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_rounded),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'change_status',
              child: ListTile(
                leading: Icon(Icons.swap_horiz_rounded),
                title: Text('Cambiar estatus'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'deactivate',
              child: ListTile(
                leading: Icon(Icons.block_rounded, color: AppColors.error),
                title: Text('Desactivar', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - Info
        SizedBox(
          width: 380,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: _buildInfoPanel(),
          ),
        ),

        // Divider
        Container(width: 1, color: AppColors.divider),

        // Right panel - Timeline
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: _buildTimelineSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        children: [
          _buildInfoPanel(),
          const SizedBox(height: AppDimensions.lg),
          _buildTimelineSection(),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // INFO PANEL
  // ══════════════════════════════════════════════════════════

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactHeader(),
        const SizedBox(height: AppDimensions.lg),
        _buildStatusPipeline(),
        const SizedBox(height: AppDimensions.lg),
        _buildContactInfo(),
        if (contact.hasDatosFiscales) ...[
          const SizedBox(height: AppDimensions.lg),
          _buildFiscalInfo(),
        ],
        if (contact.hasDireccion) ...[
          const SizedBox(height: AppDimensions.lg),
          _buildDireccionInfo(),
        ],
        if (contact.valorEstimado != null || contact.prioridad != null) ...[
          const SizedBox(height: AppDimensions.lg),
          _buildComercialInfo(),
        ],
        if (contact.mensaje != null && contact.mensaje!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.lg),
          _buildOriginalMessage(),
        ],
      ],
    );
  }

  Widget _buildContactHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Center(
              child: Text(
                contact.iniciales,
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            contact.nombreCompleto,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (contact.empresa != null) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              contact.empresa!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppDimensions.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CrmStatusChip(status: contact.status),
              if (contact.isFromWeb) ...[
                const SizedBox(width: AppDimensions.sm),
                CrmSourceChip(source: contact.source),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPipeline() {
    final statuses = [
      ContactStatus.lead,
      ContactStatus.prospecto,
      ContactStatus.clientePotencial,
      ContactStatus.cliente,
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pipeline',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isActive = contact.status.pipelineOrder >= status.pipelineOrder;
              final isCurrent = contact.status == status;

              return Expanded(
                child: Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: AppDimensions.animFast,
                          width: isCurrent ? 28 : 20,
                          height: isCurrent ? 28 : 20,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.divider,
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(
                                    color: AppColors.primaryLight,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: isActive
                                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.label,
                          style: AppTextStyles.caption.copyWith(
                            color: isActive ? AppColors.primary : AppColors.textHint,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (index < statuses.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: contact.status.pipelineOrder > status.pipelineOrder
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información de contacto', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.md),
          _DetailRow(icon: Icons.email_rounded, label: 'Email', value: contact.email),
          _DetailRow(icon: Icons.phone_rounded, label: 'Teléfono', value: contact.telefono),
          if (contact.empresa != null)
            _DetailRow(icon: Icons.business_rounded, label: 'Empresa', value: contact.empresa!),
          if (contact.cargo != null)
            _DetailRow(icon: Icons.work_rounded, label: 'Cargo', value: contact.cargo!),
          if (contact.industria != null)
            _DetailRow(icon: Icons.category_rounded, label: 'Industria', value: contact.industria!),
          if (contact.tamanoEmpresa != null)
            _DetailRow(icon: Icons.groups_rounded, label: 'Tamaño', value: contact.tamanoEmpresa!.label),
          if (contact.sitioWeb != null)
            _DetailRow(icon: Icons.language_rounded, label: 'Sitio web', value: contact.sitioWeb!),
          if (contact.interes != null)
            _DetailRow(icon: Icons.star_rounded, label: 'Interés', value: contact.interes!),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Registrado',
            value: '${contact.createdAt.day}/${contact.createdAt.month}/${contact.createdAt.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildFiscalInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.warning),
            const SizedBox(width: AppDimensions.sm),
            Text('Datos Fiscales', style: AppTextStyles.labelLarge.copyWith(color: AppColors.warning)),
          ]),
          const SizedBox(height: AppDimensions.md),
          if (contact.rfc != null) _DetailRow(icon: Icons.badge_rounded, label: 'RFC', value: contact.rfc!),
          if (contact.razonSocial != null) _DetailRow(icon: Icons.account_balance_rounded, label: 'Razón Social', value: contact.razonSocial!),
          if (contact.regimenFiscal != null) _DetailRow(icon: Icons.gavel_rounded, label: 'Régimen Fiscal', value: contact.regimenFiscal!),
          if (contact.usoCfdi != null) _DetailRow(icon: Icons.description_rounded, label: 'Uso CFDI', value: contact.usoCfdi!),
        ],
      ),
    );
  }

  Widget _buildDireccionInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: AppDimensions.sm),
            Text('Dirección', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: AppDimensions.md),
          if (contact.direccionCompleta != null)
            _DetailRow(icon: Icons.map_rounded, label: 'Dirección', value: contact.direccionCompleta!),
        ],
      ),
    );
  }

  Widget _buildComercialInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestión Comercial', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.md),
          if (contact.prioridad != null)
            _DetailRow(icon: Icons.priority_high_rounded, label: 'Prioridad', value: '${contact.prioridad!.emoji} ${contact.prioridad!.label}'),
          if (contact.valorEstimado != null)
            _DetailRow(icon: Icons.attach_money_rounded, label: 'Valor estimado', value: '\$${contact.valorEstimado!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildOriginalMessage() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message_rounded, size: 18, color: AppColors.info),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'Mensaje original del lead',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            contact.mensaje!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TIMELINE SECTION
  // ══════════════════════════════════════════════════════════

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: AppDimensions.sm),
            Text(
              'Historial de actividades',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),

        StreamBuilder<List<CrmActivityLog>>(
          stream: CrmService.instance.streamActivityLogs(contact.id),
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
              return Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                color: AppColors.error.withOpacity(0.1),
                child: Text(
                  'El historial requiere un índice en Firestore para funcionar. Revisa la consola de tu navegador o terminal para dar clic en el enlace de creación del índice.\n\nError: ${snapshot.error}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              );
            }

            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppColors.textHint.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'Sin actividades registradas',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) => CrmActivityTile(log: logs[index]),
            );
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════

  void _advanceStatus(BuildContext context) async {
    final nextStatus = contact.status.nextStatus;
    if (nextStatus == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: const Text('Avanzar estatus'),
        content: Text(
          '¿Mover a "${contact.nombreCompleto}" de ${contact.status.label} a ${nextStatus.label}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CrmService.instance.updateStatus(contact.id, nextStatus);
        HapticFeedback.mediumImpact();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Estatus actualizado a ${nextStatus.label}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'change_status':
        _showStatusChangeDialog(context);
        break;
      case 'edit':
        _showEditDialog(context);
        break;
      case 'deactivate':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            title: const Text('Desactivar contacto'),
            content: Text('¿Deseas desactivar a "${contact.nombreCompleto}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Desactivar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await CrmService.instance.deactivateContact(contact.id);
          if (context.mounted) Navigator.pop(context);
        }
        break;
    }
  }

  void _showStatusChangeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Text('Cambiar estatus', style: AppTextStyles.h4),
              ),
              const Divider(),
              ...ContactStatus.values.map((s) {
                final isCurrent = s == contact.status;
                return ListTile(
                  leading: Text(s.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(s.label),
                  trailing: isCurrent
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  selected: isCurrent,
                  onTap: isCurrent
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await CrmService.instance.updateStatus(contact.id, s);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Estatus cambiado a ${s.label}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                );
              }),
              const SizedBox(height: AppDimensions.md),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrmContactFormPage(contact: contact),
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    CrmActivityType selectedType = CrmActivityType.nota;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(Icons.note_add_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  const Text('Nueva actividad'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type selector
                    Wrap(
                      spacing: AppDimensions.sm,
                      runSpacing: AppDimensions.sm,
                      children: [
                        CrmActivityType.nota,
                        CrmActivityType.llamada,
                        CrmActivityType.email,
                        CrmActivityType.reunion,
                      ].map((type) {
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(type.label),
                          selected: isSelected,
                          onSelected: (_) => setDialogState(() => selectedType = type),
                          selectedColor: AppColors.primarySurface,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej: Llamada de seguimiento',
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    TextField(
                      controller: descripcionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Detalles de la actividad...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (tituloCtrl.text.trim().isEmpty) return;
                          setDialogState(() => saving = true);
                          try {
                            await CrmService.instance.addActivityLog(
                              contactId: contact.id,
                              type: selectedType,
                              titulo: tituloCtrl.text.trim(),
                              descripcion: descripcionCtrl.text.trim().isNotEmpty
                                  ? descripcionCtrl.text.trim()
                                  : null,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            HapticFeedback.lightImpact();
                          } catch (e) {
                            setDialogState(() => saving = false);
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
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
