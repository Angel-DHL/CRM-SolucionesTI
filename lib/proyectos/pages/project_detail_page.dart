// lib/proyectos/pages/project_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/project.dart';
import '../models/project_enums.dart';
import '../models/project_task.dart';
import '../models/project_transaction.dart';
import '../models/project_audit_log.dart';
import '../services/project_service.dart';
import '../services/project_task_service.dart';
import '../services/project_transaction_service.dart';
import '../services/project_report_service.dart';
import 'project_form_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  final _df = DateFormat('dd MMM yyyy', 'es_MX');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Project?>(
      stream: ProjectService.instance.streamProject(widget.projectId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final project = snap.data;
        if (project == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Proyecto no encontrado')));
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(project),
          body: Column(children: [
            _buildProjectHeader(project),
            TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Resumen', icon: Icon(Icons.dashboard_rounded, size: 18)),
                Tab(text: 'Tareas', icon: Icon(Icons.task_alt_rounded, size: 18)),
                Tab(text: 'Finanzas', icon: Icon(Icons.account_balance_wallet_rounded, size: 18)),
                Tab(text: 'Historial', icon: Icon(Icons.timeline_rounded, size: 18)),
              ],
            ),
            Expanded(child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildResumenTab(project),
                _buildTareasTab(project),
                _buildFinanzasTab(project),
                _buildHistorialTab(project),
              ],
            )),
          ]),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Project project) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(project.nombre, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) => _handleAction(v, project),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Editar'))),
            const PopupMenuItem(value: 'report', child: ListTile(leading: Icon(Icons.picture_as_pdf_rounded), title: Text('Generar Reporte'))),
            const PopupMenuItem(value: 'clone', child: ListTile(leading: Icon(Icons.copy_rounded), title: Text('Duplicar'))),
            const PopupMenuDivider(),
            ...ProjectStatus.values.where((s) => s != project.status).map((s) =>
              PopupMenuItem(value: 'status_${s.value}', child: ListTile(leading: Icon(s.icon, color: s.color), title: Text(s.label))),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProjectHeader(Project project) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      color: AppColors.surface,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: project.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(project.status.icon, size: 16, color: project.status.color),
            const SizedBox(width: 4),
            Text(project.status.label, style: TextStyle(fontWeight: FontWeight.w600, color: project.status.color, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(project.folio, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Icon(project.salud.icon, size: 18, color: project.salud.color),
        const Spacer(),
        Text('${project.progreso}%', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(width: 8),
        SizedBox(width: 100, child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: project.progreso / 100, backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation(project.salud.color), minHeight: 8),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB: RESUMEN
  // ═══════════════════════════════════════════════════════════

  Widget _buildResumenTab(Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // KPIs financieros
        Wrap(spacing: AppDimensions.sm, runSpacing: AppDimensions.sm, children: [
          _kpiChip('Valor', _nf.format(project.valorProyecto), Icons.attach_money_rounded, AppColors.info),
          _kpiChip('Ingresos', _nf.format(project.totalIngresos), Icons.trending_up_rounded, AppColors.success),
          _kpiChip('Egresos', _nf.format(project.totalEgresos), Icons.trending_down_rounded, AppColors.error),
          _kpiChip('Rentabilidad', _nf.format(project.rentabilidad), Icons.insights_rounded, project.rentabilidad >= 0 ? AppColors.success : AppColors.error),
          _kpiChip('Saldo', _nf.format(project.saldoPendiente), Icons.account_balance_rounded, AppColors.warning),
        ]),
        const SizedBox(height: AppDimensions.xl),
        // Información del proyecto
        _sectionCard('Descripción', [
          Text(project.descripcion, style: AppTextStyles.bodyMedium),
          if (project.descripcionDetallada != null) ...[
            const SizedBox(height: 8),
            Text(project.descripcionDetallada!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ]),
        const SizedBox(height: AppDimensions.md),
        _sectionCard('Cliente', [
          Text(project.clienteNombre, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          if (project.clienteEmpresa != null) Text(project.clienteEmpresa!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (project.clienteEmail != null) Text(project.clienteEmail!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
        ]),
        const SizedBox(height: AppDimensions.md),
        _sectionCard('Cronograma', [
          _infoRow('Inicio', project.fechaInicio != null ? _df.format(project.fechaInicio!) : 'Sin definir'),
          _infoRow('Fin estimado', project.fechaFinEstimada != null ? _df.format(project.fechaFinEstimada!) : 'Sin definir'),
          if (project.fechaFinReal != null) _infoRow('Fin real', _df.format(project.fechaFinReal!)),
          _infoRow('Días transcurridos', '${project.diasTranscurridos}'),
          _infoRow('Días restantes', '${project.diasRestantes}'),
          if (project.estaAtrasado) Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(4)),
              child: const Text('⚠️ Proyecto atrasado', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        if (project.materiales.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.md),
          _sectionCard('Materiales', project.materiales.map((m) =>
            _infoRow(m.nombre, '${m.cantidad} ${m.unidad} — ${_nf.format(m.subtotal)}'),
          ).toList()),
        ],
      ]),
    );
  }

  Widget _kpiChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: AppColors.divider)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ]),
      ]),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint))),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB: TAREAS
  // ═══════════════════════════════════════════════════════════

  Widget _buildTareasTab(Project project) {
    return StreamBuilder<List<ProjectTask>>(
      stream: ProjectTaskService.instance.streamTasks(project.id),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(children: [
              Text('${tasks.length} tareas', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddTaskDialog(project.id),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Nueva Tarea'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ]),
          ),
          Expanded(child: tasks.isEmpty
            ? Center(child: Text('Sin tareas', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                itemCount: tasks.length,
                itemBuilder: (ctx, i) => _taskTile(tasks[i]),
              ),
          ),
        ]);
      },
    );
  }

  Widget _taskTile(ProjectTask task) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), side: BorderSide(color: AppColors.divider)),
      child: ListTile(
        leading: IconButton(
          icon: Icon(task.status.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: task.status.color),
          onPressed: () => task.status.isDone ? null : ProjectTaskService.instance.completeTask(task.projectId, task.id),
        ),
        title: Text(task.titulo, style: TextStyle(decoration: task.status.isDone ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w500)),
        subtitle: Row(children: [
          if (task.asignadoNombre != null) ...[
            Icon(Icons.person_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 2),
            Text(task.asignadoNombre!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: task.priority.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
            child: Text(task.priority.label, style: TextStyle(fontSize: 10, color: task.priority.color)),
          ),
        ]),
        trailing: PopupMenuButton<TaskStatus>(
          onSelected: (s) => ProjectTaskService.instance.changeTaskStatus(task.projectId, task.id, s),
          itemBuilder: (_) => TaskStatus.values.map((s) => PopupMenuItem(value: s, child: Row(children: [
            Icon(s.icon, size: 16, color: s.color), const SizedBox(width: 8), Text(s.label),
          ]))).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: task.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(task.status.label, style: TextStyle(fontSize: 11, color: task.status.color, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(String projectId) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Tarea'),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título de la tarea'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ProjectTaskService.instance.createTask(ProjectTask(
                id: '', projectId: projectId, titulo: titleCtrl.text.trim(),
                status: TaskStatus.pendiente, priority: TaskPriority.media,
                createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: '',
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB: FINANZAS
  // ═══════════════════════════════════════════════════════════

  Widget _buildFinanzasTab(Project project) {
    return StreamBuilder<List<ProjectTransaction>>(
      stream: ProjectTransactionService.instance.streamTransactions(project.id),
      builder: (ctx, snap) {
        final txns = snap.data ?? [];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(children: [
              Text('${txns.length} transacciones', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddTransactionDialog(project.id),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Registrar'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ]),
          ),
          Expanded(child: txns.isEmpty
            ? Center(child: Text('Sin transacciones', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                itemCount: txns.length,
                itemBuilder: (ctx, i) => _txnTile(txns[i]),
              ),
          ),
        ]);
      },
    );
  }

  Widget _txnTile(ProjectTransaction txn) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), side: BorderSide(color: AppColors.divider)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: txn.type.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(txn.type.icon, color: txn.type.color, size: 20),
        ),
        title: Text(txn.concepto, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(children: [
          Text(txn.type.label, style: TextStyle(fontSize: 11, color: txn.type.color)),
          const SizedBox(width: 8),
          Text(_df.format(txn.fechaTransaccion), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
        trailing: Text(
          '${txn.esIngreso ? '+' : '-'}${_nf.format(txn.monto)}',
          style: TextStyle(fontWeight: FontWeight.w700, color: txn.esIngreso ? AppColors.success : AppColors.error),
        ),
      ),
    );
  }

  void _showAddTransactionDialog(String projectId) {
    final montoCtrl = TextEditingController();
    final conceptoCtrl = TextEditingController();
    TransactionType selectedType = TransactionType.ingreso;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Transacción'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<TransactionType>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: TransactionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setDialogState(() => selectedType = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: montoCtrl, decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: conceptoCtrl, decoration: const InputDecoration(labelText: 'Concepto')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final monto = double.tryParse(montoCtrl.text) ?? 0;
                if (monto <= 0 || conceptoCtrl.text.trim().isEmpty) return;
                await ProjectTransactionService.instance.createTransaction(ProjectTransaction(
                  id: '', projectId: projectId, folio: '',
                  type: selectedType, status: TransactionStatus.completada,
                  monto: monto, concepto: conceptoCtrl.text.trim(),
                  fechaTransaccion: DateTime.now(),
                  createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: '',
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB: HISTORIAL
  // ═══════════════════════════════════════════════════════════

  Widget _buildHistorialTab(Project project) {
    return StreamBuilder<List<ProjectAuditLog>>(
      stream: ProjectService.instance.streamAuditLogs(projectId: project.id),
      builder: (ctx, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) return Center(child: Text('Sin actividad registrada', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)));
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: logs.length,
          itemBuilder: (ctx, i) {
            final log = logs[i];
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: log.actionColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(log.actionIcon, size: 16, color: log.actionColor)),
                if (i < logs.length - 1) Container(width: 2, height: 30, color: AppColors.divider),
              ]),
              const SizedBox(width: AppDimensions.md),
              Expanded(child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(log.actionDescription, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                  if (log.details != null) Text(log.details!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                  Text('${log.userDisplayName} — ${_df.format(log.timestamp)}', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                ]),
              )),
            ]);
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════

  Future<void> _handleAction(String action, Project project) async {
    if (action == 'edit') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectFormPage(project: project)));
    } else if (action == 'report') {
      final bytes = await ProjectReportService.instance.generateReport(ProjectReportType.fichaProyecto, projectId: project.id);
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } else if (action == 'clone') {
      await ProjectService.instance.cloneProject(project.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proyecto duplicado'), backgroundColor: AppColors.success));
    } else if (action.startsWith('status_')) {
      final statusValue = action.replaceFirst('status_', '');
      final newStatus = ProjectStatusX.from(statusValue);
      await ProjectService.instance.changeStatus(project.id, newStatus);
    }
  }
}
