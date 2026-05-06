// lib/marketing/models/marketing_campaign.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'marketing_enums.dart';

class MarketingCampaign {
  final String id;
  final String folio;
  final String nombre;
  final String? descripcion;
  final CampaignStatus status;
  final CampaignType tipo;
  final List<CampaignChannel> canales;
  final List<String> tags;

  // Presupuesto
  final double presupuesto;
  final double gastoReal;
  final String moneda;

  // Fechas
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  // Objetivos
  final int objetivoLeads;
  final int objetivoConversiones;
  final int objetivoAlcance;
  final double objetivoEngagement;

  // Resultados
  final int leadsGenerados;
  final int conversionesLogradas;
  final int alcanceReal;
  final double engagementReal;

  // Vinculaciones
  final List<String> audienciaIds;
  final List<String> contactoIds;
  final List<String> opportunityIds;

  // Notas
  final String? notas;
  final String? notasInternas;

  // Auditoría
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  MarketingCampaign({
    required this.id,
    required this.folio,
    required this.nombre,
    this.descripcion,
    required this.status,
    required this.tipo,
    this.canales = const [],
    this.tags = const [],
    this.presupuesto = 0,
    this.gastoReal = 0,
    this.moneda = 'MXN',
    required this.fechaInicio,
    this.fechaFin,
    this.objetivoLeads = 0,
    this.objetivoConversiones = 0,
    this.objetivoAlcance = 0,
    this.objetivoEngagement = 0,
    this.leadsGenerados = 0,
    this.conversionesLogradas = 0,
    this.alcanceReal = 0,
    this.engagementReal = 0,
    this.audienciaIds = const [],
    this.contactoIds = const [],
    this.opportunityIds = const [],
    this.notas,
    this.notasInternas,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
  });

  // ═══════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════

  /// ROI = (Ingresos estimados - Gasto) / Gasto * 100
  double get roi {
    if (gastoReal <= 0) return 0;
    // Estimamos ingresos como conversiones * ticket promedio (configurable)
    return ((conversionesLogradas * 1000) - gastoReal) / gastoReal * 100;
  }

  /// Costo por lead
  double get costoPorLead {
    if (leadsGenerados <= 0) return 0;
    return gastoReal / leadsGenerados;
  }

  /// Tasa de conversión (leads → conversiones)
  double get tasaConversion {
    if (leadsGenerados <= 0) return 0;
    return (conversionesLogradas / leadsGenerados) * 100;
  }

  /// Progreso del presupuesto gastado
  double get progresoPpresupuesto {
    if (presupuesto <= 0) return 0;
    return (gastoReal / presupuesto * 100).clamp(0, 200);
  }

  /// Progreso de leads vs objetivo
  double get progresoLeads {
    if (objetivoLeads <= 0) return 0;
    return (leadsGenerados / objetivoLeads * 100).clamp(0, 200);
  }

  /// Días restantes
  int get diasRestantes {
    if (fechaFin == null) return -1;
    return fechaFin!.difference(DateTime.now()).inDays;
  }

  /// ¿Está activa?
  bool get isActiva => status == CampaignStatus.activa;

  /// ¿Superó presupuesto?
  bool get superoPpresupuesto => gastoReal > presupuesto && presupuesto > 0;

  /// ¿ROI negativo?
  bool get roiNegativo => roi < 0 && gastoReal > 0;

  // ═══════════════════════════════════════════════════════════
  // SERIALIZACIÓN
  // ═══════════════════════════════════════════════════════════

  factory MarketingCampaign.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return MarketingCampaign(
      id: doc.id,
      folio: m['folio'] ?? '',
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'],
      status: CampaignStatusX.from(m['status']),
      tipo: CampaignTypeX.from(m['tipo']),
      canales: (m['canales'] as List<dynamic>?)?.map((c) => CampaignChannelX.from(c)).toList() ?? [],
      tags: List<String>.from(m['tags'] ?? []),
      presupuesto: (m['presupuesto'] ?? 0).toDouble(),
      gastoReal: (m['gastoReal'] ?? 0).toDouble(),
      moneda: m['moneda'] ?? 'MXN',
      fechaInicio: m['fechaInicio'] is Timestamp
          ? (m['fechaInicio'] as Timestamp).toDate()
          : DateTime.now(),
      fechaFin: m['fechaFin'] is Timestamp
          ? (m['fechaFin'] as Timestamp).toDate()
          : null,
      objetivoLeads: m['objetivoLeads'] ?? 0,
      objetivoConversiones: m['objetivoConversiones'] ?? 0,
      objetivoAlcance: m['objetivoAlcance'] ?? 0,
      objetivoEngagement: (m['objetivoEngagement'] ?? 0).toDouble(),
      leadsGenerados: m['leadsGenerados'] ?? 0,
      conversionesLogradas: m['conversionesLogradas'] ?? 0,
      alcanceReal: m['alcanceReal'] ?? 0,
      engagementReal: (m['engagementReal'] ?? 0).toDouble(),
      audienciaIds: List<String>.from(m['audienciaIds'] ?? []),
      contactoIds: List<String>.from(m['contactoIds'] ?? []),
      opportunityIds: List<String>.from(m['opportunityIds'] ?? []),
      notas: m['notas'],
      notasInternas: m['notasInternas'],
      createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: m['updatedAt'] is Timestamp ? (m['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      createdBy: m['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'folio': folio,
    'nombre': nombre,
    'descripcion': descripcion,
    'status': status.value,
    'tipo': tipo.value,
    'canales': canales.map((c) => c.value).toList(),
    'tags': tags,
    'presupuesto': presupuesto,
    'gastoReal': gastoReal,
    'moneda': moneda,
    'fechaInicio': Timestamp.fromDate(fechaInicio),
    'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
    'objetivoLeads': objetivoLeads,
    'objetivoConversiones': objetivoConversiones,
    'objetivoAlcance': objetivoAlcance,
    'objetivoEngagement': objetivoEngagement,
    'leadsGenerados': leadsGenerados,
    'conversionesLogradas': conversionesLogradas,
    'alcanceReal': alcanceReal,
    'engagementReal': engagementReal,
    'audienciaIds': audienciaIds,
    'contactoIds': contactoIds,
    'opportunityIds': opportunityIds,
    'notas': notas,
    'notasInternas': notasInternas,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'createdBy': createdBy,
  };

  MarketingCampaign copyWith({
    String? nombre,
    String? descripcion,
    CampaignStatus? status,
    CampaignType? tipo,
    List<CampaignChannel>? canales,
    double? presupuesto,
    double? gastoReal,
    DateTime? fechaFin,
    int? leadsGenerados,
    int? conversionesLogradas,
    int? alcanceReal,
    double? engagementReal,
    String? notas,
  }) {
    return MarketingCampaign(
      id: id,
      folio: folio,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      status: status ?? this.status,
      tipo: tipo ?? this.tipo,
      canales: canales ?? this.canales,
      tags: tags,
      presupuesto: presupuesto ?? this.presupuesto,
      gastoReal: gastoReal ?? this.gastoReal,
      moneda: moneda,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      objetivoLeads: objetivoLeads,
      objetivoConversiones: objetivoConversiones,
      objetivoAlcance: objetivoAlcance,
      objetivoEngagement: objetivoEngagement,
      leadsGenerados: leadsGenerados ?? this.leadsGenerados,
      conversionesLogradas: conversionesLogradas ?? this.conversionesLogradas,
      alcanceReal: alcanceReal ?? this.alcanceReal,
      engagementReal: engagementReal ?? this.engagementReal,
      audienciaIds: audienciaIds,
      contactoIds: contactoIds,
      opportunityIds: opportunityIds,
      notas: notas ?? this.notas,
      notasInternas: notasInternas,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
  }
}
