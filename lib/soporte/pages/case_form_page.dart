// lib/soporte/pages/case_form_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/support_case.dart';
import '../models/support_enums.dart';
import '../services/support_service.dart';
import '../services/ai_support_service.dart';

class CaseFormPage extends StatefulWidget {
  final SupportCase? existing;
  const CaseFormPage({super.key, this.existing});

  @override
  State<CaseFormPage> createState() => _CaseFormPageState();
}

class _CaseFormPageState extends State<CaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  CasePriority _priority = CasePriority.media;
  CaseCategory _category = CaseCategory.otro;
  bool _saving = false;
  String? _aiSuggestion;
  bool _loadingSuggestion = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _tituloCtrl.text = widget.existing!.titulo;
      _descripcionCtrl.text = widget.existing!.descripcion;
      _priority = widget.existing!.priority;
      _category = widget.existing!.category;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _askAiSuggestion() async {
    if (_tituloCtrl.text.isEmpty && _descripcionCtrl.text.isEmpty) return;

    setState(() => _loadingSuggestion = true);
    try {
      final suggestion = await AiSupportService.instance.suggestSolution(
        _tituloCtrl.text,
        _descripcionCtrl.text,
      );
      setState(() => _aiSuggestion = suggestion);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error consultando IA: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _loadingSuggestion = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.existing != null) {
        await SupportService.instance.updateCase(widget.existing!.copyWith(
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          priority: _priority,
          category: _category,
        ));
      } else {
        await SupportService.instance.createCase(SupportCase(
          id: '',
          folio: '',
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          status: CaseStatus.abierto,
          priority: _priority,
          category: _category,
          origin: CaseOrigin.manual,
          tags: [],
          createdByUid: '',
          createdByEmail: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null ? 'Caso actualizado' : 'Caso creado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(isEdit ? 'Editar Caso' : 'Nuevo Caso', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.md),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text('Título del caso *', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppDimensions.xs),
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: _inputDecoration('Ej: Equipo no enciende después de actualización'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Descripción
                  Text('Descripción del problema *', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppDimensions.xs),
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 5,
                    decoration: _inputDecoration('Describe el problema con detalle...'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Prioridad + Categoría
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prioridad', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: AppDimensions.xs),
                            DropdownButtonFormField<CasePriority>(
                              value: _priority,
                              decoration: _inputDecoration(''),
                              items: CasePriority.values.map((p) => DropdownMenuItem(
                                value: p,
                                child: Row(children: [
                                  Icon(p.icon, size: 16, color: p.color),
                                  const SizedBox(width: 8),
                                  Text(p.label),
                                ]),
                              )).toList(),
                              onChanged: (v) => setState(() => _priority = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Categoría', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: AppDimensions.xs),
                            DropdownButtonFormField<CaseCategory>(
                              value: _category,
                              decoration: _inputDecoration(''),
                              items: CaseCategory.values.map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(children: [
                                  Icon(c.icon, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(c.label),
                                ]),
                              )).toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // Sugerencia IA
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF6366F1)),
                            const SizedBox(width: AppDimensions.sm),
                            Text('Sugerencia IA', style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600, color: const Color(0xFF6366F1),
                            )),
                            const Spacer(),
                            _loadingSuggestion
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : TextButton.icon(
                                    onPressed: _askAiSuggestion,
                                    icon: const Icon(Icons.lightbulb_rounded, size: 16),
                                    label: const Text('Buscar solución'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6366F1),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                          ],
                        ),
                        if (_aiSuggestion != null) ...[
                          const SizedBox(height: AppDimensions.sm),
                          const Divider(),
                          const SizedBox(height: AppDimensions.sm),
                          SelectableText(
                            _aiSuggestion!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: AppDimensions.xs),
                            child: Text(
                              'Completa el título y descripción, luego presiona "Buscar solución" para que la IA sugiera una posible solución basada en la base de conocimiento.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
