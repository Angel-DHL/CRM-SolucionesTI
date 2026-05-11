// lib/soporte/pages/manuals_page.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/knowledge_article.dart';
import '../models/support_enums.dart';
import '../services/knowledge_service.dart';

class ManualsPage extends StatefulWidget {
  final UserRole? role;
  const ManualsPage({super.key, this.role});

  @override
  State<ManualsPage> createState() => _ManualsPageState();
}

class _ManualsPageState extends State<ManualsPage> {
  bool _uploading = false;

  bool get _canUpload {
    if (widget.role == null) return false;
    return widget.role!.id == 'admin' ||
           widget.role!.id == 'soporte_sistemas' ||
           widget.role!.id == 'soporte_tecnico';
  }

  Future<void> _uploadManual() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    // Mostrar diálogo para nombre y categoría
    if (!mounted) return;

    final nombreCtrl = TextEditingController(text: file.name.split('.').first);
    final descCtrl = TextEditingController();
    CaseCategory cat = CaseCategory.otro;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          title: const Text('Subir Manual'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // File info
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(_fileIcon(file.name), size: 24, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            Text('${(file.size / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del manual *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: AppDimensions.md),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                ),
                const SizedBox(height: AppDimensions.md),
                DropdownButtonFormField<CaseCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: CaseCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setDialogState(() => cat = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Subir')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _uploading = true);
    try {
      await KnowledgeService.instance.uploadManual(
        nombre: nombreCtrl.text.trim(),
        descripcion: descCtrl.text.trim(),
        fileBytes: file.bytes!,
        fileName: file.name,
        categoria: cat,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Manual subido exitosamente'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'xls' || 'xlsx' => Icons.table_chart_rounded,
      'ppt' || 'pptx' => Icons.slideshow_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final df = DateFormat('dd MMM yyyy', 'es_MX');

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text('Manuales y Guías', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_canUpload)
                _uploading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.icon(
                        onPressed: _uploadManual,
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Subir Manual'),
                      ),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: StreamBuilder<List<SupportManual>>(
            stream: KnowledgeService.instance.streamManuals(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final manuals = snap.data ?? [];

              if (manuals.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                      const SizedBox(height: AppDimensions.md),
                      Text('Sin manuales', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
                      const SizedBox(height: AppDimensions.sm),
                      Text('Sube tu primer manual o genera uno con IA', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppDimensions.md),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 3,
                  mainAxisSpacing: AppDimensions.md,
                  crossAxisSpacing: AppDimensions.md,
                  childAspectRatio: isMobile ? 3 : 1.5,
                ),
                itemCount: manuals.length,
                itemBuilder: (_, i) {
                  final m = manuals[i];
                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                              ),
                              child: Icon(_fileIcon(m.fileName), size: 24, color: AppColors.primary),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.nombre, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(m.fileSizeText, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            if (m.generadoPorIA)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.auto_awesome_rounded, size: 10, color: Color(0xFF6366F1)),
                                  SizedBox(width: 3),
                                  Text('IA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                                ]),
                              ),
                          ],
                        ),
                        if (m.descripcion.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.sm),
                          Text(m.descripcion, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Text(df.format(m.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                            const Spacer(),
                            IconButton(
                              onPressed: () => launchUrl(Uri.parse(m.url)),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              tooltip: 'Descargar',
                              visualDensity: VisualDensity.compact,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
