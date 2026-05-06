// lib/marketing/pages/campaign_form_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/marketing_campaign.dart';
import '../models/marketing_enums.dart';
import '../services/marketing_service.dart';

class CampaignFormPage extends StatefulWidget {
  final MarketingCampaign? campaign;
  const CampaignFormPage({super.key, this.campaign});

  @override
  State<CampaignFormPage> createState() => _CampaignFormPageState();
}

class _CampaignFormPageState extends State<CampaignFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool get _isEditing => widget.campaign != null;

  // Campos
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _presupuestoCtrl;
  late TextEditingController _objetivoLeadsCtrl;
  late TextEditingController _objetivoConversionesCtrl;
  late TextEditingController _objetivoAlcanceCtrl;
  late TextEditingController _notasCtrl;

  CampaignType _tipo = CampaignType.redesSociales;
  List<CampaignChannel> _canales = [];
  List<String> _tags = [];
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;
  String _moneda = 'MXN';

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: c?.descripcion ?? '');
    _presupuestoCtrl = TextEditingController(text: c?.presupuesto.toString() ?? '');
    _objetivoLeadsCtrl = TextEditingController(text: c?.objetivoLeads.toString() ?? '0');
    _objetivoConversionesCtrl = TextEditingController(text: c?.objetivoConversiones.toString() ?? '0');
    _objetivoAlcanceCtrl = TextEditingController(text: c?.objetivoAlcance.toString() ?? '0');
    _notasCtrl = TextEditingController(text: c?.notas ?? '');

    if (c != null) {
      _tipo = c.tipo;
      _canales = List.from(c.canales);
      _tags = List.from(c.tags);
      _fechaInicio = c.fechaInicio;
      _fechaFin = c.fechaFin;
      _moneda = c.moneda;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _presupuestoCtrl.dispose();
    _objetivoLeadsCtrl.dispose();
    _objetivoConversionesCtrl.dispose();
    _objetivoAlcanceCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = {
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        'tipo': _tipo.value,
        'canales': _canales.map((c) => c.value).toList(),
        'tags': _tags,
        'presupuesto': double.tryParse(_presupuestoCtrl.text) ?? 0,
        'moneda': _moneda,
        'fechaInicio': Timestamp.fromDate(_fechaInicio),
        'fechaFin': _fechaFin != null ? Timestamp.fromDate(_fechaFin!) : null,
        'objetivoLeads': int.tryParse(_objetivoLeadsCtrl.text) ?? 0,
        'objetivoConversiones': int.tryParse(_objetivoConversionesCtrl.text) ?? 0,
        'objetivoAlcance': int.tryParse(_objetivoAlcanceCtrl.text) ?? 0,
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      };

      if (_isEditing) {
        await MarketingService.instance.updateCampaign(widget.campaign!.id, data);
      } else {
        await MarketingService.instance.createCampaign(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Campaña' : 'Nueva Campaña'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.md),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isEditing ? 'Guardar' : 'Crear'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección 1: Información General
              _SectionCard(
                title: '📋 Información General',
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre de la campaña *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  DropdownButtonFormField<CampaignType>(
                    value: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo de campaña'),
                    items: CampaignType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Row(children: [
                        Icon(t.icon, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ]),
                    )).toList(),
                    onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Sección 2: Canales
              _SectionCard(
                title: '📱 Canales',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CampaignChannel.values.map((ch) => FilterChip(
                      avatar: Icon(ch.icon, size: 16, color: _canales.contains(ch) ? Colors.white : ch.color),
                      label: Text(ch.label),
                      selected: _canales.contains(ch),
                      selectedColor: ch.color,
                      labelStyle: TextStyle(color: _canales.contains(ch) ? Colors.white : AppColors.textPrimary, fontSize: 12),
                      onSelected: (sel) => setState(() => sel ? _canales.add(ch) : _canales.remove(ch)),
                    )).toList(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Sección 3: Presupuesto y Fechas
              _SectionCard(
                title: '💰 Presupuesto y Fechas',
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _presupuestoCtrl,
                          decoration: const InputDecoration(labelText: 'Presupuesto', prefixText: '\$ '),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _moneda,
                          decoration: const InputDecoration(labelText: 'Moneda'),
                          items: ['MXN', 'USD'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => _moneda = v ?? 'MXN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fecha de inicio', style: TextStyle(fontSize: 13)),
                          subtitle: Text('${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}', style: AppTextStyles.labelLarge),
                          trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fechaInicio,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setState(() => _fechaInicio = date);
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.lg),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fecha fin', style: TextStyle(fontSize: 13)),
                          subtitle: Text(
                            _fechaFin != null ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}' : 'Sin definir',
                            style: AppTextStyles.labelLarge,
                          ),
                          trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fechaFin ?? _fechaInicio.add(const Duration(days: 30)),
                              firstDate: _fechaInicio,
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setState(() => _fechaFin = date);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Sección 4: Objetivos
              _SectionCard(
                title: '🎯 Objetivos',
                children: [
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _objetivoLeadsCtrl, decoration: const InputDecoration(labelText: 'Leads esperados'), keyboardType: TextInputType.number)),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(child: TextFormField(controller: _objetivoConversionesCtrl, decoration: const InputDecoration(labelText: 'Conversiones esperadas'), keyboardType: TextInputType.number)),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(child: TextFormField(controller: _objetivoAlcanceCtrl, decoration: const InputDecoration(labelText: 'Alcance esperado'), keyboardType: TextInputType.number)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Sección 5: Notas
              _SectionCard(
                title: '📝 Notas',
                children: [
                  TextFormField(
                    controller: _notasCtrl,
                    decoration: const InputDecoration(labelText: 'Notas internas', hintText: 'Observaciones, estrategia, etc.'),
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.md),
          ...children,
        ],
      ),
    );
  }
}
