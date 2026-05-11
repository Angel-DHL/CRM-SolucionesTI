// lib/soporte/pages/knowledge_base_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/knowledge_article.dart';
import '../models/support_enums.dart';
import '../services/knowledge_service.dart';

class KnowledgeBasePage extends StatefulWidget {
  const KnowledgeBasePage({super.key});

  @override
  State<KnowledgeBasePage> createState() => _KnowledgeBasePageState();
}

class _KnowledgeBasePageState extends State<KnowledgeBasePage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  CaseCategory? _categoryFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar + búsqueda
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar artículos o FAQs...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.article_rounded), text: 'Artículos'),
                  Tab(icon: Icon(Icons.help_center_rounded), text: 'FAQs'),
                ],
              ),
            ],
          ),
        ),
        // Category filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _catChip('Todas', _categoryFilter == null, () => setState(() => _categoryFilter = null)),
                ...CaseCategory.values.map((c) => _catChip(
                  c.label, _categoryFilter == c,
                  () => setState(() => _categoryFilter = _categoryFilter == c ? null : c),
                )),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildArticlesTab(),
              _buildFaqsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _catChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: const Color(0xFF6366F1),
        side: BorderSide(color: selected ? Colors.transparent : AppColors.divider),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildArticlesTab() {
    return StreamBuilder<List<KnowledgeArticle>>(
      stream: KnowledgeService.instance.streamArticles(category: _categoryFilter),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var articles = snap.data ?? [];

        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          articles = articles.where((a) =>
              a.titulo.toLowerCase().contains(q) ||
              a.tags.any((t) => t.toLowerCase().contains(q)) ||
              a.problemaSintomas.toLowerCase().contains(q)
          ).toList();
        }

        if (articles.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                const SizedBox(height: AppDimensions.md),
                Text('Sin artículos', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
                const SizedBox(height: AppDimensions.xs),
                Text('Los artículos se generan al resolver casos con IA', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
          itemBuilder: (_, i) => _ArticleCard(article: articles[i]),
        );
      },
    );
  }

  Widget _buildFaqsTab() {
    return StreamBuilder<List<SupportFaq>>(
      stream: KnowledgeService.instance.streamFaqs(category: _categoryFilter),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var faqs = snap.data ?? [];

        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          faqs = faqs.where((f) =>
              f.pregunta.toLowerCase().contains(q) ||
              f.respuesta.toLowerCase().contains(q)
          ).toList();
        }

        if (faqs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_center_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                const SizedBox(height: AppDimensions.md),
                Text('Sin FAQs', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
                const SizedBox(height: AppDimensions.md),
                FilledButton.icon(
                  onPressed: () => _showAddFaqDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar FAQ'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: faqs.length + 1,
          itemBuilder: (_, i) {
            if (i == faqs.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: _showAddFaqDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar FAQ'),
                  ),
                ),
              );
            }

            final faq = faqs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: const Icon(Icons.help_outline_rounded, size: 18, color: Color(0xFF6366F1)),
                ),
                title: Text(faq.pregunta, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppDimensions.lg, 0, AppDimensions.lg, AppDimensions.lg),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(faq.respuesta, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddFaqDialog() {
    final preguntaCtrl = TextEditingController();
    final respuestaCtrl = TextEditingController();
    CaseCategory cat = CaseCategory.otro;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          title: const Text('Nueva FAQ'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: preguntaCtrl,
                  decoration: const InputDecoration(labelText: 'Pregunta *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: AppDimensions.md),
                TextField(
                  controller: respuestaCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Respuesta *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: AppDimensions.md),
                DropdownButtonFormField<CaseCategory>(
                  value: cat,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: CaseCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setDialogState(() => cat = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (preguntaCtrl.text.trim().isEmpty || respuestaCtrl.text.trim().isEmpty) return;
                await KnowledgeService.instance.createFaq(SupportFaq(
                  id: '',
                  pregunta: preguntaCtrl.text.trim(),
                  respuesta: respuestaCtrl.text.trim(),
                  categoria: cat,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final KnowledgeArticle article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (article.generadoPorIA) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF6366F1)),
                      SizedBox(width: 3),
                      Text('IA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(article.categoria.label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.visibility_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Text('${article.vistas}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(width: AppDimensions.sm),
                  const Icon(Icons.thumb_up_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Text('${article.utilidad}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(article.titulo, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          if (article.problemaSintomas.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(article.problemaSintomas, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (article.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: article.tags.take(5).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('#$t', style: const TextStyle(fontSize: 10, color: AppColors.primary)),
              )).toList(),
            ),
          ],
          const SizedBox(height: AppDimensions.sm),
          // Expandable content
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Ver solución completa', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  article.contenido.isNotEmpty ? article.contenido : article.solucionPasos,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => KnowledgeService.instance.voteUtility(article.id),
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: const Text('Útil'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.success, visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
