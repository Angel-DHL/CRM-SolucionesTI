// lib/inventory/pages/inventory_form_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/inventory_item.dart';
import '../models/inventory_category.dart';
import '../models/inventory_location.dart';
import '../models/inventory_enums.dart';
import '../services/inventory_service.dart';
import '../widgets/forms/item_form_sections/basic_info_section.dart';
import '../widgets/forms/item_form_sections/pricing_section.dart';
import '../widgets/forms/item_form_sections/stock_section.dart';
import '../widgets/forms/item_form_sections/images_section.dart';
import '../widgets/forms/item_form_sections/product_details_section.dart';
import '../widgets/forms/item_form_sections/asset_details_section.dart';
import '../widgets/forms/item_form_sections/service_details_section.dart';

class InventoryFormPage extends StatefulWidget {
  final InventoryItem? item;
  final InventoryItem? duplicateFrom;
  final VoidCallback? onSaved;

  const InventoryFormPage({
    super.key,
    this.item,
    this.duplicateFrom,
    this.onSaved,
  });

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService.instance;

  // Controllers básicos
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descriptionController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _rentalPriceController;
  late TextEditingController _taxRateController;
  late TextEditingController _discountController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _maxStockController;
  late TextEditingController _reorderPointController;

  // Controllers de producto
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _manufacturerController;
  late TextEditingController _serialNumberController;
  late TextEditingController _barcodeController;
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _batchNumberController;

  // Controllers de activo
  late TextEditingController _depreciationRateController;

  // Controllers de servicio
  late TextEditingController _estimatedDurationController;
  late TextEditingController _detailedDescriptionController;

  // State
  InventoryItemType _selectedType = InventoryItemType.product;
  UnitOfMeasure _selectedUnit = UnitOfMeasure.unit;
  String _selectedCurrency = 'MXN';
  InventoryCategory? _selectedCategory;
  InventoryLocation? _selectedLocation;
  List<String> _tags = [];
  bool _trackInventory = true;
  bool _allowBackorder = false;
  bool _isActive = true;
  bool _isFeatured = false;

  // Product state
  DateTime? _expirationDate;

  // Asset state
  AssetCondition _assetCondition = AssetCondition.new_;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiryDate;
  DateTime? _lastMaintenanceDate;
  DateTime? _nextMaintenanceDate;
  String? _assignedToUserId;

  // Service state
  List<String> _requiredSkills = [];
  bool _isRecurring = false;

  // Images
  String? _primaryImageUrl;
  List<String> _additionalImageUrls = [];

  bool _isLoading = false;
  bool get _isEditing => widget.item != null;
  String? _savedItemId;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadInitialData();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _skuController = TextEditingController();
    _descriptionController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _sellingPriceController = TextEditingController();
    _rentalPriceController = TextEditingController();
    _taxRateController = TextEditingController();
    _discountController = TextEditingController();
    _stockController = TextEditingController(text: '0');
    _minStockController = TextEditingController(text: '0');
    _maxStockController = TextEditingController();
    _reorderPointController = TextEditingController();
    _brandController = TextEditingController();
    _modelController = TextEditingController();
    _manufacturerController = TextEditingController();
    _serialNumberController = TextEditingController();
    _barcodeController = TextEditingController();
    _weightController = TextEditingController();
    _lengthController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _batchNumberController = TextEditingController();
    _depreciationRateController = TextEditingController();
    _estimatedDurationController = TextEditingController();
    _detailedDescriptionController = TextEditingController();
  }

  void _loadInitialData() {
    final source = widget.item ?? widget.duplicateFrom;
    if (source != null) {
      _nameController.text = source.name;
      if (widget.item != null) _skuController.text = source.sku;
      _descriptionController.text = source.description;
      _purchasePriceController.text = source.purchasePrice.toString();
      _sellingPriceController.text = source.sellingPrice.toString();
      if (source.rentalPrice != null) {
        _rentalPriceController.text = source.rentalPrice.toString();
      }
      if (source.taxRate != null) {
        _taxRateController.text = source.taxRate.toString();
      }
      if (source.discount != null) {
        _discountController.text = source.discount.toString();
      }
      _stockController.text = source.stock.toString();
      _minStockController.text = source.minStock.toString();
      if (source.maxStock != null) {
        _maxStockController.text = source.maxStock.toString();
      }
      if (source.reorderPoint != null) {
        _reorderPointController.text = source.reorderPoint.toString();
      }

      _selectedType = source.type;
      _selectedUnit = source.unitOfMeasure;
      _selectedCurrency = source.currency;
      _tags = List.from(source.tags);
      _trackInventory = source.trackInventory;
      _allowBackorder = source.allowBackorder;
      _isActive = source.isActive;
      _isFeatured = source.isFeatured;

      // Product fields
      _brandController.text = source.brand ?? '';
      _modelController.text = source.model ?? '';
      _manufacturerController.text = source.manufacturer ?? '';
      _serialNumberController.text = source.serialNumber ?? '';
      _barcodeController.text = source.barcode ?? '';
      if (source.weight != null) {
        _weightController.text = source.weight.toString();
      }
      _batchNumberController.text = source.batchNumber ?? '';
      _expirationDate = source.expirationDate;

      // Asset fields
      if (source.assetCondition != null) {
        _assetCondition = source.assetCondition!;
      }
      _purchaseDate = source.purchaseDate;
      _warrantyExpiryDate = source.warrantyExpiryDate;
      _lastMaintenanceDate = source.lastMaintenanceDate;
      _nextMaintenanceDate = source.nextMaintenanceDate;
      if (source.depreciationRate != null) {
        _depreciationRateController.text = source.depreciationRate.toString();
      }
      _assignedToUserId = source.assignedToUserId;

      // Service fields
      if (source.estimatedDuration != null) {
        _estimatedDurationController.text = source.estimatedDuration.toString();
      }
      _requiredSkills = List.from(source.requiredSkills ?? []);
      _isRecurring = source.isRecurring ?? false;
      _detailedDescriptionController.text = source.detailedDescription ?? '';

      // Images
      _primaryImageUrl = source.primaryImageUrl;
      _additionalImageUrls = List.from(source.additionalImageUrls);

      // Load relations
      _loadCategory(source.categoryId);
      if (source.defaultLocationId != null) {
        _loadLocation(source.defaultLocationId!);
      }

      _savedItemId = widget.item?.id;
    }
  }

  Future<void> _loadCategory(String categoryId) async {
    // Cargar categoría desde servicio
  }

  Future<void> _loadLocation(String locationId) async {
    // Cargar ubicación desde servicio
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _rentalPriceController.dispose();
    _taxRateController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _reorderPointController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _manufacturerController.dispose();
    _serialNumberController.dispose();
    _barcodeController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _batchNumberController.dispose();
    _depreciationRateController.dispose();
    _estimatedDurationController.dispose();
    _detailedDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(_isEditing ? 'Editar Item' : 'Nuevo Item'),
        actions: [
          if (!isMobile)
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
            )
          : null,
    );
  }

  Widget _buildMobileLayout() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep < _getSteps().length - 1) {
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
      onStepTapped: (step) => setState(() => _currentStep = step),
      steps: _getSteps(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Navigation
        Container(
          width: 250,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secciones',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              _NavItem(
                icon: Icons.info_rounded,
                label: 'Información básica',
                isSelected: _currentStep == 0,
                onTap: () => setState(() => _currentStep = 0),
              ),
              _NavItem(
                icon: Icons.attach_money_rounded,
                label: 'Precios',
                isSelected: _currentStep == 1,
                onTap: () => setState(() => _currentStep = 1),
              ),
              if (_selectedType != InventoryItemType.service)
                _NavItem(
                  icon: Icons.inventory_rounded,
                  label: 'Stock',
                  isSelected: _currentStep == 2,
                  onTap: () => setState(() => _currentStep = 2),
                ),
              _NavItem(
                icon: _selectedType.icon,
                label: 'Detalles de ${_selectedType.label}',
                isSelected: _currentStep == 3,
                onTap: () => setState(() => _currentStep = 3),
              ),
              _NavItem(
                icon: Icons.image_rounded,
                label: 'Imágenes',
                isSelected: _currentStep == 4,
                onTap: () => setState(() => _currentStep = 4),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildCurrentSection(),
            ),
          ),
        ),
      ],
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Información básica'),
        content: _buildBasicInfoSection(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Precios'),
        content: _buildPricingSection(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      if (_selectedType != InventoryItemType.service)
        Step(
          title: const Text('Stock'),
          content: _buildStockSection(),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
      Step(
        title: Text('Detalles de ${_selectedType.label}'),
        content: _buildTypeSpecificSection(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Imágenes'),
        content: _buildImagesSection(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildCurrentSection() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoSection();
      case 1:
        return _buildPricingSection();
      case 2:
        return _buildStockSection();
      case 3:
        return _buildTypeSpecificSection();
      case 4:
        return _buildImagesSection();
      default:
        return _buildBasicInfoSection();
    }
  }

  Widget _buildBasicInfoSection() {
    return BasicInfoSection(
      nameController: _nameController,
      skuController: _skuController,
      descriptionController: _descriptionController,
      selectedType: _selectedType,
      onTypeChanged: (type) => setState(() => _selectedType = type),
      selectedCategory: _selectedCategory,
      onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
      selectedUnit: _selectedUnit,
      onUnitChanged: (unit) => setState(() => _selectedUnit = unit),
      tags: _tags,
      onTagsChanged: (tags) => setState(() => _tags = tags),
      isEditing: _isEditing,
    );
  }

  Widget _buildPricingSection() {
    return PricingSection(
      purchasePriceController: _purchasePriceController,
      sellingPriceController: _sellingPriceController,
      rentalPriceController: _rentalPriceController,
      taxRateController: _taxRateController,
      discountController: _discountController,
      selectedCurrency: _selectedCurrency,
      onCurrencyChanged: (c) => setState(() => _selectedCurrency = c),
      showRentalPrice: _selectedType == InventoryItemType.asset,
    );
  }

  Widget _buildStockSection() {
    return StockSection(
      stockController: _stockController,
      minStockController: _minStockController,
      maxStockController: _maxStockController,
      reorderPointController: _reorderPointController,
      selectedLocation: _selectedLocation,
      onLocationChanged: (loc) => setState(() => _selectedLocation = loc),
      trackInventory: _trackInventory,
      onTrackInventoryChanged: (v) => setState(() => _trackInventory = v),
      allowBackorder: _allowBackorder,
      onAllowBackorderChanged: (v) => setState(() => _allowBackorder = v),
      isEditing: _isEditing,
    );
  }

  Widget _buildTypeSpecificSection() {
    switch (_selectedType) {
      case InventoryItemType.product:
        return ProductDetailsSection(
          brandController: _brandController,
          modelController: _modelController,
          manufacturerController: _manufacturerController,
          serialNumberController: _serialNumberController,
          barcodeController: _barcodeController,
          weightController: _weightController,
          lengthController: _lengthController,
          widthController: _widthController,
          heightController: _heightController,
          batchNumberController: _batchNumberController,
          expirationDate: _expirationDate,
          onExpirationDateChanged: (d) => setState(() => _expirationDate = d),
        );
      case InventoryItemType.asset:
        return AssetDetailsSection(
          serialNumberController: _serialNumberController,
          brandController: _brandController,
          modelController: _modelController,
          depreciationRateController: _depreciationRateController,
          selectedCondition: _assetCondition,
          onConditionChanged: (c) => setState(() => _assetCondition = c),
          purchaseDate: _purchaseDate,
          onPurchaseDateChanged: (d) => setState(() => _purchaseDate = d),
          warrantyExpiryDate: _warrantyExpiryDate,
          onWarrantyExpiryDateChanged: (d) =>
              setState(() => _warrantyExpiryDate = d),
          lastMaintenanceDate: _lastMaintenanceDate,
          onLastMaintenanceDateChanged: (d) =>
              setState(() => _lastMaintenanceDate = d),
          nextMaintenanceDate: _nextMaintenanceDate,
          onNextMaintenanceDateChanged: (d) =>
              setState(() => _nextMaintenanceDate = d),
          assignedToUserId: _assignedToUserId,
          onAssignedToChanged: (u) => setState(() => _assignedToUserId = u),
        );
      case InventoryItemType.service:
        return ServiceDetailsSection(
          estimatedDurationController: _estimatedDurationController,
          requiredSkills: _requiredSkills,
          onRequiredSkillsChanged: (s) => setState(() => _requiredSkills = s),
          isRecurring: _isRecurring,
          onIsRecurringChanged: (v) => setState(() => _isRecurring = v),
          detailedDescriptionController: _detailedDescriptionController,
        );
    }
  }

  Widget _buildImagesSection() {
    return ImagesSection(
      primaryImageUrl: _primaryImageUrl,
      additionalImageUrls: _additionalImageUrls,
      onPrimaryImageChanged: (url) => setState(() => _primaryImageUrl = url),
      onAdditionalImagesChanged: (urls) =>
          setState(() => _additionalImageUrls = urls),
      itemId: _savedItemId,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos requeridos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();

      final item = InventoryItem(
        id: widget.item?.id ?? '',
        type: _selectedType,
        status: _isActive
            ? InventoryItemStatus.active
            : InventoryItemStatus.inactive,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        categoryId: _selectedCategory!.id,
        unitOfMeasure: _selectedUnit,
        description: _descriptionController.text.trim(),
        detailedDescription:
            _detailedDescriptionController.text.trim().isNotEmpty
            ? _detailedDescriptionController.text.trim()
            : null,
        tags: _tags,
        barcode: _barcodeController.text.trim().isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        rentalPrice: _rentalPriceController.text.isNotEmpty
            ? double.parse(_rentalPriceController.text)
            : null,
        currency: _selectedCurrency,
        taxRate: _taxRateController.text.isNotEmpty
            ? double.parse(_taxRateController.text)
            : null,
        discount: _discountController.text.isNotEmpty
            ? double.parse(_discountController.text)
            : null,
        stock: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        maxStock: _maxStockController.text.isNotEmpty
            ? int.parse(_maxStockController.text)
            : null,
        reorderPoint: _reorderPointController.text.isNotEmpty
            ? int.parse(_reorderPointController.text)
            : null,
        defaultLocationId: _selectedLocation?.id,
        brand: _brandController.text.trim().isNotEmpty
            ? _brandController.text.trim()
            : null,
        model: _modelController.text.trim().isNotEmpty
            ? _modelController.text.trim()
            : null,
        manufacturer: _manufacturerController.text.trim().isNotEmpty
            ? _manufacturerController.text.trim()
            : null,
        serialNumber: _serialNumberController.text.trim().isNotEmpty
            ? _serialNumberController.text.trim()
            : null,
        expirationDate: _expirationDate,
        batchNumber: _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        weight: _weightController.text.isNotEmpty
            ? double.parse(_weightController.text)
            : null,
        assetCondition: _selectedType == InventoryItemType.asset
            ? _assetCondition
            : null,
        purchaseDate: _purchaseDate,
        warrantyExpiryDate: _warrantyExpiryDate,
        depreciationRate: _depreciationRateController.text.isNotEmpty
            ? double.parse(_depreciationRateController.text)
            : null,
        assignedToUserId: _assignedToUserId,
        lastMaintenanceDate: _lastMaintenanceDate,
        nextMaintenanceDate: _nextMaintenanceDate,
        estimatedDuration: _estimatedDurationController.text.isNotEmpty
            ? int.parse(_estimatedDurationController.text)
            : null,
        requiredSkills: _requiredSkills.isNotEmpty ? _requiredSkills : null,
        isRecurring: _isRecurring,
        primaryImageUrl: _primaryImageUrl,
        additionalImageUrls: _additionalImageUrls,
        isActive: _isActive,
        isFeatured: _isFeatured,
        trackInventory: _trackInventory,
        allowBackorder: _allowBackorder,
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
        createdBy: widget.item?.createdBy ?? user.uid,
        lastModifiedBy: user.uid,
      );

      if (_isEditing) {
        await _inventoryService.updateItem(item);
      } else {
        final id = await _inventoryService.createItem(item);
        _savedItemId = id;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Item actualizado' : 'Item creado'),
          backgroundColor: AppColors.success,
        ),
      );

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
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primarySurface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
