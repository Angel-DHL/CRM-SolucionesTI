// lib/proyectos/services/project_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firebase_helper.dart';
import '../models/project.dart';
import '../models/project_enums.dart';
import '../models/project_material.dart';
import '../models/project_audit_log.dart';

/// Estadísticas del módulo de proyectos
class ProjectStats {
  final int totalProjects;
  final int activosCount;
  final int completadosCount;
  final int pausadosCount;
  final int planificacionCount;
  final int canceladosCount;
  final double valorTotalProyectos;
  final double totalIngresos;
  final double totalEgresos;
  final double rentabilidadPromedio;
  final int proyectosAtrasados;

  const ProjectStats({
    this.totalProjects = 0,
    this.activosCount = 0,
    this.completadosCount = 0,
    this.pausadosCount = 0,
    this.planificacionCount = 0,
    this.canceladosCount = 0,
    this.valorTotalProyectos = 0,
    this.totalIngresos = 0,
    this.totalEgresos = 0,
    this.rentabilidadPromedio = 0,
    this.proyectosAtrasados = 0,
  });
}

/// Filtros de búsqueda de proyectos
class ProjectFilters {
  final ProjectStatus? status;
  final ProjectType? type;
  final ProjectPriority? priority;
  final String? clienteId;
  final String? responsableId;
  final bool? esRecurrente;
  final String? searchQuery;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const ProjectFilters({
    this.status,
    this.type,
    this.priority,
    this.clienteId,
    this.responsableId,
    this.esRecurrente,
    this.searchQuery,
    this.fechaDesde,
    this.fechaHasta,
  });
}

class ProjectService {
  ProjectService._();
  static final ProjectService instance = ProjectService._();

  // Referencias
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseHelper.db.collection('projects');
  CollectionReference<Map<String, dynamic>> get _auditCol =>
      FirebaseHelper.db.collection('project_audit_logs');
  CollectionReference<Map<String, dynamic>> get _counterCol =>
      FirebaseHelper.db.collection('project_counters');

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // ═══════════════════════════════════════════════════════════
  // GENERACIÓN DE FOLIO
  // ═══════════════════════════════════════════════════════════

  Future<String> _generateFolio() async {
    final counterRef = _counterCol.doc('project_counter');
    return FirebaseHelper.db.runTransaction<String>((tx) async {
      final snap = await tx.get(counterRef);
      int current = 0;
      if (snap.exists) {
        current = (snap.data()?['current'] ?? 0) as int;
      }
      current++;
      tx.set(counterRef, {'current': current}, SetOptions(merge: true));
      return 'PRY-${current.toString().padLeft(6, '0')}';
    });
  }

  // ═══════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════

  /// Crear proyecto
  Future<String> createProject(Project project) async {
    final folio = await _generateFolio();
    final docRef = _col.doc();
    final data = project.copyWith(
      id: docRef.id,
      folio: folio,
      createdBy: _currentUser?.uid ?? '',
      lastModifiedBy: _currentUser?.uid,
    ).toMap();

    await docRef.set(data);

    await _logAudit(
      action: 'create',
      projectId: docRef.id,
      projectName: project.nombre,
      details: 'Proyecto creado: ${project.nombre} ($folio)',
      newData: {'status': project.status.value, 'valor': project.valorProyecto},
    );

    return docRef.id;
  }

  /// Obtener proyecto por ID
  Future<Project?> getProjectById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Project.fromDoc(doc);
  }

  /// Stream de un proyecto individual
  Stream<Project?> streamProject(String id) {
    return _col.doc(id).snapshots().map(
      (doc) => doc.exists ? Project.fromDoc(doc) : null,
    );
  }

  /// Actualizar proyecto completo
  Future<void> updateProject(Project project) async {
    final data = project.copyWith(
      lastModifiedBy: _currentUser?.uid,
      updatedAt: DateTime.now(),
    ).toUpdateMap();

    await _col.doc(project.id).update(data);

    await _logAudit(
      action: 'update',
      projectId: project.id,
      projectName: project.nombre,
      details: 'Proyecto actualizado',
    );
  }

  /// Actualizar campos específicos
  Future<void> updateProjectFields(String id, Map<String, dynamic> fields) async {
    fields['updatedAt'] = FieldValue.serverTimestamp();
    fields['lastModifiedBy'] = _currentUser?.uid;
    await _col.doc(id).update(fields);
  }

  /// Eliminar proyecto (soft delete via cancelación)
  Future<void> softDeleteProject(String id) async {
    final project = await getProjectById(id);
    await _col.doc(id).update({
      'status': ProjectStatus.cancelado.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _currentUser?.uid,
    });

    await _logAudit(
      action: 'delete',
      projectId: id,
      projectName: project?.nombre,
      details: 'Proyecto cancelado/eliminado',
    );
  }

  /// Eliminar permanentemente
  Future<void> hardDeleteProject(String id) async {
    // Eliminar subcolecciones primero
    final tasks = await _col.doc(id).collection('project_tasks').get();
    for (final t in tasks.docs) { await t.reference.delete(); }
    final txns = await _col.doc(id).collection('project_transactions').get();
    for (final t in txns.docs) { await t.reference.delete(); }
    await _col.doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════════
  // STREAMS Y QUERIES
  // ═══════════════════════════════════════════════════════════

  /// Stream de todos los proyectos con filtros opcionales
  Stream<List<Project>> streamProjects({ProjectFilters? filters}) {
    Query<Map<String, dynamic>> query = _col.orderBy('createdAt', descending: true);

    if (filters?.status != null) {
      query = query.where('status', isEqualTo: filters!.status!.value);
    }
    if (filters?.type != null) {
      query = query.where('type', isEqualTo: filters!.type!.value);
    }
    if (filters?.priority != null) {
      query = query.where('priority', isEqualTo: filters!.priority!.value);
    }
    if (filters?.clienteId != null) {
      query = query.where('clienteId', isEqualTo: filters!.clienteId);
    }
    if (filters?.responsableId != null) {
      query = query.where('responsableId', isEqualTo: filters!.responsableId);
    }
    if (filters?.esRecurrente != null) {
      query = query.where('esRecurrente', isEqualTo: filters!.esRecurrente);
    }

    return query.snapshots().map((snap) {
      var projects = snap.docs.map(Project.fromDoc).toList();

      // Filtrado en memoria para búsqueda de texto
      if (filters?.searchQuery != null && filters!.searchQuery!.isNotEmpty) {
        final q = filters.searchQuery!.toLowerCase();
        projects = projects.where((p) =>
            p.nombre.toLowerCase().contains(q) ||
            p.folio.toLowerCase().contains(q) ||
            p.clienteNombre.toLowerCase().contains(q) ||
            (p.clienteEmpresa?.toLowerCase().contains(q) ?? false) ||
            p.descripcion.toLowerCase().contains(q)
        ).toList();
      }

      return projects;
    });
  }

  /// Obtener proyectos de un cliente
  Future<List<Project>> getProjectsByClient(String clienteId) async {
    final snap = await _col
        .where('clienteId', isEqualTo: clienteId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(Project.fromDoc).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // OPERACIONES ESPECIALIZADAS
  // ═══════════════════════════════════════════════════════════

  /// Cambiar estado del proyecto con auditoría
  Future<void> changeStatus(String id, ProjectStatus newStatus) async {
    final project = await getProjectById(id);
    if (project == null) return;

    final Map<String, dynamic> updates = {
      'status': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _currentUser?.uid,
    };

    // Si se completa, registrar fecha real
    if (newStatus == ProjectStatus.completado) {
      updates['fechaFinReal'] = Timestamp.fromDate(DateTime.now());
    }

    await _col.doc(id).update(updates);

    await _logAudit(
      action: 'status_change',
      projectId: id,
      projectName: project.nombre,
      details: 'Estado: ${project.status.label} → ${newStatus.label}',
      previousData: {'status': project.status.value},
      newData: {'status': newStatus.value},
    );
  }

  /// Actualizar contadores de tareas (sin modificar progreso)
  Future<void> recalculateProgress(String projectId) async {
    final tasksSnap = await _col
        .doc(projectId)
        .collection('project_tasks')
        .get();

    int total = tasksSnap.docs.length;
    int completed = tasksSnap.docs
        .where((d) => d.data()['status'] == 'completada')
        .length;

    await _col.doc(projectId).update({
      'tareasTotal': total,
      'tareasCompletadas': completed,
      'fechaUltimaActividad': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Recalcular financieros desde transacciones Y progreso basado en pagos
  Future<void> recalculateFinancials(String projectId) async {
    final txnSnap = await _col
        .doc(projectId)
        .collection('project_transactions')
        .where('status', whereIn: ['aprobada', 'completada'])
        .get();

    double ingresos = 0;
    double egresos = 0;
    double adelantos = 0;

    for (final doc in txnSnap.docs) {
      final data = doc.data();
      final monto = (data['monto'] ?? 0).toDouble();
      final type = data['type'] as String?;

      if (['ingreso', 'pago_parcial', 'pago_final'].contains(type)) {
        ingresos += monto;
      } else if (type == 'adelanto') {
        adelantos += monto;
        ingresos += monto;
      } else if (['egreso', 'reembolso', 'gasto_material', 'gasto_mano_obra', 'gasto_operativo'].contains(type)) {
        egresos += monto;
      }
    }

    // Calcular progreso basado en pagos vs valor del proyecto
    final projectDoc = await _col.doc(projectId).get();
    final valorProyecto = (projectDoc.data()?['valorProyecto'] ?? 0).toDouble();
    int progreso = 0;
    if (valorProyecto > 0) {
      progreso = ((ingresos / valorProyecto) * 100).round().clamp(0, 100);
    }

    await _col.doc(projectId).update({
      'totalIngresos': ingresos,
      'totalEgresos': egresos,
      'totalAdelantos': adelantos,
      'costoReal': egresos,
      'progreso': progreso,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Recalcular progreso de todos los proyectos (para migrar datos existentes)
  Future<void> recalculateAllProjectsProgress() async {
    final snap = await _col.get();
    for (final doc in snap.docs) {
      await recalculateFinancials(doc.id);
    }
  }

  /// Agregar material al proyecto
  Future<void> addMaterial(String projectId, ProjectMaterial material) async {
    final project = await getProjectById(projectId);
    if (project == null) return;

    final updatedMaterials = [...project.materiales, material];

    await _col.doc(projectId).update({
      'materiales': updatedMaterials.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _currentUser?.uid,
    });

    await _logAudit(
      action: 'material_add',
      projectId: projectId,
      projectName: project.nombre,
      entityName: material.nombre,
      details: 'Material agregado: ${material.nombre} (${material.cantidad} ${material.unidad})',
    );
  }

  /// Remover material del proyecto
  Future<void> removeMaterial(String projectId, String inventoryItemId) async {
    final project = await getProjectById(projectId);
    if (project == null) return;

    final updated = project.materiales
        .where((m) => m.inventoryItemId != inventoryItemId)
        .toList();

    await _col.doc(projectId).update({
      'materiales': updated.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Agregar miembro al equipo
  Future<void> addTeamMember(String projectId, Map<String, dynamic> member) async {
    final project = await getProjectById(projectId);
    if (project == null) return;

    await _col.doc(projectId).update({
      'miembrosEquipo': FieldValue.arrayUnion([member]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logAudit(
      action: 'team_add',
      projectId: projectId,
      projectName: project.nombre,
      entityName: member['nombre'] ?? 'Miembro',
      details: 'Miembro agregado: ${member['nombre']}',
    );
  }

  /// Remover miembro del equipo
  Future<void> removeTeamMember(String projectId, String uid) async {
    final project = await getProjectById(projectId);
    if (project == null) return;

    final updated = project.miembrosEquipo
        .where((m) => m['uid'] != uid)
        .toList();

    await _col.doc(projectId).update({
      'miembrosEquipo': updated,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logAudit(
      action: 'team_remove',
      projectId: projectId,
      projectName: project.nombre,
      details: 'Miembro removido del equipo',
    );
  }

  /// Clonar proyecto (para recurrentes o plantillas)
  Future<String> cloneProject(String sourceId, {String? nuevoNombre}) async {
    final source = await getProjectById(sourceId);
    if (source == null) throw Exception('Proyecto no encontrado');

    final clone = source.copyWith(
      id: '',
      folio: '',
      nombre: nuevoNombre ?? '${source.nombre} (Copia)',
      status: ProjectStatus.planificacion,
      progreso: 0,
      tareasTotal: 0,
      tareasCompletadas: 0,
      totalIngresos: 0,
      totalEgresos: 0,
      totalAdelantos: 0,
      costoReal: 0,
      fechaFinReal: null,
      fechaUltimaActividad: null,
      proyectoPadreId: source.esRecurrente ? sourceId : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return createProject(clone);
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════

  Future<ProjectStats> getStats() async {
    final snap = await _col.get();
    final projects = snap.docs.map(Project.fromDoc).toList();

    return ProjectStats(
      totalProjects: projects.length,
      activosCount: projects.where((p) => p.status == ProjectStatus.enProgreso).length,
      completadosCount: projects.where((p) => p.status == ProjectStatus.completado).length,
      pausadosCount: projects.where((p) => p.status == ProjectStatus.pausado).length,
      planificacionCount: projects.where((p) => p.status == ProjectStatus.planificacion).length,
      canceladosCount: projects.where((p) => p.status == ProjectStatus.cancelado).length,
      valorTotalProyectos: projects.fold(0, (s, p) => s + p.valorProyecto),
      totalIngresos: projects.fold(0, (s, p) => s + p.totalIngresos),
      totalEgresos: projects.fold(0, (s, p) => s + p.totalEgresos),
      rentabilidadPromedio: projects.isNotEmpty
          ? projects.fold(0.0, (s, p) => s + p.margenRentabilidad) / projects.length
          : 0,
      proyectosAtrasados: projects.where((p) => p.estaAtrasado).length,
    );
  }

  Stream<ProjectStats> streamStats() {
    return _col.snapshots().map((snap) {
      final projects = snap.docs.map(Project.fromDoc).toList();
      return ProjectStats(
        totalProjects: projects.length,
        activosCount: projects.where((p) => p.status == ProjectStatus.enProgreso).length,
        completadosCount: projects.where((p) => p.status == ProjectStatus.completado).length,
        pausadosCount: projects.where((p) => p.status == ProjectStatus.pausado).length,
        planificacionCount: projects.where((p) => p.status == ProjectStatus.planificacion).length,
        canceladosCount: projects.where((p) => p.status == ProjectStatus.cancelado).length,
        valorTotalProyectos: projects.fold(0, (sum, p) => sum + p.valorProyecto),
        totalIngresos: projects.fold(0, (sum, p) => sum + p.totalIngresos),
        totalEgresos: projects.fold(0, (sum, p) => sum + p.totalEgresos),
        rentabilidadPromedio: projects.isNotEmpty
            ? projects.fold(0.0, (sum, p) => sum + p.margenRentabilidad) / projects.length
            : 0,
        proyectosAtrasados: projects.where((p) => p.estaAtrasado).length,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════

  Future<void> _logAudit({
    required String action,
    String? projectId,
    String? projectName,
    String? entityId,
    String? entityName,
    String? details,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      await _auditCol.add(ProjectAuditLog(
        id: '',
        module: 'projects',
        action: action,
        projectId: projectId,
        projectName: projectName,
        entityId: entityId,
        entityName: entityName,
        details: details,
        previousData: previousData,
        newData: newData,
        userId: _currentUser?.uid,
        userEmail: _currentUser?.email,
        userName: _currentUser?.email?.split('@')[0],
        timestamp: DateTime.now(),
      ).toMap());
    } catch (_) {
      // No bloquear operación principal
    }
  }

  /// Stream de audit logs para un proyecto
  Stream<List<ProjectAuditLog>> streamAuditLogs({String? projectId, int limit = 50}) {
    Query<Map<String, dynamic>> query = _auditCol;

    if (projectId != null) {
      // Filtrar por projectId y ordenar en memoria para evitar requerir composite index
      query = query.where('projectId', isEqualTo: projectId);
      return query.limit(limit).snapshots().map((snap) {
        final logs = snap.docs.map(ProjectAuditLog.fromDoc).toList();
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return logs;
      });
    }

    // Sin filtro de proyecto: se puede usar orderBy directamente
    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ProjectAuditLog.fromDoc).toList());
  }
}
