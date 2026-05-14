// lib/proyectos/pages/project_form_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../crm/models/crm_contact.dart';
import '../../crm/services/crm_service.dart';
import '../models/project.dart';
import '../models/project_enums.dart';
import '../services/project_service.dart';

class ProjectFormPage extends StatefulWidget {
  final Project? project; // null = crear nuevo
  const ProjectFormPage({super.key, this.project});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  int _currentStep = 0;

  // Controladores
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _descripcionDetalladaCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _costoEstimadoCtrl;
  late final TextEditingController _presupuestoCtrl;
  late final TextEditingController _notasInternasCtrl;
  late final TextEditingController _notasClienteCtrl;

  // Valores
  ProjectType _type = ProjectType.unico;
  ProjectPriority _priority = ProjectPriority.media;
  bool _esRecurrente = false;
  RecurrenceFrequency _frecuencia = RecurrenceFrequency.mensual;
  DateTime? _fechaInicio;
  DateTime? _fechaFinEstimada;

  // Cliente seleccionado
  String? _clienteId;
  String _clienteNombre = '';
  String? _clienteEmpresa;
  String? _clienteEmail;
  String? _clienteTelefono;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _descripcionDetalladaCtrl = TextEditingController(text: p?.descripcionDetallada ?? '');
    _valorCtrl = TextEditingController(text: p?.valorProyecto.toStringAsFixed(2) ?? '');
    _costoEstimadoCtrl = TextEditingController(text: p?.costoEstimado.toStringAsFixed(2) ?? '');
    _presupuestoCtrl = TextEditingController(text: p?.presupuesto.toStringAsFixed(2) ?? '');
    _notasInternasCtrl = TextEditingController(text: p?.notasInternas ?? '');
    _notasClienteCtrl = TextEditingController(text: p?.notasCliente ?? '');

    if (p != null) {
      _type = p.type;
      _priority = p.priority;
      _esRecurrente = p.esRecurrente;
      _frecuencia = p.frecuenciaRecurrencia ?? RecurrenceFrequency.mensual;
      _fechaInicio = p.fechaInicio;
      _fechaFinEstimada = p.fechaFinEstimada;
      _clienteId = p.clienteId;
      _clienteNombre = p.clienteNombre;
      _clienteEmpresa = p.clienteEmpresa;
      _clienteEmail = p.clienteEmail;
      _clienteTelefono = p.clienteTelefono;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _descripcionDetalladaCtrl.dispose();
    _valorCtrl.dispose();
    _costoEstimadoCtrl.dispose();
    _presupuestoCtrl.dispose();
    _notasInternasCtrl.dispose();
    _notasClienteCtrl.dispose();
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
        title: Text(_isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(_isEditing ? 'Guardar' : 'Crear'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          const SizedBox(width: AppDimensions.md),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _save();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (ctx, details) => Padding(
            padding: const EdgeInsets.only(top: AppDimensions.md),
            child: Row(children: [
              FilledButton(
                onPressed: details.onStepContinue,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(_currentStep == 3 ? 'Guardar' : 'Siguiente'),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: AppDimensions.sm),
                OutlinedButton(onPressed: details.onStepCancel, child: const Text('Anterior')),
              ],
            ]),
          ),
          steps: [
            // Step 1: Info general
            Step(
              title: const Text('Información General'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del proyecto *', prefixIcon: Icon(Icons.title_rounded)),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción corta *', prefixIcon: Icon(Icons.short_text_rounded)),
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _descripcionDetalladaCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción detallada', prefixIcon: Icon(Icons.notes_rounded)),
                  maxLines: 4,
                ),
                const SizedBox(height: AppDimensions.md),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<ProjectType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: ProjectType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  )),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(child: DropdownButtonFormField<ProjectPriority>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: ProjectPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  )),
                ]),
              ]),
            ),

            // Step 2: Cliente
            Step(
              title: const Text('Cliente'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(children: [
                _buildClientSelector(),
                if (_clienteId != null) ...[
                  const SizedBox(height: AppDimensions.md),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_clienteNombre, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      if (_clienteEmpresa != null) Text(_clienteEmpresa!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      if (_clienteEmail != null) Text(_clienteEmail!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                    ]),
                  ),
                ],
              ]),
            ),

            // Step 3: Fechas y recurrencia
            Step(
              title: const Text('Fechas y Recurrencia'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(children: [
                Row(children: [
                  Expanded(child: _buildDateField('Fecha inicio', _fechaInicio, (d) => setState(() => _fechaInicio = d))),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(child: _buildDateField('Fecha fin estimada', _fechaFinEstimada, (d) => setState(() => _fechaFinEstimada = d))),
                ]),
                const SizedBox(height: AppDimensions.md),
                SwitchListTile(
                  title: const Text('Proyecto recurrente'),
                  subtitle: const Text('Se repite periódicamente'),
                  value: _esRecurrente,
                  onChanged: (v) => setState(() => _esRecurrente = v),
                  activeColor: AppColors.primary,
                ),
                if (_esRecurrente) ...[
                  const SizedBox(height: AppDimensions.sm),
                  DropdownButtonFormField<RecurrenceFrequency>(
                    value: _frecuencia,
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    items: RecurrenceFrequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
                    onChanged: (v) => setState(() => _frecuencia = v!),
                  ),
                ],
              ]),
            ),

            // Step 4: Financiero
            Step(
              title: const Text('Información Financiera'),
              isActive: _currentStep >= 3,
              content: Column(children: [
                TextFormField(
                  controller: _valorCtrl,
                  decoration: const InputDecoration(labelText: 'Valor del proyecto (MXN)', prefixIcon: Icon(Icons.attach_money_rounded)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppDimensions.md),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _costoEstimadoCtrl,
                    decoration: const InputDecoration(labelText: 'Costo estimado'),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(child: TextFormField(
                    controller: _presupuestoCtrl,
                    decoration: const InputDecoration(labelText: 'Presupuesto'),
                    keyboardType: TextInputType.number,
                  )),
                ]),
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _notasInternasCtrl,
                  decoration: const InputDecoration(labelText: 'Notas internas'),
                  maxLines: 3,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón para abrir selector de cliente
        InkWell(
          onTap: _showClientPickerDialog,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Cliente del CRM *',
              prefixIcon: const Icon(Icons.person_search_rounded),
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              _clienteId != null ? _clienteNombre : 'Seleccionar cliente...',
              style: TextStyle(
                color: _clienteId != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),
        ),
        if (_clienteId != null) ...[
          const SizedBox(height: AppDimensions.sm),
          // Botón para limpiar selección
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _clienteId = null;
                _clienteNombre = '';
                _clienteEmpresa = null;
                _clienteEmail = null;
                _clienteTelefono = null;
              }),
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Cambiar cliente'),
            ),
          ),
        ],
      ],
    );
  }

  void _showClientPickerDialog() {
    final searchCtrl = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_rounded, color: AppColors.primary),
                            const SizedBox(width: AppDimensions.sm),
                            Text('Seleccionar Cliente', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.md),
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, empresa o email...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide.none),
                          ),
                          onChanged: (v) => setDialogState(() => searchQuery = v),
                        ),
                      ],
                    ),
                  ),
                  // Lista de contactos
                  Expanded(
                    child: StreamBuilder<List<CrmContact>>(
                      stream: CrmService.instance.streamContacts(
                        filters: CrmFilters(searchQuery: searchQuery.isNotEmpty ? searchQuery : null),
                      ),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimensions.lg),
                              child: Text('Error al cargar contactos:\n${snap.error}', 
                                style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                            ),
                          );
                        }

                        final contacts = snap.data ?? [];

                        if (contacts.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimensions.xl),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_off_rounded, size: 48, color: AppColors.textHint.withOpacity(0.3)),
                                  const SizedBox(height: AppDimensions.md),
                                  Text(
                                    searchQuery.isEmpty 
                                        ? 'No hay contactos registrados en el CRM' 
                                        : 'Sin resultados para "$searchQuery"',
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final contact = contacts[i];
                            final isSelected = contact.id == _clienteId;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? AppColors.primary : AppColors.primarySurface,
                                child: Text(
                                  contact.iniciales,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(contact.nombreCompleto, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (contact.empresa != null && contact.empresa!.isNotEmpty)
                                    Text(contact.empresa!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                  if (contact.email.isNotEmpty)
                                    Text(contact.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11)),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                  : null,
                              selected: isSelected,
                              selectedTileColor: AppColors.primarySurface,
                              onTap: () {
                                setState(() {
                                  _clienteId = contact.id;
                                  _clienteNombre = contact.nombreCompleto;
                                  _clienteEmpresa = contact.empresa;
                                  _clienteEmail = contact.email;
                                  _clienteTelefono = contact.telefono;
                                });
                                Navigator.pop(ctx);
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
          );
        },
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, ValueChanged<DateTime> onChanged) {
    final df = DateFormat('dd/MM/yyyy', 'es_MX');
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (date != null) onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today_rounded)),
        child: Text(value != null ? df.format(value) : 'Seleccionar', style: TextStyle(color: value != null ? AppColors.textPrimary : AppColors.textHint)),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteId == null || _clienteId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un cliente'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _saving = true);

    try {
      final project = Project(
        id: widget.project?.id ?? '',
        folio: widget.project?.folio ?? '',
        status: widget.project?.status ?? ProjectStatus.planificacion,
        type: _type,
        priority: _priority,
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        descripcionDetallada: _descripcionDetalladaCtrl.text.trim().isEmpty ? null : _descripcionDetalladaCtrl.text.trim(),
        clienteId: _clienteId!,
        clienteNombre: _clienteNombre,
        clienteEmpresa: _clienteEmpresa,
        clienteEmail: _clienteEmail,
        clienteTelefono: _clienteTelefono,
        fechaInicio: _fechaInicio,
        fechaFinEstimada: _fechaFinEstimada,
        esRecurrente: _esRecurrente,
        frecuenciaRecurrencia: _esRecurrente ? _frecuencia : null,
        valorProyecto: double.tryParse(_valorCtrl.text) ?? 0,
        costoEstimado: double.tryParse(_costoEstimadoCtrl.text) ?? 0,
        presupuesto: double.tryParse(_presupuestoCtrl.text) ?? 0,
        notasInternas: _notasInternasCtrl.text.trim().isEmpty ? null : _notasInternasCtrl.text.trim(),
        notasCliente: _notasClienteCtrl.text.trim().isEmpty ? null : _notasClienteCtrl.text.trim(),
        materiales: widget.project?.materiales ?? [],
        miembrosEquipo: widget.project?.miembrosEquipo ?? [],
        totalIngresos: widget.project?.totalIngresos ?? 0,
        totalEgresos: widget.project?.totalEgresos ?? 0,
        totalAdelantos: widget.project?.totalAdelantos ?? 0,
        costoReal: widget.project?.costoReal ?? 0,
        progreso: widget.project?.progreso ?? 0,
        tareasTotal: widget.project?.tareasTotal ?? 0,
        tareasCompletadas: widget.project?.tareasCompletadas ?? 0,
        createdAt: widget.project?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.project?.createdBy ?? '',
      );

      if (_isEditing) {
        await ProjectService.instance.updateProject(project);
      } else {
        await ProjectService.instance.createProject(project);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Proyecto actualizado' : 'Proyecto creado exitosamente'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
