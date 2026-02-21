import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/oper_activity.dart';

class AdminCreateActivityPage extends StatefulWidget {
  final VoidCallback onCreated;
  const AdminCreateActivityPage({super.key, required this.onCreated});

  @override
  State<AdminCreateActivityPage> createState() =>
      _AdminCreateActivityPageState();
}

class _AdminCreateActivityPageState extends State<AdminCreateActivityPage> {
  // 🔥 MISMA base que estás usando en Firebase Console (selector)
  static const String _dbId = 'crm-solucionesti';

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: _dbId);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 2));

  final Set<String> _selectedUids = {};
  final Map<String, String> _uidToEmail = {};

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool start}) async {
    final base = start ? _start : _end;

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (start) {
        _start = dt;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = dt;
        if (_end.isBefore(_start)) {
          _start = _end.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedUids.isEmpty) {
      setState(() => _error = 'Selecciona al menos un responsable.');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final assigneesUids = _selectedUids.toList();
      final assigneesEmails = assigneesUids
          .map((u) => _uidToEmail[u] ?? u)
          .toList();

      final data = OperActivity.createMap(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        plannedStartAt: _start,
        plannedEndAt: _end,
        assigneesUids: assigneesUids,
        assigneesEmails: assigneesEmails,
        createdByUid: user.uid,
        createdByEmail: user.email ?? '',
      );

      // ✅ escribe en la MISMA base (crm-solucionesti)
      await _db.collection('oper_activities').add(data);

      _titleCtrl.clear();
      _descCtrl.clear();
      _selectedUids.clear();
      _uidToEmail.clear();

      widget.onCreated();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = 'No se pudo crear: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Asignar actividad',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_error!, style: TextStyle(color: cs.onErrorContainer)),
          ),
          const SizedBox(height: 12),
        ],

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de actividad',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _pickDateTime(start: true),
                      child: Text('Inicio: ${fmt(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _pickDateTime(start: false),
                      child: Text('Fin: ${fmt(_end)}'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _AssigneePicker(
                db: _db,
                selectedUids: _selectedUids,
                onChangeEmailMap: (uid, email) => _uidToEmail[uid] = email,
                enabled: !_loading,
                onSelectionChanged: () {
                  setState(() {}); // refresca contador/validaciones si quieres
                },
              ),

              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _create,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_task),
                  label: Text(_loading ? 'Creando...' : 'Crear actividad'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssigneePicker extends StatefulWidget {
  final FirebaseFirestore db;
  final Set<String> selectedUids;
  final void Function(String uid, String email) onChangeEmailMap;
  final bool enabled;
  final VoidCallback onSelectionChanged;

  const _AssigneePicker({
    required this.db,
    required this.selectedUids,
    required this.onChangeEmailMap,
    required this.enabled,
    required this.onSelectionChanged,
  });

  @override
  State<_AssigneePicker> createState() => _AssigneePickerState();
}

class _AssigneePickerState extends State<_AssigneePicker> {
  @override
  Widget build(BuildContext context) {
    final q = widget.db.collection('users').orderBy('email');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const LinearProgressIndicator();
        }
        if (snap.hasError) {
          return Text('Error cargando usuarios: ${snap.error}');
        }

        final docs = snap.data?.docs ?? const [];

        if (docs.isEmpty) {
          return const Text(
            'No hay usuarios en /users. Crea usuarios desde Admin.',
          );
        }

        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Responsables',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if (widget.selectedUids.isNotEmpty)
                      Text(
                        '${widget.selectedUids.length} seleccionados',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: docs.map((d) {
                    final data = d.data();
                    final uid = (data['uid'] ?? d.id).toString();
                    final email = (data['email'] ?? 'sin-email').toString();
                    widget.onChangeEmailMap(uid, email);

                    final selected = widget.selectedUids.contains(uid);

                    return FilterChip(
                      selected: selected,
                      onSelected: widget.enabled
                          ? (v) {
                              setState(() {
                                if (v) {
                                  widget.selectedUids.add(uid);
                                } else {
                                  widget.selectedUids.remove(uid);
                                }
                              });
                              widget.onSelectionChanged();
                            }
                          : null,
                      label: Text(email),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
