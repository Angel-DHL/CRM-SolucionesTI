// lib/marketing/models/social_metrics.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'marketing_enums.dart';

/// Modelo unificado de métricas para cualquier plataforma
class SocialMetrics {
  final String id;
  final SocialPlatform plataforma;
  final DateTime fecha;
  final MetricPeriod periodo;

  // Métricas comunes
  final int seguidores;
  final int nuevosSeguidores;
  final int publicaciones;
  final int alcance;
  final int impresiones;
  final double engagement; // tasa de engagement %
  final int clics;
  final int compartidos;
  final int comentarios;
  final int likes;

  // Métricas de video (YouTube, TikTok)
  final int vistas;
  final int suscriptores;
  final double duracionPromedio; // en minutos

  // Métricas de sitio web (GA4)
  final int usuarios;
  final int sesiones;
  final double bounceRate;
  final double duracionSesion; // en segundos
  final int conversiones;

  // Mejor contenido del periodo
  final String? mejorContenidoTitulo;
  final String? mejorContenidoUrl;
  final int mejorContenidoMetrica; // la métrica principal (views/likes/etc)

  // Datos extra flexibles (para métricas específicas de cada plataforma)
  final Map<String, dynamic> datosExtra;

  // Fuente de datos: 'api' o 'manual'
  final String fuenteDatos;

  final DateTime createdAt;

  SocialMetrics({
    required this.id,
    required this.plataforma,
    required this.fecha,
    required this.periodo,
    this.seguidores = 0,
    this.nuevosSeguidores = 0,
    this.publicaciones = 0,
    this.alcance = 0,
    this.impresiones = 0,
    this.engagement = 0,
    this.clics = 0,
    this.compartidos = 0,
    this.comentarios = 0,
    this.likes = 0,
    this.vistas = 0,
    this.suscriptores = 0,
    this.duracionPromedio = 0,
    this.usuarios = 0,
    this.sesiones = 0,
    this.bounceRate = 0,
    this.duracionSesion = 0,
    this.conversiones = 0,
    this.mejorContenidoTitulo,
    this.mejorContenidoUrl,
    this.mejorContenidoMetrica = 0,
    this.datosExtra = const {},
    this.fuenteDatos = 'manual',
    required this.createdAt,
  });

  bool get isFromApi => fuenteDatos == 'api';

  /// Tasa de engagement calculada (si no viene precalculada)
  double get engagementRate {
    if (engagement > 0) return engagement;
    if (seguidores <= 0) return 0;
    return ((likes + comentarios + compartidos) / seguidores * 100);
  }

  /// Crecimiento de seguidores en %
  double get crecimientoPorcentual {
    final previo = seguidores - nuevosSeguidores;
    if (previo <= 0) return 0;
    return (nuevosSeguidores / previo * 100);
  }

  factory SocialMetrics.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return SocialMetrics(
      id: doc.id,
      plataforma: SocialPlatformX.from(m['plataforma']),
      fecha: m['fecha'] is Timestamp ? (m['fecha'] as Timestamp).toDate() : DateTime.now(),
      periodo: MetricPeriodX.from(m['periodo']),
      seguidores: m['seguidores'] ?? 0,
      nuevosSeguidores: m['nuevosSeguidores'] ?? 0,
      publicaciones: m['publicaciones'] ?? 0,
      alcance: m['alcance'] ?? 0,
      impresiones: m['impresiones'] ?? 0,
      engagement: (m['engagement'] ?? 0).toDouble(),
      clics: m['clics'] ?? 0,
      compartidos: m['compartidos'] ?? 0,
      comentarios: m['comentarios'] ?? 0,
      likes: m['likes'] ?? 0,
      vistas: m['vistas'] ?? 0,
      suscriptores: m['suscriptores'] ?? 0,
      duracionPromedio: (m['duracionPromedio'] ?? 0).toDouble(),
      usuarios: m['usuarios'] ?? 0,
      sesiones: m['sesiones'] ?? 0,
      bounceRate: (m['bounceRate'] ?? 0).toDouble(),
      duracionSesion: (m['duracionSesion'] ?? 0).toDouble(),
      conversiones: m['conversiones'] ?? 0,
      mejorContenidoTitulo: m['mejorContenidoTitulo'],
      mejorContenidoUrl: m['mejorContenidoUrl'],
      mejorContenidoMetrica: m['mejorContenidoMetrica'] ?? 0,
      datosExtra: Map<String, dynamic>.from(m['datosExtra'] ?? {}),
      fuenteDatos: m['fuenteDatos'] ?? 'manual',
      createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'plataforma': plataforma.value,
    'fecha': Timestamp.fromDate(fecha),
    'periodo': periodo.value,
    'seguidores': seguidores,
    'nuevosSeguidores': nuevosSeguidores,
    'publicaciones': publicaciones,
    'alcance': alcance,
    'impresiones': impresiones,
    'engagement': engagement,
    'clics': clics,
    'compartidos': compartidos,
    'comentarios': comentarios,
    'likes': likes,
    'vistas': vistas,
    'suscriptores': suscriptores,
    'duracionPromedio': duracionPromedio,
    'usuarios': usuarios,
    'sesiones': sesiones,
    'bounceRate': bounceRate,
    'duracionSesion': duracionSesion,
    'conversiones': conversiones,
    'mejorContenidoTitulo': mejorContenidoTitulo,
    'mejorContenidoUrl': mejorContenidoUrl,
    'mejorContenidoMetrica': mejorContenidoMetrica,
    'datosExtra': datosExtra,
    'fuenteDatos': fuenteDatos,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
