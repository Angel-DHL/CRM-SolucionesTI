import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/services/storage_service.dart';
import '../core/firebase_helper.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _user = FirebaseAuth.instance.currentUser;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _loading = false;
  bool _photoLoading = false;
  String? _photoUrl;
  Uint8List? _pickedImageBytes;

  // Preferences (UI only)
  String _selectedTheme = 'light';
  bool _notifOperatividad = true;
  bool _notifVentas = true;
  bool _notifProyectos = true;
  bool _notifSoporte = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _photoUrl = _user?.photoURL;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseHelper.db.collection('users').doc(_user.uid).get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          _firstNameCtrl.text = d['firstName'] ?? _user.displayName?.split(' ').first ?? '';
          _lastNameCtrl.text = d['lastName'] ?? '';
          _phoneCtrl.text = d['phone'] ?? '';
          _jobTitleCtrl.text = d['jobTitle'] ?? '';
          _selectedTheme = d['theme'] ?? 'light';
          _notifOperatividad = d['notif_operatividad'] ?? true;
          _notifVentas = d['notif_ventas'] ?? true;
          _notifProyectos = d['notif_proyectos'] ?? true;
          _notifSoporte = d['notif_soporte'] ?? true;
        });
      } else {
        _firstNameCtrl.text = _user.displayName?.split(' ').first ?? '';
        if ((_user.displayName ?? '').contains(' ')) {
          _lastNameCtrl.text = _user.displayName!.split(' ').skip(1).join(' ');
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (img == null) return;
      final bytes = await img.readAsBytes();
      setState(() { _pickedImageBytes = bytes; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
      await _user?.updateDisplayName(fullName);

      // Upload photo if picked
      if (_pickedImageBytes != null) {
        setState(() => _photoLoading = true);
        final url = await StorageService.instance.uploadProfilePhoto(_pickedImageBytes!);
        setState(() { _photoUrl = url; _pickedImageBytes = null; _photoLoading = false; });
      }

      // Save to Firestore
      await FirebaseHelper.db.collection('users').doc(_user!.uid).set({
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'jobTitle': _jobTitleCtrl.text.trim(),
        'photoURL': _photoUrl ?? '',
        'theme': _selectedTheme,
        'notif_operatividad': _notifOperatividad,
        'notif_ventas': _notifVentas,
        'notif_proyectos': _notifProyectos,
        'notif_soporte': _notifSoporte,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil actualizado'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPwCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')));
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = EmailAuthProvider.credential(email: _user!.email!, password: _currentPwCtrl.text);
      await _user.reauthenticateWithCredential(cred);
      await _user.updatePassword(_newPwCtrl.text);
      _currentPwCtrl.clear(); _newPwCtrl.clear(); _confirmPwCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Contraseña actualizada'), backgroundColor: AppColors.success));
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.code == 'wrong-password' ? 'Contraseña actual incorrecta' : 'Error: ${e.message}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _phoneCtrl.dispose(); _jobTitleCtrl.dispose();
    _currentPwCtrl.dispose(); _newPwCtrl.dispose(); _confirmPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(icon: Icon(Icons.person_rounded), text: 'Mi Perfil'),
          Tab(icon: Icon(Icons.lock_rounded), text: 'Seguridad'),
          Tab(icon: Icon(Icons.tune_rounded), text: 'Preferencias'),
        ]),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildProfileTab(),
        _buildSecurityTab(),
        _buildPreferencesTab(),
      ]),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(children: [
        // Avatar
        Stack(alignment: Alignment.bottomRight, children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 64,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: _pickedImageBytes != null
                  ? MemoryImage(_pickedImageBytes!)
                  : (_photoUrl != null && _photoUrl!.isNotEmpty ? NetworkImage(_photoUrl!) : null),
              child: (_pickedImageBytes == null && (_photoUrl == null || _photoUrl!.isEmpty))
                  ? Text((_user?.email ?? 'U').substring(0, 1).toUpperCase(),
                      style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary, fontSize: 48))
                  : null,
            ),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 3)),
            child: IconButton(icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20), onPressed: _pickImage, iconSize: 20,
              padding: const EdgeInsets.all(8), constraints: const BoxConstraints()),
          ),
        ]),
        if (_photoLoading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        const SizedBox(height: 8),
        Text(_user?.email ?? '', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppDimensions.xl),

        // Form card
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
          child: Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Información Personal', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.lg),
            Row(children: [
              Expanded(child: TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)))),
              const SizedBox(width: AppDimensions.md),
              Expanded(child: TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Apellido', prefixIcon: Icon(Icons.person_outline)))),
            ]),
            const SizedBox(height: AppDimensions.md),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone),
            const SizedBox(height: AppDimensions.md),
            TextField(controller: _jobTitleCtrl, decoration: const InputDecoration(labelText: 'Cargo / Puesto', prefixIcon: Icon(Icons.work_outline_rounded))),
            const SizedBox(height: AppDimensions.xl),
            SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(
              onPressed: _loading ? null : _saveProfile,
              icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
              label: const Text('Guardar Cambios'),
            )),
          ]))),
      ]))),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(children: [
        // Account info
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
          child: Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cuenta', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.md),
            ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Correo electrónico'), subtitle: Text(_user?.email ?? ''),
              contentPadding: EdgeInsets.zero),
            ListTile(leading: const Icon(Icons.access_time_rounded), title: const Text('Cuenta creada'),
              subtitle: Text(_user?.metadata.creationTime?.toString().split('.').first ?? 'N/A'), contentPadding: EdgeInsets.zero),
            ListTile(leading: const Icon(Icons.login_rounded), title: const Text('Último acceso'),
              subtitle: Text(_user?.metadata.lastSignInTime?.toString().split('.').first ?? 'N/A'), contentPadding: EdgeInsets.zero),
          ]))),
        const SizedBox(height: AppDimensions.lg),

        // Change password
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
          child: Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cambiar Contraseña', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.lg),
            TextField(controller: _currentPwCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: AppDimensions.md),
            TextField(controller: _newPwCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña', prefixIcon: Icon(Icons.lock_rounded))),
            const SizedBox(height: AppDimensions.md),
            TextField(controller: _confirmPwCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_rounded))),
            const SizedBox(height: AppDimensions.xl),
            SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(
              onPressed: _loading ? null : _changePassword,
              icon: const Icon(Icons.security_rounded),
              label: const Text('Cambiar Contraseña'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
            )),
          ]))),
      ]))),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(children: [
        // Theme
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
          child: Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Apariencia', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.md),
            ...['light', 'dark', 'auto'].map((t) => RadioListTile<String>(
              value: t, groupValue: _selectedTheme, onChanged: (v) => setState(() => _selectedTheme = v!),
              title: Text(t == 'light' ? '☀️ Claro' : t == 'dark' ? '🌙 Oscuro' : '🔄 Automático'),
              subtitle: Text(t == 'light' ? 'Tema claro predeterminado' : t == 'dark' ? 'Tema oscuro' : 'Según el sistema'),
              contentPadding: EdgeInsets.zero,
            )),
          ]))),
        const SizedBox(height: AppDimensions.lg),

        // Notifications
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
          child: Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notificaciones', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.md),
            SwitchListTile(title: const Text('Operatividad'), subtitle: const Text('Actividades y tareas'),
              value: _notifOperatividad, onChanged: (v) => setState(() => _notifOperatividad = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Ventas'), subtitle: const Text('Cotizaciones y pedidos'),
              value: _notifVentas, onChanged: (v) => setState(() => _notifVentas = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Proyectos'), subtitle: const Text('Tareas y transacciones'),
              value: _notifProyectos, onChanged: (v) => setState(() => _notifProyectos = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Soporte'), subtitle: const Text('Casos y tickets'),
              value: _notifSoporte, onChanged: (v) => setState(() => _notifSoporte = v), contentPadding: EdgeInsets.zero),
          ]))),
        const SizedBox(height: AppDimensions.lg),

        // Language
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
          child: Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Idioma y Región', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.md),
            ListTile(leading: const Icon(Icons.language_rounded), title: const Text('Idioma'),
              trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                child: Text('Español', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary))),
              contentPadding: EdgeInsets.zero),
            ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('Zona horaria'),
              trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                child: Text('America/Mexico_City', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary))),
              contentPadding: EdgeInsets.zero),
          ]))),
        const SizedBox(height: AppDimensions.xl),

        SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(
          onPressed: _loading ? null : _saveProfile,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Guardar Preferencias'),
        )),
      ]))),
    );
  }
}
