// lib/core/services/storage_service.dart

import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado para subir archivos a Firebase Storage.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _storage = FirebaseStorage.instance;

  /// Sube la foto de perfil del usuario actual.
  /// Devuelve la URL pública de la imagen.
  Future<String> uploadProfilePhoto(Uint8List imageBytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    final ref = _storage.ref('users/$uid/avatar.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    await ref.putData(imageBytes, metadata);
    final url = await ref.getDownloadURL();

    // Actualizar photoURL en FirebaseAuth
    await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);

    debugPrint('✅ Foto de perfil subida: $url');
    return url;
  }

  /// Elimina la foto de perfil del usuario actual.
  Future<void> deleteProfilePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _storage.ref('users/$uid/avatar.jpg').delete();
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);
    } catch (e) {
      debugPrint('⚠️ Error eliminando foto: $e');
    }
  }
}
