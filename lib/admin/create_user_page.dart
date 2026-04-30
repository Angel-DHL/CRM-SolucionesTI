import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/services/role_service.dart';
import '../core/firebase_helper.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/responsive.dart';
import '../core/role.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  Uint8List? _imageBytes;
  String? _photoUrl;

  UserRole? _role;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _result;
  String? _error;
  Map<String, dynamic>? _createdUserData;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String _region = 'us-central1';
  static const String _projectId = 'crm-solucionesti';
  static const String _functionName = 'createUserWithRoleHttp';

  Uri get _endpoint => Uri.parse(
    'https://$_region-$_projectId.cloudfunctions.net/$_functionName',
  );

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final password = _passwordCtrl.text;
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.1;
    return strength.clamp(0.0, 1.0);
  }

  Color get _passwordStrengthColor {
    final strength = _passwordStrength;
    if (strength < 0.3) return AppColors.error;
    if (strength < 0.6) return AppColors.warning;
    return AppColors.success;
  }

  String get _passwordStrengthText {
    final strength = _passwordStrength;
    if (strength == 0) return '';
    if (strength < 0.3) return 'Débil';
    if (strength < 0.6) return 'Media';
    if (strength < 0.8) return 'Buena';
    return 'Fuerte';
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    setState(() {
      _role = null;
      _result = null;
      _error = null;
      _createdUserData = null;
      _imageBytes = null;
      _photoUrl = null;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
      });
    }
  }

  Future<String?> _uploadImage(String email) async {
    if (_imageBytes == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${email}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = ref.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _result = null;
      _createdUserData = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'No autenticado. Inicia sesión de nuevo.');
      return;
    }

    if (_role == null) {
      setState(() => _error = 'Por favor selecciona un rol para el usuario');
      return;
    }

    setState(() => _loading = true);
    try {
      final idToken = await user.getIdToken(true);

      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passwordCtrl.text;
      final roleClaim = _role!.claim;
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();

      // Subir imagen primero si existe
      _photoUrl = await _uploadImage(email);

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
          'firstName': firstName,
          'lastName': lastName,
          'photoURL': _photoUrl,
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _createdUserData = data;
          _result = 'Usuario creado exitosamente';
        });

        // Haptic feedback en móvil
        HapticFeedback.mediumImpact();
        return;
      }

      // Intentar parsear error JSON
      try {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final err = decoded['error'] as Map<String, dynamic>?;
        if (err != null) {
          setState(() => _error = '${err['message']}');
          return;
        }
      } catch (_) {}

      setState(() => _error = 'Error HTTP ${resp.statusCode}');
    } catch (e) {
      setState(() => _error = 'Error de conexión. Verifica tu red.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isMobile),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(
                isMobile ? AppDimensions.md : AppDimensions.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 600),
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isMobile) {
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
        tooltip: 'Volver',
      ),
      title: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear usuario',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isMobile)
                Text(
                  'Panel de administración',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (_result != null || _error != null)
          IconButton(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Limpiar formulario',
            color: AppColors.textSecondary,
          ),
        const SizedBox(width: AppDimensions.sm),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formulario
        Expanded(flex: 3, child: _buildFormCard()),
        const SizedBox(width: AppDimensions.xl),
        // Panel lateral
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildPreviewCard(),
              const SizedBox(height: AppDimensions.lg),
              _buildTipsCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Banners de estado
        if (_error != null) ...[
          _AnimatedBanner(
            type: _BannerType.error,
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),
          const SizedBox(height: AppDimensions.md),
        ],
        if (_result != null && _createdUserData != null) ...[
          _SuccessCard(
            userData: _createdUserData!,
            onCreateAnother: _resetForm,
          ),
          const SizedBox(height: AppDimensions.md),
        ],
        if (_result == null) _buildFormCard(),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del formulario
              _FormHeader(),
              const SizedBox(height: AppDimensions.xl),

              // Banners (solo en desktop)
              if (Responsive.isDesktop(context)) ...[
                if (_error != null) ...[
                  _AnimatedBanner(
                    type: _BannerType.error,
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ),
                  const SizedBox(height: AppDimensions.md),
                ],
                if (_result != null && _createdUserData != null) ...[
                  _AnimatedBanner(
                    type: _BannerType.success,
                    message: _result!,
                    onDismiss: _resetForm,
                  ),
                  const SizedBox(height: AppDimensions.md),
                ],
              ],

              // Foto de Perfil
              _AnimatedFormField(delay: 50, child: _buildImageSelector()),
              const SizedBox(height: AppDimensions.lg),

              // Nombre y Apellido
              _AnimatedFormField(delay: 75, child: _buildNameFields()),
              const SizedBox(height: AppDimensions.lg),

              // Campo de email
              _AnimatedFormField(delay: 100, child: _buildEmailField()),
              const SizedBox(height: AppDimensions.lg),

              // Campo de contraseña
              _AnimatedFormField(delay: 200, child: _buildPasswordField()),
              const SizedBox(height: AppDimensions.lg),

              // Selector de rol
              _AnimatedFormField(delay: 300, child: _buildRoleSelector()),
              const SizedBox(height: AppDimensions.xl),

              // Botón de crear
              _AnimatedFormField(delay: 400, child: _buildSubmitButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo electrónico',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        TextFormField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_loading,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'colaborador@empresa.com',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppDimensions.sm),
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return 'Ingresa el correo del colaborador';
            final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
            if (!ok) return 'Correo inválido';
            return null;
          },
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contraseña temporal',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (_passwordStrengthText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: _passwordStrengthColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  _passwordStrengthText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _passwordStrengthColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        TextFormField(
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          enabled: !_loading,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Mínimo 6 caracteres',
            prefixIcon: Container(
              margin: const EdgeInsets.all(AppDimensions.sm),
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textHint,
              ),
              tooltip: _obscurePassword
                  ? 'Mostrar contraseña'
                  : 'Ocultar contraseña',
            ),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            final value = v ?? '';
            if (value.isEmpty) return 'Ingresa una contraseña';
            if (value.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
        ),
        if (_passwordCtrl.text.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.sm),
          _PasswordStrengthIndicator(strength: _passwordStrength),
        ],
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol del usuario',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        StreamBuilder<List<UserRole>>(
          stream: RoleService.rolesStream,
          builder: (context, snapshot) {
            final roles = snapshot.data ?? [];
            if (roles.isEmpty) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              return Text(
                'No hay roles definidos. Ve a Gestión de Roles.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              );
            }
            
            // Inicializar _role si es nulo
            if (_role == null && roles.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _role == null) {
                  setState(() => _role = roles.first);
                }
              });
            }

            final currentRole = roles.any((r) => r.id == _role?.id) 
                ? roles.firstWhere((r) => r.id == _role?.id) 
                : roles.first;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserRole>(
                  value: currentRole,
                  isExpanded: true,
                  items: roles.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.label),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _role = v);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
            child: _imageBytes == null
                ? Icon(Icons.person_outline_rounded, size: 40, color: AppColors.primary)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nombre(s)', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _firstNameCtrl,
                focusNode: _firstNameFocus,
                textInputAction: TextInputAction.next,
                enabled: !_loading,
                decoration: const InputDecoration(hintText: 'Ej: Juan'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apellido(s)', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _lastNameCtrl,
                focusNode: _lastNameFocus,
                textInputAction: TextInputAction.next,
                enabled: !_loading,
                decoration: const InputDecoration(hintText: 'Ej: Pérez'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _loading ? null : _create,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          elevation: _loading ? 0 : 2,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: _loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Text(
                    'Creando usuario...',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_rounded, size: 20),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    'Crear usuario',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final email = _emailCtrl.text.trim();
    final hasEmail = email.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Vista previa',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
            // Avatar preview
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      hasEmail ? email.substring(0, 1).toUpperCase() : '?',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    hasEmail ? email : 'usuario@ejemplo.com',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: hasEmail
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(_role ?? UserRole.soporteTecnico).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      border: Border.all(
                        color: _getRoleColor(_role ?? UserRole.soporteTecnico).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(_role ?? UserRole.soporteTecnico),
                          size: 14,
                          color: _getRoleColor(_role ?? UserRole.soporteTecnico),
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        Text(
                          _role?.label ?? 'Selecciona un rol',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _getRoleColor(_role ?? UserRole.soporteTecnico),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      elevation: 0,
      color: AppColors.infoLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.info.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Consejos',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            _TipItem(
              icon: Icons.key_rounded,
              text: 'La contraseña es temporal, el usuario debe cambiarla.',
            ),
            const SizedBox(height: AppDimensions.sm),
            _TipItem(
              icon: Icons.security_rounded,
              text: 'Los roles definen qué módulos puede acceder.',
            ),
            const SizedBox(height: AppDimensions.sm),
            _TipItem(
              icon: Icons.email_rounded,
              text: 'Usa correos corporativos para mejor control.',
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    if (role.id == 'admin') return AppColors.error;
    if (role.id == 'soporte_sistemas') return AppColors.success;
    return AppColors.info;
  }

  IconData _getRoleIcon(UserRole role) {
    if (role.id == 'admin') return Icons.admin_panel_settings_rounded;
    if (role.id == 'soporte_sistemas') return Icons.point_of_sale_rounded;
    return Icons.support_agent_rounded;
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Form Header
// ══════════════════════════════════════════════════════════════

class _FormHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo colaborador',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Complete los datos para crear la cuenta',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),
        const Divider(),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Password Strength Indicator
// ══════════════════════════════════════════════════════════════

class _PasswordStrengthIndicator extends StatelessWidget {
  final double strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AppDimensions.animFast,
      tween: Tween(begin: 0, end: strength),
      builder: (context, value, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              value < 0.3
                  ? AppColors.error
                  : value < 0.6
                  ? AppColors.warning
                  : AppColors.success,
            ),
            minHeight: 4,
          ),
        );
      },
    );
  }
}


// ══════════════════════════════════════════════════════════════
// WIDGET: Animated Banner
// ══════════════════════════════════════════════════════════════

enum _BannerType { success, error }

class _AnimatedBanner extends StatefulWidget {
  final _BannerType type;
  final String message;
  final VoidCallback onDismiss;

  const _AnimatedBanner({
    required this.type,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDimensions.animNormal,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.type == _BannerType.success;
    final color = isSuccess ? AppColors.success : AppColors.error;
    final bgColor = isSuccess ? AppColors.successLight : AppColors.errorLight;
    final icon = isSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(
                widget.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onDismiss,
              icon: Icon(Icons.close_rounded, color: color, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Success Card
// ══════════════════════════════════════════════════════════════

class _SuccessCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onCreateAnother;

  const _SuccessCard({required this.userData, required this.onCreateAnother});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.successLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.success.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          children: [
            // Icon success
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            Text(
              '¡Usuario creado exitosamente!',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.lg),

            // User info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'UID',
                    value: userData['uid'] ?? '-',
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: userData['email'] ?? '-',
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  _InfoRow(
                    icon: Icons.security_outlined,
                    label: 'Rol',
                    value: userData['role'] ?? '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            // Botón crear otro
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreateAnother,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear otro usuario'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: AppDimensions.sm),
        Text(
          '$label:',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Tip Item
// ══════════════════════════════════════════════════════════════

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.info),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.info,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Animated Form Field
// ══════════════════════════════════════════════════════════════

class _AnimatedFormField extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedFormField({required this.child, this.delay = 0});

  @override
  State<_AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<_AnimatedFormField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
