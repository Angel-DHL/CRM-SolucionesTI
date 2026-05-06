// lib/ventas/pages/quote_form_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/firebase_helper.dart';
import '../../crm/models/crm_contact.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/pages/inventory_form_page.dart';
import '../models/sale_quote.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';

class QuoteFormPage extends StatefulWidget {
  final SaleQuote? quote;
  final String? opportunityId;
  final String? preselectedContactId;
  const QuoteFormPage({super.key, this.quote, this.opportunityId, this.preselectedContactId});

  @override
  State<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends State<QuoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool get _isEditing => widget.quote != null;

  // Cliente seleccionado
  CrmContact? _selectedClient;
  List<CrmContact> _allClients = [];
  bool _loadingClients = true;

  // Items de la cotización
  final List<SaleQuoteItem> _items = [];

  // Financiero
  double _descuentoGlobal = 0;
  final double _ivaPorcentaje = 16;
  final _vigenciaCtrl = TextEditingController(text: '15');
  final _condicionesCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _notasInternasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
    if (_isEditing) _loadQuoteData();
  }

  void _loadQuoteData() {
    final q = widget.quote!;
    _items.addAll(q.items);
    _descuentoGlobal = q.descuentoGlobal;
    _vigenciaCtrl.text = q.vigenciaDias.toString();
    _condicionesCtrl.text = q.condicionesPago ?? '';
    _notasCtrl.text = q.notas ?? '';
    _notasInternasCtrl.text = q.notasInternas ?? '';
  }

  Future<void> _loadClients() async {
    try {
      final snap = await FirebaseHelper.crmContacts.get();
      final clients = snap.docs.map(CrmContact.fromDoc).toList();
      if (mounted) {
        setState(() {
          _allClients = clients;
          _loadingClients = false;
          if (_isEditing) {
            _selectedClient = clients.where((c) => c.id == widget.quote!.clienteId).firstOrNull;
          } else if (widget.preselectedContactId != null) {
            _selectedClient = clients.where((c) => c.id == widget.preselectedContactId).firstOrNull;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClients = false);
    }
  }

  // Cálculos
  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _descuentoMonto => _subtotal * _descuentoGlobal / 100;
  double get _subtotalConDescuento => _subtotal - _descuentoMonto;
  double get _ivaTotal => _subtotalConDescuento * _ivaPorcentaje / 100;
  double get _total => _subtotalConDescuento + _ivaTotal;

  @override
  void dispose() {
    _vigenciaCtrl.dispose();
    _condicionesCtrl.dispose();
    _notasCtrl.dispose();
    _notasInternasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEditing ? 'Editar cotización' : 'Nueva cotización', style: AppTextStyles.h3),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildClientSection(),
                  const SizedBox(height: AppDimensions.lg),
                  _buildItemsSection(),
                  const SizedBox(height: AppDimensions.lg),
                  _buildFinancialSection(),
                  const SizedBox(height: AppDimensions.lg),
                  _buildConditionsSection(),
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
  // CLIENT SELECTOR (INTEGRACIÓN CRM)
  // ═══════════════════════════════════════════════════════════

  Widget _buildClientSection() {
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
            Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.sm),
            Text('Cliente', style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: AppDimensions.md),
          if (_loadingClients)
            const LinearProgressIndicator()
          else
            Autocomplete<CrmContact>(
              initialValue: _selectedClient != null
                  ? TextEditingValue(text: '${_selectedClient!.nombreCompleto} — ${_selectedClient!.empresa ?? "Sin empresa"}')
                  : TextEditingValue.empty,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return _allClients;
                final q = textEditingValue.text.toLowerCase();
                return _allClients.where((c) =>
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
                    labelText: 'Buscar cliente *',
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Nombre, empresa o email...',
                  ),
                  validator: (_) => _selectedClient == null ? 'Selecciona un cliente' : null,
                );
              },
              onSelected: (client) => setState(() => _selectedClient = client),
            ),
          if (_selectedClient != null) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_selectedClient!.nombreCompleto, style: AppTextStyles.labelLarge),
                  if (_selectedClient!.empresa != null) Text(_selectedClient!.empresa!, style: AppTextStyles.bodySmall),
                  Text(_selectedClient!.email, style: AppTextStyles.caption),
                  if (_selectedClient!.rfc != null) Text('RFC: ${_selectedClient!.rfc}', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ])),
                IconButton(
                  onPressed: () => setState(() => _selectedClient = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ITEMS (INTEGRACIÓN INVENTARIO)
  // ═══════════════════════════════════════════════════════════

  Widget _buildItemsSection() {
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
            Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.sm),
            Text('Productos / Servicios', style: AppTextStyles.labelLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: AppDimensions.md),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Center(child: Text('Agrega productos del inventario', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint))),
            )
          else
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: ListTile(
                  title: Text(item.nombre, style: AppTextStyles.bodyMedium),
                  subtitle: Text('${item.cantidad} × \$${item.precioUnitario.toStringAsFixed(2)}${item.descuento > 0 ? " (-${item.descuento}%)" : ""}',
                    style: AppTextStyles.caption),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('\$${item.subtotal.toStringAsFixed(2)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _items.removeAt(i)),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    ),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddProductDialog() async {
    List<InventoryItem> products = [];
    bool loading = true;

    try {
      final snap = await FirebaseHelper.inventoryItems.get();
      products = snap.docs.map(InventoryItem.fromDoc).toList();
      loading = false;
    } catch (_) {
      loading = false;
    }

    if (!mounted) return;

    InventoryItem? selected;
    final cantidadCtrl = TextEditingController(text: '1');
    final descuentoCtrl = TextEditingController(text: '0');
    final searchCtrl = TextEditingController();
    List<InventoryItem> filtered = products;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          void filterProducts(String query) {
            setDState(() {
              if (query.isEmpty) {
                filtered = products;
              } else {
                final q = query.toLowerCase();
                filtered = products.where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q) ||
                  (p.brand?.toLowerCase().contains(q) ?? false)
                ).toList();
              }
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.sm),
                      Text('Agregar producto', style: AppTextStyles.h4),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, size: 20)),
                    ]),
                    const SizedBox(height: AppDimensions.md),

                    // Search
                    TextFormField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, SKU o marca...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(onPressed: () { searchCtrl.clear(); filterProducts(''); }, icon: const Icon(Icons.clear_rounded, size: 18))
                            : null,
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide.none),
                      ),
                      onChanged: filterProducts,
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Product list or selected product
                    if (selected != null) ...[
                      // Selected product card
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: AppDimensions.md),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(selected!.name, style: AppTextStyles.labelLarge),
                              Text('SKU: ${selected!.sku}', style: AppTextStyles.caption),
                            ])),
                            IconButton(
                              onPressed: () => setDState(() => selected = null),
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primary),
                              tooltip: 'Cambiar producto',
                            ),
                          ]),
                          const SizedBox(height: AppDimensions.md),
                          Row(children: [
                            _infoChip(Icons.attach_money_rounded, '\$${selected!.sellingPrice.toStringAsFixed(2)}', AppColors.success),
                            const SizedBox(width: AppDimensions.sm),
                            _infoChip(Icons.inventory_rounded, 'Stock: ${selected!.stock}',
                              selected!.stock > 0 ? AppColors.primary : AppColors.error),
                            if (selected!.brand != null) ...[
                              const SizedBox(width: AppDimensions.sm),
                              _infoChip(Icons.branding_watermark_rounded, selected!.brand!, AppColors.textSecondary),
                            ],
                          ]),
                          const SizedBox(height: AppDimensions.md),
                          Row(children: [
                            Expanded(child: TextFormField(
                              controller: cantidadCtrl,
                              decoration: const InputDecoration(labelText: 'Cantidad', isDense: true, prefixIcon: Icon(Icons.numbers_rounded, size: 18)),
                              keyboardType: TextInputType.number,
                            )),
                            const SizedBox(width: AppDimensions.md),
                            Expanded(child: TextFormField(
                              controller: descuentoCtrl,
                              decoration: const InputDecoration(labelText: 'Descuento %', isDense: true, prefixIcon: Icon(Icons.discount_rounded, size: 18)),
                              keyboardType: TextInputType.number,
                            )),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      SizedBox(width: double.infinity, child: FilledButton.icon(
                        onPressed: () {
                          final cantidad = double.tryParse(cantidadCtrl.text) ?? 1;
                          final descuento = double.tryParse(descuentoCtrl.text) ?? 0;
                          final subtotal = SaleQuoteItem.calcSubtotal(cantidad, selected!.sellingPrice, descuento);
                          setState(() {
                            _items.add(SaleQuoteItem(
                              inventoryItemId: selected!.id, sku: selected!.sku,
                              nombre: selected!.name, descripcion: selected!.description,
                              cantidad: cantidad, unidad: selected!.unitOfMeasure.name,
                              precioUnitario: selected!.sellingPrice,
                              descuento: descuento, subtotal: subtotal,
                            ));
                          });
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Agregar a cotización'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                      )),
                    ] else ...[
                      // Product list
                      Expanded(
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : filtered.isEmpty
                                ? _buildNoProductsFound(ctx, searchCtrl.text)
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final p = filtered[i];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: 4),
                                        leading: Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySurface,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(child: Icon(
                                            p.type.name == 'servicio' ? Icons.engineering_rounded : Icons.inventory_2_rounded,
                                            size: 18, color: AppColors.primary,
                                          )),
                                        ),
                                        title: Text(p.name, style: AppTextStyles.bodyMedium),
                                        subtitle: Text('${p.sku} • \$${p.sellingPrice.toStringAsFixed(2)} • Stock: ${p.stock}',
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                        trailing: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                                        onTap: () => setDState(() => selected = p),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _buildNoProductsFound(BuildContext dialogCtx, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.md),
            Text(
              query.isNotEmpty ? 'No se encontró "$query"' : 'No hay productos en inventario',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const InventoryFormPage(),
                )).then((_) {
                  // Refresh will happen when user comes back
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear nuevo producto'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text('Se abrirá el formulario de inventario', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FINANCIAL
  // ═══════════════════════════════════════════════════════════

  Widget _buildFinancialSection() {
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
          Text('Resumen financiero', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          _row('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: AppDimensions.sm),
          Row(children: [
            const Text('Descuento global '),
            SizedBox(width: 60, child: TextFormField(
              initialValue: _descuentoGlobal.toStringAsFixed(0),
              decoration: const InputDecoration(suffixText: '%', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => _descuentoGlobal = double.tryParse(v) ?? 0),
            )),
            const Spacer(),
            Text('-\$${_descuentoMonto.toStringAsFixed(2)}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
          ]),
          const SizedBox(height: AppDimensions.sm),
          _row('IVA (${_ivaPorcentaje.toStringAsFixed(0)}%)', '\$${_ivaTotal.toStringAsFixed(2)}'),
          const Divider(),
          _row('Total', '\$${_total.toStringAsFixed(2)} MXN', isBold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
      Text(value, style: (isBold ? AppTextStyles.h4 : AppTextStyles.labelLarge).copyWith(color: AppColors.primary)),
    ]);
  }

  Widget _buildConditionsSection() {
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
          Text('Condiciones', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          TextFormField(controller: _vigenciaCtrl, decoration: const InputDecoration(labelText: 'Vigencia (días)'), keyboardType: TextInputType.number),
          const SizedBox(height: AppDimensions.md),
          TextFormField(controller: _condicionesCtrl, decoration: const InputDecoration(labelText: 'Condiciones de pago'), maxLines: 2),
          const SizedBox(height: AppDimensions.md),
          TextFormField(controller: _notasCtrl, decoration: const InputDecoration(labelText: 'Notas (visibles en PDF)'), maxLines: 3),
          const SizedBox(height: AppDimensions.md),
          TextFormField(controller: _notasInternasCtrl, decoration: const InputDecoration(labelText: 'Notas internas (no visibles para el cliente)', prefixIcon: Icon(Icons.lock_outline_rounded)), maxLines: 2),
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
        label: Text(_isEditing ? 'Guardar cambios' : 'Crear cotización'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd))),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto'), backgroundColor: AppColors.warning));
      return;
    }

    setState(() => _saving = true);
    try {
      final vigencia = int.tryParse(_vigenciaCtrl.text) ?? 15;
      final quote = SaleQuote(
        id: widget.quote?.id ?? '',
        folio: widget.quote?.folio ?? '',
        status: widget.quote?.status ?? QuoteStatus.borrador,
        clienteId: _selectedClient!.id,
        clienteNombre: _selectedClient!.nombreCompleto,
        clienteEmail: _selectedClient!.email,
        clienteTelefono: _selectedClient!.telefono,
        clienteRfc: _selectedClient!.rfc,
        clienteRazonSocial: _selectedClient!.razonSocial,
        clienteEmpresa: _selectedClient!.empresa,
        clienteDireccion: _selectedClient!.direccionCompleta,
        items: _items,
        subtotal: _subtotal,
        descuentoGlobal: _descuentoGlobal,
        subtotalConDescuento: _subtotalConDescuento,
        ivaPorcentaje: _ivaPorcentaje,
        ivaTotal: _ivaTotal,
        total: _total,
        vigenciaDias: vigencia,
        fechaExpiracion: DateTime.now().add(Duration(days: vigencia)),
        condicionesPago: _condicionesCtrl.text.isNotEmpty ? _condicionesCtrl.text : null,
        notas: _notasCtrl.text.isNotEmpty ? _notasCtrl.text : null,
        notasInternas: _notasInternasCtrl.text.isNotEmpty ? _notasInternasCtrl.text : null,
        opportunityId: widget.opportunityId ?? widget.quote?.opportunityId,
        version: widget.quote?.version ?? 1,
        createdAt: widget.quote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.quote?.createdBy ?? '',
      );

      if (_isEditing) {
        await VentasService.instance.updateQuote(quote);
      } else {
        await VentasService.instance.createQuote(quote);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? '✅ Cotización actualizada' : '✅ Cotización creada'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Error saving quote: $e');
      debugPrint('Stacktrace: $stack');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e\nRevisa la consola para más detalles'), backgroundColor: AppColors.error, duration: const Duration(seconds: 5)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
