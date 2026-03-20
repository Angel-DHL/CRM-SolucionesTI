// lib/inventory/services/inventory_category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase_helper.dart';
import '../models/inventory_category.dart';

class InventoryCategoryService {
  InventoryCategoryService._();
  static final InventoryCategoryService instance = InventoryCategoryService._();

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      FirebaseHelper.inventoryCategories;

  // ═══════════════════════════════════════════════════════════
  // CREAR CATEGORÍA
  // ═══════════════════════════════════════════════════════════

  /// Crear nueva categoría
  Future<String> createCategory(InventoryCategory category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Generar slug si no existe
      String slug = category.slug;
      if (slug.isEmpty) {
        slug = InventoryCategory.generateSlug(category.name);
      }

      // Verificar slug único
      slug = await _ensureUniqueSlug(slug);

      // Calcular nivel y path
      int level = 0;
      String path = slug;
      List<String> ancestorIds = [];

      if (category.parentId != null) {
        final parentDoc = await _categoriesRef.doc(category.parentId).get();
        if (parentDoc.exists) {
          final parent = InventoryCategory.fromDoc(parentDoc);
          level = parent.level + 1;
          path = '${parent.path}/$slug';
          ancestorIds = [...parent.ancestorIds, parent.id];
        }
      }

      final data = category
          .copyWith(
            slug: slug,
            level: level,
            path: path,
            ancestorIds: ancestorIds,
            createdBy: user.uid,
            lastModifiedBy: user.uid,
          )
          .toMap();

      final docRef = await _categoriesRef.add(data);

      // Actualizar contador de hijos del padre
      if (category.parentId != null) {
        await _updateChildCount(category.parentId!, 1);
      }

      debugPrint('✅ Categoría creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creando categoría: $e');
      rethrow;
    }
  }

  /// Asegurar slug único
  Future<String> _ensureUniqueSlug(String baseSlug) async {
    String slug = baseSlug;
    int counter = 1;

    while (true) {
      final existing = await _categoriesRef
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) break;

      slug = '$baseSlug-$counter';
      counter++;
    }

    return slug;
  }

  // ═══════════════════════════════════════════════════════════
  // LEER CATEGORÍAS
  // ═══════════════════════════════════════════════════════════

  /// Obtener categoría por ID
  Future<InventoryCategory?> getCategoryById(String id) async {
    try {
      final doc = await _categoriesRef.doc(id).get();
      if (!doc.exists) return null;
      return InventoryCategory.fromDoc(doc);
    } catch (e) {
      debugPrint('❌ Error obteniendo categoría: $e');
      rethrow;
    }
  }

  /// Stream de todas las categorías
  Stream<List<InventoryCategory>> streamCategories({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _categoriesRef;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('displayOrder')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(InventoryCategory.fromDoc).toList(),
        );
  }

  /// Stream de categorías raíz (sin padre)
  Stream<List<InventoryCategory>> streamRootCategories({
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _categoriesRef.where(
      'parentId',
      isNull: true,
    );

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('displayOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(InventoryCategory.fromDoc).toList(),
        );
  }

  /// Stream de subcategorías
  Stream<List<InventoryCategory>> streamSubcategories(
    String parentId, {
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _categoriesRef.where(
      'parentId',
      isEqualTo: parentId,
    );

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('displayOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(InventoryCategory.fromDoc).toList(),
        );
  }

  /// Obtener árbol de categorías completo
  Future<List<CategoryNode>> getCategoryTree({bool activeOnly = true}) async {
    Query<Map<String, dynamic>> query = _categoriesRef;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.orderBy('displayOrder').get();
    final categories = snapshot.docs.map(InventoryCategory.fromDoc).toList();

    // Construir árbol
    final Map<String?, List<InventoryCategory>> grouped = {};
    for (final cat in categories) {
      grouped.putIfAbsent(cat.parentId, () => []).add(cat);
    }

    List<CategoryNode> buildNodes(String? parentId) {
      final children = grouped[parentId] ?? [];
      return children
          .map(
            (cat) => CategoryNode(category: cat, children: buildNodes(cat.id)),
          )
          .toList();
    }

    return buildNodes(null);
  }

  /// Obtener ruta de breadcrumb
  Future<List<InventoryCategory>> getBreadcrumb(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return [];

    final breadcrumb = <InventoryCategory>[];

    // Obtener ancestros
    for (final ancestorId in category.ancestorIds) {
      final ancestor = await getCategoryById(ancestorId);
      if (ancestor != null) {
        breadcrumb.add(ancestor);
      }
    }

    breadcrumb.add(category);
    return breadcrumb;
  }

  // ═══════════════════════════════════════════════════════════
  // ACTUALIZAR CATEGORÍA
  // ═══════════════════════════════════════════════════════════

  /// Actualizar categoría
  Future<void> updateCategory(InventoryCategory category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final data = category.copyWith(lastModifiedBy: user.uid).toUpdateMap();

      await _categoriesRef.doc(category.id).update(data);

      debugPrint('✅ Categoría actualizada: ${category.id}');
    } catch (e) {
      debugPrint('❌ Error actualizando categoría: $e');
      rethrow;
    }
  }

  /// Mover categoría a otro padre
  Future<void> moveCategory(String categoryId, String? newParentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final category = await getCategoryById(categoryId);
      if (category == null) throw Exception('Categoría no encontrada');

      final oldParentId = category.parentId;

      // Calcular nuevo nivel, path y ancestros
      int newLevel = 0;
      String newPath = category.slug;
      List<String> newAncestorIds = [];

      if (newParentId != null) {
        final newParent = await getCategoryById(newParentId);
        if (newParent != null) {
          newLevel = newParent.level + 1;
          newPath = '${newParent.path}/${category.slug}';
          newAncestorIds = [...newParent.ancestorIds, newParent.id];
        }
      }

      await _categoriesRef.doc(categoryId).update({
        'parentId': newParentId,
        'level': newLevel,
        'path': newPath,
        'ancestorIds': newAncestorIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': user.uid,
      });

      // Actualizar contadores
      if (oldParentId != null) {
        await _updateChildCount(oldParentId, -1);
      }
      if (newParentId != null) {
        await _updateChildCount(newParentId, 1);
      }

      // Actualizar hijos recursivamente
      await _updateChildrenPaths(categoryId, newPath, newLevel, newAncestorIds);

      debugPrint('✅ Categoría movida: $categoryId');
    } catch (e) {
      debugPrint('❌ Error moviendo categoría: $e');
      rethrow;
    }
  }

  /// Actualizar paths de hijos recursivamente
  Future<void> _updateChildrenPaths(
    String parentId,
    String parentPath,
    int parentLevel,
    List<String> parentAncestorIds,
  ) async {
    final children = await _categoriesRef
        .where('parentId', isEqualTo: parentId)
        .get();

    for (final childDoc in children.docs) {
      final child = InventoryCategory.fromDoc(childDoc);
      final newPath = '$parentPath/${child.slug}';
      final newLevel = parentLevel + 1;
      final newAncestorIds = [...parentAncestorIds, parentId];

      await _categoriesRef.doc(child.id).update({
        'path': newPath,
        'level': newLevel,
        'ancestorIds': newAncestorIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recursión
      await _updateChildrenPaths(child.id, newPath, newLevel, newAncestorIds);
    }
  }

  /// Reordenar categorías
  Future<void> reorderCategories(List<String> categoryIds) async {
    final batch = FirebaseHelper.db.batch();

    for (int i = 0; i < categoryIds.length; i++) {
      batch.update(_categoriesRef.doc(categoryIds[i]), {
        'displayOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    debugPrint('✅ Categorías reordenadas');
  }

  // ═══════════════════════════════════════════════════════════
  // ELIMINAR CATEGORÍA
  // ═══════════════════════════════════════════════════════════

  /// Verificar si se puede eliminar
  Future<bool> canDeleteCategory(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return false;

    // No se puede eliminar si tiene hijos
    if (category.childCategoryCount > 0) return false;

    // No se puede eliminar si tiene items
    if (category.itemCount > 0) return false;

    return true;
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String categoryId) async {
    if (!await canDeleteCategory(categoryId)) {
      throw Exception(
        'No se puede eliminar: la categoría tiene subcategorías o items',
      );
    }

    try {
      final category = await getCategoryById(categoryId);

      await _categoriesRef.doc(categoryId).delete();

      // Actualizar contador del padre
      if (category?.parentId != null) {
        await _updateChildCount(category!.parentId!, -1);
      }

      debugPrint('✅ Categoría eliminada: $categoryId');
    } catch (e) {
      debugPrint('❌ Error eliminando categoría: $e');
      rethrow;
    }
  }

  /// Desactivar categoría (soft delete)
  Future<void> deactivateCategory(String categoryId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _categoriesRef.doc(categoryId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': user.uid,
    });

    debugPrint('✅ Categoría desactivada: $categoryId');
  }

  // ═══════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════

  /// Actualizar contador de hijos
  Future<void> _updateChildCount(String categoryId, int delta) async {
    try {
      await _categoriesRef.doc(categoryId).update({
        'childCategoryCount': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Error actualizando contador de hijos: $e');
    }
  }
}

/// Nodo del árbol de categorías
class CategoryNode {
  final InventoryCategory category;
  final List<CategoryNode> children;

  CategoryNode({required this.category, required this.children});

  bool get hasChildren => children.isNotEmpty;
}
