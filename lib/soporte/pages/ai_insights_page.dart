// lib/soporte/pages/ai_insights_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/support_enums.dart';
import '../services/ai_support_service.dart';
import '../services/knowledge_service.dart';
import '../models/knowledge_article.dart';

class AiInsightsPage extends StatefulWidget {
  const AiInsightsPage({super.key});

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  bool _analyzing = false;
  List<Map<String, String>> _patterns = [];

  bool _generatingManual = false;
  CaseCategory _manualCategory = CaseCategory.software;
  String? _generatedManual;
  bool _savingPdf = false;

  Future<void> _analyzeOperatividad() async {
    setState(() { _analyzing = true; _patterns = []; });
    try {
      final results = await AiSupportService.instance.analyzeOperatividadComments();
      setState(() => _patterns = results);
      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron patrones significativos'), backgroundColor: AppColors.info),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al analizar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _analyzing = false);
    }
  }

  Future<void> _generateManual() async {
    setState(() { _generatingManual = true; _generatedManual = null; });
    try {
      final content = await AiSupportService.instance.generateManualContent(_manualCategory);
      setState(() => _generatedManual = content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _generatingManual = false);
    }
  }

  /// Genera un PDF a partir del contenido markdown y lo sube a Firebase Storage
  Future<void> _saveManualAsPdf() async {
    if (_generatedManual == null) return;
    setState(() => _savingPdf = true);

    try {
      final pdfBytes = await _buildPdfFromMarkdown(
        _generatedManual!,
        'Manual de ${_manualCategory.label}',
      );

      // Subir a Firebase Storage y guardar como SupportManual
      final fileName = 'manual_${_manualCategory.value}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await KnowledgeService.instance.uploadManual(
        nombre: 'Manual de ${_manualCategory.label} - IA',
        descripcion: 'Manual generado automáticamente por IA para la categoría ${_manualCategory.label}',
        fileBytes: pdfBytes,
        fileName: fileName,
        categoria: _manualCategory,
        generadoPorIA: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Manual PDF guardado en Manuales y Guías'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _savingPdf = false);
    }
  }

  /// Construye un PDF profesional a partir de texto markdown
  Future<Uint8List> _buildPdfFromMarkdown(String markdown, String title) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
        italic: await PdfGoogleFonts.nunitoItalic(),
        boldItalic: await PdfGoogleFonts.nunitoBoldItalic(),
      ),
    );

    final primaryPdf = PdfColor.fromInt(AppColors.primary.value);
    final primaryDarkPdf = PdfColor.fromInt(AppColors.primaryDark.value);
    final textPdf = PdfColor.fromInt(AppColors.textPrimary.value);
    final hintPdf = PdfColor.fromInt(AppColors.textHint.value);

    // Parsear líneas del markdown
    final lines = markdown.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      if (trimmed.startsWith('# ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
          child: pw.Text(trimmed.substring(2),
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryDarkPdf)),
        ));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
          child: pw.Text(trimmed.substring(3),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryPdf)),
        ));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: pw.Text(trimmed.substring(4),
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textPdf)),
        ));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('• ', style: pw.TextStyle(fontSize: 11, color: primaryPdf)),
            pw.Expanded(child: pw.Text(trimmed.substring(2), style: pw.TextStyle(fontSize: 11, color: textPdf, lineSpacing: 2))),
          ]),
        ));
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
          child: pw.Text(trimmed, style: pw.TextStyle(fontSize: 11, color: textPdf, lineSpacing: 2)),
        ));
      } else if (trimmed.startsWith('---')) {
        widgets.add(pw.Divider(color: PdfColor.fromInt(AppColors.divider.value)));
      } else {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(trimmed, style: pw.TextStyle(fontSize: 11, color: textPdf, lineSpacing: 2)),
        ));
      }
    }

    // Portada
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(0),
      build: (_) => pw.Column(children: [
        pw.Container(
          width: double.infinity, height: 220,
          decoration: pw.BoxDecoration(color: primaryDarkPdf),
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('CRM Soluciones TI', style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 28, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Generado por IA • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(color: PdfColor.fromHex('#B0B0B0'), fontSize: 12)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Documento generado automáticamente', style: pw.TextStyle(fontSize: 14, color: hintPdf)),
                pw.SizedBox(height: 8),
                pw.Text('Este manual fue creado utilizando inteligencia artificial (Gemini) a partir de la base de conocimiento del sistema de soporte.',
                  style: pw.TextStyle(fontSize: 11, color: hintPdf, lineSpacing: 2)),
              ],
            ),
          ),
        ),
      ]),
    ));

    // Contenido en páginas multi-page
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      header: (_) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: primaryPdf, width: 0.5))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, color: primaryPdf, fontWeight: pw.FontWeight.bold)),
          pw.Text('CRM Soluciones TI', style: pw.TextStyle(fontSize: 10, color: hintPdf)),
        ]),
      ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Generado por IA', style: pw.TextStyle(fontSize: 9, color: hintPdf)),
          pw.Text('Página ${ctx.pageNumber}', style: pw.TextStyle(fontSize: 9, color: hintPdf)),
        ]),
      ),
      build: (_) => widgets,
    ));

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppDimensions.xl),
          if (!isMobile)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildOperatividadAnalysis()),
              const SizedBox(width: AppDimensions.lg),
              Expanded(child: _buildManualGenerator()),
            ])
          else ...[
            _buildOperatividadAnalysis(),
            const SizedBox(height: AppDimensions.lg),
            _buildManualGenerator(),
          ],
          const SizedBox(height: AppDimensions.xl),
          _buildAiGeneratedArticles(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6366F1).withValues(alpha: 0.08), const Color(0xFF8B5CF6).withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: AppDimensions.lg),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Inteligencia Artificial', style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w700,
            foreground: Paint()..shader = const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
          )),
          Text('Análisis inteligente de actividades y generación automática de documentación',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _buildOperatividadAnalysis() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.analytics_rounded, size: 20, color: Color(0xFF6366F1)),
          const SizedBox(width: AppDimensions.sm),
          Text('Analizar Operatividad', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: AppDimensions.sm),
        Text('Escanea las actividades recientes, identifica problemas recurrentes y sugiere artículos para la base de conocimiento.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          width: double.infinity,
          child: _analyzing
              ? Column(children: [
                  const SizedBox(height: AppDimensions.lg),
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppDimensions.md),
                  Text('Analizando actividades con IA...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: AppDimensions.lg),
                ])
              : FilledButton.icon(
                  onPressed: _analyzeOperatividad,
                  icon: const Icon(Icons.psychology_rounded),
                  label: const Text('Analizar Actividades'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)),
                ),
        ),
        if (_patterns.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.lg),
          const Divider(),
          const SizedBox(height: AppDimensions.sm),
          Text('Patrones identificados (${_patterns.length}):', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDimensions.sm),
          ..._patterns.map((p) => Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.sm),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(child: Text(p['problema'] ?? '', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 4),
              Text('💡 ${p['solucion'] ?? ''}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(4)),
                child: Text(p['categoria'] ?? 'otro', style: const TextStyle(fontSize: 10, color: AppColors.primary)),
              ),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _buildManualGenerator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_stories_rounded, size: 20, color: Color(0xFF6366F1)),
          const SizedBox(width: AppDimensions.sm),
          Text('Generar Manual PDF', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: AppDimensions.sm),
        Text('Genera un manual completo en PDF a partir de los artículos y casos de soporte. Se guarda automáticamente en Manuales y Guías.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<CaseCategory>(
          initialValue: _manualCategory,
          decoration: InputDecoration(
            labelText: 'Categoría',
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide(color: AppColors.divider)),
          ),
          items: CaseCategory.values.map((c) => DropdownMenuItem(value: c, child: Row(children: [
            Icon(c.icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(c.label),
          ]))).toList(),
          onChanged: (v) => setState(() => _manualCategory = v!),
        ),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          width: double.infinity,
          child: _generatingManual
              ? Column(children: [
                  const SizedBox(height: AppDimensions.lg),
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppDimensions.md),
                  Text('Generando manual con IA...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: AppDimensions.lg),
                ])
              : FilledButton.icon(
                  onPressed: _generateManual,
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Generar Manual'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)),
                ),
        ),
        if (_generatedManual != null) ...[
          const SizedBox(height: AppDimensions.lg),
          const Divider(),
          const SizedBox(height: AppDimensions.sm),
          Row(children: [
            Text('Vista previa:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _generatedManual!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado'), backgroundColor: AppColors.success));
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copiar'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            _savingPdf
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton.icon(
                    onPressed: _saveManualAsPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Guardar PDF'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                  ),
          ]),
          const SizedBox(height: AppDimensions.sm),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: AppColors.divider)),
            child: SingleChildScrollView(
              child: SelectableText(_generatedManual!, style: AppTextStyles.bodySmall.copyWith(height: 1.6, fontFamily: 'monospace')),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildAiGeneratedArticles() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history_edu_rounded, size: 20, color: Color(0xFF6366F1)),
          const SizedBox(width: AppDimensions.sm),
          Text('Bitácora IA', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
            child: const Text('Auto-generados', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
          ),
        ]),
        const SizedBox(height: AppDimensions.md),
        StreamBuilder<List<KnowledgeArticle>>(
          stream: KnowledgeService.instance.streamArticles(),
          builder: (context, snap) {
            final articles = (snap.data ?? []).where((a) => a.generadoPorIA).toList();
            if (articles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Center(child: Column(children: [
                  Icon(Icons.auto_awesome_rounded, size: 40, color: AppColors.textHint.withValues(alpha: 0.3)),
                  const SizedBox(height: AppDimensions.sm),
                  Text('Sin artículos generados por IA aún', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                ])),
              );
            }
            return Column(children: articles.take(10).map((a) => Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                  child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.titulo, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(a.categoria.label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ])),
              ]),
            )).toList());
          },
        ),
      ]),
    );
  }
}
