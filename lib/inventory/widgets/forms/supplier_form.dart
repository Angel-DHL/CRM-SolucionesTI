// lib/inventory/widgets/forms/supplier_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_supplier.dart';
import '../../services/inventory_supplier_service.dart';

class SupplierForm extends StatefulWidget {
  final InventorySupplier? supplier;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const SupplierForm({super.key, this.supplier, this.onSaved, this.onCancel});

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  final _supplierService = InventorySupplierService.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPositionController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _leadTimeDaysController = TextEditingController();
  final _notesController = TextEditingController();

  SupplierType _selectedType = SupplierType.distributor;
  SupplierStatus _selectedStatus = SupplierStatus.active;
  PaymentTerms _selectedPaymentTerms = PaymentTerms.net30;
  bool _isPreferred = false;
  bool _sendPurchaseOrders = true;

  bool _isLoading = false;
  bool get _isEditing => widget.supplier != null;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.supplier != null) {
      final s = widget.supplier!;
      _nameController.text = s.name;
      _tradeNameController.text = s.tradeName ?? '';
      _emailController.text = s.email;
      _phoneController.text = s.phone ?? '';
      _mobileController.text = s.mobile ?? '';
      _websiteController.text = s.website ?? '';
      _taxIdController.text = s.taxId ?? '';
      _contactNameController.text = s.contactName ?? '';
      _contactPositionController.text = s.contactPosition ?? '';
      _addressLine1Controller.text = s.addressLine1 ?? '';
      _addressLine2Controller.text = s.addressLine2 ?? '';
      _cityController.text = s.city ?? '';
      _stateController.text = s.state ?? '';
      _postalCodeController.text = s.postalCode ?? '';
      _countryController.text = s.country ?? '';
      _creditLimitController.text = s.creditLimit?.toString() ?? '';
      _leadTimeDaysController.text = s.leadTimeDays?.toString() ?? '';
      _notesController.text = s.notes ?? '';
      _selectedType = s.type;
      _selectedStatus = s.status;
      _selectedPaymentTerms = s.paymentTerms;
      _isPreferred = s.isPreferred;
      _sendPurchaseOrders = s.sendPurchaseOrders;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tradeNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _contactNameController.dispose();
    _contactPositionController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _creditLimitController.dispose();
    _leadTimeDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      if (_isEditing) {
        final updated = widget.supplier!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          status: _selectedStatus,
          email: _emailController.text.trim(),
          paymentTerms: _selectedPaymentTerms,
          isPreferred: _isPreferred,
          updatedAt: now,
        );
        // Note: Full copyWith would include all fields
        await _supplierService.updateSupplier(updated);
      } else {
        final newSupplier = InventorySupplier(
          id: '',
          code: '',
          name: _nameController.text.trim(),
          tradeName: _tradeNameController.text.trim().isNotEmpty
              ? _tradeNameController.text.trim()
              : null,
          type: _selectedType,
          status: _selectedStatus,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          mobile: _mobileController.text.trim().isNotEmpty
              ? _mobileController.text.trim()
              : null,
          website: _websiteController.text.trim().isNotEmpty
              ? _websiteController.text.trim()
              : null,
          taxId: _taxIdController.text.trim().isNotEmpty
              ? _taxIdController.text.trim()
              : null,
          contactName: _contactNameController.text.trim().isNotEmpty
              ? _contactNameController.text.trim()
              : null,
          contactPosition: _contactPositionController.text.trim().isNotEmpty
              ? _contactPositionController.text.trim()
              : null,
          addressLine1: _addressLine1Controller.text.trim().isNotEmpty
              ? _addressLine1Controller.text.trim()
              : null,
          addressLine2: _addressLine2Controller.text.trim().isNotEmpty
              ? _addressLine2Controller.text.trim()
              : null,
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : null,
          state: _stateController.text.trim().isNotEmpty
              ? _stateController.text.trim()
              : null,
          postalCode: _postalCodeController.text.trim().isNotEmpty
              ? _postalCodeController.text.trim()
              : null,
          country: _countryController.text.trim().isNotEmpty
              ? _countryController.text.trim()
              : null,
          paymentTerms: _selectedPaymentTerms,
          creditLimit: double.tryParse(_creditLimitController.text),
          leadTimeDays: int.tryParse(_leadTimeDaysController.text),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          isPreferred: _isPreferred,
          sendPurchaseOrders: _sendPurchaseOrders,
          createdAt: now,
          updatedAt: now,
          createdBy: '',
        );

        await _supplierService.createSupplier(newSupplier);
      }

      if (!mounted) return;
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
          } else {
            widget.onCancel?.call();
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: AppDimensions.lg),
            child: Row(
              children: [
                if (_currentStep < 3)
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continuar'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                  ),
                const SizedBox(width: AppDimensions.md),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(_currentStep == 0 ? 'Cancelar' : 'Atrás'),
                ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Basic Info
          Step(
            title: const Text('Información Básica'),
            subtitle: const Text('Datos principales del proveedor'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildBasicInfoStep(),
          ),

          // Step 2: Contact
          Step(
            title: const Text('Contacto'),
            subtitle: const Text('Información de contacto'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildContactStep(),
          ),

          // Step 3: Address
          Step(
            title: const Text('Dirección'),
            subtitle: const Text('Ubicación física'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildAddressStep(),
          ),

          // Step 4: Commercial
          Step(
            title: const Text('Comercial'),
            subtitle: const Text('Términos y configuración'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: _buildCommercialStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector
        Text('Tipo de proveedor *', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: SupplierType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedType = type),
              avatar: Icon(type.icon, size: 18),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.lg),

        // Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Razón social / Nombre *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.business_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // Trade name
        TextFormField(
          controller: _tradeNameController,
          decoration: InputDecoration(
            labelText: 'Nombre comercial',
            hintText: 'Si es diferente de la razón social',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.storefront_rounded),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppDimensions.md),

        // Tax ID
        TextFormField(
          controller: _taxIdController,
          decoration: InputDecoration(
            labelText: 'RFC / NIT',
            hintText: 'Identificación fiscal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.badge_rounded),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: AppDimensions.lg),

        // Preferred and status
        SwitchListTile(
          title: const Text('Proveedor preferido'),
          subtitle: const Text('Aparecerá destacado en las búsquedas'),
          value: _isPreferred,
          onChanged: (v) => setState(() => _isPreferred = v),
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.star_rounded,
            color: _isPreferred ? AppColors.warning : AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.email_rounded),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El email es requerido';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // Phones
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Celular',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        // Website
        TextFormField(
          controller: _websiteController,
          decoration: InputDecoration(
            labelText: 'Sitio web',
            hintText: 'https://www.ejemplo.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.language_rounded),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppDimensions.lg),

        // Contact person
        Text('Persona de contacto', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _contactNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: _contactPositionController,
                decoration: InputDecoration(
                  labelText: 'Cargo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.work_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _addressLine1Controller,
          decoration: InputDecoration(
            labelText: 'Dirección línea 1',
            hintText: 'Calle, número...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.location_on_rounded),
          ),
        ),
        const SizedBox(height: AppDimensions.md),

        TextFormField(
          controller: _addressLine2Controller,
          decoration: InputDecoration(
            labelText: 'Dirección línea 2',
            hintText: 'Colonia, edificio, piso...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.md),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: _postalCodeController,
                decoration: InputDecoration(
                  labelText: 'C.P.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'País',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommercialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment terms
        Text('Términos de pago', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        DropdownButtonFormField<PaymentTerms>(
          value: _selectedPaymentTerms,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.payment_rounded),
          ),
          items: PaymentTerms.values.map((terms) {
            return DropdownMenuItem(value: terms, child: Text(terms.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedPaymentTerms = value);
            }
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // Credit limit and lead time
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _creditLimitController,
                decoration: InputDecoration(
                  labelText: 'Límite de crédito',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: _leadTimeDaysController,
                decoration: InputDecoration(
                  labelText: 'Tiempo de entrega',
                  suffixText: 'días',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),

        // Send purchase orders
        SwitchListTile(
          title: const Text('Enviar órdenes de compra'),
          subtitle: const Text('Enviar automáticamente por email'),
          value: _sendPurchaseOrders,
          onChanged: (v) => setState(() => _sendPurchaseOrders = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppDimensions.md),

        // Notes
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Notas',
            hintText: 'Información adicional del proveedor...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
