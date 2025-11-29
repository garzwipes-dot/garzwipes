import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryStorageProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  static const String _cloudName = 'deu33hkyk';
  static const String _apiKey = '914296722192612';
  static const String _apiSecret = 'RxyIfUwfEPye_nlhFrB5UgiiCs4';
  static const String _uploadPreset = 'garzwipes_upload';

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _deleteFromCloudinary =
      true; // true = eliminar de Cloudinary, false = solo Supabase

  bool get deleteFromCloudinary => _deleteFromCloudinary;
  set deleteFromCloudinary(bool value) {
    _deleteFromCloudinary = value;
    notifyListeners();
    print('Modo deleteFromCloudinary cambiado a: $value');
  }

  // Método para generar signature de Cloudinary
  String _generateSignature(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    final signatureString =
        sortedKeys.map((key) => '$key=${params[key]}').join('&') + _apiSecret;
    return sha1.convert(utf8.encode(signatureString)).toString();
  }

  Future<String?> uploadImage(String imagePath) async {
    try {
      _isUploading = true;
      notifyListeners();

      final imageFile = XFile(imagePath);
      final imageUrl = await _uploadToCloudinary(
        imageFile: imageFile,
        userId: 'temp_upload',
      );

      _isUploading = false;
      notifyListeners();
      return imageUrl;
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      print('Error en uploadImage: $e');
      return null;
    }
  }

  Future<bool> uploadUserPhoto({
    required String userId,
    required XFile imageFile,
    required int displayOrder,
  }) async {
    try {
      _isUploading = true;
      notifyListeners();

      final imageUrl = await _uploadToCloudinary(
        imageFile: imageFile,
        userId: userId,
      );

      if (imageUrl == null) {
        throw Exception('Error al subir la imagen a Cloudinary');
      }

      final success = await _savePhotoReference(
        userId: userId,
        photoUrl: imageUrl,
        displayOrder: displayOrder,
      );

      _isUploading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      print('Error subiendo imagen: $e');
      return false;
    }
  }

  Future<String?> _uploadToCloudinary({
    required XFile imageFile,
    required String userId,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileSizeInMB = bytes.length / (1024 * 1024);

      const maxFileSize = 2 * 1024 * 1024; // 2MB en bytes
      if (bytes.length > maxFileSize) {
        print(
            '❌ Imagen demasiado grande: ${fileSizeInMB.toStringAsFixed(2)}MB (Máximo: 2MB)');
        throw Exception(
            'La imagen es demasiado grande (${fileSizeInMB.toStringAsFixed(2)}MB). Máximo permitido: 2MB');
      }

      print('✅ Tamaño de imagen válido: ${fileSizeInMB.toStringAsFixed(2)}MB');

      const uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'garzwipes/$userId';
      request.fields['public_id'] =
          'photo_${DateTime.now().millisecondsSinceEpoch}';

      String fileName = imageFile.name;
      if (fileName.isEmpty) {
        fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'];
        print(
            '✅ Imagen subida exitosamente: ${secureUrl?.substring(0, 50)}...');
        return secureUrl;
      } else {
        final errorData = await response.stream.bytesToString();
        print('❌ Error en upload: ${response.statusCode} - $errorData');
        throw Exception('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en _uploadToCloudinary: $e');
      rethrow; // Propaga el error para manejarlo en el método llamador
    }
  }

  Future<bool> _savePhotoReference({
    required String userId,
    required String photoUrl,
    required int displayOrder,
  }) async {
    try {
      await _supabase.from('user_photos').insert({
        'user_id': userId,
        'photo_url': photoUrl,
        'display_order': displayOrder,
      });
      return true;
    } catch (e) {
      print('Error guardando referencia en Supabase: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPhotos(String userId) async {
    try {
      final response = await _supabase
          .from('user_photos')
          .select('id, photo_url, display_order')
          .eq('user_id', userId)
          .order('display_order');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo fotos del usuario: $e');
      return [];
    }
  }

  // MÉTODO MEJORADO - Con modo configurable
  Future<bool> deletePhoto(
      String userId, String photoId, String photoUrl) async {
    try {
      print('=== INICIANDO ELIMINACION DE FOTO ===');
      print('User ID: $userId');
      print('Photo ID: $photoId');
      print('Modo deleteFromCloudinary: $_deleteFromCloudinary');

      if (_deleteFromCloudinary) {
        // MODO 1: Intentar eliminar de Cloudinary y Supabase
        print('MODO: Eliminar de Cloudinary y Supabase');
        final cloudinarySuccess = await _deleteFromCloudinaryOnly(photoUrl);

        if (cloudinarySuccess) {
          print('Exito en Cloudinary, eliminando de Supabase...');
          await _deleteFromSupabaseOnly(userId, photoId);
          print('Foto eliminada correctamente de Cloudinary y Supabase');
          return true;
        } else {
          print('Fallo en Cloudinary, eliminando solo de Supabase...');
          return await _deleteFromSupabaseOnly(userId, photoId);
        }
      } else {
        // MODO 2: Solo eliminar de Supabase
        print('MODO: Eliminar solo de Supabase (Cloudinary preservado)');
        return await _deleteFromSupabaseOnly(userId, photoId);
      }
    } catch (e) {
      print('Error general eliminando foto: $e');
      return await _deleteFromSupabaseOnly(userId, photoId);
    }
  }

  // Método para eliminar solo de Cloudinary
  Future<bool> _deleteFromCloudinaryOnly(String photoUrl) async {
    try {
      // Extraer public_id de la URL de Cloudinary
      String publicId = '';

      final uri = Uri.parse(photoUrl);
      final path = uri.path;

      final regex = RegExp(r'/v\d+/(.+)\.(jpg|jpeg|png)');
      final match = regex.firstMatch(path);

      if (match != null) {
        publicId = match.group(1)!;
        print('Public ID extraido: $publicId');
      } else {
        print('No se pudo extraer public_id');
        return false;
      }

      // Generar timestamp (en segundos)
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      // Parámetros para la firma (solo public_id y timestamp)
      final paramsForSignature = {
        'public_id': publicId,
        'timestamp': timestamp,
      };

      // Generar signature
      final signature = _generateSignature(paramsForSignature);
      print('Signature generada: $signature');

      // Eliminar de Cloudinary
      const deleteUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy';

      final response = await http.post(
        Uri.parse(deleteUrl),
        body: {
          'api_key': _apiKey,
          'public_id': publicId,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      print('Response status de Cloudinary: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Exito eliminando de Cloudinary');
        return true;
      } else {
        print('Error de Cloudinary: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error eliminando de Cloudinary: $e');
      return false;
    }
  }

  // Método para eliminar solo de Supabase
  Future<bool> _deleteFromSupabaseOnly(String userId, String photoId) async {
    try {
      await _supabase
          .from('user_photos')
          .delete()
          .eq('id', photoId)
          .eq('user_id', userId);
      print('Foto eliminada de Supabase');
      return true;
    } catch (e) {
      print('Error eliminando de Supabase: $e');
      return false;
    }
  }

  // Método público para cambiar el modo (útil para testing)
  void setDeleteMode(bool deleteFromCloudinary) {
    _deleteFromCloudinary = deleteFromCloudinary;
    notifyListeners();
    print('Modo deleteFromCloudinary establecido a: $deleteFromCloudinary');
  }

  // Método para obtener el estado actual
  bool getCurrentDeleteMode() {
    return _deleteFromCloudinary;
  }

  Future<List<XFile>> pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      return images;
    } catch (e) {
      print('Error seleccionando imagenes: $e');
      return [];
    }
  }

  Future<XFile?> takePhotoWithCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
    } catch (e) {
      print('Error tomando foto: $e');
      return null;
    }
  }

  Future<bool> updatePhotoOrder(
      String userId, List<Map<String, dynamic>> photos) async {
    try {
      for (final photo in photos) {
        await _supabase
            .from('user_photos')
            .update({'display_order': photo['display_order']})
            .eq('id', photo['id'])
            .eq('user_id', userId);
      }
      return true;
    } catch (e) {
      print('Error actualizando orden: $e');
      return false;
    }
  }

  Future<List<String>> uploadMultipleImages(List<String> imagePaths) async {
    final List<String> uploadedUrls = [];
    for (final imagePath in imagePaths) {
      final url = await uploadImage(imagePath);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    return uploadedUrls;
  }
}
