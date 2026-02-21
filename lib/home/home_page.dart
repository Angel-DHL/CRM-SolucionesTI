import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/role.dart';
import '../core/role_access.dart';
import '../admin/create_user_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserRole? _role;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Forzar refresh para traer custom claims actualizados
      final token = await user.getIdTokenResult(true);
      final claimRole = token.claims?['role'] as String?;
      setState(() {
        _role = UserRole.fromClaim(claimRole);
      });
    } catch (_) {
      setState(
        () => _error = 'No se pudo cargar el rol. Intenta reiniciar sesión.',
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inicio')),
        body: Center(child: Text(_error!)),
      );
    }

    final role = _role ?? UserRole.soporteTecnico;
    final modules = RoleAccess.allModules
        .where((m) => RoleAccess.canAccess(role, m))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel - ${role.label}'),
        actions: [
          IconButton(
            tooltip: 'Refrescar rol',
            onPressed: _loadRole,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (role == UserRole.admin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateUserPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Crear usuario'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final crossAxisCount = w < 520 ? 2 : (w < 900 ? 3 : 4);

                      return GridView.builder(
                        itemCount: modules.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemBuilder: (context, i) {
                          final m = modules[i];
                          return _ModuleCard(
                            title: m.title,
                            icon: _iconForModule(m),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Abrir módulo: ${m.title} (pendiente)',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForModule(AppModule m) {
    switch (m) {
      case AppModule.operatividad:
        return Icons.dashboard_customize_outlined;
      case AppModule.ventas:
        return Icons.point_of_sale_outlined;
      case AppModule.inventario:
        return Icons.inventory_2_outlined;
      case AppModule.marketing:
        return Icons.campaign_outlined;
      case AppModule.soporte:
        return Icons.support_agent_outlined;
      case AppModule.proyectos:
        return Icons.account_tree_outlined;
    }
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: cs.primary),
              const Spacer(),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Acceder',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
