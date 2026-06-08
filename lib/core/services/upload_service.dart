// lib/core/services/upload_service.dart
// Servicio para subir archivos e imagenes a Supabase Storage via el backend

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../api/api_client.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final _picker = ImagePicker();

  /// Selecciona y sube una foto de perfil desde galeria o camara
  Future<String?> pickAndUploadAvatar({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) return null;

      return await uploadAvatar(File(image.path));
    } catch (e) {
      throw Exception('Error seleccionando imagen: $e');
    }
  }

  /// Sube un avatar al backend
  Future<String> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'avatar.jpg',
      ),
    });

    final response = await ApiClient().dio.post(
      '/upload/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data['data']['avatar_url'];
  }

  /// Selecciona y sube un archivo de evidencia para una sesion
  Future<String?> pickAndUploadSessionFile(String sessionId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      return await uploadSessionFile(sessionId, file, result.files.single.name);
    } catch (e) {
      throw Exception('Error seleccionando archivo: $e');
    }
  }

  /// Sube un archivo de sesion al backend
  Future<String> uploadSessionFile(String sessionId, File file, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await ApiClient().dio.post(
      '/upload/session/$sessionId',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data['data']['file_url'];
  }

  /// Selecciona imagen desde camara
  Future<String?> pickFromCamera(String sessionId) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return null;
    return uploadSessionFile(sessionId, File(image.path), 'evidencia.jpg');
  }
}
