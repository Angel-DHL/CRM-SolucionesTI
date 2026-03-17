import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } catch (_) {
      setState(() => _error = 'Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'No se pudo iniciar sesión (${e.code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDesktop ? AppColors.heroGradient : null,
          color: isDesktop ? null : AppColors.background,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: Responsive.horizontalPadding(context),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginCard(isMobile, isDesktop),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isMobile, bool isDesktop) {
    return Container(
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
      child: Card(
        elevation: isDesktop ? 8 : 0,
        shadowColor: AppColors.primaryDark.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isMobile ? AppDimensions.radiusLg : AppDimensions.radiusXl,
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(
            isMobile ? AppDimensions.lg : AppDimensions.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isMobile),
              SizedBox(height: isMobile ? AppDimensions.lg : AppDimensions.xl),
              if (_error != null) ...[
                _ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: AppDimensions.md),
              ],
              _buildLoginForm(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        // Logo/Icono animado
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Container(
            width: isMobile ? 80 : 96,
            height: isMobile ? 80 : 96,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: isMobile ? 40 : 48,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isMobile ? AppDimensions.md : AppDimensions.lg),

        // Título
        Text(
          'Bienvenido',
          style: isMobile
              ? AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                )
              : AppTextStyles.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.xs),

        // Subtítulo
        Text(
          'CRM Soluciones TI',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Inicia sesión para continuar',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de correo
          _AnimatedInputField(
            delay: 100,
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'tu@empresa.com',
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
                    size: AppDimensions.iconMd,
                  ),
                ),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Ingresa tu correo';
                final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
                if (!ok) return 'Correo inválido';
                return null;
              },
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Campo de contraseña
          _AnimatedInputField(
            delay: 200,
            child: TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: '••••••••',
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
                    size: AppDimensions.iconMd,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                  ),
                  tooltip: _obscure
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                ),
              ),
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return 'Ingresa tu contraseña';
                if (value.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
              onFieldSubmitted: (_) => _login(),
            ),
          ),

          SizedBox(height: isMobile ? AppDimensions.lg : AppDimensions.xl),

          // Botón de login
          _AnimatedInputField(
            delay: 300,
            child: SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _loading ? null : _login,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: _loading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          ),

          // Información adicional
          const SizedBox(height: AppDimensions.lg),
          _AnimatedInputField(
            delay: 400,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    Text(
                      'Acceso solo para usuarios autorizados',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Error Banner Mejorado
// ══════════════════════════════════════════════════════════════

class _ErrorBanner extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  State<_ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<_ErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(
                  widget.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                tooltip: 'Cerrar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Campo de Input Animado
// ══════════════════════════════════════════════════════════════

class _AnimatedInputField extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedInputField({required this.child, this.delay = 0});

  @override
  State<_AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<_AnimatedInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
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
