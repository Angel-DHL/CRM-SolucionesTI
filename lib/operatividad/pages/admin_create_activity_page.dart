// lib/operatividad/pages/admin_create_activity_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crm_solucionesti/operatividad/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/firebase_helper.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/oper_activity.dart';
import '../services/activity_log_service.dart';

class AdminCreateActivityPage extends StatefulWidget {
  final VoidCallback onCreated;

  const AdminCreateActivityPage({super.key, required this.onCreated});

  @override
  State<AdminCreateActivityPage> createState() =>
      _AdminCreateActivityPageState();
}

class _AdminCreateActivityPageState extends State<AdminCreateActivityPage>
    with SingleTickerProviderStateMixin {
  FirebaseFirestore get _db => FirebaseHelper.db;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _estimatedHoursCtrl = TextEditingController();
  final _slaHoursCtrl = TextEditingController();

  // State
  int _currentStep = 0;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String _priority = 'medium';
  final Set<String> _selectedUids = {};
  final Map<String, String> _uidToEmail = {};
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  bool _loading = false;
  String? _error;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _estimatedHoursCtrl.dispose();
    _tagController.dispose();
    _animController.dispose();
    _slaHoursCtrl.dispose();
    super.dispose();
  }

  DateTime get _plannedStartAt => DateTime(
    _startDate.year,
    _startDate.month,
    _startDate.day,
    _startTime.hour,
    _startTime.minute,
  );

  DateTime get _plannedEndAt => DateTime(
    _endDate.year,
    _endDate.month,
    _endDate.day,
    _endTime.hour,
    _endTime.minute,
  );

  bool get _isStep1Valid {
    return _titleCtrl.text.trim().isNotEmpty;
  }

  bool get _isStep2Valid {
    return _plannedEndAt.isAfter(_plannedStartAt);
  }

  bool get _isStep3Valid {
    return _selectedUids.isNotEmpty;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = date;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate.subtract(const Duration(days: 1));
        }
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startTime = time;
      } else {
        _endTime = time;
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _nextStep() {
    if (_currentStep == 0 && !_isStep1Valid) {
      setState(() => _error = 'Completa los campos requeridos');
      return;
    }
    if (_currentStep == 1 && !_isStep2Valid) {
      setState(
        () => _error = 'La fecha de fin debe ser posterior a la de inicio',
      );
      return;
    }
    if (_currentStep == 2 && !_isStep3Valid) {
      setState(() => _error = 'Selecciona al menos un responsable');
      return;
    }

    setState(() {
      _error = null;
      if (_currentStep < 3) {
        _currentStep++;
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _error = null;
      });
    }
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final slaHours = double.tryParse(_slaHoursCtrl.text) ?? 0;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedUids.isEmpty) {
      setState(() => _error = 'Selecciona al menos un responsable');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final assigneesUids = _selectedUids.toList();
      final assigneesEmails = assigneesUids
          .map((u) => _uidToEmail[u] ?? u)
          .toList();

      final estimatedHours = double.tryParse(_estimatedHoursCtrl.text) ?? 0;

      final data = OperActivity.createMap(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        plannedStartAt: _plannedStartAt,
        plannedEndAt: _plannedEndAt,
        assigneesUids: assigneesUids,
        assigneesEmails: assigneesEmails,
        createdByUid: user.uid,
        createdByEmail: user.email ?? '',
        priority: _priority,
        tags: _tags,
        estimatedHours: estimatedHours,
        slaHours: slaHours,
      );

      await _db.collection('oper_activities').add(data);

      // ✅ Notificar a los asignados
      final createdActivity = OperActivity(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        plannedStartAt: _plannedStartAt,
        plannedEndAt: _plannedEndAt,
        assigneesUids: assigneesUids,
        assigneesEmails: assigneesEmails,
        createdByUid: user.uid,
        createdByEmail: user.email ?? '',
        priority: _priority,
        tags: _tags,
        estimatedHours: estimatedHours,
        slaHours: slaHours,
        id: '',
        status: OperStatus.planned,
        progress: 0,
        actualStartAt: null,
        actualEndAt: null,
        workStartAt: null,
        workEndAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await NotificationService.notifyActivityAssigned(
        activity: createdActivity,
        assigneeUids: assigneesUids,
      );

      HapticFeedback.mediumImpact();
      widget.onCreated();

      final docRef = await _db.collection('oper_activities').add(data);
      // ✅ Registrar en bitácora
      await ActivityLogService.logCreated(
        activityId: docRef.id,
        title: _titleCtrl.text.trim(),
      );

      if (mounted) {
        _resetForm();
      }
    } catch (e) {
      setState(() => _error = 'Error al crear la actividad: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _estimatedHoursCtrl.clear();
    _tagController.clear();
    _selectedUids.clear();
    _uidToEmail.clear();
    _slaHoursCtrl.clear();
    _tags.clear();
    setState(() {
      _currentStep = 0;
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endDate = DateTime.now().add(const Duration(days: 1));
      _endTime = const TimeOfDay(hour: 18, minute: 0);
      _priority = 'medium';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return FadeTransition(
      opacity: _animController,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: AppDimensions.lg),

            // Progress indicator
            _StepIndicator(
              currentStep: _currentStep,
              steps: const ['Información', 'Fechas', 'Asignación', 'Revisión'],
            ),
            const SizedBox(height: AppDimensions.xl),

            // Error banner
            if (_error != null) ...[
              _ErrorBanner(
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
              const SizedBox(height: AppDimensions.md),
            ],

            // Step content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: AppDimensions.animFast,
                  child: _buildStepContent(),
                ),
              ),
            ),

            // Actions
            const SizedBox(height: AppDimensions.lg),
            _buildActions(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: const Icon(
            Icons.add_task_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva actividad',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Completa los pasos para crear la actividad',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Information(key: const ValueKey('step1'));
      case 1:
        return _buildStep2Dates(key: const ValueKey('step2'));
      case 2:
        return _buildStep3Assignment(key: const ValueKey('step3'));
      case 3:
        return _buildStep4Review(key: const ValueKey('step4'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Information({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        _FormSection(
          title: 'Título de la actividad',
          required: true,
          child: TextFormField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'Ej: Instalación de servidor',
              prefixIcon: Container(
                margin: const EdgeInsets.all(AppDimensions.sm),
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  Icons.title_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'El título es requerido';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // Description
        _FormSection(
          title: 'Descripción',
          child: TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe los detalles de la actividad...',
              alignLabelWithHint: true,
            ),
            textInputAction: TextInputAction.newline,
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // Priority
        _FormSection(
          title: 'Prioridad',
          child: _PrioritySelector(
            value: _priority,
            onChanged: (v) => setState(() => _priority = v),
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // Tags
        _FormSection(
          title: 'Etiquetas',
          subtitle: 'Opcional - para organizar actividades',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Agregar etiqueta',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: _addTag,
                          icon: Icon(Icons.add_rounded),
                          color: AppColors.primary,
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.md),
                Wrap(
                  spacing: AppDimensions.sm,
                  runSpacing: AppDimensions.sm,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                      backgroundColor: AppColors.primarySurface,
                      deleteIcon: Icon(Icons.close_rounded, size: 16),
                      deleteIconColor: AppColors.primary,
                      onDeleted: () => _removeTag(tag),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Dates({Key? key}) {
    final duration = _plannedEndAt.difference(_plannedStartAt);
    final hours = duration.inHours;
    final days = duration.inDays;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.lg),
        // Start date/time
        _FormSection(
          title: 'SLA (Acuerdo de nivel de servicio)',
          subtitle: 'Opcional - tiempo máximo para completar',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _slaHoursCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 24 (0 = sin SLA)',
                  prefixIcon: Icon(Icons.timer_rounded),
                  suffixText: 'horas',
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              // Presets rápidos de SLA
              Wrap(
                spacing: AppDimensions.sm,
                children: [
                  _SlaPresetChip(
                    label: '4h',
                    onTap: () => _slaHoursCtrl.text = '4',
                  ),
                  _SlaPresetChip(
                    label: '8h',
                    onTap: () => _slaHoursCtrl.text = '8',
                  ),
                  _SlaPresetChip(
                    label: '24h',
                    onTap: () => _slaHoursCtrl.text = '24',
                  ),
                  _SlaPresetChip(
                    label: '48h',
                    onTap: () => _slaHoursCtrl.text = '48',
                  ),
                  _SlaPresetChip(
                    label: '72h',
                    onTap: () => _slaHoursCtrl.text = '72',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // End date/time
        _FormSection(
          title: 'Fecha y hora de fin',
          required: true,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _DatePickerField(
                  label: 'Fecha',
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                flex: 2,
                child: _TimePickerField(
                  label: 'Hora',
                  time: _endTime,
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // Duration preview
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.info),
              const SizedBox(width: AppDimensions.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duración planificada',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                  Text(
                    days > 0
                        ? '$days días, ${hours % 24} horas'
                        : '$hours horas',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // Estimated hours
        _FormSection(
          title: 'Horas estimadas de trabajo',
          subtitle: 'Opcional - tiempo real de trabajo',
          child: TextFormField(
            controller: _estimatedHoursCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ej: 8',
              prefixIcon: Icon(Icons.hourglass_empty_rounded),
              suffixText: 'horas',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Assignment({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormSection(
          title: 'Asignar responsables',
          required: true,
          subtitle: 'Selecciona uno o más colaboradores',
          child: _AssigneePicker(
            selectedUids: _selectedUids,
            onChangeEmailMap: (uid, email) => _uidToEmail[uid] = email,
            enabled: !_loading,
            onSelectionChanged: () => setState(() {}),
          ),
        ),

        if (_selectedUids.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: AppDimensions.md),
                Text(
                  '${_selectedUids.length} responsable(s) seleccionado(s)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep4Review({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisa la información',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Text(
          'Verifica que todos los datos sean correctos antes de crear la actividad.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: AppDimensions.xl),

        // Summary card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            side: BorderSide(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Priority
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleCtrl.text,
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_descCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.sm),
                            Text(
                              _descCtrl.text,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    _PriorityBadge(priority: _priority),
                  ],
                ),

                const Divider(height: AppDimensions.xl),

                // Dates
                _ReviewRow(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Inicio',
                  value: _formatDateTime(_plannedStartAt),
                  color: AppColors.success,
                ),
                const SizedBox(height: AppDimensions.md),
                _ReviewRow(
                  icon: Icons.flag_outlined,
                  label: 'Fin',
                  value: _formatDateTime(_plannedEndAt),
                  color: AppColors.info,
                ),

                if (_estimatedHoursCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.md),
                  _ReviewRow(
                    icon: Icons.hourglass_empty_rounded,
                    label: 'Horas estimadas',
                    value: '${_estimatedHoursCtrl.text} horas',
                    color: AppColors.warning,
                  ),
                ],

                const Divider(height: AppDimensions.xl),

                // Assignees
                _ReviewRow(
                  icon: Icons.people_outline_rounded,
                  label: 'Responsables',
                  value: _selectedUids
                      .map((uid) => _uidToEmail[uid]?.split('@').first ?? uid)
                      .join(', '),
                  color: AppColors.primary,
                ),

                // Tags
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: Icon(
                          Icons.label_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Wrap(
                          spacing: AppDimensions.xs,
                          runSpacing: AppDimensions.xs,
                          children: _tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.sm,
                                vertical: AppDimensions.xs / 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isMobile) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _previousStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
            ),
          ),

        if (_currentStep > 0) const SizedBox(width: AppDimensions.md),

        Expanded(
          flex: 2,
          child: _currentStep < 3
              ? FilledButton.icon(
                  onPressed: _nextStep,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Siguiente'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                )
              : FilledButton.icon(
                  onPressed: _loading ? null : _create,
                  icon: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_loading ? 'Creando...' : 'Crear actividad'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 52),
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${weekDays[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Step Indicator
// ══════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Línea conectora
          final stepIndex = index ~/ 2;
          final isCompleted = currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.primary : AppColors.divider,
            ),
          );
        }

        // Círculo del paso
        final stepIndex = index ~/ 2;
        final isCompleted = currentStep > stepIndex;
        final isCurrent = currentStep == stepIndex;

        return _StepCircle(
          number: stepIndex + 1,
          label: steps[stepIndex],
          isCompleted: isCompleted,
          isCurrent: isCurrent,
        );
      }),
    );
  }
}

class _SlaPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SlaPresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
      backgroundColor: AppColors.primarySurface,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: AppDimensions.animFast,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primary
                : isCurrent
                ? AppColors.primarySurface
                : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isCurrent
                  ? AppColors.primary
                  : AppColors.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    number.toString(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isCurrent ? AppColors.primary : AppColors.textHint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isCurrent || isCompleted
                ? AppColors.primary
                : AppColors.textHint,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Form Components
// ══════════════════════════════════════════════════════════════

class _FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool required;
  final Widget child;

  const _FormSection({
    required this.title,
    this.subtitle,
    this.required = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
        const SizedBox(height: AppDimensions.sm),
        child,
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.md),
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
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.sm),
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
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
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
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PriorityOption(
          priority: 'low',
          label: 'Baja',
          icon: Icons.keyboard_double_arrow_down_rounded,
          color: AppColors.info,
          isSelected: value == 'low',
          onTap: () => onChanged('low'),
        ),
        const SizedBox(width: AppDimensions.sm),
        _PriorityOption(
          priority: 'medium',
          label: 'Media',
          icon: Icons.remove_rounded,
          color: AppColors.warning,
          isSelected: value == 'medium',
          onTap: () => onChanged('medium'),
        ),
        const SizedBox(width: AppDimensions.sm),
        _PriorityOption(
          priority: 'high',
          label: 'Alta',
          icon: Icons.keyboard_double_arrow_up_rounded,
          color: AppColors.error,
          isSelected: value == 'high',
          onTap: () => onChanged('high'),
        ),
      ],
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final String priority;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.priority,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: AppDimensions.animFast,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? color : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
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
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  Color get _color {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String get _label {
    switch (priority) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      default:
        return 'Baja';
    }
  }

  IconData get _icon {
    switch (priority) {
      case 'high':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'medium':
        return Icons.remove_rounded;
      default:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: AppDimensions.xs),
          Text(
            _label,
            style: AppTextStyles.labelMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppDimensions.md),
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
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: AppColors.error, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Assignee Picker
// ══════════════════════════════════════════════════════════════

class _AssigneePicker extends StatefulWidget {
  final Set<String> selectedUids;
  final void Function(String uid, String email) onChangeEmailMap;
  final bool enabled;
  final VoidCallback onSelectionChanged;

  const _AssigneePicker({
    required this.selectedUids,
    required this.onChangeEmailMap,
    required this.enabled,
    required this.onSelectionChanged,
  });

  @override
  State<_AssigneePicker> createState() => _AssigneePickerState();
}

class _AssigneePickerState extends State<_AssigneePicker> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar colaborador...',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase()),
        ),

        const SizedBox(height: AppDimensions.md),

        // Users list
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseHelper.users.orderBy('email').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.xl),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar usuarios',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'No hay usuarios disponibles',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Filter by search
            final filteredDocs = docs.where((doc) {
              final email = (doc.data()['email'] ?? '')
                  .toString()
                  .toLowerCase();
              return email.contains(_searchQuery);
            }).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                final data = doc.data();
                final uid = (data['uid'] ?? doc.id).toString();
                final email = (data['email'] ?? 'sin-email').toString();
                widget.onChangeEmailMap(uid, email);

                final isSelected = widget.selectedUids.contains(uid);

                return _AssigneeItem(
                  uid: uid,
                  email: email,
                  isSelected: isSelected,
                  enabled: widget.enabled,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        widget.selectedUids.remove(uid);
                      } else {
                        widget.selectedUids.add(uid);
                      }
                    });
                    widget.onSelectionChanged();
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AssigneeItem extends StatelessWidget {
  final String uid;
  final String email;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _AssigneeItem({
    required this.uid,
    required this.email,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDimensions.animFast,
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected
                      ? AppColors.primary
                      : AppColors.primarySurface,
                  child: Text(
                    email.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.split('@').first,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: AppDimensions.animFast,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
