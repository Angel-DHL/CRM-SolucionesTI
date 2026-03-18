// lib/operatividad/widgets/evidence_viewer_dialog.dart

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/firebase_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/oper_evidence.dart';

class EvidenceViewerDialog extends StatefulWidget {
  final OperEvidence evidence;
  final String activityId;
  final bool canDelete; // ✅ AGREGAR

  const EvidenceViewerDialog({
    super.key,
    required this.evidence,
    required this.activityId,
    this.canDelete = false, // ✅ AGREGAR
  });

  @override
  State<EvidenceViewerDialog> createState() => _EvidenceViewerDialogState();
}

class _EvidenceViewerDialogState extends State<EvidenceViewerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final uri = Uri.parse(widget.evidence.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteEvidence() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: const Text('Eliminar evidencia'),
        content: Text(
          '¿Estás seguro de eliminar "${widget.evidence.fileName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      // Eliminar de Storage
      final storageRef = FirebaseStorage.instance.ref(
        widget.evidence.storagePath,
      );
      await storageRef.delete();

      // Eliminar de Firestore
      await FirebaseHelper.operActivities
          .doc(widget.activityId)
          .collection('evidences')
          .doc(widget.evidence.id)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Evidencia eliminada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenSize = MediaQuery.of(context).size;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(
          isMobile ? AppDimensions.sm : AppDimensions.md,
        ),
        child: Container(
          // ✅ Usar constraints basados en el tamaño de pantalla
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenSize.width : 1000,
            maxHeight: isMobile
                ? screenSize.height * 0.9
                : screenSize.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(isMobile),

              // Content
              Flexible(
                child: widget.evidence.isImage
                    ? _buildImageViewer(isMobile)
                    : _buildDocumentViewer(),
              ),

              // Footer
              _buildFooter(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              widget.evidence.isImage
                  ? Icons.image_rounded
                  : Icons.insert_drive_file_rounded,
              color: AppColors.primary,
              size: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(width: AppDimensions.md),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.evidence.fileName,
                  style:
                      (isMobile ? AppTextStyles.bodyMedium : AppTextStyles.h3)
                          .copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isMobile)
                  Row(
                    children: [
                      Text(
                        'Subido por ${widget.evidence.uploadedByEmail.split('@').first}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        '• ${widget.evidence.formattedFileSize}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(AppDimensions.xs),
              decoration: BoxDecoration(
                color: AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 18),
            ),
            tooltip: 'Cerrar',
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(bool isMobile) {
    return Container(
      color: Colors.black87,
      constraints: BoxConstraints(minHeight: isMobile ? 200 : 300),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.network(
            widget.evidence.downloadUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'Cargando imagen...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stack) {
              debugPrint('Error cargando imagen en viewer: $error');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'Error al cargar la imagen',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        'Intenta descargarla directamente',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      OutlinedButton.icon(
                        onPressed: _download,
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white70,
                        ),
                        label: Text(
                          'Descargar',
                          style: TextStyle(color: Colors.white70),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    IconData icon;
    String message;

    switch (widget.evidence.fileExtension) {
      case 'pdf':
        icon = Icons.picture_as_pdf_rounded;
        message = 'Documento PDF';
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description_rounded;
        message = 'Documento de Word';
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart_rounded;
        message = 'Hoja de cálculo';
        break;
      default:
        icon = Icons.insert_drive_file_rounded;
        message = 'Archivo';
    }

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.xl),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              message,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              widget.evidence.fileName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xl),
            FilledButton.icon(
              onPressed: _download,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Descargar archivo'),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Row(
        children: [
          // Upload info
          if (!isMobile) ...[
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
            const SizedBox(width: AppDimensions.xs),
            Expanded(
              child: Text(
                _formatDate(widget.evidence.uploadedAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
          ] else
            const Spacer(),

          // Actions
          if (widget.canDelete) ...[
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _deleteEvidence,
              icon: _isDeleting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
              label: Text(
                _isDeleting ? 'Eliminando...' : 'Eliminar',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
          ],
          FilledButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(isMobile ? 'Descargar' : 'Descargar archivo'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
