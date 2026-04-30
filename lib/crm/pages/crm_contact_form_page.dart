// lib/crm/pages/crm_contact_form_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/crm_contact.dart';
import '../models/crm_enums.dart';
import '../services/crm_service.dart';

class CrmContactFormPage extends StatefulWidget {
  final CrmContact? contact; // null = crear, != null = editar

  const CrmContactFormPage({super.key, this.contact});

  @override
  State<CrmContactFormPage> createState() => _CrmContactFormPageState();
}

class _CrmContactFormPageState extends State<CrmContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get _isEditing => widget.contact != null;

  // Personal
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();

  // Empresa
  final _empresaCtrl = TextEditingController();
  final _industriaCtrl = TextEditingController();
  final _sitioWebCtrl = TextEditingController();
  CompanySize? _tamanoEmpresa;

  // Fiscal
  final _rfcCtrl = TextEditingController();
  final _razonSocialCtrl = TextEditingController();
  String? _regimenFiscal;
  String? _usoCfdi;

  // Dirección
  final _direccionCtrl = TextEditingController();
  final _coloniaCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  final _paisCtrl = TextEditingController();

  // Gestión
  ContactStatus _status = ContactStatus.lead;
  ContactSource _source = ContactSource.otro;
  ContactPriority? _prioridad;
  final _valorCtrl = TextEditingController();
  final _interesCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  // Secciones colapsables
  bool _showEmpresa = false;
  bool _showFiscal = false;
  bool _showDireccion = false;

  @override
  void initState() {
    super.initState();
    _paisCtrl.text = 'México';
    if (_isEditing) _loadContact();
  }

  void _loadContact() {
    final c = widget.contact!;
    _nombreCtrl.text = c.nombre;
    _apellidosCtrl.text = c.apellidos;
    _emailCtrl.text = c.email;
    _telefonoCtrl.text = c.telefono;
    _cargoCtrl.text = c.cargo ?? '';
    _empresaCtrl.text = c.empresa ?? '';
    _industriaCtrl.text = c.industria ?? '';
    _sitioWebCtrl.text = c.sitioWeb ?? '';
    _tamanoEmpresa = c.tamanoEmpresa;
    _rfcCtrl.text = c.rfc ?? '';
    _razonSocialCtrl.text = c.razonSocial ?? '';
    _regimenFiscal = c.regimenFiscal;
    _usoCfdi = c.usoCfdi;
    _direccionCtrl.text = c.direccion ?? '';
    _coloniaCtrl.text = c.colonia ?? '';
    _ciudadCtrl.text = c.ciudad ?? '';
    _estadoCtrl.text = c.estado ?? '';
    _cpCtrl.text = c.codigoPostal ?? '';
    _paisCtrl.text = c.pais ?? 'México';
    _status = c.status;
    _source = c.source;
    _prioridad = c.prioridad;
    _valorCtrl.text = c.valorEstimado?.toStringAsFixed(2) ?? '';
    _interesCtrl.text = c.interes ?? '';
    _notasCtrl.text = c.notas ?? '';

    _showEmpresa = c.empresa != null && c.empresa!.isNotEmpty;
    _showFiscal = c.hasDatosFiscales;
    _showDireccion = c.hasDireccion;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _apellidosCtrl.dispose();
    _emailCtrl.dispose(); _telefonoCtrl.dispose();
    _cargoCtrl.dispose(); _empresaCtrl.dispose();
    _industriaCtrl.dispose(); _sitioWebCtrl.dispose();
    _rfcCtrl.dispose(); _razonSocialCtrl.dispose();
    _direccionCtrl.dispose(); _coloniaCtrl.dispose();
    _ciudadCtrl.dispose(); _estadoCtrl.dispose();
    _cpCtrl.dispose(); _paisCtrl.dispose();
    _valorCtrl.dispose(); _interesCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 20),
          ),
        ),
        title: Text(
          _isEditing ? 'Editar contacto' : 'Nuevo contacto',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    icon: Icons.person_rounded,
                    title: 'Información Personal',
                    initiallyExpanded: true,
                    alwaysExpanded: true,
                    children: [_buildPersonalFields()],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildSection(
                    icon: Icons.business_rounded,
                    title: 'Información Empresarial',
                    initiallyExpanded: _showEmpresa,
                    children: [_buildEmpresaFields()],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildSection(
                    icon: Icons.receipt_long_rounded,
                    title: 'Datos Fiscales',
                    initiallyExpanded: _showFiscal,
                    children: [_buildFiscalFields()],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildSection(
                    icon: Icons.location_on_rounded,
                    title: 'Dirección Fiscal',
                    initiallyExpanded: _showDireccion,
                    children: [_buildDireccionFields()],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildSection(
                    icon: Icons.settings_rounded,
                    title: 'Gestión Comercial',
                    initiallyExpanded: true,
                    alwaysExpanded: true,
                    children: [_buildGestionFields()],
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _buildSaveButton(),
                  const SizedBox(height: AppDimensions.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COLLAPSIBLE SECTION WRAPPER
  // ═══════════════════════════════════════════════════════════

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
    bool alwaysExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded || alwaysExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.xs),
          childrenPadding: const EdgeInsets.fromLTRB(AppDimensions.md, 0, AppDimensions.md, AppDimensions.md),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          title: Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
          trailing: alwaysExpanded ? const SizedBox.shrink() : null,
          children: children,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PERSONAL FIELDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildPersonalFields() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre *', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: TextFormField(
            controller: _apellidosCtrl,
            decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.person_outline)),
          )),
        ]),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined)),
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppDimensions.md),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _telefonoCtrl,
            decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: TextFormField(
            controller: _cargoCtrl,
            decoration: const InputDecoration(labelText: 'Cargo', prefixIcon: Icon(Icons.work_outline)),
          )),
        ]),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMPRESA FIELDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildEmpresaFields() {
    return Column(
      children: [
        TextFormField(
          controller: _empresaCtrl,
          decoration: const InputDecoration(labelText: 'Nombre de empresa', prefixIcon: Icon(Icons.business_outlined)),
        ),
        const SizedBox(height: AppDimensions.md),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _industriaCtrl,
            decoration: const InputDecoration(labelText: 'Industria / Giro', prefixIcon: Icon(Icons.category_outlined)),
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: DropdownButtonFormField<CompanySize>(
            value: _tamanoEmpresa,
            decoration: const InputDecoration(labelText: 'Tamaño', prefixIcon: Icon(Icons.groups_outlined)),
            items: CompanySize.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
            onChanged: (v) => setState(() => _tamanoEmpresa = v),
          )),
        ]),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: _sitioWebCtrl,
          decoration: const InputDecoration(labelText: 'Sitio web', prefixIcon: Icon(Icons.language_outlined)),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FISCAL FIELDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildFiscalFields() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: TextFormField(
            controller: _rfcCtrl,
            decoration: const InputDecoration(labelText: 'RFC', prefixIcon: Icon(Icons.badge_outlined)),
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final rfc = v.trim().toUpperCase();
              // RFC persona moral: 3 letras + 6 dígitos + 3 homoclave
              // RFC persona física: 4 letras + 6 dígitos + 3 homoclave
              if (rfc.length != 12 && rfc.length != 13) return 'RFC debe tener 12 o 13 caracteres';
              return null;
            },
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: TextFormField(
            controller: _razonSocialCtrl,
            decoration: const InputDecoration(labelText: 'Razón Social', prefixIcon: Icon(Icons.account_balance_outlined)),
          )),
        ]),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<String>(
          value: _regimenFiscal,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Régimen Fiscal', prefixIcon: Icon(Icons.gavel_outlined)),
          items: RegimenFiscalCatalog.options.map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _regimenFiscal = v),
        ),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<String>(
          value: _usoCfdi,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Uso de CFDI', prefixIcon: Icon(Icons.description_outlined)),
          items: UsoCfdiCatalog.options.map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _usoCfdi = v),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIRECCIÓN FIELDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildDireccionFields() {
    return Column(
      children: [
        TextFormField(
          controller: _direccionCtrl,
          decoration: const InputDecoration(labelText: 'Calle y número', prefixIcon: Icon(Icons.home_outlined)),
        ),
        const SizedBox(height: AppDimensions.md),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _coloniaCtrl,
            decoration: const InputDecoration(labelText: 'Colonia'),
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: TextFormField(
            controller: _cpCtrl,
            decoration: const InputDecoration(labelText: 'C.P.'),
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: AppDimensions.md),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _ciudadCtrl,
            decoration: const InputDecoration(labelText: 'Ciudad'),
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: TextFormField(
            controller: _estadoCtrl,
            decoration: const InputDecoration(labelText: 'Estado'),
          )),
        ]),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: _paisCtrl,
          decoration: const InputDecoration(labelText: 'País', prefixIcon: Icon(Icons.public_outlined)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GESTIÓN FIELDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildGestionFields() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: DropdownButtonFormField<ContactStatus>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Estatus', prefixIcon: Icon(Icons.flag_outlined)),
            items: ContactStatus.values.map((s) => DropdownMenuItem(value: s, child: Text('${s.emoji} ${s.label}'))).toList(),
            onChanged: (v) => setState(() => _status = v ?? ContactStatus.lead),
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: DropdownButtonFormField<ContactSource>(
            value: _source,
            decoration: const InputDecoration(labelText: 'Fuente', prefixIcon: Icon(Icons.source_outlined)),
            items: ContactSource.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
            onChanged: (v) => setState(() => _source = v ?? ContactSource.otro),
          )),
        ]),
        const SizedBox(height: AppDimensions.md),
        Row(children: [
          Expanded(child: DropdownButtonFormField<ContactPriority>(
            value: _prioridad,
            decoration: const InputDecoration(labelText: 'Prioridad', prefixIcon: Icon(Icons.priority_high_rounded)),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sin prioridad')),
              ...ContactPriority.values.map((p) => DropdownMenuItem(value: p, child: Text('${p.emoji} ${p.label}'))),
            ],
            onChanged: (v) => setState(() => _prioridad = v),
          )),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: TextFormField(
            controller: _valorCtrl,
            decoration: const InputDecoration(labelText: 'Valor estimado (\$)', prefixIcon: Icon(Icons.attach_money_rounded)),
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: _interesCtrl,
          decoration: const InputDecoration(labelText: 'Servicio / Producto de interés', prefixIcon: Icon(Icons.star_outline_rounded)),
        ),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: _notasCtrl,
          decoration: const InputDecoration(labelText: 'Notas', prefixIcon: Icon(Icons.notes_rounded), alignLabelWithHint: true),
          maxLines: 3,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SAVE BUTTON
  // ═══════════════════════════════════════════════════════════

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _save,
        icon: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_isEditing ? Icons.save_rounded : Icons.person_add_rounded),
        label: Text(_isEditing ? 'Guardar cambios' : 'Crear contacto'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SAVE LOGIC
  // ═══════════════════════════════════════════════════════════

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

      final contact = CrmContact(
        id: widget.contact?.id ?? '',
        status: _status,
        source: _source,
        nombre: _nombreCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        cargo: nullIfEmpty(_cargoCtrl.text),
        empresa: nullIfEmpty(_empresaCtrl.text),
        industria: nullIfEmpty(_industriaCtrl.text),
        sitioWeb: nullIfEmpty(_sitioWebCtrl.text),
        tamanoEmpresa: _tamanoEmpresa,
        rfc: nullIfEmpty(_rfcCtrl.text)?.toUpperCase(),
        razonSocial: nullIfEmpty(_razonSocialCtrl.text),
        regimenFiscal: _regimenFiscal,
        usoCfdi: _usoCfdi,
        direccion: nullIfEmpty(_direccionCtrl.text),
        colonia: nullIfEmpty(_coloniaCtrl.text),
        ciudad: nullIfEmpty(_ciudadCtrl.text),
        estado: nullIfEmpty(_estadoCtrl.text),
        codigoPostal: nullIfEmpty(_cpCtrl.text),
        pais: nullIfEmpty(_paisCtrl.text),
        leadId: widget.contact?.leadId,
        mensaje: widget.contact?.mensaje,
        fuente: widget.contact?.fuente,
        interes: nullIfEmpty(_interesCtrl.text),
        tags: widget.contact?.tags ?? [],
        notas: nullIfEmpty(_notasCtrl.text),
        prioridad: _prioridad,
        valorEstimado: double.tryParse(_valorCtrl.text),
        asignadoA: widget.contact?.asignadoA,
        fechaUltimoContacto: widget.contact?.fechaUltimoContacto,
        fechaProximoSeguimiento: widget.contact?.fechaProximoSeguimiento,
        createdAt: widget.contact?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.contact?.createdBy ?? '',
      );

      if (_isEditing) {
        await CrmService.instance.updateContact(contact);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Contacto actualizado'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      } else {
        await CrmService.instance.createContact(contact);
        if (!mounted) return;

        final addAnother = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            icon: Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
            ),
            title: const Text('¡Contacto creado!'),
            content: Text(
              '"${_nombreCtrl.text.trim()}" se guardó exitosamente.\n\n¿Deseas agregar otro contacto?',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(false),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('No, regresar'),
              ),
              const SizedBox(width: AppDimensions.sm),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Sí, agregar otro'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        if (addAnother == true) {
          _resetForm();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _nombreCtrl.clear(); _apellidosCtrl.clear();
    _emailCtrl.clear(); _telefonoCtrl.clear(); _cargoCtrl.clear();
    _empresaCtrl.clear(); _industriaCtrl.clear(); _sitioWebCtrl.clear();
    _rfcCtrl.clear(); _razonSocialCtrl.clear();
    _direccionCtrl.clear(); _coloniaCtrl.clear();
    _ciudadCtrl.clear(); _estadoCtrl.clear(); _cpCtrl.clear();
    _paisCtrl.text = 'México';
    _valorCtrl.clear(); _interesCtrl.clear(); _notasCtrl.clear();
    setState(() {
      _tamanoEmpresa = null;
      _regimenFiscal = null;
      _usoCfdi = null;
      _status = ContactStatus.lead;
      _source = ContactSource.otro;
      _prioridad = null;
    });
    _formKey.currentState?.reset();
  }
}
