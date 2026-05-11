// lib/soporte/pages/case_detail_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/support_case.dart';
import '../models/support_enums.dart';
import '../services/support_service.dart';
import '../services/ai_support_service.dart';

class CaseDetailPage extends StatefulWidget {
  final String caseId;
  const CaseDetailPage({super.key, required this.caseId});

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  final _commentCtrl = TextEditingController();
  final _solucionCtrl = TextEditingController();
  bool _generatingArticle = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _solucionCtrl.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    await SupportService.instance.addComment(widget.caseId, text);
    _commentCtrl.clear();
  }

  Future<void> _changeStatus(CaseStatus newStatus) async {
    await SupportService.instance.changeStatus(widget.caseId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado cambiado a ${newStatus.label}'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _resolveCase() async {
    final solucion = _solucionCtrl.text.trim();
    if (solucion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la solución antes de resolver'), backgroundColor: AppColors.warning),
      );
      return;
    }
    await SupportService.instance.resolveCase(widget.caseId, solucion);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Caso resuelto!'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _generateArticle(SupportCase caso) async {
    setState(() => _generatingArticle = true);
    try {
      await AiSupportService.instance.generateArticleFromCase(caso);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Artículo generado en la Base de Conocimiento'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generando artículo: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _generatingArticle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy HH:mm', 'es_MX');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Detalle del Caso', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<SupportCase?>(
        stream: SupportService.instance.streamCase(widget.caseId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final caso = snap.data;
          if (caso == null) {
            return const Center(child: Text('Caso no encontrado'));
          }

          if (caso.solucion != null && _solucionCtrl.text.isEmpty) {
            _solucionCtrl.text = caso.solucion!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(caso, df),
                    const SizedBox(height: AppDimensions.lg),

                    // Info grid
                    _buildInfoGrid(caso, df),
                    const SizedBox(height: AppDimensions.lg),

                    // Descripción
                    _buildSection('Descripción del Problema', Icons.description_rounded, caso.descripcion),
                    const SizedBox(height: AppDimensions.lg),

                    // Solución
                    _buildSolutionSection(caso),
                    const SizedBox(height: AppDimensions.lg),

                    // IA Article generation
                    if (caso.isResolved) _buildAiSection(caso),
                    if (caso.isResolved) const SizedBox(height: AppDimensions.lg),

                    // Acciones de estado
                    if (caso.isOpen) _buildStatusActions(caso),
                    if (caso.isOpen) const SizedBox(height: AppDimensions.lg),

                    // Comentarios
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(SupportCase caso, DateFormat df) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: caso.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(caso.status.icon, size: 16, color: caso.status.color),
                  const SizedBox(width: 4),
                  Text(caso.status.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: caso.status.color)),
                ]),
              ),
              const SizedBox(width: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: caso.priority.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(caso.priority.icon, size: 14, color: caso.priority.color),
                  const SizedBox(width: 4),
                  Text(caso.priority.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: caso.priority.color)),
                ]),
              ),
              const Spacer(),
              Text(caso.folio, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(caso.titulo, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(SupportCase caso, DateFormat df) {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.sm,
      children: [
        _infoChip(Icons.category_rounded, 'Categoría', caso.category.label),
        _infoChip(Icons.source_rounded, 'Origen', caso.origin.label),
        _infoChip(Icons.person_rounded, 'Asignado', caso.assignedName),
        _infoChip(Icons.access_time_rounded, 'Creado', df.format(caso.createdAt)),
        if (caso.resolvedAt != null) _infoChip(Icons.check_circle_rounded, 'Resuelto', df.format(caso.resolvedAt!)),
        if (caso.tiempoResolucion != null) _infoChip(Icons.timer_rounded, 'Tiempo', caso.tiempoResolucionText),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
              Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppDimensions.sm),
            Text(title, style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: AppDimensions.md),
          SelectableText(content, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildSolutionSection(SupportCase caso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: caso.isResolved
            ? AppColors.success.withValues(alpha: 0.03)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: caso.isResolved ? AppColors.success.withValues(alpha: 0.3) : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_rounded, size: 18, color: caso.isResolved ? AppColors.success : AppColors.warning),
            const SizedBox(width: AppDimensions.sm),
            Text('Solución', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: AppDimensions.md),
          if (caso.isResolved && caso.solucion != null)
            SelectableText(caso.solucion!, style: AppTextStyles.bodyMedium.copyWith(height: 1.6))
          else ...[
            TextFormField(
              controller: _solucionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe la solución aplicada...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _resolveCase,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Marcar como Resuelto'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiSection(SupportCase caso) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1).withValues(alpha: 0.05), const Color(0xFF8B5CF6).withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 24, color: Color(0xFF6366F1)),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generar artículo con IA', style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600, color: const Color(0xFF6366F1),
                )),
                Text(
                  'Crear un artículo de base de conocimiento a partir de este caso resuelto',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          _generatingArticle
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : FilledButton.icon(
                  onPressed: () => _generateArticle(caso),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Generar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(SupportCase caso) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: [
        if (caso.status == CaseStatus.abierto)
          OutlinedButton.icon(
            onPressed: () => _changeStatus(CaseStatus.enProgreso),
            icon: Icon(CaseStatus.enProgreso.icon, size: 16),
            label: const Text('Iniciar'),
          ),
        if (caso.status != CaseStatus.enEspera)
          OutlinedButton.icon(
            onPressed: () => _changeStatus(CaseStatus.enEspera),
            icon: Icon(CaseStatus.enEspera.icon, size: 16),
            label: const Text('En Espera'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
          ),
        OutlinedButton.icon(
          onPressed: () => _changeStatus(CaseStatus.cerrado),
          icon: Icon(CaseStatus.cerrado.icon, size: 16),
          label: const Text('Cerrar'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.chat_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: AppDimensions.sm),
            Text('Comentarios', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: AppDimensions.md),
          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              IconButton.filled(
                onPressed: _addComment,
                icon: const Icon(Icons.send_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          // Comments list
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupportService.instance.streamComments(widget.caseId),
            builder: (context, snap) {
              final comments = snap.data ?? [];
              if (comments.isEmpty) {
                return Text('Sin comentarios aún', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint));
              }

              return Column(
                children: comments.map((c) {
                  final email = (c['authorEmail'] ?? '').toString();
                  final text = (c['text'] ?? '').toString();
                  final ts = c['createdAt'] is Timestamp
                      ? (c['createdAt'] as Timestamp).toDate().toLocal()
                      : DateTime.now();

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(email.isNotEmpty ? email[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: Text(email.split('@').first, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            Text(DateFormat('dd/MM HH:mm').format(ts), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
