// lib/proyectos/models/project_enums.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// ESTADO DEL PROYECTO
// ═══════════════════════════════════════════════════════════

enum ProjectStatus {
  planificacion,
  enProgreso,
  pausado,
  completado,
  cancelado,
  enRevision,
}

extension ProjectStatusX on ProjectStatus {
  String get value => switch (this) {
    ProjectStatus.planificacion => 'planificacion',
    ProjectStatus.enProgreso => 'en_progreso',
    ProjectStatus.pausado => 'pausado',
    ProjectStatus.completado => 'completado',
    ProjectStatus.cancelado => 'cancelado',
    ProjectStatus.enRevision => 'en_revision',
  };

  String get label => switch (this) {
    ProjectStatus.planificacion => 'Planificación',
    ProjectStatus.enProgreso => 'En Progreso',
    ProjectStatus.pausado => 'Pausado',
    ProjectStatus.completado => 'Completado',
    ProjectStatus.cancelado => 'Cancelado',
    ProjectStatus.enRevision => 'En Revisión',
  };

  String get emoji => switch (this) {
    ProjectStatus.planificacion => '📋',
    ProjectStatus.enProgreso => '🚀',
    ProjectStatus.pausado => '⏸️',
    ProjectStatus.completado => '✅',
    ProjectStatus.cancelado => '❌',
    ProjectStatus.enRevision => '🔍',
  };

  IconData get icon => switch (this) {
    ProjectStatus.planificacion => Icons.edit_note_rounded,
    ProjectStatus.enProgreso => Icons.play_circle_rounded,
    ProjectStatus.pausado => Icons.pause_circle_rounded,
    ProjectStatus.completado => Icons.check_circle_rounded,
    ProjectStatus.cancelado => Icons.cancel_rounded,
    ProjectStatus.enRevision => Icons.rate_review_rounded,
  };

  Color get color => switch (this) {
    ProjectStatus.planificacion => AppColors.info,
    ProjectStatus.enProgreso => AppColors.primaryMedium,
    ProjectStatus.pausado => AppColors.warning,
    ProjectStatus.completado => AppColors.success,
    ProjectStatus.cancelado => AppColors.error,
    ProjectStatus.enRevision => const Color(0xFF7E57C2),
  };

  bool get isActive => this == ProjectStatus.enProgreso || this == ProjectStatus.enRevision;
  bool get isEditable => this != ProjectStatus.completado && this != ProjectStatus.cancelado;

  static ProjectStatus from(String? v) => switch (v) {
    'planificacion' => ProjectStatus.planificacion,
    'en_progreso' => ProjectStatus.enProgreso,
    'pausado' => ProjectStatus.pausado,
    'completado' => ProjectStatus.completado,
    'cancelado' => ProjectStatus.cancelado,
    'en_revision' => ProjectStatus.enRevision,
    _ => ProjectStatus.planificacion,
  };
}

// ═══════════════════════════════════════════════════════════
// TIPO DE PROYECTO
// ═══════════════════════════════════════════════════════════

enum ProjectType {
  unico,
  recurrente,
  mantenimiento,
  consultoria,
  desarrollo,
  implementacion,
}

extension ProjectTypeX on ProjectType {
  String get value => switch (this) {
    ProjectType.unico => 'unico',
    ProjectType.recurrente => 'recurrente',
    ProjectType.mantenimiento => 'mantenimiento',
    ProjectType.consultoria => 'consultoria',
    ProjectType.desarrollo => 'desarrollo',
    ProjectType.implementacion => 'implementacion',
  };

  String get label => switch (this) {
    ProjectType.unico => 'Único',
    ProjectType.recurrente => 'Recurrente',
    ProjectType.mantenimiento => 'Mantenimiento',
    ProjectType.consultoria => 'Consultoría',
    ProjectType.desarrollo => 'Desarrollo',
    ProjectType.implementacion => 'Implementación',
  };

  IconData get icon => switch (this) {
    ProjectType.unico => Icons.looks_one_rounded,
    ProjectType.recurrente => Icons.repeat_rounded,
    ProjectType.mantenimiento => Icons.build_rounded,
    ProjectType.consultoria => Icons.psychology_rounded,
    ProjectType.desarrollo => Icons.code_rounded,
    ProjectType.implementacion => Icons.rocket_launch_rounded,
  };

  Color get color => switch (this) {
    ProjectType.unico => AppColors.info,
    ProjectType.recurrente => const Color(0xFF7E57C2),
    ProjectType.mantenimiento => AppColors.warning,
    ProjectType.consultoria => const Color(0xFF26C6DA),
    ProjectType.desarrollo => AppColors.primaryMedium,
    ProjectType.implementacion => AppColors.success,
  };

  static ProjectType from(String? v) => switch (v) {
    'unico' => ProjectType.unico,
    'recurrente' => ProjectType.recurrente,
    'mantenimiento' => ProjectType.mantenimiento,
    'consultoria' => ProjectType.consultoria,
    'desarrollo' => ProjectType.desarrollo,
    'implementacion' => ProjectType.implementacion,
    _ => ProjectType.unico,
  };
}

// ═══════════════════════════════════════════════════════════
// PRIORIDAD DEL PROYECTO
// ═══════════════════════════════════════════════════════════

enum ProjectPriority {
  baja,
  media,
  alta,
  critica,
}

extension ProjectPriorityX on ProjectPriority {
  String get value => name;

  String get label => switch (this) {
    ProjectPriority.baja => 'Baja',
    ProjectPriority.media => 'Media',
    ProjectPriority.alta => 'Alta',
    ProjectPriority.critica => 'Crítica',
  };

  IconData get icon => switch (this) {
    ProjectPriority.baja => Icons.arrow_downward_rounded,
    ProjectPriority.media => Icons.remove_rounded,
    ProjectPriority.alta => Icons.arrow_upward_rounded,
    ProjectPriority.critica => Icons.priority_high_rounded,
  };

  Color get color => switch (this) {
    ProjectPriority.baja => AppColors.success,
    ProjectPriority.media => AppColors.info,
    ProjectPriority.alta => AppColors.warning,
    ProjectPriority.critica => AppColors.error,
  };

  int get order => switch (this) {
    ProjectPriority.baja => 0,
    ProjectPriority.media => 1,
    ProjectPriority.alta => 2,
    ProjectPriority.critica => 3,
  };

  static ProjectPriority from(String? v) => switch (v) {
    'baja' => ProjectPriority.baja,
    'media' => ProjectPriority.media,
    'alta' => ProjectPriority.alta,
    'critica' => ProjectPriority.critica,
    _ => ProjectPriority.media,
  };
}

// ═══════════════════════════════════════════════════════════
// ESTADO DE TAREA
// ═══════════════════════════════════════════════════════════

enum TaskStatus {
  pendiente,
  enProgreso,
  enRevision,
  completada,
  cancelada,
  bloqueada,
}

extension TaskStatusX on TaskStatus {
  String get value => switch (this) {
    TaskStatus.pendiente => 'pendiente',
    TaskStatus.enProgreso => 'en_progreso',
    TaskStatus.enRevision => 'en_revision',
    TaskStatus.completada => 'completada',
    TaskStatus.cancelada => 'cancelada',
    TaskStatus.bloqueada => 'bloqueada',
  };

  String get label => switch (this) {
    TaskStatus.pendiente => 'Pendiente',
    TaskStatus.enProgreso => 'En Progreso',
    TaskStatus.enRevision => 'En Revisión',
    TaskStatus.completada => 'Completada',
    TaskStatus.cancelada => 'Cancelada',
    TaskStatus.bloqueada => 'Bloqueada',
  };

  IconData get icon => switch (this) {
    TaskStatus.pendiente => Icons.radio_button_unchecked_rounded,
    TaskStatus.enProgreso => Icons.timelapse_rounded,
    TaskStatus.enRevision => Icons.rate_review_rounded,
    TaskStatus.completada => Icons.check_circle_rounded,
    TaskStatus.cancelada => Icons.cancel_rounded,
    TaskStatus.bloqueada => Icons.block_rounded,
  };

  Color get color => switch (this) {
    TaskStatus.pendiente => AppColors.textHint,
    TaskStatus.enProgreso => AppColors.info,
    TaskStatus.enRevision => const Color(0xFF7E57C2),
    TaskStatus.completada => AppColors.success,
    TaskStatus.cancelada => AppColors.error,
    TaskStatus.bloqueada => AppColors.warning,
  };

  bool get isActive => this == TaskStatus.enProgreso || this == TaskStatus.enRevision;
  bool get isDone => this == TaskStatus.completada;

  static TaskStatus from(String? v) => switch (v) {
    'pendiente' => TaskStatus.pendiente,
    'en_progreso' => TaskStatus.enProgreso,
    'en_revision' => TaskStatus.enRevision,
    'completada' => TaskStatus.completada,
    'cancelada' => TaskStatus.cancelada,
    'bloqueada' => TaskStatus.bloqueada,
    _ => TaskStatus.pendiente,
  };
}

// ═══════════════════════════════════════════════════════════
// PRIORIDAD DE TAREA
// ═══════════════════════════════════════════════════════════

enum TaskPriority {
  baja,
  media,
  alta,
  urgente,
}

extension TaskPriorityX on TaskPriority {
  String get value => name;

  String get label => switch (this) {
    TaskPriority.baja => 'Baja',
    TaskPriority.media => 'Media',
    TaskPriority.alta => 'Alta',
    TaskPriority.urgente => 'Urgente',
  };

  Color get color => switch (this) {
    TaskPriority.baja => AppColors.success,
    TaskPriority.media => AppColors.info,
    TaskPriority.alta => AppColors.warning,
    TaskPriority.urgente => AppColors.error,
  };

  static TaskPriority from(String? v) => switch (v) {
    'baja' => TaskPriority.baja,
    'media' => TaskPriority.media,
    'alta' => TaskPriority.alta,
    'urgente' => TaskPriority.urgente,
    _ => TaskPriority.media,
  };
}

// ═══════════════════════════════════════════════════════════
// TIPO DE TRANSACCIÓN
// ═══════════════════════════════════════════════════════════

enum TransactionType {
  ingreso,
  egreso,
  adelanto,
  pagoParcial,
  pagoFinal,
  reembolso,
  gastoMaterial,
  gastoManoObra,
  gastoOperativo,
}

extension TransactionTypeX on TransactionType {
  String get value => switch (this) {
    TransactionType.ingreso => 'ingreso',
    TransactionType.egreso => 'egreso',
    TransactionType.adelanto => 'adelanto',
    TransactionType.pagoParcial => 'pago_parcial',
    TransactionType.pagoFinal => 'pago_final',
    TransactionType.reembolso => 'reembolso',
    TransactionType.gastoMaterial => 'gasto_material',
    TransactionType.gastoManoObra => 'gasto_mano_obra',
    TransactionType.gastoOperativo => 'gasto_operativo',
  };

  String get label => switch (this) {
    TransactionType.ingreso => 'Ingreso',
    TransactionType.egreso => 'Egreso',
    TransactionType.adelanto => 'Adelanto',
    TransactionType.pagoParcial => 'Pago Parcial',
    TransactionType.pagoFinal => 'Pago Final',
    TransactionType.reembolso => 'Reembolso',
    TransactionType.gastoMaterial => 'Gasto de Material',
    TransactionType.gastoManoObra => 'Gasto Mano de Obra',
    TransactionType.gastoOperativo => 'Gasto Operativo',
  };

  IconData get icon => switch (this) {
    TransactionType.ingreso => Icons.arrow_downward_rounded,
    TransactionType.egreso => Icons.arrow_upward_rounded,
    TransactionType.adelanto => Icons.fast_forward_rounded,
    TransactionType.pagoParcial => Icons.payments_rounded,
    TransactionType.pagoFinal => Icons.price_check_rounded,
    TransactionType.reembolso => Icons.undo_rounded,
    TransactionType.gastoMaterial => Icons.inventory_2_rounded,
    TransactionType.gastoManoObra => Icons.engineering_rounded,
    TransactionType.gastoOperativo => Icons.receipt_long_rounded,
  };

  Color get color => switch (this) {
    TransactionType.ingreso => AppColors.success,
    TransactionType.egreso => AppColors.error,
    TransactionType.adelanto => AppColors.info,
    TransactionType.pagoParcial => const Color(0xFF26C6DA),
    TransactionType.pagoFinal => AppColors.success,
    TransactionType.reembolso => AppColors.warning,
    TransactionType.gastoMaterial => AppColors.primaryMedium,
    TransactionType.gastoManoObra => const Color(0xFF7E57C2),
    TransactionType.gastoOperativo => AppColors.textSecondary,
  };

  /// Es un ingreso al proyecto (dinero que entra)
  bool get isIncome => [
    TransactionType.ingreso,
    TransactionType.adelanto,
    TransactionType.pagoParcial,
    TransactionType.pagoFinal,
  ].contains(this);

  /// Es un egreso del proyecto (dinero que sale)
  bool get isExpense => [
    TransactionType.egreso,
    TransactionType.reembolso,
    TransactionType.gastoMaterial,
    TransactionType.gastoManoObra,
    TransactionType.gastoOperativo,
  ].contains(this);

  static TransactionType from(String? v) => switch (v) {
    'ingreso' => TransactionType.ingreso,
    'egreso' => TransactionType.egreso,
    'adelanto' => TransactionType.adelanto,
    'pago_parcial' => TransactionType.pagoParcial,
    'pago_final' => TransactionType.pagoFinal,
    'reembolso' => TransactionType.reembolso,
    'gasto_material' => TransactionType.gastoMaterial,
    'gasto_mano_obra' => TransactionType.gastoManoObra,
    'gasto_operativo' => TransactionType.gastoOperativo,
    _ => TransactionType.ingreso,
  };
}

// ═══════════════════════════════════════════════════════════
// ESTADO DE TRANSACCIÓN
// ═══════════════════════════════════════════════════════════

enum TransactionStatus {
  pendiente,
  aprobada,
  rechazada,
  completada,
}

extension TransactionStatusX on TransactionStatus {
  String get value => name;

  String get label => switch (this) {
    TransactionStatus.pendiente => 'Pendiente',
    TransactionStatus.aprobada => 'Aprobada',
    TransactionStatus.rechazada => 'Rechazada',
    TransactionStatus.completada => 'Completada',
  };

  Color get color => switch (this) {
    TransactionStatus.pendiente => AppColors.warning,
    TransactionStatus.aprobada => AppColors.info,
    TransactionStatus.rechazada => AppColors.error,
    TransactionStatus.completada => AppColors.success,
  };

  static TransactionStatus from(String? v) => switch (v) {
    'pendiente' => TransactionStatus.pendiente,
    'aprobada' => TransactionStatus.aprobada,
    'rechazada' => TransactionStatus.rechazada,
    'completada' => TransactionStatus.completada,
    _ => TransactionStatus.pendiente,
  };
}

// ═══════════════════════════════════════════════════════════
// MÉTODO DE PAGO
// ═══════════════════════════════════════════════════════════

enum PaymentMethodProject {
  transferencia,
  efectivo,
  tarjeta,
  cheque,
  otro,
}

extension PaymentMethodProjectX on PaymentMethodProject {
  String get value => name;

  String get label => switch (this) {
    PaymentMethodProject.transferencia => 'Transferencia',
    PaymentMethodProject.efectivo => 'Efectivo',
    PaymentMethodProject.tarjeta => 'Tarjeta',
    PaymentMethodProject.cheque => 'Cheque',
    PaymentMethodProject.otro => 'Otro',
  };

  IconData get icon => switch (this) {
    PaymentMethodProject.transferencia => Icons.account_balance_rounded,
    PaymentMethodProject.efectivo => Icons.attach_money_rounded,
    PaymentMethodProject.tarjeta => Icons.credit_card_rounded,
    PaymentMethodProject.cheque => Icons.description_rounded,
    PaymentMethodProject.otro => Icons.more_horiz_rounded,
  };

  static PaymentMethodProject from(String? v) => switch (v) {
    'transferencia' => PaymentMethodProject.transferencia,
    'efectivo' => PaymentMethodProject.efectivo,
    'tarjeta' => PaymentMethodProject.tarjeta,
    'cheque' => PaymentMethodProject.cheque,
    _ => PaymentMethodProject.otro,
  };
}

// ═══════════════════════════════════════════════════════════
// FRECUENCIA DE RECURRENCIA
// ═══════════════════════════════════════════════════════════

enum RecurrenceFrequency {
  semanal,
  quincenal,
  mensual,
  bimestral,
  trimestral,
  semestral,
  anual,
}

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get value => name;

  String get label => switch (this) {
    RecurrenceFrequency.semanal => 'Semanal',
    RecurrenceFrequency.quincenal => 'Quincenal',
    RecurrenceFrequency.mensual => 'Mensual',
    RecurrenceFrequency.bimestral => 'Bimestral',
    RecurrenceFrequency.trimestral => 'Trimestral',
    RecurrenceFrequency.semestral => 'Semestral',
    RecurrenceFrequency.anual => 'Anual',
  };

  /// Días aproximados del ciclo
  int get days => switch (this) {
    RecurrenceFrequency.semanal => 7,
    RecurrenceFrequency.quincenal => 15,
    RecurrenceFrequency.mensual => 30,
    RecurrenceFrequency.bimestral => 60,
    RecurrenceFrequency.trimestral => 90,
    RecurrenceFrequency.semestral => 180,
    RecurrenceFrequency.anual => 365,
  };

  static RecurrenceFrequency from(String? v) => switch (v) {
    'semanal' => RecurrenceFrequency.semanal,
    'quincenal' => RecurrenceFrequency.quincenal,
    'mensual' => RecurrenceFrequency.mensual,
    'bimestral' => RecurrenceFrequency.bimestral,
    'trimestral' => RecurrenceFrequency.trimestral,
    'semestral' => RecurrenceFrequency.semestral,
    'anual' => RecurrenceFrequency.anual,
    _ => RecurrenceFrequency.mensual,
  };
}

// ═══════════════════════════════════════════════════════════
// SALUD DEL PROYECTO (calculada, no persistida)
// ═══════════════════════════════════════════════════════════

enum ProjectHealth {
  excelente,
  buena,
  enRiesgo,
  critica,
}

extension ProjectHealthX on ProjectHealth {
  String get label => switch (this) {
    ProjectHealth.excelente => 'Excelente',
    ProjectHealth.buena => 'Buena',
    ProjectHealth.enRiesgo => 'En Riesgo',
    ProjectHealth.critica => 'Crítica',
  };

  IconData get icon => switch (this) {
    ProjectHealth.excelente => Icons.sentiment_very_satisfied_rounded,
    ProjectHealth.buena => Icons.sentiment_satisfied_rounded,
    ProjectHealth.enRiesgo => Icons.sentiment_dissatisfied_rounded,
    ProjectHealth.critica => Icons.sentiment_very_dissatisfied_rounded,
  };

  Color get color => switch (this) {
    ProjectHealth.excelente => AppColors.success,
    ProjectHealth.buena => AppColors.primaryMedium,
    ProjectHealth.enRiesgo => AppColors.warning,
    ProjectHealth.critica => AppColors.error,
  };
}
