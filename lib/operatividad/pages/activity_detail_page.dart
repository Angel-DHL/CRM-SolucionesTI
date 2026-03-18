// lib/operatividad/pages/activity_detail_page.dart

import 'dart:typed_data';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/firebase_helper.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/oper_activity.dart';
import '../models/oper_evidence.dart';
import '../models/oper_comment.dart';
import '../widgets/evidence_viewer_dialog.dart';

class ActivityDetailPage extends StatefulWidget {
  final String activityId;

  const ActivityDetailPage({super.key, required this.activityId});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage>
    with TickerProviderStateMixin {
  bool _uploading = false;
  String? _uploadError;
  UserRole? _userRole;

  late ConfettiController _confettiController;
  late AnimationController _completionAnimController;

  final _commentController = TextEditingController();
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _setupAnimations();
  }

  void _setupAnimations() {
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _completionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdTokenResult(true);
    final claimRole = token.claims?['role'] as String?;
    setState(() {
      _userRole = UserRole.fromClaim(claimRole);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _completionAnimController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseHelper.operActivities.doc(widget.activityId);

  bool get _isAdmin => _userRole == UserRole.admin;

  Future<void> _setWorkStart() async {
    HapticFeedback.mediumImpact();
    await _ref.update({
      'workStartAt': FieldValue.serverTimestamp(),
      'actualStartAt': FieldValue.serverTimestamp(),
      'status': OperStatus.inProgress.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.play_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Text('¡Trabajo iniciado!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _setWorkEnd() async {
    HapticFeedback.heavyImpact();

    await _ref.update({
      'workEndAt': FieldValue.serverTimestamp(),
      'actualEndAt': FieldValue.serverTimestamp(),
      'status': OperStatus.done.value,
      'progress': 100,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Animación de completado
    _confettiController.play();
    _completionAnimController.forward(from: 0);

    if (!mounted) return;
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _CompletionCelebrationDialog(onDismiss: () => Navigator.pop(context)),
    );
  }

  Future<void> _updateStatus(OperStatus status) async {
    await _ref.update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == OperStatus.done) 'progress': 100,
    });

    if (status == OperStatus.done) {
      _confettiController.play();
    }
  }

  Future<void> _updateProgress(int value) async {
    await _ref.update({
      'progress': value.clamp(0, 100),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _uploadEvidence(OperActivity activity) async {
    setState(() => _uploadError = null);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final email = FirebaseAuth.instance.currentUser!.email ?? '';

    final res = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
      ],
    );

    if (res == null || res.files.isEmpty) return;

    setState(() => _uploading = true);

    try {
      for (final file in res.files) {
        final Uint8List? bytes = file.bytes;
        final fileName = file.name;

        if (bytes == null) continue;

        final storagePath =
            'operatividad/${activity.id}/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final ref = FirebaseStorage.instance.ref(storagePath);

        await ref.putData(bytes);
        final url = await ref.getDownloadURL();

        // Detectar tipo de archivo
        final extension = fileName.split('.').last.toLowerCase();
        final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);

        await _ref.collection('evidences').add({
          'fileName': fileName,
          'storagePath': storagePath,
          'downloadUrl': url,
          'fileType': isImage ? 'image' : 'document',
          'fileSize': bytes.length,
          'uploadedByUid': uid,
          'uploadedByEmail': email,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      }

      await _ref.update({'updatedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('${res.files.length} archivo(s) subido(s)'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _uploadError = 'Error al subir: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingComment = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await _ref.collection('comments').add({
        'text': text,
        'authorUid': user.uid,
        'authorEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      await _ref.update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar comentario: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Stack(
      children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _ref.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingSkeleton();
            }

            if (snapshot.hasError) {
              return _ErrorView(
                message: 'Error al cargar la actividad',
                onRetry: () => setState(() {}),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const _NotFoundView();
            }

            final activity = OperActivity.fromDoc(snapshot.data!);

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context, activity, isMobile),
              body: isMobile
                  ? _buildMobileLayout(activity)
                  : _buildDesktopLayout(activity),
              bottomNavigationBar: isMobile
                  ? _buildMobileActionBar(activity)
                  : null,
            );
          },
        ),

        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.success,
              AppColors.warning,
              AppColors.info,
            ],
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    OperActivity activity,
    bool isMobile,
  ) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle de actividad',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'ID: ${activity.id.substring(0, 8)}...',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
      actions: [
        if (!isMobile && _isAdmin)
          IconButton(
            onPressed: () => _showEditDialog(activity),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Editar',
            color: AppColors.textSecondary,
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          onSelected: (value) {
            switch (value) {
              case 'share':
                _shareActivity(activity);
                break;
              case 'delete':
                if (_isAdmin) _deleteActivity();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_rounded),
                  SizedBox(width: 8),
                  Text('Compartir'),
                ],
              ),
            ),
            if (_isAdmin)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(width: AppDimensions.sm),
      ],
    );
  }

  Widget _buildDesktopLayout(OperActivity activity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActivityHeader(activity: activity),
                const SizedBox(height: AppDimensions.xl),
                _ProgressSection(
                  activity: activity,
                  onProgressChanged: _updateProgress,
                ),
                const SizedBox(height: AppDimensions.xl),
                _TimeTrackingSection(
                  activity: activity,
                  onStartWork: _setWorkStart,
                  onEndWork: _setWorkEnd,
                ),
                const SizedBox(height: AppDimensions.xl),
                _DescriptionSection(activity: activity),
                const SizedBox(height: AppDimensions.xl),
                _EvidencesSection(
                  activityId: activity.id,
                  activity: activity, // ✅ AGREGAR
                  onUpload: () => _uploadEvidence(activity),
                  uploading: _uploading,
                  uploadError: _uploadError,
                ),
                const SizedBox(height: AppDimensions.xl),
                _CommentsSection(
                  activityId: activity.id,
                  commentController: _commentController,
                  onSendComment: _sendComment,
                  sending: _sendingComment,
                ),
              ],
            ),
          ),
        ),

        // Side panel
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.divider)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusSection(
                  activity: activity,
                  onStatusChanged: _updateStatus,
                  isAdmin: _isAdmin,
                ),
                const SizedBox(height: AppDimensions.lg),
                _AssigneesSection(activity: activity),
                const SizedBox(height: AppDimensions.lg),
                _DatesSection(activity: activity),
                const SizedBox(height: AppDimensions.lg),
                _MetadataSection(activity: activity),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(OperActivity activity) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Header card
          Container(
            margin: const EdgeInsets.all(AppDimensions.md),
            child: _ActivityHeader(activity: activity, compact: true),
          ),

          // Tabs
          Container(
            color: AppColors.surface,
            child: TabBar(
              tabs: const [
                Tab(text: 'Detalles'),
                Tab(text: 'Evidencias'),
                Tab(text: 'Comentarios'),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                // Detalles tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    children: [
                      _ProgressSection(
                        activity: activity,
                        onProgressChanged: _updateProgress,
                        compact: true,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _StatusSection(
                        activity: activity,
                        onStatusChanged: _updateStatus,
                        isAdmin: _isAdmin,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _DescriptionSection(activity: activity),
                      const SizedBox(height: AppDimensions.md),
                      _AssigneesSection(activity: activity),
                      const SizedBox(height: AppDimensions.md),
                      _DatesSection(activity: activity),
                    ],
                  ),
                ),

                // Evidencias tab
                _EvidencesSection(
                  activityId: activity.id,
                  activity: activity, // ✅ AGREGAR
                  onUpload: () => _uploadEvidence(activity),
                  uploading: _uploading,
                  uploadError: _uploadError,
                  fullPage: true,
                ),

                // Comentarios tab
                _CommentsSection(
                  activityId: activity.id,
                  commentController: _commentController,
                  onSendComment: _sendComment,
                  sending: _sendingComment,
                  fullPage: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionBar(OperActivity activity) {
    final canStart = activity.workStartAt == null;
    final canEnd = activity.workStartAt != null && activity.workEndAt == null;
    final isCompleted =
        activity.status == OperStatus.done ||
        activity.status == OperStatus.verified;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (canStart)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _setWorkStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                  ),
                ),
              )
            else if (canEnd)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _setWorkEnd,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Finalizar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                  ),
                ),
              )
            else if (isCompleted)
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completada',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(width: AppDimensions.sm),

            // Upload button
            IconButton(
              onPressed: _uploading ? null : () => _uploadEvidence(activity),
              icon: _uploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.attach_file_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primarySurface,
                foregroundColor: AppColors.primary,
              ),
              tooltip: 'Adjuntar evidencia',
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(OperActivity activity) {
    // TODO: Implementar diálogo de edición
  }

  void _shareActivity(OperActivity activity) {
    // TODO: Implementar compartir
  }

  Future<void> _deleteActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: const Text(
          '¿Estás seguro de eliminar esta actividad? Esta acción no se puede deshacer.',
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

    if (confirm == true) {
      await _ref.delete();
      if (mounted) Navigator.pop(context);
    }
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Secciones de la página
// ══════════════════════════════════════════════════════════════

class _ActivityHeader extends StatelessWidget {
  final OperActivity activity;
  final bool compact;

  const _ActivityHeader({required this.activity, this.compact = false});

  Color _getStatusColor(OperStatus status) {
    switch (status) {
      case OperStatus.planned:
        return AppColors.info;
      case OperStatus.inProgress:
        return AppColors.warning;
      case OperStatus.done:
        return AppColors.success;
      case OperStatus.verified:
        return AppColors.primary;
      case OperStatus.blocked:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(OperStatus status) {
    switch (status) {
      case OperStatus.planned:
        return Icons.schedule_rounded;
      case OperStatus.inProgress:
        return Icons.pending_actions_rounded;
      case OperStatus.done:
        return Icons.check_circle_rounded;
      case OperStatus.verified:
        return Icons.verified_rounded;
      case OperStatus.blocked:
        return Icons.block_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(activity.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppDimensions.md : AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    _getStatusIcon(activity.status),
                    color: color,
                    size: compact ? 24 : 32,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: compact
                            ? AppTextStyles.h3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              )
                            : AppTextStyles.h2.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.sm,
                          vertical: AppDimensions.xs / 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          activity.status.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  _CircularProgress(
                    progress: activity.progress / 100,
                    color: color,
                  ),
              ],
            ),

            if (!compact && activity.priority != null) ...[
              const SizedBox(height: AppDimensions.md),
              _PriorityBadge(priority: activity.priority!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final double progress;
  final Color color;

  const _CircularProgress({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  Color get _color {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String get _label {
    switch (priority) {
      case 'high':
        return 'Alta prioridad';
      case 'medium':
        return 'Prioridad media';
      default:
        return 'Baja prioridad';
    }
  }

  IconData get _icon {
    switch (priority) {
      case 'high':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'medium':
        return Icons.remove_rounded;
      default:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: AppDimensions.xs),
          Text(
            _label,
            style: AppTextStyles.labelMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatefulWidget {
  final OperActivity activity;
  final ValueChanged<int> onProgressChanged;
  final bool compact;

  const _ProgressSection({
    required this.activity,
    required this.onProgressChanged,
    this.compact = false,
  });

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  late double _currentProgress;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.activity.progress.toDouble();
  }

  @override
  void didUpdateWidget(_ProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity.progress != widget.activity.progress) {
      _currentProgress = widget.activity.progress.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Progreso',
      icon: Icons.trending_up_rounded,
      compact: widget.compact,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_currentProgress.toInt()}%',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Completado',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _currentProgress,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                setState(() => _currentProgress = value);
              },
              onChangeEnd: (value) {
                widget.onProgressChanged(value.toInt());
              },
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickProgressButton(
                label: '0%',
                onTap: () {
                  setState(() => _currentProgress = 0);
                  widget.onProgressChanged(0);
                },
              ),
              _QuickProgressButton(
                label: '25%',
                onTap: () {
                  setState(() => _currentProgress = 25);
                  widget.onProgressChanged(25);
                },
              ),
              _QuickProgressButton(
                label: '50%',
                onTap: () {
                  setState(() => _currentProgress = 50);
                  widget.onProgressChanged(50);
                },
              ),
              _QuickProgressButton(
                label: '75%',
                onTap: () {
                  setState(() => _currentProgress = 75);
                  widget.onProgressChanged(75);
                },
              ),
              _QuickProgressButton(
                label: '100%',
                onTap: () {
                  setState(() => _currentProgress = 100);
                  widget.onProgressChanged(100);
                },
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickProgressButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _QuickProgressButton({
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppColors.primary : AppColors.primarySurface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: highlight ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeTrackingSection extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onStartWork;
  final VoidCallback onEndWork;

  const _TimeTrackingSection({
    required this.activity,
    required this.onStartWork,
    required this.onEndWork,
  });

  String _formatDateTime(DateTime? date) {
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration() {
    if (activity.workStartAt == null) return '--';

    final end = activity.workEndAt ?? DateTime.now();
    final duration = end.difference(activity.workStartAt!);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final canStart = activity.workStartAt == null;
    final canEnd = activity.workStartAt != null && activity.workEndAt == null;
    final isCompleted = activity.workEndAt != null;

    return _SectionCard(
      title: 'Control de tiempo',
      icon: Icons.timer_rounded,
      child: Column(
        children: [
          // Time info row
          Row(
            children: [
              Expanded(
                child: _TimeInfoCard(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Inicio',
                  value: _formatDateTime(activity.workStartAt),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _TimeInfoCard(
                  icon: Icons.stop_circle_outlined,
                  label: 'Fin',
                  value: _formatDateTime(activity.workEndAt),
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _TimeInfoCard(
                  icon: Icons.hourglass_empty_rounded,
                  label: 'Duración',
                  value: _calculateDuration(),
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canStart ? onStartWork : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar trabajo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.divider,
                    minimumSize: const Size(0, 52),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canEnd ? onEndWork : null,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Finalizar trabajo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.divider,
                    minimumSize: const Size(0, 52),
                  ),
                ),
              ),
            ],
          ),

          if (isCompleted) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    'Trabajo completado',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimeInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final OperActivity activity;
  final ValueChanged<OperStatus> onStatusChanged;
  final bool isAdmin;

  const _StatusSection({
    required this.activity,
    required this.onStatusChanged,
    required this.isAdmin,
  });

  Color _getStatusColor(OperStatus status) {
    switch (status) {
      case OperStatus.planned:
        return AppColors.info;
      case OperStatus.inProgress:
        return AppColors.warning;
      case OperStatus.done:
        return AppColors.success;
      case OperStatus.verified:
        return AppColors.primary;
      case OperStatus.blocked:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Estado',
      icon: Icons.flag_rounded,
      child: Wrap(
        spacing: AppDimensions.sm,
        runSpacing: AppDimensions.sm,
        children: OperStatus.values.map((status) {
          final isSelected = activity.status == status;
          final color = _getStatusColor(status);

          return ChoiceChip(
            selected: isSelected,
            onSelected: (selected) {
              if (selected) onStatusChanged(status);
            },
            label: Text(status.label),
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: color.withOpacity(0.1),
            selectedColor: color,
            side: BorderSide(
              color: isSelected ? color : color.withOpacity(0.3),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final OperActivity activity;

  const _DescriptionSection({required this.activity});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Descripción',
      icon: Icons.description_rounded,
      child: Text(
        activity.description.isEmpty ? 'Sin descripción' : activity.description,
        style: AppTextStyles.bodyMedium.copyWith(
          color: activity.description.isEmpty
              ? AppColors.textHint
              : AppColors.textPrimary,
          height: 1.6,
        ),
      ),
    );
  }
}

class _AssigneesSection extends StatelessWidget {
  final OperActivity activity;

  const _AssigneesSection({required this.activity});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Responsables',
      icon: Icons.people_rounded,
      child: activity.assigneesEmails.isEmpty
          ? Text(
              'Sin asignar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            )
          : Wrap(
              spacing: AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: activity.assigneesEmails.map((email) {
                return _AssigneeChip(email: email);
              }).toList(),
            ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  final String email;

  const _AssigneeChip({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Text(
              email.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Text(
            email.split('@').first,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatesSection extends StatelessWidget {
  final OperActivity activity;

  const _DatesSection({required this.activity});

  String _formatDate(DateTime date) {
    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${weekDays[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        activity.plannedEndAt.isBefore(DateTime.now()) &&
        activity.status != OperStatus.done &&
        activity.status != OperStatus.verified;

    return _SectionCard(
      title: 'Fechas planificadas',
      icon: Icons.calendar_today_rounded,
      child: Column(
        children: [
          _DateRow(
            label: 'Inicio',
            date: _formatDate(activity.plannedStartAt),
            icon: Icons.play_circle_outline_rounded,
            color: AppColors.success,
          ),
          const Divider(height: AppDimensions.lg),
          _DateRow(
            label: 'Fin',
            date: _formatDate(activity.plannedEndAt),
            icon: Icons.flag_outlined,
            color: isOverdue ? AppColors.error : AppColors.info,
            warning: isOverdue ? 'Vencida' : null,
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final Color color;
  final String? warning;

  const _DateRow({
    required this.label,
    required this.date,
    required this.icon,
    required this.color,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Text(
                date,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (warning != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs / 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  warning!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetadataSection extends StatelessWidget {
  final OperActivity activity;

  const _MetadataSection({required this.activity});

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Información',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _MetadataRow(label: 'Creado por', value: activity.createdByEmail),
          const SizedBox(height: AppDimensions.sm),
          _MetadataRow(
            label: 'Fecha de creación',
            value: _formatDateTime(activity.createdAt),
          ),
          const SizedBox(height: AppDimensions.sm),
          _MetadataRow(
            label: 'Última actualización',
            value: _formatDateTime(activity.updatedAt),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Evidencias
// ══════════════════════════════════════════════════════════════

class _EvidencesSection extends StatelessWidget {
  final String activityId;
  final OperActivity activity; // ✅ AGREGAR
  final VoidCallback onUpload;
  final bool uploading;
  final String? uploadError;
  final bool fullPage;

  const _EvidencesSection({
    required this.activityId,
    required this.activity, // ✅ AGREGAR
    required this.onUpload,
    required this.uploading,
    required this.uploadError,
    this.fullPage = false,
  });

  // ✅ Verificar si el usuario actual es asignado
  bool get _isCurrentUserAssigned {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return false;
    return activity.assigneesUids.contains(currentUid);
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseHelper.operActivities
          .doc(activityId)
          .collection('evidences')
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error cargando evidencias: ${snapshot.error}');
        }

        final docs = snapshot.data?.docs ?? [];
        final evidences = docs.map(OperEvidence.fromDoc).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Solo mostrar botón de upload si es asignado
            if (_isCurrentUserAssigned)
              OutlinedButton.icon(
                onPressed: uploading ? null : onUpload,
                icon: uploading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(uploading ? 'Subiendo...' : 'Subir evidencia'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              )
            else
              // Mostrar mensaje informativo si no puede subir
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 18,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Solo los responsables asignados pueden subir evidencias',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (uploadError != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        uploadError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimensions.lg),

            // Evidences grid
            if (evidences.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 48,
                        color: AppColors.textHint.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'Sin evidencias',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: fullPage ? 2 : 3,
                  crossAxisSpacing: AppDimensions.sm,
                  mainAxisSpacing: AppDimensions.sm,
                  childAspectRatio: 1,
                ),
                itemCount: evidences.length,
                itemBuilder: (context, index) {
                  return _EvidenceCard(
                    evidence: evidences[index],
                    activityId: activityId,
                    canDelete: _isCurrentUserAssigned, // ✅ Pasar permiso
                  );
                },
              ),
          ],
        );
      },
    );

    if (fullPage) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: content,
      );
    }

    return _SectionCard(
      title: 'Evidencias',
      icon: Icons.attachment_rounded,
      child: content,
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final OperEvidence evidence;
  final String activityId;
  final bool canDelete; // ✅ AGREGAR

  const _EvidenceCard({
    required this.evidence,
    required this.activityId,
    this.canDelete = false, // ✅ AGREGAR
  });

  bool get _isImage {
    final ext = evidence.fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  IconData get _fileIcon {
    final ext = evidence.fileName.split('.').last.toLowerCase();
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _openEvidence(BuildContext context) async {
    if (_isImage) {
      showDialog(
        context: context,
        builder: (context) => EvidenceViewerDialog(
          evidence: evidence,
          activityId: activityId,
          canDelete: canDelete, // ✅ Pasar permiso al viewer
        ),
      );
    } else {
      final uri = Uri.parse(evidence.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _deleteEvidence(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: const Text('Eliminar evidencia'),
        content: Text('¿Estás seguro de eliminar "${evidence.fileName}"?'),
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

    if (confirm != true) return;

    try {
      // Eliminar de Storage
      final storageRef = FirebaseStorage.instance.ref(evidence.storagePath);
      await storageRef.delete();

      // Eliminar de Firestore
      await FirebaseHelper.operActivities
          .doc(activityId)
          .collection('evidences')
          .doc(evidence.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Evidencia eliminada'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: () => _openEvidence(context),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Expanded(
                  child: _isImage
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusMd - 1),
                          ),
                          child: Image.network(
                            evidence.downloadUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stack) {
                              debugPrint('Error cargando imagen: $error');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      color: AppColors.textHint,
                                      size: 32,
                                    ),
                                    const SizedBox(height: AppDimensions.xs),
                                    Text(
                                      'Error',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            _fileIcon,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppDimensions.radiusMd - 1),
                    ),
                  ),
                  child: Text(
                    evidence.fileName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ Botón de eliminar (solo si tiene permiso)
        if (canDelete)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: InkWell(
                onTap: () => _deleteEvidence(context),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Comentarios
// ══════════════════════════════════════════════════════════════

class _CommentsSection extends StatelessWidget {
  final String activityId;
  final TextEditingController commentController;
  final VoidCallback onSendComment;
  final bool sending;
  final bool fullPage;

  const _CommentsSection({
    required this.activityId,
    required this.commentController,
    required this.onSendComment,
    required this.sending,
    this.fullPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Escribe un comentario...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.md,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendComment(),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            IconButton(
              onPressed: sending ? null : onSendComment,
              icon: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.lg),

        // Comments list - AHORA USANDO EL MODELO
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseHelper.operActivities
              .doc(activityId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // ✅ Agregar debug para ver errores
            if (snapshot.hasError) {
              debugPrint('Error cargando comentarios: ${snapshot.error}');
              return Center(
                child: Text(
                  'Error al cargar comentarios',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: AppColors.textHint.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'Sin comentarios',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ✅ Ahora usamos el modelo OperComment
            final comments = docs.map(OperComment.fromDoc).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _CommentItem(comment: comment);
              },
            );
          },
        ),
      ],
    );

    if (fullPage) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: content,
      );
    }

    return _SectionCard(
      title: 'Comentarios',
      icon: Icons.chat_rounded,
      child: content,
    );
  }
}

// ✅ Widget actualizado para usar OperComment
class _CommentItem extends StatelessWidget {
  final OperComment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  comment.authorInitial,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                comment.authorName,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (comment.isEdited) ...[
                const SizedBox(width: AppDimensions.xs),
                Text(
                  '(editado)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                comment.timeAgo,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            comment.text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════
// WIDGETS: Helpers
// ══════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool compact;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppDimensions.md : AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? AppDimensions.md : AppDimensions.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _CompletionCelebrationDialog extends StatefulWidget {
  final VoidCallback onDismiss;

  const _CompletionCelebrationDialog({required this.onDismiss});

  @override
  State<_CompletionCelebrationDialog> createState() =>
      _CompletionCelebrationDialogState();
}

class _CompletionCelebrationDialogState
    extends State<_CompletionCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration_rounded,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(
                '¡Excelente trabajo!',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'Has completado esta actividad exitosamente',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.lg),
              FilledButton(
                onPressed: widget.onDismiss,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('¡Genial!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Loading & Error States
// ══════════════════════════════════════════════════════════════

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.lg),
            Text(message, style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.lg),
            Text('Actividad no encontrada', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
