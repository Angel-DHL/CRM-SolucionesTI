// lib/home/services/dashboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/firebase_helper.dart';

/// Datos agregados del dashboard ejecutivo
class DashboardKPIs {
  final int activeActivities;
  final int overdueActivities;
  final int activeProjects;
  final int openQuotes;
  final double monthlySales;
  final int newLeads;
  final int openCases;
  final int inventoryCount;
  final int activeCampaigns;

  const DashboardKPIs({
    this.activeActivities = 0,
    this.overdueActivities = 0,
    this.activeProjects = 0,
    this.openQuotes = 0,
    this.monthlySales = 0,
    this.newLeads = 0,
    this.openCases = 0,
    this.inventoryCount = 0,
    this.activeCampaigns = 0,
  });

  Map<String, dynamic> toMap() => {
    'activeActivities': activeActivities,
    'overdueActivities': overdueActivities,
    'activeProjects': activeProjects,
    'openQuotes': openQuotes,
    'monthlySales': monthlySales,
    'newLeads': newLeads,
    'openCases': openCases,
    'inventoryCount': inventoryCount,
    'activeCampaigns': activeCampaigns,
  };
}

class ChartDataPoint {
  final String label;
  final double value;
  final String? color;

  const ChartDataPoint({required this.label, required this.value, this.color});
}

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  // Cache
  DashboardKPIs? _cachedKPIs;
  DateTime? _lastFetch;

  /// Carga todos los KPIs del dashboard
  Future<DashboardKPIs> loadKPIs({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedKPIs != null && _lastFetch != null) {
      final elapsed = DateTime.now().difference(_lastFetch!);
      if (elapsed.inMinutes < 2) return _cachedKPIs!;
    }

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthStartTs = Timestamp.fromDate(monthStart);

      // Ejecutar todas las queries en paralelo
      final results = await Future.wait([
        _countActiveActivities(),          // 0
        _countOverdueActivities(),         // 1
        _countActiveProjects(),            // 2
        _countOpenQuotes(),                // 3
        _calcMonthlySales(monthStartTs),   // 4
        _countNewLeads(monthStartTs),      // 5
        _countOpenCases(),                 // 6
        _countInventory(),                 // 7
        _countActiveCampaigns(),           // 8
      ]);

      _cachedKPIs = DashboardKPIs(
        activeActivities: results[0] as int,
        overdueActivities: results[1] as int,
        activeProjects: results[2] as int,
        openQuotes: results[3] as int,
        monthlySales: results[4] as double,
        newLeads: results[5] as int,
        openCases: results[6] as int,
        inventoryCount: results[7] as int,
        activeCampaigns: results[8] as int,
      );
      _lastFetch = DateTime.now();
      return _cachedKPIs!;
    } catch (e) {
      debugPrint('Error loading KPIs: $e');
      return _cachedKPIs ?? const DashboardKPIs();
    }
  }

  // ─── Queries individuales ──────────────────────────────────

  Future<int> _countActiveActivities() async {
    try {
      final snap = await FirebaseHelper.operActivities.get();
      return snap.docs.where((d) {
        final s = d.data()['status']?.toString() ?? '';
        return s != 'done' && s != 'verified';
      }).length;
    } catch (_) { return 0; }
  }

  Future<int> _countOverdueActivities() async {
    try {
      final snap = await FirebaseHelper.operActivities.get();
      final now = DateTime.now();
      return snap.docs.where((d) {
        final s = d.data()['status']?.toString() ?? '';
        if (s == 'done' || s == 'verified') return false;
        final pe = d.data()['plannedEndAt'];
        if (pe is Timestamp) return pe.toDate().isBefore(now);
        return false;
      }).length;
    } catch (_) { return 0; }
  }

  Future<int> _countActiveProjects() async {
    try {
      final snap = await FirebaseHelper.projects
          .where('status', isEqualTo: 'active')
          .count().get();
      return snap.count ?? 0;
    } catch (_) { return 0; }
  }

  Future<int> _countOpenQuotes() async {
    try {
      final snap = await FirebaseHelper.db.collection('sales_quotes')
          .where('status', whereIn: ['draft', 'sent', 'borrador', 'enviada'])
          .count().get();
      return snap.count ?? 0;
    } catch (_) { return 0; }
  }

  Future<double> _calcMonthlySales(Timestamp monthStart) async {
    try {
      // Sumar transacciones de tipo ingreso de proyectos este mes
      final projSnap = await FirebaseHelper.projects.get();
      double total = 0;
      for (final proj in projSnap.docs) {
        final txSnap = await FirebaseHelper.projects
            .doc(proj.id)
            .collection('project_transactions')
            .where('type', isEqualTo: 'ingreso')
            .where('date', isGreaterThanOrEqualTo: monthStart)
            .get();
        for (final tx in txSnap.docs) {
          total += (tx.data()['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      // También sumar órdenes de venta del mes
      try {
        final ordersSnap = await FirebaseHelper.db.collection('sales_orders')
            .where('createdAt', isGreaterThanOrEqualTo: monthStart)
            .get();
        for (final order in ordersSnap.docs) {
          total += (order.data()['total'] as num?)?.toDouble() ?? 0;
        }
      } catch (_) {}
      return total;
    } catch (_) { return 0; }
  }

  Future<int> _countNewLeads(Timestamp monthStart) async {
    try {
      final snap = await FirebaseHelper.leads
          .where('createdAt', isGreaterThanOrEqualTo: monthStart)
          .count().get();
      return snap.count ?? 0;
    } catch (_) {
      // Fallback: count all
      try {
        final snap = await FirebaseHelper.leads.count().get();
        return snap.count ?? 0;
      } catch (_) { return 0; }
    }
  }

  Future<int> _countOpenCases() async {
    try {
      final snap = await FirebaseHelper.supportCases.get();
      return snap.docs.where((d) {
        final s = d.data()['status']?.toString() ?? '';
        return s != 'resuelto' && s != 'cerrado';
      }).length;
    } catch (_) { return 0; }
  }

  Future<int> _countInventory() async {
    try {
      final snap = await FirebaseHelper.inventoryItems.count().get();
      return snap.count ?? 0;
    } catch (_) { return 0; }
  }

  Future<int> _countActiveCampaigns() async {
    try {
      final snap = await FirebaseHelper.db.collection('marketing_campaigns')
          .where('status', isEqualTo: 'active')
          .count().get();
      return snap.count ?? 0;
    } catch (_) { return 0; }
  }

  // ─── Datos para gráficas ──────────────────────────────────

  /// Distribución de actividades por estado
  Future<List<ChartDataPoint>> getOperatividadChart() async {
    try {
      final snap = await FirebaseHelper.operActivities.get();
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final status = doc.data()['status']?.toString() ?? 'planned';
        counts[status] = (counts[status] ?? 0) + 1;
      }
      final labels = {
        'planned': 'Planeada',
        'in_progress': 'En progreso',
        'done': 'Realizada',
        'verified': 'Verificada',
        'blocked': 'Bloqueada',
      };
      return counts.entries.map((e) => ChartDataPoint(
        label: labels[e.key] ?? e.key,
        value: e.value.toDouble(),
      )).toList();
    } catch (_) { return []; }
  }

  /// Pipeline de ventas (oportunidades por etapa)
  Future<List<ChartDataPoint>> getSalesPipelineChart() async {
    try {
      final snap = await FirebaseHelper.db.collection('sales_opportunities').get();
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final stage = doc.data()['stage']?.toString() ?? 'prospecto';
        counts[stage] = (counts[stage] ?? 0) + 1;
      }
      final order = ['prospecto', 'calificado', 'propuesta', 'negociacion', 'cerrado_ganado', 'cerrado_perdido'];
      final labels = {
        'prospecto': 'Prospecto',
        'calificado': 'Calificado',
        'propuesta': 'Propuesta',
        'negociacion': 'Negociación',
        'cerrado_ganado': 'Ganado',
        'cerrado_perdido': 'Perdido',
      };
      return order
          .where((s) => counts.containsKey(s))
          .map((s) => ChartDataPoint(label: labels[s] ?? s, value: (counts[s] ?? 0).toDouble()))
          .toList();
    } catch (_) { return []; }
  }

  /// Casos de soporte por categoría
  Future<List<ChartDataPoint>> getSupportChart() async {
    try {
      final snap = await FirebaseHelper.supportCases.get();
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final cat = doc.data()['categoria']?.toString() ?? 'otro';
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
      return counts.entries.map((e) => ChartDataPoint(
        label: e.key, value: e.value.toDouble(),
      )).toList();
    } catch (_) { return []; }
  }

  /// Ventas mensuales (últimos 6 meses)
  Future<List<ChartDataPoint>> getMonthlySalesChart() async {
    try {
      final now = DateTime.now();
      final points = <ChartDataPoint>[];
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(date.year, date.month + 1, 1);
        final start = Timestamp.fromDate(date);
        final end = Timestamp.fromDate(nextMonth);

        double total = 0;
        // Órdenes de venta
        try {
          final ordersSnap = await FirebaseHelper.db.collection('sales_orders')
              .where('createdAt', isGreaterThanOrEqualTo: start)
              .where('createdAt', isLessThan: end)
              .get();
          for (final o in ordersSnap.docs) {
            total += (o.data()['total'] as num?)?.toDouble() ?? 0;
          }
        } catch (_) {}

        // Ingresos de proyectos
        try {
          final projSnap = await FirebaseHelper.projects.get();
          for (final proj in projSnap.docs) {
            final txSnap = await FirebaseHelper.projects
                .doc(proj.id)
                .collection('project_transactions')
                .where('type', isEqualTo: 'ingreso')
                .where('date', isGreaterThanOrEqualTo: start)
                .where('date', isLessThan: end)
                .get();
            for (final tx in txSnap.docs) {
              total += (tx.data()['amount'] as num?)?.toDouble() ?? 0;
            }
          }
        } catch (_) {}

        points.add(ChartDataPoint(
          label: months[date.month - 1],
          value: total,
        ));
      }
      return points;
    } catch (_) { return []; }
  }

  /// Actividades vencidas (top 5)
  Future<List<Map<String, dynamic>>> getOverdueActivities() async {
    try {
      final snap = await FirebaseHelper.operActivities.get();
      final now = DateTime.now();
      final overdue = snap.docs.where((d) {
        final s = d.data()['status']?.toString() ?? '';
        if (s == 'done' || s == 'verified') return false;
        final pe = d.data()['plannedEndAt'];
        if (pe is Timestamp) return pe.toDate().isBefore(now);
        return false;
      }).take(5).map((d) => {
        'id': d.id,
        'title': d.data()['title'] ?? '',
        'daysOverdue': now.difference((d.data()['plannedEndAt'] as Timestamp).toDate()).inDays,
        'status': d.data()['status'] ?? '',
      }).toList();
      return overdue;
    } catch (_) { return []; }
  }

  /// Últimas cotizaciones
  Future<List<Map<String, dynamic>>> getRecentQuotes() async {
    try {
      final snap = await FirebaseHelper.db.collection('sales_quotes')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      return snap.docs.map((d) => {
        'id': d.id,
        'folio': d.data()['folio'] ?? '',
        'clientName': d.data()['clientName'] ?? d.data()['contactName'] ?? '',
        'total': (d.data()['total'] as num?)?.toDouble() ?? 0,
        'status': d.data()['status'] ?? '',
      }).toList();
    } catch (_) { return []; }
  }

  /// Casos de soporte urgentes
  Future<List<Map<String, dynamic>>> getUrgentCases() async {
    try {
      final snap = await FirebaseHelper.supportCases
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      return snap.docs.where((d) {
        final s = d.data()['status']?.toString() ?? '';
        return s != 'resuelto' && s != 'cerrado';
      }).take(5).map((d) => {
        'id': d.id,
        'folio': d.data()['folio'] ?? '',
        'titulo': d.data()['titulo'] ?? '',
        'prioridad': d.data()['prioridad'] ?? 'media',
        'status': d.data()['status'] ?? '',
      }).toList();
    } catch (_) { return []; }
  }
}
