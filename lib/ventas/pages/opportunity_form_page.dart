// lib/ventas/pages/opportunity_form_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/firebase_helper.dart';
import '../../crm/models/crm_contact.dart';
import '../models/sale_opportunity.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';

class OpportunityFormPage extends StatefulWidget {
  final SaleOpportunity? opportunity;
  const OpportunityFormPage({super.key, this.opportunity});

  @override
  State<OpportunityFormPage> createState() => _OpportunityFormPageState();
}

class _OpportunityFormPageState extends State<OpportunityFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool get _isEditing => widget.opportunity != null;

  // Contacto
  CrmContact? _selectedContact;
  List<CrmContact> _allContacts = [];
  bool _loadingContacts = true;

  // Campos
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _valorCtrl = TextEditingController(text: '0');
  final _probabilidadCtrl = TextEditingController(text: '50');
  final _notasCtrl = TextEditingController();
  OpportunitySource _origen = OpportunitySource.otro;
  DateTime? _fechaCierre;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    if (_isEditing) _loadData();
  }

  void _loadData() {
    final o = widget.opportunity!;
    _tituloCtrl.text = o.titulo;
    _descripcionCtrl.text = o.descripcion ?? '';
    _valorCtrl.text = o.valorEstimado.toStringAsFixed(0);
    _probabilidadCtrl.text = o.probabilidad.toStringAsFixed(0);
    _notasCtrl.text = o.notas ?? '';
    _origen = o.origen;
    _fechaCierre = o.fechaCierreEstimada;
  }

  Future<void> _loadContacts() async {
    try {
      final snap = await FirebaseHelper.crmContacts.get();
      final contacts = snap.docs.map(CrmContact.fromDoc).toList();
      if (mounted) {
        setState(() {
          _allContacts = contacts;
          _loadingContacts = false;
          if (_isEditing) {
            _selectedContact = contacts.where((c) => c.id == widget.opportunity!.contactoId).firstOrNull;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _valorCtrl.dispose();
    _probabilidadCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEditing ? 'Editar oportunidad' : 'Nueva oportunidad', style: AppTextStyles.h3),
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
                  _buildContactSection(),
                  const SizedBox(height: AppDimensions.lg),
                  _buildDetailsSection(),
                  const SizedBox(height: AppDimensions.lg),
                  _buildValuesSection(),
                  const SizedBox(height: AppDimensions.lg),
                  _buildNotesSection(),
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

  Widget _buildContactSection() {
    return _card(
      icon: Icons.person_rounded,
      title: 'Contacto',
      child: Column(
        children: [
          if (_loadingContacts)
            const LinearProgressIndicator()
          else
            Autocomplete<CrmContact>(
              initialValue: _selectedContact != null
                  ? TextEditingValue(text: '${_selectedContact!.nombreCompleto} — ${_selectedContact!.empresa ?? "Sin empresa"}')
                  : TextEditingValue.empty,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return _allContacts;
                final q = textEditingValue.text.toLowerCase();
                return _allContacts.where((c) =>
                  c.nombreCompleto.toLowerCase().contains(q) ||
                  (c.empresa?.toLowerCase().contains(q) ?? false) ||
                  c.email.toLowerCase().contains(q));
              },
              displayStringForOption: (c) => '${c.nombreCompleto} — ${c.empresa ?? "Sin empresa"}',
              fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                return TextFormField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Buscar contacto *',
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Nombre, empresa o email...',
                  ),
                  validator: (_) => _selectedContact == null ? 'Selecciona un contacto' : null,
                );
              },
              onSelected: (contact) => setState(() => _selectedContact = contact),
            ),
          if (_selectedContact != null) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_selectedContact!.nombreCompleto, style: AppTextStyles.labelLarge),
                  if (_selectedContact!.empresa != null) Text(_selectedContact!.empresa!, style: AppTextStyles.bodySmall),
                  Text(_selectedContact!.email, style: AppTextStyles.caption),
                ])),
                IconButton(
                  onPressed: () => setState(() => _selectedContact = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return _card(
      icon: Icons.lightbulb_rounded,
      title: 'Detalles',
      child: Column(
        children: [
          TextFormField(
            controller: _tituloCtrl,
            decoration: const InputDecoration(labelText: 'Título de la oportunidad *', prefixIcon: Icon(Icons.title_rounded)),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: AppDimensions.md),
          TextFormField(
            controller: _descripcionCtrl,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 2,
          ),
          const SizedBox(height: AppDimensions.md),
          DropdownButtonFormField<OpportunitySource>(
            initialValue: _origen,
            decoration: const InputDecoration(labelText: 'Origen', prefixIcon: Icon(Icons.source_rounded)),
            items: OpportunitySource.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
            onChanged: (v) => setState(() => _origen = v ?? OpportunitySource.otro),
          ),
          const SizedBox(height: AppDimensions.md),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaCierre ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _fechaCierre = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Fecha estimada de cierre', prefixIcon: Icon(Icons.event_rounded)),
              child: Text(
                _fechaCierre != null ? '${_fechaCierre!.day}/${_fechaCierre!.month}/${_fechaCierre!.year}' : 'Sin definir',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesSection() {
    return _card(
      icon: Icons.attach_money_rounded,
      title: 'Valor',
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor estimado (MXN) *', prefixIcon: Icon(Icons.attach_money_rounded)),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Número inválido';
                return null;
              },
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: TextFormField(
              controller: _probabilidadCtrl,
              decoration: const InputDecoration(labelText: 'Probabilidad % *', prefixIcon: Icon(Icons.percent_rounded)),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                final n = double.tryParse(v);
                if (n == null || n < 0 || n > 100) return '0-100';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _card(
      icon: Icons.notes_rounded,
      title: 'Notas',
      child: TextFormField(
        controller: _notasCtrl,
        decoration: const InputDecoration(labelText: 'Notas adicionales'),
        maxLines: 3,
      ),
    );
  }

  Widget _card({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.sm),
            Text(title, style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_rounded),
        label: Text(_isEditing ? 'Guardar cambios' : 'Crear oportunidad'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContact == null) return;

    setState(() => _saving = true);
    try {
      final opp = SaleOpportunity(
        id: widget.opportunity?.id ?? '',
        folio: widget.opportunity?.folio ?? '',
        status: widget.opportunity?.status ?? OpportunityStatus.nueva,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.isNotEmpty ? _descripcionCtrl.text.trim() : null,
        valorEstimado: double.tryParse(_valorCtrl.text) ?? 0,
        probabilidad: double.tryParse(_probabilidadCtrl.text) ?? 50,
        origen: _origen,
        fechaCierreEstimada: _fechaCierre,
        contactoId: _selectedContact!.id,
        contactoNombre: _selectedContact!.nombreCompleto,
        contactoEmail: _selectedContact!.email,
        contactoTelefono: _selectedContact!.telefono,
        contactoEmpresa: _selectedContact!.empresa,
        cotizacionIds: widget.opportunity?.cotizacionIds ?? [],
        notas: _notasCtrl.text.isNotEmpty ? _notasCtrl.text.trim() : null,
        createdAt: widget.opportunity?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.opportunity?.createdBy ?? '',
      );

      if (_isEditing) {
        await VentasService.instance.updateOpportunity(opp);
      } else {
        await VentasService.instance.createOpportunity(opp);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? '✅ Oportunidad actualizada' : '✅ Oportunidad creada'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
