// lib/operatividad/widgets/operatividad_filters.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/oper_activity.dart';
import '../../core/firebase_helper.dart';

class OperatividadFilters extends StatefulWidget {
  final Set<OperStatus> statusFilters;
  final Set<String> assigneeFilters;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final void Function(
    Set<OperStatus> status,
    Set<String> assignees,
    DateTime? startDate,
    DateTime? endDate,
  )
  onApply;

  const OperatividadFilters({
    super.key,
    required this.statusFilters,
    required this.assigneeFilters,
    required this.filterStartDate,
    required this.filterEndDate,
    required this.onApply,
  });

  @override
  State<OperatividadFilters> createState() => _OperatividadFiltersState();
}

class _OperatividadFiltersState extends State<OperatividadFilters> {
  late Set<OperStatus> _statusFilters;
  late Set<String> _assigneeFilters;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _statusFilters = Set.from(widget.statusFilters);
    _assigneeFilters = Set.from(widget.assigneeFilters);
    _startDate = widget.filterStartDate;
    _endDate = widget.filterEndDate;
  }

  void _clearAll() {
    setState(() {
      _statusFilters.clear();
      _assigneeFilters.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  void _apply() {
    widget.onApply(_statusFilters, _assigneeFilters, _startDate, _endDate);
  }

  Color _getStatusColor(OperStatus status) {
    switch (status) {
      case OperStatus.planned:
        return AppColors.info;
      case OperStatus.inProgress:
        return AppColors.warning;
      case OperStatus.done:
        return AppColors.success;
      case OperStatus.verified:
        return AppColors.primary;
      case OperStatus.blocked:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtros',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'Limpiar todo',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  children: [
                    // Status filter
                    _FilterSection(
                      title: 'Estado',
                      icon: Icons.flag_rounded,
                      child: Wrap(
                        spacing: AppDimensions.sm,
                        runSpacing: AppDimensions.sm,
                        children: OperStatus.values.map((status) {
                          final isSelected = _statusFilters.contains(status);
                          final color = _getStatusColor(status);

                          return FilterChip(
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _statusFilters.add(status);
                                } else {
                                  _statusFilters.remove(status);
                                }
                              });
                            },
                            label: Text(status.label),
                            labelStyle: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: color.withOpacity(0.1),
                            selectedColor: color,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? color
                                  : color.withOpacity(0.3),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.xl),

                    // Date range filter
                    _FilterSection(
                      title: 'Rango de fechas',
                      icon: Icons.date_range_rounded,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _DatePickerButton(
                                  label: 'Desde',
                                  date: _startDate,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (date != null) {
                                      setState(() => _startDate = date);
                                    }
                                  },
                                  onClear: () =>
                                      setState(() => _startDate = null),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.md),
                              Expanded(
                                child: _DatePickerButton(
                                  label: 'Hasta',
                                  date: _endDate,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (date != null) {
                                      setState(() => _endDate = date);
                                    }
                                  },
                                  onClear: () =>
                                      setState(() => _endDate = null),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.md),
                          // Quick date presets
                          Wrap(
                            spacing: AppDimensions.sm,
                            children: [
                              _QuickDateChip(
                                label: 'Hoy',
                                onTap: () {
                                  final now = DateTime.now();
                                  setState(() {
                                    _startDate = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    );
                                    _endDate = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      23,
                                      59,
                                    );
                                  });
                                },
                              ),
                              _QuickDateChip(
                                label: 'Esta semana',
                                onTap: () {
                                  final now = DateTime.now();
                                  final weekStart = now.subtract(
                                    Duration(days: now.weekday - 1),
                                  );
                                  setState(() {
                                    _startDate = DateTime(
                                      weekStart.year,
                                      weekStart.month,
                                      weekStart.day,
                                    );
                                    _endDate = _startDate!.add(
                                      const Duration(days: 6),
                                    );
                                  });
                                },
                              ),
                              _QuickDateChip(
                                label: 'Este mes',
                                onTap: () {
                                  final now = DateTime.now();
                                  setState(() {
                                    _startDate = DateTime(
                                      now.year,
                                      now.month,
                                      1,
                                    );
                                    _endDate = DateTime(
                                      now.year,
                                      now.month + 1,
                                      0,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.xl),

                    // Assignees filter
                    _FilterSection(
                      title: 'Asignados',
                      icon: Icons.people_rounded,
                      child: _AssigneeSelector(
                        selectedUids: _assigneeFilters,
                        onChanged: (uids) {
                          setState(() {
                            _assigneeFilters.clear();
                            _assigneeFilters.addAll(uids);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(AppDimensions.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _apply,
                        child: const Text('Aplicar filtros'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppDimensions.sm),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        child,
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
                        : 'Seleccionar',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textHint,
                visualDensity: VisualDensity.compact,
              )
            else
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
      backgroundColor: AppColors.primarySurface,
      side: BorderSide.none,
    );
  }
}

class _AssigneeSelector extends StatelessWidget {
  final Set<String> selectedUids;
  final ValueChanged<Set<String>> onChanged;

  const _AssigneeSelector({
    required this.selectedUids,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseHelper.users.orderBy('email').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text(
            'Error al cargar usuarios',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          );
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return Text(
            'No hay usuarios disponibles',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          );
        }

        return Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: users.map((doc) {
            final data = doc.data();
            final uid = (data['uid'] ?? doc.id).toString();
            final email = (data['email'] ?? 'Sin email').toString();
            final isSelected = selectedUids.contains(uid);

            return FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                final newSet = Set<String>.from(selectedUids);
                if (selected) {
                  newSet.add(uid);
                } else {
                  newSet.remove(uid);
                }
                onChanged(newSet);
              },
              avatar: CircleAvatar(
                backgroundColor: isSelected
                    ? Colors.white
                    : AppColors.primarySurface,
                child: Text(
                  email.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              label: Text(email.split('@').first),
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
