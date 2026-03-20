// lib/inventory/widgets/forms/item_form_sections/service_details_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ServiceDetailsSection extends StatelessWidget {
  final TextEditingController estimatedDurationController;
  final List<String> requiredSkills;
  final ValueChanged<List<String>> onRequiredSkillsChanged;
  final bool isRecurring;
  final ValueChanged<bool> onIsRecurringChanged;
  final TextEditingController detailedDescriptionController;

  const ServiceDetailsSection({
    super.key,
    required this.estimatedDurationController,
    required this.requiredSkills,
    required this.onRequiredSkillsChanged,
    required this.isRecurring,
    required this.onIsRecurringChanged,
    required this.detailedDescriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          icon: Icons.miscellaneous_services_rounded,
          title: 'Detalles del Servicio',
        ),
        const SizedBox(height: AppDimensions.lg),

        // Duration
        Text('Duración del servicio', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: estimatedDurationController,
                decoration: InputDecoration(
                  labelText: 'Duración estimada',
                  hintText: 'Ej: 60',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.timer_rounded),
                  suffixText: 'minutos',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _DurationQuickSelect(
                onSelected: (minutes) {
                  estimatedDurationController.text = minutes.toString();
                },
              ),
            ),
          ],
        ),

        // Duration helper
        if (estimatedDurationController.text.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          _DurationDisplay(
            minutes: int.tryParse(estimatedDurationController.text) ?? 0,
          ),
        ],
        const SizedBox(height: AppDimensions.lg),

        // Recurring service
        SwitchListTile(
          title: const Text('Servicio recurrente'),
          subtitle: const Text('Este servicio se realiza de forma periódica'),
          value: isRecurring,
          onChanged: onIsRecurringChanged,
          contentPadding: EdgeInsets.zero,
          secondary: Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: isRecurring
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(
              Icons.repeat_rounded,
              color: isRecurring ? AppColors.success : AppColors.textHint,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // Required skills
        Text('Habilidades requeridas', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),

        _SkillsInput(
          skills: requiredSkills,
          onChanged: onRequiredSkillsChanged,
        ),

        const SizedBox(height: AppDimensions.lg),

        // Detailed description
        Text(
          'Descripción detallada del servicio',
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: AppDimensions.sm),

        TextFormField(
          controller: detailedDescriptionController,
          decoration: InputDecoration(
            hintText:
                'Describe en detalle qué incluye el servicio, procedimientos, requisitos, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: AppDimensions.md),

        // Service checklist template
        _ServiceChecklistHelper(),
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

class _DurationQuickSelect extends StatelessWidget {
  final ValueChanged<int> onSelected;

  const _DurationQuickSelect({required this.onSelected});

  static const List<int> _quickOptions = [30, 60, 90, 120, 180, 240];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      itemBuilder: (context) => _quickOptions.map((minutes) {
        return PopupMenuItem(
          value: minutes,
          child: Text(_formatDuration(minutes)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time_rounded, size: 18),
            const SizedBox(width: AppDimensions.xs),
            const Text('Rápido'),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hr${hours > 1 ? 's' : ''}';
    return '$hours hr${hours > 1 ? 's' : ''} $mins min';
  }
}

class _DurationDisplay extends StatelessWidget {
  final int minutes;

  const _DurationDisplay({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    String formatted;
    if (hours == 0) {
      formatted = '$mins minutos';
    } else if (mins == 0) {
      formatted = '$hours hora${hours > 1 ? 's' : ''}';
    } else {
      formatted = '$hours hora${hours > 1 ? 's' : ''} $mins minutos';
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: AppColors.info),
          const SizedBox(width: AppDimensions.xs),
          Text(
            'Duración: $formatted',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsInput extends StatefulWidget {
  final List<String> skills;
  final ValueChanged<List<String>> onChanged;

  const _SkillsInput({required this.skills, required this.onChanged});

  @override
  State<_SkillsInput> createState() => _SkillsInputState();
}

class _SkillsInputState extends State<_SkillsInput> {
  final _controller = TextEditingController();

  static const List<String> _suggestedSkills = [
    'Electricidad',
    'Plomería',
    'Programación',
    'Redes',
    'Soporte técnico',
    'Instalación',
    'Mantenimiento',
    'Diseño',
    'Consultoría',
    'Capacitación',
  ];

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !widget.skills.contains(trimmed)) {
      widget.onChanged([...widget.skills, trimmed]);
    }
    _controller.clear();
  }

  void _removeSkill(String skill) {
    widget.onChanged(widget.skills.where((s) => s != skill).toList());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableSuggestions = _suggestedSkills
        .where((s) => !widget.skills.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected skills
              if (widget.skills.isNotEmpty) ...[
                Wrap(
                  spacing: AppDimensions.xs,
                  runSpacing: AppDimensions.xs,
                  children: widget.skills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeSkill(skill),
                          backgroundColor: AppColors.primarySurface,
                          deleteIconColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppDimensions.sm),
              ],

              // Text input
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Agregar habilidad...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: AppDimensions.xs,
                  ),
                ),
                onSubmitted: _addSkill,
              ),
            ],
          ),
        ),

        // Suggestions
        if (availableSuggestions.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Sugerencias:',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.xs),
          Wrap(
            spacing: AppDimensions.xs,
            runSpacing: AppDimensions.xs,
            children: availableSuggestions
                .take(6)
                .map(
                  (skill) => ActionChip(
                    label: Text(skill),
                    onPressed: () => _addSkill(skill),
                    avatar: const Icon(Icons.add, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ServiceChecklistHelper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                size: 18,
                color: AppColors.info,
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'Sugerencias para la descripción',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            '• ¿Qué incluye el servicio?\n'
            '• ¿Cuáles son los pasos o procedimientos?\n'
            '• ¿Qué materiales o herramientas se requieren?\n'
            '• ¿Hay requisitos previos para el cliente?\n'
            '• ¿Qué garantía ofrece el servicio?',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
