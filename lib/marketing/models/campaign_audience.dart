// lib/marketing/models/campaign_audience.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'marketing_enums.dart';

class CampaignAudience {
  final String id;
  final String nombre;
  final String? descripcion;
  final AudienceSegment segmento;

  /// Criterios de filtro flexibles
  final Map<String, dynamic> criterios;

  /// Tamaño estimado del público
  final int tamanioEstimado;

  /// IDs de contactos reales del CRM que coinciden
  final List<String> contactoIds;

  /// IDs de campañas vinculadas
  final List<String> campaignIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  CampaignAudience({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.segmento,
    this.criterios = const {},
    this.tamanioEstimado = 0,
    this.contactoIds = const [],
    this.campaignIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get contactosReales => contactoIds.length;

  factory CampaignAudience.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return CampaignAudience(
      id: doc.id,
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'],
      segmento: AudienceSegmentX.from(m['segmento']),
      criterios: Map<String, dynamic>.from(m['criterios'] ?? {}),
      tamanioEstimado: m['tamanioEstimado'] ?? 0,
      contactoIds: List<String>.from(m['contactoIds'] ?? []),
      campaignIds: List<String>.from(m['campaignIds'] ?? []),
      createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: m['updatedAt'] is Timestamp ? (m['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'segmento': segmento.value,
    'criterios': criterios,
    'tamanioEstimado': tamanioEstimado,
    'contactoIds': contactoIds,
    'campaignIds': campaignIds,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
