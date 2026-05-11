// lib/proyectos/services/project_report_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/project.dart';
import '../models/project_enums.dart';
import 'project_service.dart';
import 'project_task_service.dart';
import 'project_transaction_service.dart';

/// Tipos de reporte de proyectos
enum ProjectReportType {
  fichaProyecto('Ficha del Proyecto'),
  estadoFinanciero('Estado Financiero'),
  cronogramaTareas('Cronograma de Tareas'),
  historialTransacciones('Historial de Transacciones'),
  resumenEjecutivo('Resumen Ejecutivo'),
  listadoProyectos('Listado de Proyectos');

  final String label;
  const ProjectReportType(this.label);
}

class ProjectReportService {
  ProjectReportService._();
  static final ProjectReportService instance = ProjectReportService._();

  final _projectService = ProjectService.instance;
  final _taskService = ProjectTaskService.instance;
  final _txnService = ProjectTransactionService.instance;

  // Colores institucionales
  static final _primaryDark = PdfColor.fromHex('#44562C');
  static final _primaryLight = PdfColor.fromHex('#ACC952');
  static final _primaryPale = PdfColor.fromHex('#F0F5E4');
  static final _textPrimary = PdfColor.fromHex('#1A1F16');
  static final _textSecondary = PdfColor.fromHex('#3D4A35');
  static final _textHint = PdfColor.fromHex('#8B9A78');
  static final _divider = PdfColor.fromHex('#E8EDE0');
  static final _white = PdfColors.white;

  static final _nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  static final _df = DateFormat('dd/MM/yyyy', 'es_MX');
  static final _dtf = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');

  // ═══════════════════════════════════════════════════════════
  // GENERADOR PRINCIPAL
  // ═══════════════════════════════════════════════════════════

  Future<Uint8List> generateReport(ProjectReportType type, {String? projectId}) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      ),
    );

    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/branding/logo.jpg');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    switch (type) {
      case ProjectReportType.fichaProyecto:
        if (projectId != null) await _addFichaProyecto(pdf, projectId, logo);
        break;
      case ProjectReportType.estadoFinanciero:
        if (projectId != null) await _addEstadoFinanciero(pdf, projectId, logo);
        break;
      case ProjectReportType.cronogramaTareas:
        if (projectId != null) await _addCronogramaTareas(pdf, projectId, logo);
        break;
      case ProjectReportType.historialTransacciones:
        if (projectId != null) await _addHistorialTransacciones(pdf, projectId, logo);
        break;
      case ProjectReportType.resumenEjecutivo:
        if (projectId != null) await _addResumenEjecutivo(pdf, projectId, logo);
        break;
      case ProjectReportType.listadoProyectos:
        await _addListadoProyectos(pdf, logo);
        break;
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER / FOOTER COMPARTIDOS
  // ═══════════════════════════════════════════════════════════

  pw.Widget _buildHeader(String title, String subtitle, pw.MemoryImage? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _primaryDark,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          if (logo != null) ...[
            pw.Container(
              width: 50, height: 50,
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(color: _white, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _white)),
              pw.SizedBox(height: 2),
              pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: _primaryLight)),
              pw.SizedBox(height: 4),
              pw.Text('Generado el ${_dtf.format(DateTime.now())}', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#C8D1BC'))),
            ],
          )),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Soluciones TI', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primaryLight)),
              pw.Text('ventas@solucionesti.com.mx', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#C8D1BC'))),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _primaryLight, width: 2))),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Soluciones TI — Módulo de Proyectos', style: pw.TextStyle(fontSize: 7, color: _textHint)),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(fontSize: 7, color: _textHint)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FICHA DEL PROYECTO
  // ═══════════════════════════════════════════════════════════

  Future<void> _addFichaProyecto(pw.Document pdf, String projectId, pw.MemoryImage? logo) async {
    final project = await _projectService.getProjectById(projectId);
    if (project == null) return;

    final summary = await _txnService.getTransactionSummary(projectId);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _buildHeader('FICHA DEL PROYECTO', project.folio, logo),
      footer: _buildFooter,
      build: (ctx) => [
        pw.SizedBox(height: 16),
        // Info principal
        _buildInfoSection('INFORMACIÓN GENERAL', [
          ['Nombre', project.nombre],
          ['Folio', project.folio],
          ['Estado', project.status.label],
          ['Tipo', project.type.label],
          ['Prioridad', project.priority.label],
          ['Descripción', project.descripcion],
        ]),
        pw.SizedBox(height: 12),
        // Cliente
        _buildInfoSection('CLIENTE', [
          ['Nombre', project.clienteNombre],
          if (project.clienteEmpresa != null) ['Empresa', project.clienteEmpresa!],
          if (project.clienteEmail != null) ['Email', project.clienteEmail!],
          if (project.clienteTelefono != null) ['Teléfono', project.clienteTelefono!],
        ]),
        pw.SizedBox(height: 12),
        // Fechas
        _buildInfoSection('CRONOGRAMA', [
          ['Fecha inicio', project.fechaInicio != null ? _df.format(project.fechaInicio!) : 'Sin definir'],
          ['Fecha estimada fin', project.fechaFinEstimada != null ? _df.format(project.fechaFinEstimada!) : 'Sin definir'],
          if (project.fechaFinReal != null) ['Fecha real fin', _df.format(project.fechaFinReal!)],
          ['Progreso', '${project.progreso}%'],
          ['Tareas', '${project.tareasCompletadas}/${project.tareasTotal}'],
        ]),
        pw.SizedBox(height: 12),
        // Financiero
        _buildFinancialBox(project, summary),
        pw.SizedBox(height: 12),
        // Materiales
        if (project.materiales.isNotEmpty) ...[
          _buildMaterialsTable(project),
          pw.SizedBox(height: 12),
        ],
        // Equipo
        if (project.miembrosEquipo.isNotEmpty)
          _buildTeamSection(project),
      ],
    ));
  }

  pw.Widget _buildInfoSection(String title, List<List<String>> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _primaryPale, borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryDark, letterSpacing: 1)),
          pw.SizedBox(height: 8),
          ...rows.map((r) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(children: [
              pw.SizedBox(width: 120, child: pw.Text(r[0], style: pw.TextStyle(fontSize: 9, color: _textHint))),
              pw.Expanded(child: pw.Text(r[1], style: pw.TextStyle(fontSize: 9, color: _textPrimary))),
            ]),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialBox(Project project, TransactionSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryDark, width: 1.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        pw.Text('RESUMEN FINANCIERO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryDark, letterSpacing: 1)),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
          _financialKpi('Valor del Proyecto', _nf.format(project.valorProyecto)),
          _financialKpi('Total Ingresos', _nf.format(summary.totalIngresos)),
          _financialKpi('Total Egresos', _nf.format(summary.totalEgresos)),
          _financialKpi('Rentabilidad', _nf.format(summary.rentabilidad)),
        ]),
        pw.SizedBox(height: 8),
        pw.Divider(color: _divider),
        pw.SizedBox(height: 8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
          _financialKpi('Adelantos', _nf.format(summary.totalAdelantos)),
          _financialKpi('Saldo Pendiente', _nf.format(summary.saldoPendiente)),
          _financialKpi('Presupuesto', _nf.format(project.presupuesto)),
          _financialKpi('Costo Real', _nf.format(project.costoReal)),
        ]),
      ]),
    );
  }

  pw.Widget _financialKpi(String label, String value) {
    return pw.Column(children: [
      pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primaryDark)),
      pw.SizedBox(height: 2),
      pw.Text(label, style: pw.TextStyle(fontSize: 7, color: _textHint)),
    ]);
  }

  pw.Widget _buildMaterialsTable(Project project) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('MATERIALES', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryDark, letterSpacing: 1)),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 8),
        headerDecoration: pw.BoxDecoration(color: _primaryDark),
        cellStyle: pw.TextStyle(fontSize: 8, color: _textPrimary),
        headers: ['SKU', 'Material', 'Cantidad', 'P. Unit.', 'Subtotal'],
        data: project.materiales.map((m) => [
          m.sku, m.nombre, '${m.cantidad} ${m.unidad}',
          _nf.format(m.precioUnitario), _nf.format(m.subtotal),
        ]).toList(),
      ),
    ]);
  }

  pw.Widget _buildTeamSection(Project project) {
    return _buildInfoSection('EQUIPO DEL PROYECTO', [
      if (project.responsableNombre != null) ['Responsable', project.responsableNombre!],
      ...project.miembrosEquipo.map((m) => [
        m['rol']?.toString() ?? 'Miembro',
        m['nombre']?.toString() ?? '',
      ]),
    ]);
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADO FINANCIERO
  // ═══════════════════════════════════════════════════════════

  Future<void> _addEstadoFinanciero(pw.Document pdf, String projectId, pw.MemoryImage? logo) async {
    final project = await _projectService.getProjectById(projectId);
    if (project == null) return;
    final summary = await _txnService.getTransactionSummary(projectId);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _buildHeader('ESTADO FINANCIERO', '${project.nombre} — ${project.folio}', logo),
      footer: _buildFooter,
      build: (ctx) => [
        pw.SizedBox(height: 16),
        _buildFinancialBox(project, summary),
        pw.SizedBox(height: 16),
        _buildInfoSection('DESGLOSE DE GASTOS', [
          ['Materiales', _nf.format(summary.gastosMaterial)],
          ['Mano de Obra', _nf.format(summary.gastosManoObra)],
          ['Operativos', _nf.format(summary.gastosOperativos)],
          ['Total Egresos', _nf.format(summary.totalEgresos)],
        ]),
        pw.SizedBox(height: 16),
        _buildInfoSection('INDICADORES', [
          ['Margen de Rentabilidad', '${project.margenRentabilidad.toStringAsFixed(1)}%'],
          ['% Cobrado', '${project.porcentajeCobro.toStringAsFixed(1)}%'],
          ['Variación Presupuesto', _nf.format(project.variacionPresupuesto)],
          ['Salud', project.salud.label],
        ]),
      ],
    ));
  }

  // ═══════════════════════════════════════════════════════════
  // CRONOGRAMA DE TAREAS
  // ═══════════════════════════════════════════════════════════

  Future<void> _addCronogramaTareas(pw.Document pdf, String projectId, pw.MemoryImage? logo) async {
    final project = await _projectService.getProjectById(projectId);
    if (project == null) return;

    final tasksSnap = await _taskService.streamTasks(projectId).first;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _buildHeader('CRONOGRAMA DE TAREAS', '${project.nombre} — ${project.folio}', logo),
      footer: _buildFooter,
      build: (ctx) => [
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 8),
          headerDecoration: pw.BoxDecoration(color: _primaryDark),
          cellStyle: pw.TextStyle(fontSize: 8),
          headers: ['#', 'Tarea', 'Estado', 'Prioridad', 'Asignado', 'Inicio', 'Vencimiento', 'Progreso', 'Horas'],
          data: tasksSnap.asMap().entries.map((e) {
            final t = e.value;
            return [
              '${e.key + 1}', t.titulo, t.status.label, t.priority.label,
              t.asignadoNombre ?? '-',
              t.fechaInicio != null ? _df.format(t.fechaInicio!) : '-',
              t.fechaVencimiento != null ? _df.format(t.fechaVencimiento!) : '-',
              '${t.progreso}%',
              '${t.horasReales}/${t.horasEstimadas}',
            ];
          }).toList(),
        ),
      ],
    ));
  }

  // ═══════════════════════════════════════════════════════════
  // HISTORIAL DE TRANSACCIONES
  // ═══════════════════════════════════════════════════════════

  Future<void> _addHistorialTransacciones(pw.Document pdf, String projectId, pw.MemoryImage? logo) async {
    final project = await _projectService.getProjectById(projectId);
    if (project == null) return;

    final txns = await _txnService.streamTransactions(projectId).first;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _buildHeader('HISTORIAL DE TRANSACCIONES', '${project.nombre} — ${project.folio}', logo),
      footer: _buildFooter,
      build: (ctx) => [
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 8),
          headerDecoration: pw.BoxDecoration(color: _primaryDark),
          cellStyle: pw.TextStyle(fontSize: 8),
          headers: ['Folio', 'Fecha', 'Tipo', 'Concepto', 'Monto', 'Estado', 'Método'],
          data: txns.map((t) => [
            t.folio, _df.format(t.fechaTransaccion), t.type.label,
            t.concepto.length > 30 ? '${t.concepto.substring(0, 30)}...' : t.concepto,
            '${t.esIngreso ? '+' : '-'}${_nf.format(t.monto)}',
            t.status.label, t.metodoPago?.label ?? '-',
          ]).toList(),
        ),
      ],
    ));
  }

  // ═══════════════════════════════════════════════════════════
  // RESUMEN EJECUTIVO
  // ═══════════════════════════════════════════════════════════

  Future<void> _addResumenEjecutivo(pw.Document pdf, String projectId, pw.MemoryImage? logo) async {
    final project = await _projectService.getProjectById(projectId);
    if (project == null) return;
    final summary = await _txnService.getTransactionSummary(projectId);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _buildHeader('RESUMEN EJECUTIVO', project.nombre, logo),
      footer: _buildFooter,
      build: (ctx) => [
        pw.SizedBox(height: 20),
        // Datos clave
        pw.Row(children: [
          pw.Expanded(child: _kpiCard('Estado', project.status.label)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _kpiCard('Progreso', '${project.progreso}%')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _kpiCard('Rentabilidad', _nf.format(summary.rentabilidad))),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _kpiCard('Salud', project.salud.label)),
        ]),
        pw.SizedBox(height: 16),
        _buildFinancialBox(project, summary),
        pw.SizedBox(height: 16),
        _buildInfoSection('DATOS DEL PROYECTO', [
          ['Cliente', project.clienteNombre],
          ['Tipo', project.type.label],
          ['Responsable', project.responsableNombre ?? 'Sin asignar'],
          ['Inicio', project.fechaInicio != null ? _df.format(project.fechaInicio!) : 'Sin definir'],
          ['Fin estimado', project.fechaFinEstimada != null ? _df.format(project.fechaFinEstimada!) : 'Sin definir'],
          ['Tareas', '${project.tareasCompletadas} de ${project.tareasTotal} completadas'],
        ]),
      ],
    ));
  }

  pw.Widget _kpiCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _primaryPale, borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primaryDark)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _textSecondary)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LISTADO DE PROYECTOS
  // ═══════════════════════════════════════════════════════════

  Future<void> _addListadoProyectos(pw.Document pdf, pw.MemoryImage? logo) async {
    final projects = await _projectService.streamProjects().first;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _buildHeader('LISTADO DE PROYECTOS', 'Todos los proyectos registrados', logo),
      footer: _buildFooter,
      build: (ctx) => [
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _white, fontSize: 8),
          headerDecoration: pw.BoxDecoration(color: _primaryDark),
          cellStyle: pw.TextStyle(fontSize: 8),
          headers: ['Folio', 'Proyecto', 'Cliente', 'Estado', 'Tipo', 'Valor', 'Progreso', 'Inicio'],
          data: projects.map((p) => [
            p.folio,
            p.nombre.length > 25 ? '${p.nombre.substring(0, 25)}...' : p.nombre,
            p.clienteNombre.length > 20 ? '${p.clienteNombre.substring(0, 20)}...' : p.clienteNombre,
            p.status.label, p.type.label, _nf.format(p.valorProyecto),
            '${p.progreso}%',
            p.fechaInicio != null ? _df.format(p.fechaInicio!) : '-',
          ]).toList(),
        ),
      ],
    ));
  }
}
