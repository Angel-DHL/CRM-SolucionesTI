// lib/soporte/models/knowledge_article.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'support_enums.dart';

class KnowledgeArticle {
  final String id;
  final String titulo;
  final String contenido;
  final CaseCategory categoria;
  final List<String> tags;
  final String problemaSintomas;
  final String solucionPasos;
  final bool generadoPorIA;
  final List<String> casosRelacionados;
  final String createdByUid;
  final String createdByEmail;
  final int vistas;
  final int utilidad;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KnowledgeArticle({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.categoria,
    this.tags = const [],
    this.problemaSintomas = '',
    this.solucionPasos = '',
    this.generadoPorIA = false,
    this.casosRelacionados = const [],
    required this.createdByUid,
    required this.createdByEmail,
    this.vistas = 0,
    this.utilidad = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  static KnowledgeArticle fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime parseTs(dynamic t) => t is Timestamp ? t.toDate().toLocal() : DateTime.now();

    return KnowledgeArticle(
      id: doc.id,
      titulo: (d['titulo'] ?? '').toString(),
      contenido: (d['contenido'] ?? '').toString(),
      categoria: CaseCategoryX.from(d['categoria'] as String?),
      tags: List<String>.from(d['tags'] ?? const []),
      problemaSintomas: (d['problemaSintomas'] ?? '').toString(),
      solucionPasos: (d['solucionPasos'] ?? '').toString(),
      generadoPorIA: d['generadoPorIA'] == true,
      casosRelacionados: List<String>.from(d['casosRelacionados'] ?? const []),
      createdByUid: (d['createdByUid'] ?? '').toString(),
      createdByEmail: (d['createdByEmail'] ?? '').toString(),
      vistas: (d['vistas'] ?? 0) as int,
      utilidad: (d['utilidad'] ?? 0) as int,
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'contenido': contenido,
    'categoria': categoria.value,
    'tags': tags,
    'problemaSintomas': problemaSintomas,
    'solucionPasos': solucionPasos,
    'generadoPorIA': generadoPorIA,
    'casosRelacionados': casosRelacionados,
    'createdByUid': createdByUid,
    'createdByEmail': createdByEmail,
    'vistas': vistas,
    'utilidad': utilidad,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

// ═══════════════════════════════════════════════════════════
// FAQ
// ═══════════════════════════════════════════════════════════

class SupportFaq {
  final String id;
  final String pregunta;
  final String respuesta;
  final CaseCategory categoria;
  final int orden;
  final bool activo;

  const SupportFaq({
    required this.id,
    required this.pregunta,
    required this.respuesta,
    required this.categoria,
    this.orden = 0,
    this.activo = true,
  });

  static SupportFaq fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SupportFaq(
      id: doc.id,
      pregunta: (d['pregunta'] ?? '').toString(),
      respuesta: (d['respuesta'] ?? '').toString(),
      categoria: CaseCategoryX.from(d['categoria'] as String?),
      orden: (d['orden'] ?? 0) as int,
      activo: d['activo'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'pregunta': pregunta,
    'respuesta': respuesta,
    'categoria': categoria.value,
    'orden': orden,
    'activo': activo,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

// ═══════════════════════════════════════════════════════════
// MANUAL / GUÍA
// ═══════════════════════════════════════════════════════════

class SupportManual {
  final String id;
  final String nombre;
  final String descripcion;
  final String url; // URL de Firebase Storage
  final String fileName;
  final int fileSize;
  final CaseCategory categoria;
  final bool generadoPorIA;
  final String createdByUid;
  final String createdByEmail;
  final DateTime createdAt;

  const SupportManual({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.url,
    required this.fileName,
    this.fileSize = 0,
    required this.categoria,
    this.generadoPorIA = false,
    required this.createdByUid,
    required this.createdByEmail,
    required this.createdAt,
  });

  static SupportManual fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime parseTs(dynamic t) => t is Timestamp ? t.toDate().toLocal() : DateTime.now();

    return SupportManual(
      id: doc.id,
      nombre: (d['nombre'] ?? '').toString(),
      descripcion: (d['descripcion'] ?? '').toString(),
      url: (d['url'] ?? '').toString(),
      fileName: (d['fileName'] ?? '').toString(),
      fileSize: (d['fileSize'] ?? 0) as int,
      categoria: CaseCategoryX.from(d['categoria'] as String?),
      generadoPorIA: d['generadoPorIA'] == true,
      createdByUid: (d['createdByUid'] ?? '').toString(),
      createdByEmail: (d['createdByEmail'] ?? '').toString(),
      createdAt: parseTs(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'url': url,
    'fileName': fileName,
    'fileSize': fileSize,
    'categoria': categoria.value,
    'generadoPorIA': generadoPorIA,
    'createdByUid': createdByUid,
    'createdByEmail': createdByEmail,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get fileSizeText {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
