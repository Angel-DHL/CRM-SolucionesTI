// lib/inventory/pages/inventory_list_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/inventory_item.dart';
import '../models/inventory_enums.dart';
import '../services/inventory_service.dart';
import '../widgets/cards/inventory_item_card.dart';
import '../widgets/filters/inventory_search_bar.dart';
import '../widgets/filters/inventory_filters.dart';
import '../widgets/dialogs/stock_movement_dialog.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/common/inventory_loading.dart';
import '../widgets/common/inventory_empty_state.dart';
import '../widgets/common/inventory_error_view.dart';
import 'inventory_detail_page.dart';
import 'inventory_form_page.dart';

enum InventoryListView { grid, list }

class InventoryListPage extends StatefulWidget {
  final UserRole role;
  final InventoryItemType? initialTypeFilter;

  const InventoryListPage({
    super.key,
    required this.role,
    this.initialTypeFilter,
  });

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _inventoryService = InventoryService.instance;
  final _scrollController = ScrollController();

  InventoryFilters _filters = InventoryFilters.none;
  InventoryListView _viewMode = InventoryListView.list;
  String _searchQuery = '';

  // Paginación
  final List<InventoryItem> _items = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    if (widget.initialTypeFilter != null) {
      _filters = _filters.copyWith(type: widget.initialTypeFilter);
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _inventoryService.getItemsPaginated(
        filters: _filters.copyWith(searchQuery: _searchQuery),
        pageSize: _pageSize,
        startAfter: _lastDocument,
      );

      setState(() {
        _items.addAll(result.items);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _refresh() {
    setState(() {
      _items.clear();
      _lastDocument = null;
      _hasMore = true;
    });
  }

  void _updateFilters(InventoryFilters newFilters) {
    setState(() {
      _filters = newFilters;
      _refresh();
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      _refresh();
    });
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_filters.type != null) count++;
    if (_filters.status != null) count++;
    if (_filters.categoryId != null) count++;
    if (_filters.isStockLow == true) count++;
    if (_filters.isActive != null) count++;
    if (_filters.isFeatured != null) count++;
    if (_filters.minPrice != null) count++;
    if (_filters.maxPrice != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isAdmin = widget.role == UserRole.admin;

    return Column(
      children: [
        // Search bar
        InventorySearchBar(
          initialValue: _searchQuery,
          onChanged: _updateSearch,
          onFilterTap: () => _showFilters(context),
          activeFiltersCount: _activeFiltersCount,
        ),

        // Type filter chips
        if (!isMobile) _buildTypeFilterChips(),

        // Content
        Expanded(
          child: StreamBuilder<List<InventoryItem>>(
            stream: _inventoryService.streamItems(
              filters: _filters.copyWith(searchQuery: _searchQuery),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const InventoryLoading(
                  message: 'Cargando inventario...',
                );
              }

              if (snapshot.hasError) {
                return InventoryErrorView.loadError(
                  errorMessage: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return InventoryEmptyState.items(
                  hasFilters: _filters.hasFilters || _searchQuery.isNotEmpty,
                  onClearFilters: () {
                    setState(() {
                      _filters = InventoryFilters.none;
                      _searchQuery = '';
                    });
                  },
                  onAddItem: isAdmin ? _showCreateItem : null,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: _viewMode == InventoryListView.grid
                    ? _buildGridView(items, isMobile)
                    : _buildListView(items),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      child: Row(
        children: [
          // All types chip
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: FilterChip(
              label: const Text('Todos'),
              selected: _filters.type == null,
              onSelected: (_) {
                _updateFilters(_filters.copyWith(type: null));
              },
            ),
          ),
          // Type chips
          ...InventoryItemType.values.map((type) {
            final isSelected = _filters.type == type;
            return Padding(
              padding: const EdgeInsets.only(right: AppDimensions.sm),
              child: FilterChip(
                avatar: Icon(type.icon, size: 18),
                label: Text(type.label),
                selected: isSelected,
                selectedColor: type.color.withOpacity(0.2),
                onSelected: (_) {
                  _updateFilters(
                    _filters.copyWith(type: isSelected ? null : type),
                  );
                },
              ),
            );
          }),
          const Spacer(),
          // View mode toggle
          SegmentedButton<InventoryListView>(
            segments: const [
              ButtonSegment(
                value: InventoryListView.list,
                icon: Icon(Icons.view_list_rounded),
              ),
              ButtonSegment(
                value: InventoryListView.grid,
                icon: Icon(Icons.grid_view_rounded),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selection) {
              setState(() => _viewMode = selection.first);
            },
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<InventoryItem> items) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = items[index];
        return InventoryItemCard(
          item: item,
          onTap: () => _navigateToDetail(item),
          onEdit: widget.role == UserRole.admin
              ? () => _showEditItem(item)
              : null,
          onDelete: widget.role == UserRole.admin
              ? () => _confirmDelete(item)
              : null,
          onStockMovement: item.type != InventoryItemType.service
              ? () => _showStockMovement(item)
              : null,
        );
      },
    );
  }

  Widget _buildGridView(List<InventoryItem> items, bool isMobile) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimensions.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: AppDimensions.md,
        mainAxisSpacing: AppDimensions.md,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final item = items[index];
        return _ItemGridCard(item: item, onTap: () => _navigateToDetail(item));
      },
    );
  }

  void _showFilters(BuildContext context) {
    InventoryFiltersSheet.show(
      context,
      currentFilters: _filters,
      onApply: _updateFilters,
    );
  }

  void _showCreateItem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(
          onSaved: () {
            Navigator.pop(context);
            _refresh();
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showEditItem(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(
          item: item,
          onSaved: () {
            Navigator.pop(context);
            _refresh();
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToDetail(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InventoryDetailPage(itemId: item.id)),
    );
  }

  void _showStockMovement(InventoryItem item) {
    StockMovementDialog.show(context, item: item, onSuccess: _refresh);
  }

  Future<void> _confirmDelete(InventoryItem item) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Eliminar item',
      message:
          '¿Estás seguro de que deseas eliminar este item? Esta acción no se puede deshacer.',
      itemName: item.name,
      requireConfirmation: true,
      onConfirm: () async {
        await _inventoryService.softDeleteItem(item.id);
      },
    );

    if (confirmed) {
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item eliminado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════
// GRID CARD
// ══════════════════════════════════════════════════════════════

class _ItemGridCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const _ItemGridCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusMd),
                  ),
                  color: AppColors.surface,
                  image: item.primaryImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(item.primaryImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.primaryImageUrl == null
                    ? Center(
                        child: Icon(
                          item.type.icon,
                          size: 48,
                          color: item.type.color.withOpacity(0.3),
                        ),
                      )
                    : null,
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${item.sellingPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        if (item.type != InventoryItemType.service)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.isStockLow
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.stock}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: item.isStockLow
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
