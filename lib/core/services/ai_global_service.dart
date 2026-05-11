// lib/core/services/ai_global_service.dart

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado de IA para todos los módulos del CRM.
/// Utiliza Gemini 2.5 Flash vía Firebase AI Logic.
class AiGlobalService {
  AiGlobalService._();
  static final AiGlobalService instance = AiGlobalService._();

  GenerativeModel get _model =>
      FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

  // ═══════════════════════════════════════════════════════════
  // DASHBOARD — RESUMEN EJECUTIVO
  // ═══════════════════════════════════════════════════════════

  Future<String> generateExecutiveSummary(Map<String, dynamic> kpis) async {
    try {
      final prompt = '''
Eres el asistente ejecutivo de una empresa de soluciones tecnológicas (TI). 
Genera un resumen ejecutivo breve (máximo 5 puntos) del estado actual de la empresa basándote en estos KPIs:

- Actividades operativas activas: ${kpis['activeActivities']}
- Actividades vencidas: ${kpis['overdueActivities']}
- Proyectos activos: ${kpis['activeProjects']}
- Ventas del mes: \$${kpis['monthlySales']}
- Cotizaciones abiertas: ${kpis['openQuotes']}
- Leads nuevos (mes): ${kpis['newLeads']}
- Casos de soporte abiertos: ${kpis['openCases']}
- Productos en inventario: ${kpis['inventoryCount']}
- Campañas activas: ${kpis['activeCampaigns']}

Formato de respuesta:
📊 [Resumen general en 1 línea]

✅ [Aspecto positivo]
⚠️ [Área que requiere atención]
🎯 [Acción recomendada prioritaria]
📈 [Oportunidad identificada]

Sé directo, profesional y en español.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el resumen.';
    } catch (e) {
      debugPrint('Error generando resumen ejecutivo: $e');
      return 'Error al generar resumen: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CRM — CONTACTOS
  // ═══════════════════════════════════════════════════════════

  /// Genera un resumen ejecutivo de un contacto
  Future<String> generateContactSummary({
    required Map<String, dynamic> contact,
    required List<Map<String, dynamic>> activityLogs,
    required List<Map<String, dynamic>> quotes,
  }) async {
    try {
      final logsText = activityLogs.take(10).map((l) =>
        '- ${l['type']}: ${l['description']} (${l['date']})').join('\n');
      final quotesText = quotes.take(5).map((q) =>
        '- ${q['folio']}: \$${q['total']} (${q['status']})').join('\n');

      final prompt = '''
Eres un asesor comercial de TI. Genera un resumen ejecutivo de este cliente:

Nombre: ${contact['name']}
Empresa: ${contact['company']}
Email: ${contact['email']}
Teléfono: ${contact['phone']}
Etapa: ${contact['stage']}
Origen: ${contact['source']}

Historial de actividades:
$logsText

Cotizaciones:
$quotesText

Genera:
1. PERFIL: Resumen del cliente en 2 líneas
2. RELACIÓN: Estado actual de la relación comercial
3. SIGUIENTE ACCIÓN: Qué hacer a continuación para avanzar la relación
4. RIESGO: ¿Hay algún riesgo de perder este cliente?

Responde en español, de forma concisa y profesional.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el resumen.';
    } catch (e) {
      debugPrint('Error generando resumen de contacto: $e');
      return 'Error al generar resumen: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // VENTAS — PRONÓSTICO Y ANÁLISIS
  // ═══════════════════════════════════════════════════════════

  /// Pronóstico de ventas basado en oportunidades activas
  Future<String> generateSalesForecast({
    required List<Map<String, dynamic>> opportunities,
    required List<Map<String, dynamic>> recentOrders,
  }) async {
    try {
      final oppsText = opportunities.take(15).map((o) =>
        '- ${o['title']}: \$${o['amount']} (Etapa: ${o['stage']}, Prob: ${o['probability']}%)').join('\n');
      final ordersText = recentOrders.take(10).map((o) =>
        '- ${o['folio']}: \$${o['total']} (${o['date']})').join('\n');

      final prompt = '''
Eres un analista de ventas. Analiza las oportunidades y ventas recientes:

OPORTUNIDADES ACTIVAS:
$oppsText

VENTAS RECIENTES:
$ordersText

Genera:
1. PRONÓSTICO: Ingreso estimado para los próximos 30 días con probabilidad ponderada
2. TENDENCIA: ¿Las ventas están subiendo, bajando o estables?
3. OPORTUNIDADES CLAVE: Las 3 oportunidades con mayor potencial de cierre
4. RECOMENDACIÓN: Acciones para mejorar la conversión

Responde en español. Sé analítico y usa números concretos.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el pronóstico.';
    } catch (e) {
      debugPrint('Error generando pronóstico: $e');
      return 'Error al generar pronóstico: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MARKETING — CONTENIDO Y ANÁLISIS
  // ═══════════════════════════════════════════════════════════

  /// Genera contenido para una campaña
  Future<String> generateCampaignContent({
    required String campaignName,
    required String type,
    required String audience,
    required String objective,
  }) async {
    try {
      final prompt = '''
Eres un experto en marketing digital para una empresa de soluciones de TI.
Genera contenido para la siguiente campaña:

Nombre: $campaignName
Tipo: $type
Audiencia: $audience
Objetivo: $objective

Genera:
1. ASUNTO/TÍTULO: Un titular atractivo
2. CONTENIDO PRINCIPAL: El cuerpo del mensaje (3-4 párrafos)
3. CALL-TO-ACTION: Un llamado a la acción efectivo
4. HASHTAGS: 5 hashtags relevantes (si aplica)

Responde en español. El tono debe ser profesional pero cercano.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el contenido.';
    } catch (e) {
      debugPrint('Error generando contenido: $e');
      return 'Error al generar contenido: $e';
    }
  }

  /// Análisis de rendimiento de campañas
  Future<String> analyzeCampaignPerformance({
    required List<Map<String, dynamic>> campaigns,
  }) async {
    try {
      final text = campaigns.take(10).map((c) =>
        '- ${c['name']}: ${c['type']}, Estado: ${c['status']}, '
        'Presupuesto: \$${c['budget']}, Alcance: ${c['reach']}, '
        'Conversiones: ${c['conversions']}').join('\n');

      final prompt = '''
Analiza el rendimiento de estas campañas de marketing:

$text

Genera:
1. RESUMEN: Estado general del marketing
2. MEJOR CAMPAÑA: Cuál tiene mejor rendimiento y por qué
3. ÁREAS DE MEJORA: Qué campañas necesitan ajustes
4. RECOMENDACIÓN: Próximos pasos estratégicos

Responde en español, con datos concretos.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo analizar.';
    } catch (e) {
      debugPrint('Error analizando campañas: $e');
      return 'Error al analizar: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // INVENTARIO — ALERTAS Y OPTIMIZACIÓN
  // ═══════════════════════════════════════════════════════════

  Future<String> analyzeInventory({
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> movements,
  }) async {
    try {
      final itemsText = items.take(20).map((i) =>
        '- ${i['name']}: Stock=${i['stock']}, Min=${i['minStock']}, '
        'Categoría=${i['category']}').join('\n');
      final movText = movements.take(15).map((m) =>
        '- ${m['type']}: ${m['item']} x${m['quantity']} (${m['date']})').join('\n');

      final prompt = '''
Eres un analista de inventario de TI. Analiza este inventario:

PRODUCTOS:
$itemsText

MOVIMIENTOS RECIENTES:
$movText

Genera:
1. ALERTAS: Productos que están por debajo del stock mínimo o en riesgo
2. TENDENCIAS: Productos con mayor rotación
3. RECOMENDACIONES: Sugerencias de reabastecimiento
4. OPTIMIZACIÓN: Productos con exceso de stock

Responde en español, con alertas claras y accionables.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo analizar.';
    } catch (e) {
      debugPrint('Error analizando inventario: $e');
      return 'Error al analizar: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // OPERATIVIDAD — RESUMEN SEMANAL
  // ═══════════════════════════════════════════════════════════

  Future<String> generateWeeklySummary({
    required List<Map<String, dynamic>> activities,
  }) async {
    try {
      final text = activities.take(20).map((a) =>
        '- ${a['title']}: Estado=${a['status']}, Asignados=${a['assignees']}, '
        'Progreso=${a['progress']}%, Vencida=${a['overdue']}').join('\n');

      final prompt = '''
Genera un resumen semanal ejecutivo de operatividad para este equipo de TI:

ACTIVIDADES:
$text

Genera:
1. RESUMEN: Estado general de la operación en 2 líneas
2. LOGROS: Qué se completó esta semana
3. PENDIENTES: Qué queda por hacer (priorizar vencidas)
4. RIESGOS: Actividades en riesgo de no completarse
5. RECOMENDACIÓN: Prioridades para la próxima semana

Responde en español. Formato ejecutivo y directo.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar.';
    } catch (e) {
      debugPrint('Error generando resumen semanal: $e');
      return 'Error al generar: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PROYECTOS — RIESGO Y REPORTE
  // ═══════════════════════════════════════════════════════════

  Future<String> analyzeProjectRisk({
    required Map<String, dynamic> project,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final tasksText = tasks.take(10).map((t) =>
        '- ${t['title']}: ${t['status']}, Progreso: ${t['progress']}%').join('\n');
      final txText = transactions.take(10).map((t) =>
        '- ${t['type']}: \$${t['amount']} (${t['date']})').join('\n');

      final prompt = '''
Analiza el riesgo de este proyecto de TI:

PROYECTO: ${project['name']}
Valor: \$${project['value']}
Estado: ${project['status']}
Avance financiero: ${project['paymentProgress']}%
Inicio: ${project['startDate']}
Fin planeado: ${project['endDate']}

TAREAS:
$tasksText

TRANSACCIONES:
$txText

Genera:
1. NIVEL DE RIESGO: [Bajo/Medio/Alto/Crítico] con justificación
2. ANÁLISIS FINANCIERO: ¿Los pagos están al día?
3. ANÁLISIS DE TAREAS: ¿Se va a entregar a tiempo?
4. ALERTAS: Problemas identificados
5. RECOMENDACIONES: Acciones inmediatas

Responde en español.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo analizar.';
    } catch (e) {
      debugPrint('Error analizando riesgo: $e');
      return 'Error al analizar: $e';
    }
  }

  Future<String> generateProjectReport({
    required Map<String, dynamic> project,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final tasksText = tasks.map((t) =>
        '- ${t['title']}: ${t['status']}').join('\n');
      final txText = transactions.map((t) =>
        '- ${t['type']}: \$${t['amount']}').join('\n');

      final prompt = '''
Genera un reporte ejecutivo para el cliente del siguiente proyecto:

PROYECTO: ${project['name']}
Descripción: ${project['description']}
Valor total: \$${project['value']}
Avance financiero: ${project['paymentProgress']}%

TAREAS:
$tasksText

TRANSACCIONES:
$txText

El reporte debe ser:
1. TÍTULO del reporte
2. RESUMEN EJECUTIVO (2-3 líneas para el cliente)
3. AVANCES DEL PERÍODO (qué se ha logrado)
4. PRÓXIMOS PASOS (qué sigue)
5. ESTADO FINANCIERO (simplificado para el cliente)

Usa un lenguaje NO técnico, profesional y orientado al cliente.
Responde en español con formato Markdown.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar.';
    } catch (e) {
      debugPrint('Error generando reporte: $e');
      return 'Error al generar: $e';
    }
  }
}
