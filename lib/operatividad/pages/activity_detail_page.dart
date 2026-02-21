import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/oper_activity.dart';
import '../models/oper_evidence.dart';

class ActivityDetailPage extends StatefulWidget {
  final String activityId;
  const ActivityDetailPage({super.key, required this.activityId});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  bool _uploading = false;
  String? _uploadError;

  DocumentReference<Map<String, dynamic>> get _ref => FirebaseFirestore.instance
      .collection('oper_activities')
      .doc(widget.activityId);

  bool get _isAdminRole {
    // Ojo: esto en UI es solo para UX; seguridad real está en Rules.
    // Si quieres, lo leemos de claims, pero aquí simplifico.
    return false;
  }

  Future<void> _setWorkStart(OperActivity a) async {
    await _ref.update({
      'workStartAt': FieldValue.serverTimestamp(),
      'status': OperStatus.inProgress.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _setWorkEnd(OperActivity a) async {
    await _ref.update({
      'workEndAt': FieldValue.serverTimestamp(),
      'actualEndAt': FieldValue.serverTimestamp(),
      'status': OperStatus.done.value,
      'progress': 100,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateStatus(OperStatus status) async {
    await _ref.update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateProgress(int value) async {
    await _ref.update({
      'progress': value.clamp(0, 100),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _uploadEvidence(OperActivity a) async {
    setState(() {
      _uploadError = null;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final email = FirebaseAuth.instance.currentUser!.email ?? '';

    final res = await FilePicker.platform.pickFiles(
      withData: true, // Important for web: bytes come here
      allowMultiple: false,
    );
    if (res == null) return;
    final f = res.files.single;

    final Uint8List? bytes = f.bytes;
    final fileName = f.name;

    if (bytes == null) {
      setState(
        () => _uploadError = 'No se pudieron obtener bytes del archivo.',
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final storagePath = 'operatividad/${a.id}/$uid/$fileName';
      final ref = FirebaseStorage.instance.ref(storagePath);

      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      await _ref.collection('evidences').add({
        'fileName': fileName,
        'storagePath': storagePath,
        'downloadUrl': url,
        'uploadedByUid': uid,
        'uploadedByEmail': email,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      // marca actualización
      await _ref.update({'updatedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Evidencia subida ✅')));
    } catch (e) {
      setState(() => _uploadError = 'Error subiendo evidencia: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ref.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Actividad no encontrada.')),
          );
        }

        final a = OperActivity.fromDoc(snap.data!);

        return Scaffold(
          appBar: AppBar(title: const Text('Detalle de actividad')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    a.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.description.isEmpty ? 'Sin descripción' : a.description,
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Pill(label: 'Estado: ${a.status.label}'),
                      _Pill(label: 'Progreso: ${a.progress}%'),
                      _Pill(
                        label: 'Responsables: ${a.assigneesEmails.join(', ')}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Acciones',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),

                          // Start / End work
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: (a.workStartAt == null)
                                      ? () => _setWorkStart(a)
                                      : null,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Iniciar trabajo'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      (a.workStartAt != null &&
                                          a.workEndAt == null)
                                      ? () => _setWorkEnd(a)
                                      : null,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Finalizar trabajo'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Status dropdown
                          DropdownButtonFormField<OperStatus>(
                            value: a.status,
                            decoration: const InputDecoration(
                              labelText: 'Cambiar estado',
                              border: OutlineInputBorder(),
                            ),
                            items: OperStatus.values
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              _updateStatus(v);
                            },
                          ),

                          const SizedBox(height: 10),

                          // Progress slider
                          Row(
                            children: [
                              const Text('Progreso'),
                              Expanded(
                                child: Slider(
                                  value: a.progress.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 20,
                                  label: '${a.progress}%',
                                  onChanged: (v) => _updateProgress(v.round()),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Evidence upload
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _uploading
                                  ? null
                                  : () => _uploadEvidence(a),
                              icon: _uploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.attach_file),
                              label: Text(
                                _uploading ? 'Subiendo...' : 'Anexar evidencia',
                              ),
                            ),
                          ),

                          if (_uploadError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _uploadError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Evidences list
                  _EvidencesList(activityId: a.id),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EvidencesList extends StatelessWidget {
  final String activityId;
  const _EvidencesList({required this.activityId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('oper_activities')
        .doc(activityId);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref
          .collection('evidences')
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final docs = snap.data!.docs;
        final items = docs.map(OperEvidence.fromDoc).toList();

        if (items.isEmpty) {
          return const Text('Sin evidencias.');
        }

        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evidencias',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (e) => ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(e.fileName),
                    subtitle: Text('Subido por: ${e.uploadedByEmail}'),
                    trailing: IconButton(
                      tooltip: 'Abrir',
                      onPressed: () {
                        // En web/móvil abrir URL: por simplicidad lo copiamos al portapapeles o se lo muestras.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('URL: ${e.downloadUrl}')),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
