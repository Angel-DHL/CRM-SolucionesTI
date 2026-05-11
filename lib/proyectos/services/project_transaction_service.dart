// lib/proyectos/services/project_transaction_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firebase_helper.dart';
import '../models/project_transaction.dart';
import '../models/project_enums.dart';
import 'project_service.dart';

/// Resumen financiero de un proyecto
class TransactionSummary {
  final double totalIngresos;
  final double totalEgresos;
  final double totalAdelantos;
  final double rentabilidad;
  final double saldoPendiente;
  final int totalTransacciones;
  final int pendientes;
  final double gastosMaterial;
  final double gastosManoObra;
  final double gastosOperativos;

  const TransactionSummary({
    this.totalIngresos = 0,
    this.totalEgresos = 0,
    this.totalAdelantos = 0,
    this.rentabilidad = 0,
    this.saldoPendiente = 0,
    this.totalTransacciones = 0,
    this.pendientes = 0,
    this.gastosMaterial = 0,
    this.gastosManoObra = 0,
    this.gastosOperativos = 0,
  });
}

class ProjectTransactionService {
  ProjectTransactionService._();
  static final ProjectTransactionService instance = ProjectTransactionService._();

  final _projectService = ProjectService.instance;
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _txnCol(String projectId) =>
      FirebaseHelper.db.collection('projects').doc(projectId).collection('project_transactions');

  CollectionReference<Map<String, dynamic>> get _counterCol =>
      FirebaseHelper.db.collection('project_counters');

  // ═══════════════════════════════════════════════════════════
  // GENERACIÓN DE FOLIO
  // ═══════════════════════════════════════════════════════════

  Future<String> _generateFolio() async {
    final counterRef = _counterCol.doc('transaction_counter');
    return FirebaseHelper.db.runTransaction<String>((tx) async {
      final snap = await tx.get(counterRef);
      int current = (snap.data()?['current'] ?? 0) as int;
      current++;
      tx.set(counterRef, {'current': current}, SetOptions(merge: true));
      return 'TRX-${current.toString().padLeft(6, '0')}';
    });
  }

  // ═══════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════

  Future<String> createTransaction(ProjectTransaction transaction) async {
    final folio = await _generateFolio();
    final docRef = _txnCol(transaction.projectId).doc();

    final data = transaction.copyWith(
      id: docRef.id,
      folio: folio,
      createdBy: _currentUser?.uid ?? '',
      createdByName: _currentUser?.email?.split('@')[0],
    ).toMap();

    await docRef.set(data);

    // Recalcular financieros del proyecto
    await _projectService.recalculateFinancials(transaction.projectId);

    // Auditoría
    await _logTxnAudit(
      action: transaction.type.isIncome ? 'payment' : 'expense',
      projectId: transaction.projectId,
      details: '${transaction.type.label}: \$${transaction.monto.toStringAsFixed(2)} - ${transaction.concepto}',
    );

    return docRef.id;
  }

  Future<void> updateTransaction(ProjectTransaction transaction) async {
    await _txnCol(transaction.projectId).doc(transaction.id).update(
      transaction.copyWith(lastModifiedBy: _currentUser?.uid).toUpdateMap(),
    );
    await _projectService.recalculateFinancials(transaction.projectId);
  }

  Future<void> deleteTransaction(String projectId, String transactionId) async {
    await _txnCol(projectId).doc(transactionId).delete();
    await _projectService.recalculateFinancials(projectId);
  }

  // ═══════════════════════════════════════════════════════════
  // OPERACIONES RÁPIDAS
  // ═══════════════════════════════════════════════════════════

  /// Registrar adelanto
  Future<String> registerAdvance(String projectId, {
    required double monto,
    required String concepto,
    PaymentMethodProject? metodoPago,
    String? referencia,
    String? notas,
  }) async {
    return createTransaction(ProjectTransaction(
      id: '', projectId: projectId, folio: '',
      type: TransactionType.adelanto,
      status: TransactionStatus.completada,
      monto: monto, concepto: concepto,
      metodoPago: metodoPago,
      referencia: referencia, notas: notas,
      fechaTransaccion: DateTime.now(),
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
      createdBy: _currentUser?.uid ?? '',
    ));
  }

  /// Registrar pago parcial
  Future<String> registerPartialPayment(String projectId, {
    required double monto,
    required String concepto,
    PaymentMethodProject? metodoPago,
    String? referencia,
  }) async {
    return createTransaction(ProjectTransaction(
      id: '', projectId: projectId, folio: '',
      type: TransactionType.pagoParcial,
      status: TransactionStatus.completada,
      monto: monto, concepto: concepto,
      metodoPago: metodoPago, referencia: referencia,
      fechaTransaccion: DateTime.now(),
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
      createdBy: _currentUser?.uid ?? '',
    ));
  }

  /// Registrar gasto
  Future<String> registerExpense(String projectId, {
    required double monto,
    required String concepto,
    required TransactionType expenseType,
    String? inventoryItemId,
    String? inventoryItemName,
    String? notas,
  }) async {
    return createTransaction(ProjectTransaction(
      id: '', projectId: projectId, folio: '',
      type: expenseType,
      status: TransactionStatus.completada,
      monto: monto, concepto: concepto,
      inventoryItemId: inventoryItemId,
      inventoryItemName: inventoryItemName,
      notas: notas,
      fechaTransaccion: DateTime.now(),
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
      createdBy: _currentUser?.uid ?? '',
    ));
  }

  /// Aprobar transacción
  Future<void> approveTransaction(String projectId, String transactionId) async {
    await _txnCol(projectId).doc(transactionId).update({
      'status': TransactionStatus.aprobada.value,
      'aprobadoPor': _currentUser?.uid,
      'aprobadoPorNombre': _currentUser?.email?.split('@')[0],
      'fechaAprobacion': Timestamp.fromDate(DateTime.now()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _projectService.recalculateFinancials(projectId);
  }

  /// Rechazar transacción
  Future<void> rejectTransaction(String projectId, String transactionId, String motivo) async {
    await _txnCol(projectId).doc(transactionId).update({
      'status': TransactionStatus.rechazada.value,
      'motivoRechazo': motivo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _projectService.recalculateFinancials(projectId);
  }

  // ═══════════════════════════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════════════════════════

  Stream<List<ProjectTransaction>> streamTransactions(String projectId, {TransactionType? type}) {
    Query<Map<String, dynamic>> query = _txnCol(projectId)
        .orderBy('fechaTransaccion', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type.value);
    }

    return query.snapshots().map(
      (snap) => snap.docs.map((d) => ProjectTransaction.fromDoc(d, projectId)).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RESUMEN FINANCIERO
  // ═══════════════════════════════════════════════════════════

  Future<TransactionSummary> getTransactionSummary(String projectId) async {
    final snap = await _txnCol(projectId).get();
    final project = await _projectService.getProjectById(projectId);
    final txns = snap.docs.map((d) => ProjectTransaction.fromDoc(d, projectId)).toList();

    final confirmed = txns.where((t) => t.estaConfirmada).toList();

    double ingresos = confirmed.where((t) => t.esIngreso).fold(0, (s, t) => s + t.monto);
    double egresos = confirmed.where((t) => t.esEgreso).fold(0, (s, t) => s + t.monto);
    double adelantos = confirmed.where((t) => t.type == TransactionType.adelanto).fold(0, (s, t) => s + t.monto);

    return TransactionSummary(
      totalIngresos: ingresos,
      totalEgresos: egresos,
      totalAdelantos: adelantos,
      rentabilidad: ingresos - egresos,
      saldoPendiente: (project?.valorProyecto ?? 0) - ingresos,
      totalTransacciones: txns.length,
      pendientes: txns.where((t) => t.status == TransactionStatus.pendiente).length,
      gastosMaterial: confirmed.where((t) => t.type == TransactionType.gastoMaterial).fold(0, (s, t) => s + t.monto),
      gastosManoObra: confirmed.where((t) => t.type == TransactionType.gastoManoObra).fold(0, (s, t) => s + t.monto),
      gastosOperativos: confirmed.where((t) => t.type == TransactionType.gastoOperativo).fold(0, (s, t) => s + t.monto),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════

  Future<void> _logTxnAudit({
    required String action,
    required String projectId,
    String? details,
  }) async {
    try {
      await FirebaseHelper.db.collection('project_audit_logs').add({
        'module': 'transactions',
        'action': action,
        'projectId': projectId,
        'details': details,
        'userId': _currentUser?.uid,
        'userEmail': _currentUser?.email,
        'userName': _currentUser?.email?.split('@')[0],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
