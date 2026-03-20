// lib/inventory/services/inventory_storage_service.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class InventoryStorageService {
  InventoryStorageService._();
  static final InventoryStorageService instance = InventoryStorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Configuración
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxImagesPerItem = 5;
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
  ];

  // ═══════════════════════════════════════════════════════════
  // SUBIR IMÁGENES
  // ═══════════════════════════════════════════════════════════

  /// Subir imagen desde selector de archivos
  Future<String?> uploadItemImage(
    String itemId, {
    bool isPrimary = false,
    int? imageIndex,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedImageExtensions,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;

      // Validar tamaño
      if ((file.size) > maxImageSizeBytes) {
        throw Exception('La imagen excede el tamaño máximo de 5MB');
      }

      // Generar path
      final extension = file.extension ?? 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = isPrimary
          ? 'primary_$timestamp.$extension'
          : 'image_${imageIndex ?? timestamp}_$timestamp.$extension';
      final path = 'inventory/$itemId/images/$fileName';

      // Subir archivo
      String downloadUrl;

      if (kIsWeb) {
        // Web: usar bytes
        if (file.bytes == null) throw Exception('No se pudo leer el archivo');
        downloadUrl = await _uploadBytes(path, file.bytes!, file.name);
      } else {
        // Móvil/Desktop: usar path
        if (file.path == null) throw Exception('No se pudo acceder al archivo');
        downloadUrl = await _uploadFile(path, File(file.path!));
      }

      debugPrint('✅ Imagen subida: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error subiendo imagen: $e');
      rethrow;
    }
  }

  /// Subir múltiples imágenes
  Future<List<String>> uploadMultipleImages(String itemId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedImageExtensions,
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return [];

      // Validar cantidad
      if (result.files.length > maxImagesPerItem) {
        throw Exception('Máximo $maxImagesPerItem imágenes permitidas');
      }

      final urls = <String>[];

      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];

        // Validar tamaño
        if ((file.size) > maxImageSizeBytes) {
          debugPrint('⚠️ Imagen ${file.name} excede el tamaño máximo, omitida');
          continue;
        }

        final extension = file.extension ?? 'jpg';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'image_${i}_$timestamp.$extension';
        final path = 'inventory/$itemId/images/$fileName';

        String downloadUrl;

        if (kIsWeb) {
          if (file.bytes == null) continue;
          downloadUrl = await _uploadBytes(path, file.bytes!, file.name);
        } else {
          if (file.path == null) continue;
          downloadUrl = await _uploadFile(path, File(file.path!));
        }

        urls.add(downloadUrl);
      }

      debugPrint('✅ ${urls.length} imágenes subidas');
      return urls;
    } catch (e) {
      debugPrint('❌ Error subiendo imágenes: $e');
      rethrow;
    }
  }

  /// Subir desde bytes (para web o imágenes procesadas)
  Future<String> _uploadBytes(
    String path,
    Uint8List bytes,
    String originalName,
  ) async {
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: _getContentType(originalName),
      customMetadata: {
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'uploadedAt': DateTime.now().toIso8601String(),
        'originalName': originalName,
      },
    );

    final uploadTask = await ref.putData(bytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Subir desde archivo
  Future<String> _uploadFile(String path, File file) async {
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: _getContentType(file.path),
      customMetadata: {
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = await ref.putFile(file, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => 'application/octet-stream',
    };
  }

  // ═══════════════════════════════════════════════════════════
  // SUBIR DOCUMENTOS
  // ═══════════════════════════════════════════════════════════

  /// Subir documento adjunto
  Future<String?> uploadDocument(String itemId, {String? folder}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...allowedDocumentExtensions,
          ...allowedImageExtensions,
        ],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final extension = file.extension ?? 'pdf';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = _sanitizeFileName(file.name);
      final path =
          'inventory/$itemId/${folder ?? "documents"}/${timestamp}_$safeFileName';

      String downloadUrl;

      if (kIsWeb) {
        if (file.bytes == null) throw Exception('No se pudo leer el archivo');
        downloadUrl = await _uploadBytes(path, file.bytes!, file.name);
      } else {
        if (file.path == null) throw Exception('No se pudo acceder al archivo');
        downloadUrl = await _uploadFile(path, File(file.path!));
      }

      debugPrint('✅ Documento subido: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error subiendo documento: $e');
      rethrow;
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  // ═══════════════════════════════════════════════════════════
  // ELIMINAR ARCHIVOS
  // ═══════════════════════════════════════════════════════════

  /// Eliminar imagen por URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Imagen eliminada');
    } catch (e) {
      debugPrint('⚠️ Error eliminando imagen: $e');
      // No relanzar error para no bloquear operaciones
    }
  }

  /// Eliminar todas las imágenes de un item
  Future<void> deleteAllItemImages(String itemId) async {
    try {
      final ref = _storage.ref().child('inventory/$itemId/images');
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }

      debugPrint('✅ Todas las imágenes eliminadas para item: $itemId');
    } catch (e) {
      debugPrint('⚠️ Error eliminando imágenes: $e');
    }
  }

  /// Eliminar todos los archivos de un item
  Future<void> deleteAllItemFiles(String itemId) async {
    try {
      final ref = _storage.ref().child('inventory/$itemId');
      await _deleteFolder(ref);
      debugPrint('✅ Todos los archivos eliminados para item: $itemId');
    } catch (e) {
      debugPrint('⚠️ Error eliminando archivos: $e');
    }
  }

  Future<void> _deleteFolder(Reference ref) async {
    final listResult = await ref.listAll();

    for (final item in listResult.items) {
      await item.delete();
    }

    for (final prefix in listResult.prefixes) {
      await _deleteFolder(prefix);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════

  /// Obtener URL de descarga
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('⚠️ Error obteniendo URL: $e');
      return null;
    }
  }

  /// Listar imágenes de un item
  Future<List<String>> listItemImages(String itemId) async {
    try {
      final ref = _storage.ref().child('inventory/$itemId/images');
      final listResult = await ref.listAll();

      final urls = <String>[];
      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      debugPrint('⚠️ Error listando imágenes: $e');
      return [];
    }
  }

  /// Verificar si existe archivo
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
}
