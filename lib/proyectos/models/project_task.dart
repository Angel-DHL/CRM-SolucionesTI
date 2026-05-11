// lib/proyectos/models/project_task.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_enums.dart';

/// Tarea dentro de un proyecto.
/// Subcolección Firestore: `projects/{projectId}/project_tasks/{taskId}`
class ProjectTask {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final String projectId;

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN BÁSICA
  // ═══════════════════════════════════════════════════════════
  final String titulo;
  final String? descripcion;
  final TaskStatus status;
  final TaskPriority priority;
  final List<String> etiquetas;

  // ═══════════════════════════════════════════════════════════
  // ASIGNACIÓN
  // ═══════════════════════════════════════════════════════════
  final String? asignadoA; // UID del responsable
  final String? asignadoNombre;
  final String? asignadoEmail;

  // ═══════════════════════════════════════════════════════════
  // FECHAS
  // ═══════════════════════════════════════════════════════════
  final DateTime? fechaInicio;
  final DateTime? fechaVencimiento;
  final DateTime? fechaCompletada;

  // ═══════════════════════════════════════════════════════════
  // PROGRESO Y TIEMPO
  // ═══════════════════════════════════════════════════════════
  final int progreso; // 0-100
  final double horasEstimadas;
  final double horasReales;

  // ═══════════════════════════════════════════════════════════
  // DEPENDENCIAS Y ORDEN
  // ═══════════════════════════════════════════════════════════
  final List<String> dependencias; // IDs de tareas que deben completarse primero
  final int orden; // Para ordenamiento en tablero Kanban

  // ═══════════════════════════════════════════════════════════
  // NOTAS
  // ═══════════════════════════════════════════════════════════
  final String? notas;

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  ProjectTask({
    required this.id,
    required this.projectId,
    required this.titulo,
    this.descripcion,
    required this.status,
    required this.priority,
    this.etiquetas = const [],
    this.asignadoA,
    this.asignadoNombre,
    this.asignadoEmail,
    this.fechaInicio,
    this.fechaVencimiento,
    this.fechaCompletada,
    this.progreso = 0,
    this.horasEstimadas = 0,
    this.horasReales = 0,
    this.dependencias = const [],
    this.orden = 0,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // ═══════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS
  // ═══════════════════════════════════════════════════════════

  /// ¿La tarea está vencida?
  bool get estaVencida =>
      fechaVencimiento != null &&
      fechaVencimiento!.isBefore(DateTime.now()) &&
      !status.isDone &&
      status != TaskStatus.cancelada;

  /// Días restantes
  int get diasRestantes {
    if (fechaVencimiento == null) return 0;
    return fechaVencimiento!.difference(DateTime.now()).inDays;
  }

  /// Horas pendientes
  double get horasPendientes =>
      horasEstimadas > horasReales ? horasEstimadas - horasReales : 0;

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════

  static ProjectTask fromDoc(DocumentSnapshot doc, String projectId) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime parseTs(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }

    DateTime? parseTsNull(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate().toLocal();
      return null;
    }

    return ProjectTask(
      id: doc.id,
      projectId: projectId,
      titulo: d['titulo'] ?? '',
      descripcion: d['descripcion'],
      status: TaskStatusX.from(d['status']),
      priority: TaskPriorityX.from(d['priority']),
      etiquetas: List<String>.from(d['etiquetas'] ?? []),
      asignadoA: d['asignadoA'],
      asignadoNombre: d['asignadoNombre'],
      asignadoEmail: d['asignadoEmail'],
      fechaInicio: parseTsNull(d['fechaInicio']),
      fechaVencimiento: parseTsNull(d['fechaVencimiento']),
      fechaCompletada: parseTsNull(d['fechaCompletada']),
      progreso: d['progreso'] ?? 0,
      horasEstimadas: (d['horasEstimadas'] ?? 0).toDouble(),
      horasReales: (d['horasReales'] ?? 0).toDouble(),
      dependencias: List<String>.from(d['dependencias'] ?? []),
      orden: d['orden'] ?? 0,
      notas: d['notas'],
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      createdBy: d['createdBy'] ?? '',
      lastModifiedBy: d['lastModifiedBy'],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN A MAP
  // ═══════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'descripcion': descripcion,
    'status': status.value,
    'priority': priority.value,
    'etiquetas': etiquetas,
    'asignadoA': asignadoA,
    'asignadoNombre': asignadoNombre,
    'asignadoEmail': asignadoEmail,
    'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
    'fechaVencimiento': fechaVencimiento != null ? Timestamp.fromDate(fechaVencimiento!) : null,
    'fechaCompletada': fechaCompletada != null ? Timestamp.fromDate(fechaCompletada!) : null,
    'progreso': progreso,
    'horasEstimadas': horasEstimadas,
    'horasReales': horasReales,
    'dependencias': dependencias,
    'orden': orden,
    'notas': notas,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
    'lastModifiedBy': lastModifiedBy,
  };

  Map<String, dynamic> toUpdateMap() {
    final map = toMap();
    map.remove('createdAt');
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  // ═══════════════════════════════════════════════════════════
  // COPYWITH
  // ═══════════════════════════════════════════════════════════

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? titulo,
    String? descripcion,
    TaskStatus? status,
    TaskPriority? priority,
    List<String>? etiquetas,
    String? asignadoA,
    String? asignadoNombre,
    String? asignadoEmail,
    DateTime? fechaInicio,
    DateTime? fechaVencimiento,
    DateTime? fechaCompletada,
    int? progreso,
    double? horasEstimadas,
    double? horasReales,
    List<String>? dependencias,
    int? orden,
    String? notas,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      etiquetas: etiquetas ?? this.etiquetas,
      asignadoA: asignadoA ?? this.asignadoA,
      asignadoNombre: asignadoNombre ?? this.asignadoNombre,
      asignadoEmail: asignadoEmail ?? this.asignadoEmail,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaCompletada: fechaCompletada ?? this.fechaCompletada,
      progreso: progreso ?? this.progreso,
      horasEstimadas: horasEstimadas ?? this.horasEstimadas,
      horasReales: horasReales ?? this.horasReales,
      dependencias: dependencias ?? this.dependencias,
      orden: orden ?? this.orden,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
