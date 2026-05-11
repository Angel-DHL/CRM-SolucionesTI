// lib/proyectos/pages/project_tasks_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/firebase_helper.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import '../models/project_enums.dart';
import '../services/project_service.dart';
import '../services/project_task_service.dart';

class ProjectTasksPage extends StatefulWidget {
  final UserRole role;
  const ProjectTasksPage({super.key, required this.role});

  @override
  State<ProjectTasksPage> createState() => _ProjectTasksPageState();
}

class _ProjectTasksPageState extends State<ProjectTasksPage> {
  String? _selectedProjectId;
  final _df = DateFormat('dd/MM', 'es_MX');

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildProjectSelector(),
      Expanded(
        child: _selectedProjectId == null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.task_alt_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                const SizedBox(height: AppDimensions.md),
                Text('Selecciona un proyecto para ver sus tareas', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
              ]))
            : _buildKanban(_selectedProjectId!),
      ),
    ]);
  }

  Widget _buildProjectSelector() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: StreamBuilder<List<Project>>(
        stream: ProjectService.instance.streamProjects(),
        builder: (ctx, snap) {
          final projects = snap.data ?? [];
          return Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _selectedProjectId,
              decoration: const InputDecoration(labelText: 'Proyecto', prefixIcon: Icon(Icons.folder_rounded), isDense: true),
              items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.folio} — ${p.nombre}', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _selectedProjectId = v),
            )),
            if (_selectedProjectId != null) ...[
              const SizedBox(width: AppDimensions.md),
              FilledButton.icon(
                onPressed: () => _showAddTaskDialog(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Nueva Tarea'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ]);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // KANBAN CON DRAG & DROP
  // ═══════════════════════════════════════════════════════════

  Widget _buildKanban(String projectId) {
    return StreamBuilder<Map<TaskStatus, List<ProjectTask>>>(
      stream: ProjectTaskService.instance.streamTasksGrouped(projectId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final grouped = snap.data ?? {};
        final columns = [TaskStatus.pendiente, TaskStatus.enProgreso, TaskStatus.enRevision, TaskStatus.completada];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((status) {
              final tasks = grouped[status] ?? [];
              return _KanbanColumn(
                status: status,
                tasks: tasks,
                df: _df,
                onTaskDropped: (task) => _onTaskDropped(task, status),
                onTaskTap: _showTaskDetailDialog,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _onTaskDropped(ProjectTask task, TaskStatus newStatus) async {
    if (task.status == newStatus) return;
    try {
      await ProjectTaskService.instance.changeTaskStatus(task.projectId, task.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tarea movida a ${newStatus.label}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DIÁLOGO DE DETALLE DE TAREA
  // ═══════════════════════════════════════════════════════════

  void _showTaskDetailDialog(ProjectTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        title: Row(children: [
          Icon(task.status.icon, color: task.status.color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(task.titulo, style: AppTextStyles.h4)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (task.descripcion != null && task.descripcion!.isNotEmpty)
            Text(task.descripcion!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _detailRow(Icons.flag_rounded, 'Prioridad', task.priority.label, task.priority.color),
          _detailRow(Icons.swap_horiz_rounded, 'Estado', task.status.label, task.status.color),
          if (task.asignadoNombre != null)
            _detailRow(Icons.person_rounded, 'Asignado', task.asignadoNombre!, AppColors.primary),
          if (task.fechaVencimiento != null)
            _detailRow(Icons.event_rounded, 'Vence', _df.format(task.fechaVencimiento!), task.estaVencida ? AppColors.error : AppColors.textSecondary),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ProjectTaskService.instance.deleteTask(task.projectId, task.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIÁLOGO DE NUEVA TAREA (MEJORADO)
  // ═══════════════════════════════════════════════════════════

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TaskPriority priority = TaskPriority.media;
    String? asignadoUid;
    String? asignadoNombre;
    String? asignadoEmail;
    DateTime? fechaVencimiento;
    bool syncOper = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(children: [
                  const Icon(Icons.add_task_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Nueva Tarea', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ]),
                const Divider(height: AppDimensions.lg),

                // Título
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título de la tarea *', prefixIcon: Icon(Icons.title_rounded)), autofocus: true),
                const SizedBox(height: AppDimensions.md),

                // Descripción
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', prefixIcon: Icon(Icons.notes_rounded)), maxLines: 2),
                const SizedBox(height: AppDimensions.md),

                // Prioridad
                DropdownButtonFormField<TaskPriority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Prioridad', prefixIcon: Icon(Icons.flag_rounded), isDense: true),
                  items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(p.label),
                  ]))).toList(),
                  onChanged: (v) => setDialogState(() => priority = v!),
                ),
                const SizedBox(height: AppDimensions.md),

                // Asignar responsable
                _UserPickerField(
                  selectedName: asignadoNombre,
                  onSelected: (uid, name, email) => setDialogState(() {
                    asignadoUid = uid;
                    asignadoNombre = name;
                    asignadoEmail = email;
                  }),
                  onClear: () => setDialogState(() {
                    asignadoUid = null;
                    asignadoNombre = null;
                    asignadoEmail = null;
                  }),
                ),
                const SizedBox(height: AppDimensions.md),

                // Fecha de vencimiento
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime(2035));
                    if (date != null) setDialogState(() => fechaVencimiento = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha de vencimiento',
                      prefixIcon: const Icon(Icons.event_rounded),
                      suffixIcon: fechaVencimiento != null ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: () => setDialogState(() => fechaVencimiento = null)) : null,
                    ),
                    child: Text(fechaVencimiento != null ? DateFormat('dd/MM/yyyy').format(fechaVencimiento!) : 'Seleccionar (opcional)', style: TextStyle(color: fechaVencimiento != null ? AppColors.textPrimary : AppColors.textHint)),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Checkbox Operatividad
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  child: CheckboxListTile(
                    value: syncOper,
                    onChanged: (v) => setDialogState(() => syncOper = v ?? false),
                    activeColor: AppColors.primary,
                    title: const Text('Sincronizar con Operatividad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Crea también una actividad en el módulo de Operatividad', style: TextStyle(fontSize: 11)),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Botones
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final task = ProjectTask(
                        id: '', projectId: _selectedProjectId!, titulo: titleCtrl.text.trim(),
                        descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        status: TaskStatus.pendiente, priority: priority,
                        asignadoA: asignadoUid, asignadoNombre: asignadoNombre, asignadoEmail: asignadoEmail,
                        fechaVencimiento: fechaVencimiento,
                        createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: '',
                      );
                      if (syncOper && asignadoUid != null) {
                        await ProjectTaskService.instance.createTaskWithOperActivity(task);
                      } else {
                        await ProjectTaskService.instance.createTask(task);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Crear Tarea'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ]),
              ])),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: COLUMNA KANBAN CON DRAG TARGET
// ═══════════════════════════════════════════════════════════

class _KanbanColumn extends StatefulWidget {
  final TaskStatus status;
  final List<ProjectTask> tasks;
  final DateFormat df;
  final Future<void> Function(ProjectTask) onTaskDropped;
  final void Function(ProjectTask) onTaskTap;

  const _KanbanColumn({required this.status, required this.tasks, required this.df, required this.onTaskDropped, required this.onTaskTap});

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ProjectTask>(
      onWillAcceptWithDetails: (details) {
        final willAccept = details.data.status != widget.status;
        if (willAccept && !_isDragOver) setState(() => _isDragOver = true);
        return willAccept;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        widget.onTaskDropped(details.data);
      },
      builder: (ctx, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          margin: const EdgeInsets.only(right: AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _isDragOver ? Border.all(color: widget.status.color, width: 2.5) : null,
            boxShadow: _isDragOver ? [BoxShadow(color: widget.status.color.withOpacity(0.15), blurRadius: 12)] : null,
          ),
          child: Column(children: [
            // Column header
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: _isDragOver ? widget.status.color.withOpacity(0.2) : widget.status.color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Icon(widget.status.icon, size: 18, color: widget.status.color),
                const SizedBox(width: 8),
                Text(widget.status.label, style: TextStyle(fontWeight: FontWeight.w600, color: widget.status.color)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: widget.status.color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.tasks.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.status.color)),
                ),
              ]),
            ),
            // Tasks list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _isDragOver ? widget.status.color.withOpacity(0.05) : AppColors.surface,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border.all(color: _isDragOver ? widget.status.color.withOpacity(0.3) : AppColors.divider),
                ),
                child: widget.tasks.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.lg),
                        child: Text(_isDragOver ? 'Soltar aquí' : 'Sin tareas',
                          style: TextStyle(color: _isDragOver ? widget.status.color : AppColors.textHint, fontSize: 13, fontWeight: _isDragOver ? FontWeight.w600 : FontWeight.w400)),
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        itemCount: widget.tasks.length,
                        itemBuilder: (ctx, i) => _DraggableKanbanCard(task: widget.tasks[i], df: widget.df, onTap: () => widget.onTaskTap(widget.tasks[i])),
                      ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: TARJETA KANBAN DRAGGABLE
// ═══════════════════════════════════════════════════════════

class _DraggableKanbanCard extends StatelessWidget {
  final ProjectTask task;
  final DateFormat df;
  final VoidCallback onTap;

  const _DraggableKanbanCard({required this.task, required this.df, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Draggable<ProjectTask>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 260, child: _buildCard(isDragging: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCard()),
      child: GestureDetector(onTap: onTap, child: _buildCard()),
    );
  }

  Widget _buildCard({bool isDragging = false}) {
    return Card(
      elevation: isDragging ? 4 : 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isDragging ? AppColors.primary : AppColors.divider)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Título
          Text(task.titulo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (task.descripcion != null && task.descripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(task.descripcion!, style: const TextStyle(fontSize: 10, color: AppColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          const SizedBox(height: 6),
          // Prioridad + Fecha
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: task.priority.color.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
              child: Text(task.priority.label, style: TextStyle(fontSize: 9, color: task.priority.color, fontWeight: FontWeight.w500)),
            ),
            if (task.fechaVencimiento != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.event_rounded, size: 10, color: task.estaVencida ? AppColors.error : AppColors.textHint),
              const SizedBox(width: 2),
              Text(df.format(task.fechaVencimiento!), style: TextStyle(fontSize: 9, color: task.estaVencida ? AppColors.error : AppColors.textHint, fontWeight: task.estaVencida ? FontWeight.w600 : FontWeight.w400)),
            ],
            const Spacer(),
            // Avatar asignado
            if (task.asignadoNombre != null)
              Tooltip(
                message: task.asignadoNombre!,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(task.asignadoNombre![0].toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
          ]),
          if (task.estaVencida)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(3)),
                child: const Text('⚠️ Vencida', style: TextStyle(fontSize: 9, color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: SELECTOR DE USUARIO
// ═══════════════════════════════════════════════════════════

class _UserPickerField extends StatelessWidget {
  final String? selectedName;
  final void Function(String uid, String name, String email) onSelected;
  final VoidCallback onClear;

  const _UserPickerField({required this.selectedName, required this.onSelected, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showUserPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Asignar a',
          prefixIcon: const Icon(Icons.person_rounded),
          suffixIcon: selectedName != null ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: onClear) : const Icon(Icons.arrow_drop_down_rounded),
        ),
        child: Text(selectedName ?? 'Sin asignar (opcional)', style: TextStyle(color: selectedName != null ? AppColors.textPrimary : AppColors.textHint)),
      ),
    );
  }

  void _showUserPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Row(children: [
                const Icon(Icons.people_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Seleccionar Responsable', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseHelper.users.snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) return const Center(child: Text('No hay usuarios'));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final data = docs[i].data();
                      final email = (data['email'] ?? '').toString();
                      final name = email.split('@').first;
                      final role = (data['role'] ?? '').toString();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primarySurface,
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('$email • $role', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        onTap: () {
                          onSelected(docs[i].id, name, email);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
