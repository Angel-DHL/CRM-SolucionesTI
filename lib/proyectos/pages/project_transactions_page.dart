// lib/proyectos/pages/project_transactions_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/project.dart';
import '../models/project_transaction.dart';
import '../models/project_enums.dart';
import '../services/project_service.dart';
import '../services/project_transaction_service.dart';

class ProjectTransactionsPage extends StatefulWidget {
  final UserRole role;
  const ProjectTransactionsPage({super.key, required this.role});

  @override
  State<ProjectTransactionsPage> createState() => _ProjectTransactionsPageState();
}

class _ProjectTransactionsPageState extends State<ProjectTransactionsPage> {
  String? _selectedProjectId;
  final _nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  final _df = DateFormat('dd MMM yyyy', 'es_MX');

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildProjectSelector(),
      if (_selectedProjectId != null) _buildSummaryBar(),
      Expanded(
        child: _selectedProjectId == null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.account_balance_wallet_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                const SizedBox(height: AppDimensions.md),
                Text('Selecciona un proyecto', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
              ]))
            : _buildTransactionList(),
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
                onPressed: _showAddTransaction,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Registrar'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    return FutureBuilder<TransactionSummary>(
      future: ProjectTransactionService.instance.getTransactionSummary(_selectedProjectId!),
      builder: (ctx, snap) {
        final s = snap.data ?? const TransactionSummary();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
          color: AppColors.primarySurface,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _summaryChip('Ingresos', _nf.format(s.totalIngresos), AppColors.success),
            _summaryChip('Egresos', _nf.format(s.totalEgresos), AppColors.error),
            _summaryChip('Rentabilidad', _nf.format(s.rentabilidad), s.rentabilidad >= 0 ? AppColors.success : AppColors.error),
            _summaryChip('Pendiente', _nf.format(s.saldoPendiente), AppColors.warning),
          ]),
        );
      },
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ]);
  }

  Widget _buildTransactionList() {
    return StreamBuilder<List<ProjectTransaction>>(
      stream: ProjectTransactionService.instance.streamTransactions(_selectedProjectId!),
      builder: (ctx, snap) {
        final txns = snap.data ?? [];
        if (txns.isEmpty) return Center(child: Text('Sin transacciones', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)));
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: txns.length,
          itemBuilder: (ctx, i) {
            final t = txns[i];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), side: BorderSide(color: AppColors.divider)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: t.type.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(t.type.icon, color: t.type.color, size: 20),
                ),
                title: Text(t.concepto, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Row(children: [
                  Text(t.folio, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(width: 8),
                  Text(t.type.label, style: TextStyle(fontSize: 11, color: t.type.color)),
                  const SizedBox(width: 8),
                  Text(_df.format(t.fechaTransaccion), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ]),
                trailing: Text(
                  '${t.esIngreso ? '+' : '-'}${_nf.format(t.monto)}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: t.esIngreso ? AppColors.success : AppColors.error),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTransaction() {
    final montoCtrl = TextEditingController();
    final conceptoCtrl = TextEditingController();
    TransactionType selectedType = TransactionType.ingreso;
    PaymentMethodProject selectedMethod = PaymentMethodProject.transferencia;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Transacción'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethodProject>(
              value: selectedMethod,
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: PaymentMethodProject.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
              onChanged: (v) => setDialogState(() => selectedMethod = v!),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final monto = double.tryParse(montoCtrl.text) ?? 0;
                if (monto <= 0 || conceptoCtrl.text.trim().isEmpty) return;
                await ProjectTransactionService.instance.createTransaction(ProjectTransaction(
                  id: '', projectId: _selectedProjectId!, folio: '',
                  type: selectedType, status: TransactionStatus.completada,
                  monto: monto, concepto: conceptoCtrl.text.trim(),
                  metodoPago: selectedMethod,
                  fechaTransaccion: DateTime.now(),
                  createdAt: DateTime.now(), updatedAt: DateTime.now(), createdBy: '',
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {}); // Refresh summary
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
