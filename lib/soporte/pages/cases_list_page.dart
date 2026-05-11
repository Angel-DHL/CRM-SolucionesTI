// lib/soporte/pages/cases_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/support_case.dart';
import '../models/support_enums.dart';
import '../services/support_service.dart';
import 'case_detail_page.dart';
import 'case_form_page.dart';

class CasesListPage extends StatefulWidget {
  const CasesListPage({super.key});

  @override
  State<CasesListPage> createState() => _CasesListPageState();
}

class _CasesListPageState extends State<CasesListPage> {
  CaseStatus? _statusFilter;
  CaseCategory? _categoryFilter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        // Filtros
        Container(
          padding: EdgeInsets.all(isMobile ? AppDimensions.sm : AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            children: [
              // Búsqueda
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por título, folio o cliente...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              // Chips de filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', _statusFilter == null, () => setState(() => _statusFilter = null)),
                    ...CaseStatus.values.map((s) => _buildFilterChip(
                      s.label, _statusFilter == s,
                      () => setState(() => _statusFilter = _statusFilter == s ? null : s),
                      color: s.color,
                    )),
                    const SizedBox(width: AppDimensions.md),
                    const VerticalDivider(width: 1),
                    const SizedBox(width: AppDimensions.md),
                    ...CaseCategory.values.map((c) => _buildFilterChip(
                      c.label, _categoryFilter == c,
                      () => setState(() => _categoryFilter = _categoryFilter == c ? null : c),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: StreamBuilder<List<SupportCase>>(
            stream: SupportService.instance.streamCases(
              status: _statusFilter,
              category: _categoryFilter,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var cases = snap.data ?? [];

              // Filtro de búsqueda local
              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                cases = cases.where((c) =>
                    c.titulo.toLowerCase().contains(q) ||
                    c.folio.toLowerCase().contains(q) ||
                    (c.clienteNombre?.toLowerCase().contains(q) ?? false)
                ).toList();
              }

              if (cases.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
                      const SizedBox(height: AppDimensions.md),
                      Text('No hay casos', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
                      const SizedBox(height: AppDimensions.sm),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaseFormPage())),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Crear primer caso'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.all(isMobile ? AppDimensions.sm : AppDimensions.md),
                itemCount: cases.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.xs),
                itemBuilder: (context, i) => _CaseCard(
                  caso: cases[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CaseDetailPage(caseId: cases[i].id)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        )),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.background,
        selectedColor: color ?? AppColors.primary,
        side: BorderSide(color: selected ? Colors.transparent : AppColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final SupportCase caso;
  final VoidCallback onTap;

  const _CaseCard({required this.caso, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy HH:mm', 'es_MX');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: caso.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(caso.status.icon, size: 14, color: caso.status.color),
                        const SizedBox(width: 4),
                        Text(caso.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: caso.status.color)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(caso.category.icon, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(caso.category.label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Priority
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: caso.priority.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(caso.priority.icon, size: 12, color: caso.priority.color),
                        const SizedBox(width: 3),
                        Text(caso.priority.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: caso.priority.color)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(caso.folio, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(caso.titulo, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(caso.assignedName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  const Spacer(),
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(df.format(caso.createdAt), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
