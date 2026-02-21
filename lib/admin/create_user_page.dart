import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/role.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  UserRole _role = UserRole.soporteTecnico;
  bool _loading = false;
  String? _result;
  String? _error;

  static const String _region = 'us-central1';
  static const String _projectId = 'crm-solucionesti';
  static const String _functionName = 'createUserWithRoleHttp';

  Uri get _endpoint => Uri.parse(
    'https://$_region-$_projectId.cloudfunctions.net/$_functionName',
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _result = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'No autenticado. Inicia sesión de nuevo.');
      return;
    }

    setState(() => _loading = true);
    try {
      final idToken = await user.getIdToken(true);

      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passwordCtrl.text;
      final roleClaim = _role.claim;

      if (kDebugMode) {
        debugPrint('POST -> $_endpoint');
        debugPrint('ADMIN UID: ${user.uid}');
      }

      final resp = await http.post(
        _endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': roleClaim,
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _result =
              'Usuario creado ✅\nUID: ${data['uid']}\nEmail: ${data['email']}\nRol: ${data['role']}';
        });
        return;
      }

      // Intentar parsear error JSON
      try {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final err = decoded['error'] as Map<String, dynamic>?;
        if (err != null) {
          setState(
            () => _error = 'Error (${err['status']}): ${err['message']}',
          );
          return;
        }
      } catch (_) {}

      setState(() => _error = 'HTTP ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear usuario')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_error != null) ...[
                  _Banner(
                    text: _error!,
                    bg: cs.errorContainer,
                    fg: cs.onErrorContainer,
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_result != null) ...[
                  _Banner(
                    text: _result!,
                    bg: cs.primaryContainer,
                    fg: cs.onPrimaryContainer,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email del colaborador',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Ingresa el email.';
                          final ok = RegExp(
                            r'^[^@]+@[^@]+\.[^@]+$',
                          ).hasMatch(value);
                          if (!ok) return 'Email inválido.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña temporal (mínimo 6)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.length < 6) return 'Mínimo 6 caracteres.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        value: _role,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                        ),
                        items: UserRole.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _role = v!),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _create,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(
                            _loading ? 'Creando...' : 'Crear usuario',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData icon;

  const _Banner({
    required this.text,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: fg)),
          ),
        ],
      ),
    );
  }
}
