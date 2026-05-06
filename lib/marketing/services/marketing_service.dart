// lib/marketing/services/marketing_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/firebase_helper.dart';
import '../models/marketing_campaign.dart';
import '../models/campaign_audience.dart';
import '../models/social_metrics.dart';
import '../models/marketing_enums.dart';

class MarketingService {
  MarketingService._();
  static final MarketingService instance = MarketingService._();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ═══════════════════════════════════════════════════════════
  // FOLIOS
  // ═══════════════════════════════════════════════════════════

  Future<String> _nextFolio(String prefix) async {
    try {
      final ref = FirebaseHelper.marketingCounters.doc(prefix);
      final result = await FirebaseHelper.db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        int current = 0;
        if (snap.exists) {
          current = (snap.data()?['current'] ?? 0) as int;
        }
        final next = current + 1;
        tx.set(ref, {'current': next}, SetOptions(merge: true));
        return next;
      });
      return '$prefix-${result.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('Error generating folio: $e');
      final ts = DateTime.now().millisecondsSinceEpoch % 100000;
      return '$prefix-$ts';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CAMPAÑAS — CRUD
  // ═══════════════════════════════════════════════════════════

  Stream<List<MarketingCampaign>> streamCampaigns({CampaignStatus? status}) {
    Query<Map<String, dynamic>> q = FirebaseHelper.marketingCampaigns
        .orderBy('createdAt', descending: true);
    if (status != null) {
      q = q.where('status', isEqualTo: status.value);
    }
    return q.snapshots().map((snap) =>
        snap.docs.map(MarketingCampaign.fromDoc).toList());
  }

  Stream<MarketingCampaign?> streamCampaign(String id) {
    return FirebaseHelper.marketingCampaigns.doc(id).snapshots().map(
      (snap) => snap.exists ? MarketingCampaign.fromDoc(snap) : null,
    );
  }

  Future<String> createCampaign(Map<String, dynamic> data) async {
    final folio = await _nextFolio('MKT');
    final now = DateTime.now();
    data.addAll({
      'folio': folio,
      'status': CampaignStatus.borrador.value,
      'leadsGenerados': 0,
      'conversionesLogradas': 0,
      'alcanceReal': 0,
      'engagementReal': 0,
      'gastoReal': 0,
      'contactoIds': [],
      'opportunityIds': [],
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': _uid,
    });
    final ref = await FirebaseHelper.marketingCampaigns.add(data);
    return ref.id;
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await FirebaseHelper.marketingCampaigns.doc(id).update(data);
  }

  Future<void> deleteCampaign(String id) async {
    await FirebaseHelper.marketingCampaigns.doc(id).delete();
  }

  Future<void> updateCampaignStatus(String id, CampaignStatus status) async {
    await updateCampaign(id, {'status': status.value});
  }

  Future<void> updateCampaignResults(String id, {
    int? leads,
    int? conversiones,
    int? alcance,
    double? engagement,
    double? gasto,
  }) async {
    final data = <String, dynamic>{};
    if (leads != null) data['leadsGenerados'] = leads;
    if (conversiones != null) data['conversionesLogradas'] = conversiones;
    if (alcance != null) data['alcanceReal'] = alcance;
    if (engagement != null) data['engagementReal'] = engagement;
    if (gasto != null) data['gastoReal'] = gasto;
    if (data.isNotEmpty) await updateCampaign(id, data);
  }

  // ═══════════════════════════════════════════════════════════
  // AUDIENCIAS — CRUD
  // ═══════════════════════════════════════════════════════════

  Stream<List<CampaignAudience>> streamAudiences() {
    return FirebaseHelper.marketingAudiences
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CampaignAudience.fromDoc).toList());
  }

  Future<String> createAudience(Map<String, dynamic> data) async {
    final now = DateTime.now();
    data.addAll({
      'contactoIds': [],
      'campaignIds': [],
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    final ref = await FirebaseHelper.marketingAudiences.add(data);
    return ref.id;
  }

  Future<void> updateAudience(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await FirebaseHelper.marketingAudiences.doc(id).update(data);
  }

  Future<void> deleteAudience(String id) async {
    await FirebaseHelper.marketingAudiences.doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTRICAS SOCIALES — CRUD & QUERIES
  // ═══════════════════════════════════════════════════════════

  Stream<List<SocialMetrics>> streamMetrics({
    SocialPlatform? platform,
    MetricPeriod? period,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> q = FirebaseHelper.marketingSocialMetrics
        .orderBy('fecha', descending: true)
        .limit(limit);
    if (platform != null) {
      q = q.where('plataforma', isEqualTo: platform.value);
    }
    if (period != null) {
      q = q.where('periodo', isEqualTo: period.value);
    }
    return q.snapshots().map(
      (snap) => snap.docs.map(SocialMetrics.fromDoc).toList(),
    );
  }

  Future<void> addMetric(SocialMetrics metric) async {
    await FirebaseHelper.marketingSocialMetrics.add(metric.toMap());
  }

  Future<void> deleteMetric(String id) async {
    await FirebaseHelper.marketingSocialMetrics.doc(id).delete();
  }

  /// Obtener la última métrica de cada plataforma
  Future<Map<SocialPlatform, SocialMetrics>> getLatestMetricsPerPlatform() async {
    final result = <SocialPlatform, SocialMetrics>{};
    for (final platform in SocialPlatform.values) {
      final snap = await FirebaseHelper.marketingSocialMetrics
          .where('plataforma', isEqualTo: platform.value)
          .orderBy('fecha', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        result[platform] = SocialMetrics.fromDoc(snap.docs.first);
      }
    }
    return result;
  }

  /// Historial de una métrica para gráficos
  Future<List<SocialMetrics>> getMetricsHistory(
    SocialPlatform platform, {
    int months = 6,
  }) async {
    final since = DateTime.now().subtract(Duration(days: months * 30));
    final snap = await FirebaseHelper.marketingSocialMetrics
        .where('plataforma', isEqualTo: platform.value)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('fecha')
        .get();
    return snap.docs.map(SocialMetrics.fromDoc).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // YOUTUBE API (via Cloud Function)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> syncYouTubeMetrics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken();

      final uri = Uri.parse(
        'https://us-central1-crm-solucionesti.cloudfunctions.net/fetchYouTubeMetrics',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': 'sync'}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('YouTube sync error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('YouTube sync error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Campañas activas
    final activeCampaigns = await FirebaseHelper.marketingCampaigns
        .where('status', isEqualTo: CampaignStatus.activa.value)
        .get();

    // Total presupuesto y gasto
    double totalPresupuesto = 0;
    double totalGasto = 0;
    int totalLeads = 0;
    int totalConversiones = 0;
    int totalAlcance = 0;

    final allCampaigns = await FirebaseHelper.marketingCampaigns.get();
    for (final doc in allCampaigns.docs) {
      final d = doc.data();
      totalPresupuesto += (d['presupuesto'] ?? 0).toDouble();
      totalGasto += (d['gastoReal'] ?? 0).toDouble();
      totalLeads += (d['leadsGenerados'] ?? 0) as int;
      totalConversiones += (d['conversionesLogradas'] ?? 0) as int;
      totalAlcance += (d['alcanceReal'] ?? 0) as int;
    }

    // Leads este mes (solo campañas creadas este mes)
    final monthCampaigns = await FirebaseHelper.marketingCampaigns
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .get();
    int leadsEsteMes = 0;
    for (final doc in monthCampaigns.docs) {
      leadsEsteMes += (doc.data()['leadsGenerados'] ?? 0) as int;
    }

    // Seguidores totales (suma de última métrica de cada plataforma)
    final latestMetrics = await getLatestMetricsPerPlatform();
    int seguidoresTotales = 0;
    int nuevosSeguidoresSemana = 0;
    for (final m in latestMetrics.values) {
      seguidoresTotales += m.seguidores + m.suscriptores;
      nuevosSeguidoresSemana += m.nuevosSeguidores;
    }

    // ROI promedio
    double roiPromedio = 0;
    int campaignsConGasto = 0;
    for (final doc in allCampaigns.docs) {
      final gasto = (doc.data()['gastoReal'] ?? 0).toDouble();
      if (gasto > 0) {
        final conv = (doc.data()['conversionesLogradas'] ?? 0) as int;
        roiPromedio += ((conv * 1000) - gasto) / gasto * 100;
        campaignsConGasto++;
      }
    }
    if (campaignsConGasto > 0) roiPromedio /= campaignsConGasto;

    // Costo por lead
    double costoPorLead = totalLeads > 0 ? totalGasto / totalLeads : 0;

    return {
      'campanasActivas': activeCampaigns.docs.length,
      'totalPresupuesto': totalPresupuesto,
      'totalGasto': totalGasto,
      'totalLeads': totalLeads,
      'leadsEsteMes': leadsEsteMes,
      'totalConversiones': totalConversiones,
      'totalAlcance': totalAlcance,
      'seguidoresTotales': seguidoresTotales,
      'nuevosSeguidoresSemana': nuevosSeguidoresSemana,
      'roiPromedio': roiPromedio,
      'costoPorLead': costoPorLead,
      'tasaConversion': totalLeads > 0 ? (totalConversiones / totalLeads * 100) : 0.0,
      'latestMetrics': latestMetrics,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // ANALÍTICA — Leads por canal
  // ═══════════════════════════════════════════════════════════

  Future<Map<CampaignChannel, int>> getLeadsByChannel() async {
    final result = <CampaignChannel, int>{};
    final snap = await FirebaseHelper.marketingCampaigns.get();
    for (final doc in snap.docs) {
      final d = doc.data();
      final leads = (d['leadsGenerados'] ?? 0) as int;
      final canales = (d['canales'] as List<dynamic>?) ?? [];
      for (final canal in canales) {
        final ch = CampaignChannelX.from(canal);
        result[ch] = (result[ch] ?? 0) + leads;
      }
    }
    return result;
  }

  /// Top campañas por ROI
  Future<List<MarketingCampaign>> getTopCampaigns({int limit = 5}) async {
    final snap = await FirebaseHelper.marketingCampaigns
        .where('gastoReal', isGreaterThan: 0)
        .get();
    final campaigns = snap.docs.map(MarketingCampaign.fromDoc).toList();
    campaigns.sort((a, b) => b.roi.compareTo(a.roi));
    return campaigns.take(limit).toList();
  }
}
