import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/role.dart';
import '../models/oper_activity.dart';
import '../widgets/gantt_view.dart';
import 'activity_detail_page.dart';
import 'admin_create_activity_page.dart';

class OperatividadPage extends StatefulWidget {
  const OperatividadPage({super.key});

  @override
  State<OperatividadPage> createState() => _OperatividadPageState();
}

class _OperatividadPageState extends State<OperatividadPage> {
  UserRole? _role;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdTokenResult(true);
    final claimRole = token.claims?['role'] as String?;
    setState(() {
      _role = UserRole.fromClaim(claimRole);
      _loadingRole = false;
    });
  }

  Query<Map<String, dynamic>> _baseQuery(UserRole role) {
    final col = FirebaseFirestore.instance.collection('oper_activities');

    // Admin: ve todo. No-admin: solo asignadas.
    if (role == UserRole.admin) {
      return col.orderBy('plannedStartAt', descending: false);
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return col
        .where('assigneesUids', arrayContains: uid)
        .orderBy('plannedStartAt');
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = _role ?? UserRole.soporteTecnico;

    return DefaultTabController(
      length: role == UserRole.admin ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Operatividad'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Planificador'),
              const Tab(text: 'Mis actividades'),
              if (role == UserRole.admin) const Tab(text: 'Asignar'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _baseQuery(role).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            final docs = snap.data?.docs ?? const [];
            final activities = docs.map(OperActivity.fromDoc).toList();

            return TabBarView(
              children: [
                // Planificador (Gantt)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: GanttView(
                    activities: activities,
                    onTapActivity: (a) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailPage(activityId: a.id),
                      ),
                    ),
                  ),
                ),

                // Mis actividades (lista)
                _MyActivitiesList(
                  role: role,
                  activities: activities.where((a) {
                    if (role == UserRole.admin) return true;
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    return a.assigneesUids.contains(uid);
                  }).toList(),
                ),

                if (role == UserRole.admin)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AdminCreateActivityPage(
                          onCreated: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Actividad creada ✅'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MyActivitiesList extends StatelessWidget {
  final UserRole role;
  final List<OperActivity> activities;

  const _MyActivitiesList({required this.role, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(child: Text('No hay actividades asignadas.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = activities[i];
        return _ActivityTile(
          a: a,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActivityDetailPage(activityId: a.id),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final OperActivity a;
  final VoidCallback onTap;

  const _ActivityTile({required this.a, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color badgeColor(OperStatus s) => switch (s) {
      OperStatus.planned => cs.secondaryContainer,
      OperStatus.inProgress => Colors.orange.shade200,
      OperStatus.done => Colors.green.shade200,
      OperStatus.verified => Colors.teal.shade200,
      OperStatus.blocked => Colors.red.shade200,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.assigneesEmails.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (a.progress.clamp(0, 100)) / 100,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor(a.status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  a.status.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
