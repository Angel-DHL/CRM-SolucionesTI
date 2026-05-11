// lib/soporte/services/ai_support_service.dart

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/firebase_helper.dart';
import '../models/knowledge_article.dart';
import '../models/support_case.dart';
import '../models/support_enums.dart';
import 'knowledge_service.dart';

class AiSupportService {
  AiSupportService._();
  static final AiSupportService instance = AiSupportService._();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  /// Modelo de Gemini (Gemini Developer API - Tier gratuito)
  GenerativeModel get _model =>
      FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

  // ═══════════════════════════════════════════════════════════
  // 1. GENERAR ARTÍCULO DESDE CASO RESUELTO
  // ═══════════════════════════════════════════════════════════

  /// Toma un caso resuelto y genera un artículo de base de conocimiento
  Future<KnowledgeArticle?> generateArticleFromCase(SupportCase caso) async {
    try {
      // Obtener comentarios del caso
      final commentsSnap = await FirebaseHelper.supportCases
          .doc(caso.id)
          .collection('comments')
          .orderBy('createdAt')
          .get();

      final comentarios = commentsSnap.docs
          .map((d) => '- ${d.data()['authorEmail']}: ${d.data()['text']}')
          .join('\n');

      final prompt = '''
Eres un experto en soporte técnico de TI. Genera un artículo de base de conocimiento 
a partir del siguiente caso de soporte resuelto.

**Caso:** ${caso.titulo}
**Categoría:** ${caso.category.label}
**Descripción del problema:** ${caso.descripcion}
**Solución aplicada:** ${caso.solucion ?? 'No especificada'}
**Comentarios del equipo:**
$comentarios

Genera el artículo con el siguiente formato EXACTO (usa estos encabezados):

TÍTULO: [título conciso y descriptivo del problema]
SÍNTOMAS: [síntomas que presenta el problema, como los identificaría el usuario]
DIAGNÓSTICO: [posibles causas del problema]
SOLUCIÓN: [pasos detallados numerados para resolver el problema]
PREVENCIÓN: [medidas para evitar que el problema se repita]
TAGS: [lista de etiquetas separadas por coma para búsqueda]

Responde en español. Sé claro y conciso.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      if (text.isEmpty) return null;

      // Parsear respuesta
      final titulo = _extractSection(text, 'TÍTULO') ?? caso.titulo;
      final sintomas = _extractSection(text, 'SÍNTOMAS') ?? '';
      final diagnostico = _extractSection(text, 'DIAGNÓSTICO') ?? '';
      final solucion = _extractSection(text, 'SOLUCIÓN') ?? '';
      final prevencion = _extractSection(text, 'PREVENCIÓN') ?? '';
      final tagsStr = _extractSection(text, 'TAGS') ?? '';
      final tags = tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      final contenido = '''## Diagnóstico
$diagnostico

## Solución
$solucion

## Prevención
$prevencion''';

      final article = KnowledgeArticle(
        id: '',
        titulo: titulo,
        contenido: contenido,
        categoria: caso.category,
        tags: tags,
        problemaSintomas: sintomas,
        solucionPasos: solucion,
        generadoPorIA: true,
        casosRelacionados: [caso.id],
        createdByUid: _uid,
        createdByEmail: _email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Guardar automáticamente
      await KnowledgeService.instance.createArticle(article);

      return article;
    } catch (e) {
      debugPrint('Error generando artículo con IA: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 2. ANALIZAR ACTIVIDADES DE OPERATIVIDAD
  // ═══════════════════════════════════════════════════════════

  /// Analiza comentarios de actividades recientes y sugiere artículos
  Future<List<Map<String, String>>> analyzeOperatividadComments() async {
    try {
      // Obtener las actividades más recientes (todas, no solo completadas)
      final snap = await FirebaseHelper.operActivities
          .orderBy('updatedAt', descending: true)
          .limit(30)
          .get();

      debugPrint('Actividades encontradas: ${snap.docs.length}');

      if (snap.docs.isEmpty) return [];

      // Recopilar datos de cada actividad (incluir descripción + comentarios)
      final activitiesData = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final title = data['title']?.toString() ?? '';
        final desc = data['description']?.toString() ?? '';
        final status = data['status']?.toString() ?? 'unknown';

        // Intentar obtener comentarios (puede no tener)
        String comments = '';
        try {
          final commentsSnap = await FirebaseHelper.operActivities
              .doc(doc.id)
              .collection('comments')
              .orderBy('createdAt')
              .limit(10)
              .get();

          comments = commentsSnap.docs
              .map((c) => c.data()['text']?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .join('; ');
        } catch (_) {
          // Si no hay subcolección de comentarios, continuar
        }

        if (title.isNotEmpty || desc.isNotEmpty || comments.isNotEmpty) {
          activitiesData.add(
            'Actividad: $title\nEstado: $status\nDescripción: $desc\nComentarios: $comments',
          );
        }
      }

      debugPrint('Actividades con datos: ${activitiesData.length}');

      if (activitiesData.isEmpty) return [];

      final prompt = '''
Eres un analista de soporte técnico. Analiza los siguientes registros de actividades 
de un equipo de TI. Identifica problemas recurrentes, incidencias frecuentes o áreas 
que requieran documentación de soporte.

${activitiesData.join('\n---\n')}

Para cada problema o patrón identificado, responde con el siguiente formato (uno por línea):
PROBLEMA: [descripción corta del problema] | SOLUCIÓN: [resumen de la solución] | CATEGORÍA: [hardware/software/red/configuracion/consulta/otro]

Identifica máximo 5 patrones. Si no hay problemas significativos, aún así identifica 
las áreas de trabajo más comunes que podrían beneficiarse de documentación.
Responde en español.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      debugPrint('Respuesta IA análisis: $text');

      if (text.isEmpty) return [];

      final results = <Map<String, String>>[];
      for (final line in text.split('\n')) {
        if (!line.contains('PROBLEMA:')) continue;

        final parts = line.split('|');
        if (parts.isNotEmpty) {
          results.add({
            'problema': parts[0].replaceFirst('PROBLEMA:', '').trim(),
            'solucion': parts.length > 1 ? parts[1].replaceFirst('SOLUCIÓN:', '').trim() : '',
            'categoria': parts.length > 2 ? parts[2].replaceFirst('CATEGORÍA:', '').trim() : 'otro',
          });
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error analizando actividades: $e');
      rethrow; // Rethrow para que la UI muestre el error
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 3. GENERAR MANUAL POR CATEGORÍA
  // ═══════════════════════════════════════════════════════════

  /// Genera un manual completo de resolución de problemas para una categoría
  Future<String> generateManualContent(CaseCategory category) async {
    try {
      // Obtener todos los artículos de la categoría
      final snap = await FirebaseHelper.supportArticles
          .where('categoria', isEqualTo: category.value)
          .get();

      final articles = snap.docs.map(KnowledgeArticle.fromDoc).toList();

      if (articles.isEmpty) {
        return 'No hay artículos suficientes para generar un manual de ${category.label}.';
      }

      final articlesText = articles.map((a) => '''
Artículo: ${a.titulo}
Síntomas: ${a.problemaSintomas}
Solución: ${a.solucionPasos}
''').join('\n---\n');

      final prompt = '''
Eres un redactor técnico profesional. Genera un manual completo de resolución de 
problemas para la categoría "${category.label}" a partir de los siguientes artículos 
de base de conocimiento.

$articlesText

El manual debe tener:
1. TÍTULO del manual
2. ÍNDICE con los temas cubiertos
3. Para cada problema:
   - Título descriptivo
   - Síntomas y cómo identificar el problema
   - Pasos detallados de solución (numerados)
   - Notas de prevención
4. GLOSARIO de términos técnicos (si aplica)
5. RECOMENDACIONES GENERALES

Usa formato Markdown. El manual debe ser profesional, claro y útil para técnicos 
de soporte de nivel 1 y 2. Responde en español.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el manual.';
    } catch (e) {
      debugPrint('Error generando manual: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 4. SUGERENCIA DE SOLUCIÓN
  // ═══════════════════════════════════════════════════════════

  /// Busca artículos similares y sugiere solución basada en título/descripción
  Future<String> suggestSolution(String titulo, String descripcion) async {
    try {
      // Primero buscar en artículos existentes
      final articles = await KnowledgeService.instance.searchArticles(titulo);
      
      String existingContext = '';
      if (articles.isNotEmpty) {
        final top = articles.take(3);
        existingContext = top.map((a) => '- ${a.titulo}: ${a.solucionPasos}').join('\n');
      }

      final prompt = '''
Eres un asistente de soporte técnico de TI. Un usuario reportó el siguiente problema:

Título: $titulo
Descripción: $descripcion

${existingContext.isNotEmpty ? 'Artículos similares encontrados en la base de conocimiento:\n$existingContext\n' : ''}

Basándote en la información disponible, sugiere una posible solución en 3-5 pasos 
concisos. Si hay artículos similares, prioriza esas soluciones.

Responde en español, de forma clara y directa.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar una sugerencia.';
    } catch (e) {
      debugPrint('Error sugiriendo solución: $e');
      return 'Error al consultar la IA. Intenta de nuevo.';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UTILIDADES PRIVADAS
  // ═══════════════════════════════════════════════════════════

  String? _extractSection(String text, String section) {
    final pattern = RegExp('$section:\\s*(.+?)(?=\\n[A-ZÁÉÍÓÚ]+:|\\Z)', dotAll: true);
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }
}
