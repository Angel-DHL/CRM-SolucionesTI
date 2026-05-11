// lib/proyectos/services/project_task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firebase_helper.dart';
import '../../operatividad/models/oper_activity.dart';
import '../models/project_task.dart';
import '../models/project_enums.dart';
import 'project_service.dart';

class ProjectTaskService {
  ProjectTaskService._();
  static final ProjectTaskService instance = ProjectTaskService._();

  final _projectService = ProjectService.instance;
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _tasksCol(String projectId) =>
      FirebaseHelper.db.collection('projects').doc(projectId).collection('project_tasks');

  // ═══════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════

  Future<String> createTask(ProjectTask task) async {
    final docRef = _tasksCol(task.projectId).doc();
    final data = task.copyWith(
      id: docRef.id,
      createdBy: _currentUser?.uid ?? '',
    ).toMap();

    await docRef.set(data);

    // Recalcular progreso del proyecto
    await _projectService.recalculateProgress(task.projectId);

    // Auditoría
    await _logTaskAudit(
      action: 'task_create',
      projectId: task.projectId,
      taskName: task.titulo,
      details: 'Tarea creada: ${task.titulo}',
    );

    return docRef.id;
  }

  /// Crear tarea Y actividad en Operatividad (batch atómico)
  Future<String> createTaskWithOperActivity(ProjectTask task) async {
    final user = _currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Obtener nombre del proyecto para contexto
    final project = await _projectService.getProjectById(task.projectId);
    final projectName = project?.nombre ?? 'Proyecto';

    final taskDocRef = _tasksCol(task.projectId).doc();
    final operDocRef = FirebaseHelper.operActivities.doc();

    final taskData = task.copyWith(
      id: taskDocRef.id,
      createdBy: user.uid,
    ).toMap();

    final now = DateTime.now();
    final operData = OperActivity.createMap(
      title: '[$projectName] ${task.titulo}',
      description: task.descripcion ?? 'Tarea del proyecto: $projectName',
      plannedStartAt: task.fechaInicio ?? now,
      plannedEndAt: task.fechaVencimiento ?? now.add(const Duration(days: 7)),
      assigneesUids: task.asignadoA != null ? [task.asignadoA!] : [user.uid],
      assigneesEmails: task.asignadoEmail != null ? [task.asignadoEmail!] : [user.email ?? ''],
      createdByUid: user.uid,
      createdByEmail: user.email ?? '',
      priority: task.priority == TaskPriority.alta || task.priority == TaskPriority.urgente ? 'high' : task.priority == TaskPriority.baja ? 'low' : 'medium',
      tags: ['proyecto', projectName, 'PRY-TASK:${taskDocRef.id}'],
    );

    final batch = FirebaseHelper.db.batch();
    batch.set(taskDocRef, taskData);
    batch.set(operDocRef, operData);
    await batch.commit();

    await _projectService.recalculateProgress(task.projectId);

    await _logTaskAudit(
      action: 'task_create',
      projectId: task.projectId,
      taskName: task.titulo,
      details: 'Tarea creada con sincronización a Operatividad: ${task.titulo}',
    );

    return taskDocRef.id;
  }

  Future<ProjectTask?> getTaskById(String projectId, String taskId) async {
    final doc = await _tasksCol(projectId).doc(taskId).get();
    if (!doc.exists) return null;
    return ProjectTask.fromDoc(doc, projectId);
  }

  Future<void> updateTask(ProjectTask task) async {
    await _tasksCol(task.projectId).doc(task.id).update(
      task.copyWith(lastModifiedBy: _currentUser?.uid).toUpdateMap(),
    );
    await _projectService.recalculateProgress(task.projectId);
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _tasksCol(projectId).doc(taskId).delete();
    await _projectService.recalculateProgress(projectId);
  }

  // ═══════════════════════════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════════════════════════

  Stream<List<ProjectTask>> streamTasks(String projectId, {TaskStatus? status}) {
    Query<Map<String, dynamic>> query = _tasksCol(projectId).orderBy('orden');

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    return query.snapshots().map(
      (snap) => snap.docs.map((d) => ProjectTask.fromDoc(d, projectId)).toList(),
    );
  }

  /// One-shot para obtener tareas (para IA)
  Future<List<ProjectTask>> getProjectTasks(String projectId) async {
    final snap = await _tasksCol(projectId).orderBy('orden').get();
    return snap.docs.map((d) => ProjectTask.fromDoc(d, projectId)).toList();
  }

  /// Stream de tareas agrupadas por estado (para Kanban)
  Stream<Map<TaskStatus, List<ProjectTask>>> streamTasksGrouped(String projectId) {
    return _tasksCol(projectId).orderBy('orden').snapshots().map((snap) {
      final tasks = snap.docs.map((d) => ProjectTask.fromDoc(d, projectId)).toList();
      final grouped = <TaskStatus, List<ProjectTask>>{};
      for (final s in TaskStatus.values) {
        grouped[s] = tasks.where((t) => t.status == s).toList();
      }
      return grouped;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // OPERACIONES ESPECIALIZADAS
  // ═══════════════════════════════════════════════════════════

  /// Completar una tarea
  Future<void> completeTask(String projectId, String taskId) async {
    await _tasksCol(projectId).doc(taskId).update({
      'status': TaskStatus.completada.value,
      'progreso': 100,
      'fechaCompletada': Timestamp.fromDate(DateTime.now()),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _currentUser?.uid,
    });

    await _projectService.recalculateProgress(projectId);

    await _logTaskAudit(
      action: 'task_complete',
      projectId: projectId,
      details: 'Tarea completada',
    );
  }

  /// Cambiar estado de tarea
  Future<void> changeTaskStatus(String projectId, String taskId, TaskStatus newStatus) async {
    final Map<String, dynamic> updates = {
      'status': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _currentUser?.uid,
    };

    if (newStatus == TaskStatus.completada) {
      updates['progreso'] = 100;
      updates['fechaCompletada'] = Timestamp.fromDate(DateTime.now());
    }

    await _tasksCol(projectId).doc(taskId).update(updates);
    await _projectService.recalculateProgress(projectId);
  }

  /// Reordenar tareas (para Kanban drag & drop)
  Future<void> reorderTasks(String projectId, List<String> taskIds) async {
    final batch = FirebaseHelper.db.batch();
    for (int i = 0; i < taskIds.length; i++) {
      batch.update(_tasksCol(projectId).doc(taskIds[i]), {'orden': i});
    }
    await batch.commit();
  }

  /// Registrar horas trabajadas
  Future<void> logHours(String projectId, String taskId, double hours) async {
    final task = await getTaskById(projectId, taskId);
    if (task == null) return;

    await _tasksCol(projectId).doc(taskId).update({
      'horasReales': task.horasReales + hours,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, int>> getTaskCountsByStatus(String projectId) async {
    final snap = await _tasksCol(projectId).get();
    final counts = <String, int>{};
    for (final s in TaskStatus.values) {
      counts[s.value] = snap.docs.where((d) => d.data()['status'] == s.value).length;
    }
    return counts;
  }

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA INTERNA
  // ═══════════════════════════════════════════════════════════

  Future<void> _logTaskAudit({
    required String action,
    required String projectId,
    String? taskName,
    String? details,
  }) async {
    try {
      await FirebaseHelper.db.collection('project_audit_logs').add({
        'module': 'tasks',
        'action': action,
        'projectId': projectId,
        'entityName': taskName,
        'details': details,
        'userId': _currentUser?.uid,
        'userEmail': _currentUser?.email,
        'userName': _currentUser?.email?.split('@')[0],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
