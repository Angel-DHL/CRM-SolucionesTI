// lib/soporte/models/support_enums.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// ESTADO DEL CASO
// ═══════════════════════════════════════════════════════════

enum CaseStatus { abierto, enProgreso, enEspera, resuelto, cerrado }

extension CaseStatusX on CaseStatus {
  String get value => switch (this) {
    CaseStatus.abierto => 'abierto',
    CaseStatus.enProgreso => 'en_progreso',
    CaseStatus.enEspera => 'en_espera',
    CaseStatus.resuelto => 'resuelto',
    CaseStatus.cerrado => 'cerrado',
  };

  String get label => switch (this) {
    CaseStatus.abierto => 'Abierto',
    CaseStatus.enProgreso => 'En Progreso',
    CaseStatus.enEspera => 'En Espera',
    CaseStatus.resuelto => 'Resuelto',
    CaseStatus.cerrado => 'Cerrado',
  };

  Color get color => switch (this) {
    CaseStatus.abierto => AppColors.info,
    CaseStatus.enProgreso => AppColors.primary,
    CaseStatus.enEspera => AppColors.warning,
    CaseStatus.resuelto => AppColors.success,
    CaseStatus.cerrado => AppColors.textHint,
  };

  IconData get icon => switch (this) {
    CaseStatus.abierto => Icons.fiber_new_rounded,
    CaseStatus.enProgreso => Icons.sync_rounded,
    CaseStatus.enEspera => Icons.pause_circle_rounded,
    CaseStatus.resuelto => Icons.check_circle_rounded,
    CaseStatus.cerrado => Icons.archive_rounded,
  };

  static CaseStatus from(String? v) => switch (v) {
    'abierto' => CaseStatus.abierto,
    'en_progreso' => CaseStatus.enProgreso,
    'en_espera' => CaseStatus.enEspera,
    'resuelto' => CaseStatus.resuelto,
    'cerrado' => CaseStatus.cerrado,
    _ => CaseStatus.abierto,
  };
}

// ═══════════════════════════════════════════════════════════
// PRIORIDAD DEL CASO
// ═══════════════════════════════════════════════════════════

enum CasePriority { baja, media, alta, urgente }

extension CasePriorityX on CasePriority {
  String get value => switch (this) {
    CasePriority.baja => 'baja',
    CasePriority.media => 'media',
    CasePriority.alta => 'alta',
    CasePriority.urgente => 'urgente',
  };

  String get label => switch (this) {
    CasePriority.baja => 'Baja',
    CasePriority.media => 'Media',
    CasePriority.alta => 'Alta',
    CasePriority.urgente => 'Urgente',
  };

  Color get color => switch (this) {
    CasePriority.baja => AppColors.success,
    CasePriority.media => AppColors.info,
    CasePriority.alta => AppColors.warning,
    CasePriority.urgente => AppColors.error,
  };

  IconData get icon => switch (this) {
    CasePriority.baja => Icons.arrow_downward_rounded,
    CasePriority.media => Icons.remove_rounded,
    CasePriority.alta => Icons.arrow_upward_rounded,
    CasePriority.urgente => Icons.priority_high_rounded,
  };

  static CasePriority from(String? v) => switch (v) {
    'baja' => CasePriority.baja,
    'media' => CasePriority.media,
    'alta' => CasePriority.alta,
    'urgente' => CasePriority.urgente,
    _ => CasePriority.media,
  };
}

// ═══════════════════════════════════════════════════════════
// CATEGORÍA DEL CASO
// ═══════════════════════════════════════════════════════════

enum CaseCategory { hardware, software, red, configuracion, consulta, otro }

extension CaseCategoryX on CaseCategory {
  String get value => switch (this) {
    CaseCategory.hardware => 'hardware',
    CaseCategory.software => 'software',
    CaseCategory.red => 'red',
    CaseCategory.configuracion => 'configuracion',
    CaseCategory.consulta => 'consulta',
    CaseCategory.otro => 'otro',
  };

  String get label => switch (this) {
    CaseCategory.hardware => 'Hardware',
    CaseCategory.software => 'Software',
    CaseCategory.red => 'Red / Conectividad',
    CaseCategory.configuracion => 'Configuración',
    CaseCategory.consulta => 'Consulta',
    CaseCategory.otro => 'Otro',
  };

  IconData get icon => switch (this) {
    CaseCategory.hardware => Icons.memory_rounded,
    CaseCategory.software => Icons.code_rounded,
    CaseCategory.red => Icons.wifi_rounded,
    CaseCategory.configuracion => Icons.settings_rounded,
    CaseCategory.consulta => Icons.help_outline_rounded,
    CaseCategory.otro => Icons.category_rounded,
  };

  static CaseCategory from(String? v) => switch (v) {
    'hardware' => CaseCategory.hardware,
    'software' => CaseCategory.software,
    'red' => CaseCategory.red,
    'configuracion' => CaseCategory.configuracion,
    'consulta' => CaseCategory.consulta,
    'otro' => CaseCategory.otro,
    _ => CaseCategory.otro,
  };
}

// ═══════════════════════════════════════════════════════════
// ORIGEN DEL CASO
// ═══════════════════════════════════════════════════════════

enum CaseOrigin { manual, operatividad, cliente, proyecto }

extension CaseOriginX on CaseOrigin {
  String get value => switch (this) {
    CaseOrigin.manual => 'manual',
    CaseOrigin.operatividad => 'operatividad',
    CaseOrigin.cliente => 'cliente',
    CaseOrigin.proyecto => 'proyecto',
  };

  String get label => switch (this) {
    CaseOrigin.manual => 'Manual',
    CaseOrigin.operatividad => 'Operatividad',
    CaseOrigin.cliente => 'Cliente',
    CaseOrigin.proyecto => 'Proyecto',
  };

  static CaseOrigin from(String? v) => switch (v) {
    'manual' => CaseOrigin.manual,
    'operatividad' => CaseOrigin.operatividad,
    'cliente' => CaseOrigin.cliente,
    'proyecto' => CaseOrigin.proyecto,
    _ => CaseOrigin.manual,
  };
}
