import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/cloudinary_storage_provider.dart';
import '../../providers/auth_provider.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;

  // LÍMITE CAMBIADO A 3 FOTOS
  static const int _maxPhotos = 3;

  // Método para verificar si es web
  bool get _isWeb => identical(0, 0.0);

  // NUEVO MÉTODO: Validar tamaño de imágenes antes de agregarlas
  Future<List<XFile>> _validateAndFilterImages(List<XFile> images) async {
    final List<XFile> validImages = [];
    const maxSizeInBytes = 2 * 1024 * 1024; // 2MB

    for (final image in images) {
      try {
        final bytes = await image.readAsBytes();
        final fileSizeInMB = bytes.length / (1024 * 1024);

        if (bytes.length <= maxSizeInBytes) {
          validImages.add(image);
          print(
              '✅ Imagen válida: ${image.name} - ${fileSizeInMB.toStringAsFixed(2)}MB');
        } else {
          print(
              '❌ Imagen muy grande: ${image.name} - ${fileSizeInMB.toStringAsFixed(2)}MB');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '"${image.name}" es muy grande (${fileSizeInMB.toStringAsFixed(2)}MB). Máximo: 2MB'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error validando imagen ${image.name}: $e');
      }
    }

    return validImages;
  }

  Future<void> _pickImages() async {
    try {
      print('=== INICIANDO SELECCIÓN DE GALERÍA ===');

      // Verificar si ya se alcanzó el límite
      if (_selectedImages.length >= _maxPhotos) {
        _showError('Ya has seleccionado el máximo de $_maxPhotos fotos');
        return;
      }

      // Solo solicitar permisos si no es web
      if (!_isWeb) {
        final galleryStatus = await Permission.photos.request();
        if (!galleryStatus.isGranted) {
          _showError(
              'Se necesitan permisos de galería para seleccionar imágenes');
          return;
        }
      }

      final storageProvider = context.read<CloudinaryStorageProvider>();
      final images = await storageProvider.pickImagesFromGallery();

      print('Imágenes seleccionadas de galería: ${images.length}');

      if (images.isNotEmpty) {
        // NUEVO: Validar tamaño de imágenes antes de agregarlas
        final validImages = await _validateAndFilterImages(images);

        if (validImages.isEmpty) {
          _showError(
              'Todas las imágenes seleccionadas exceden el límite de 2MB');
          return;
        }

        // Calcular cuántas fotos más se pueden agregar
        final availableSlots = _maxPhotos - _selectedImages.length;
        final imagesToAdd = validImages.length > availableSlots
            ? validImages.sublist(0, availableSlots)
            : validImages;

        if (imagesToAdd.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(imagesToAdd);
          });
          print('Total de imágenes seleccionadas: ${_selectedImages.length}');

          // Mostrar mensaje si se excedió el límite
          if (validImages.length > availableSlots) {
            _showInfo(
                'Solo se agregaron $availableSlots fotos (límite: $_maxPhotos)');
          }

          // Mostrar mensaje si algunas imágenes fueron filtradas
          if (validImages.length < images.length) {
            final filteredCount = images.length - validImages.length;
            _showInfo(
                '$filteredCount imágenes fueron descartadas por exceder 2MB');
          }
        }
      } else {
        print('No se seleccionaron imágenes de galería');
      }
    } catch (e) {
      print('Error en selección de galería: $e');
      _showError('Error al seleccionar imágenes: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      print('=== INICIANDO CÁMARA ===');

      // Verificar si ya se alcanzó el límite
      if (_selectedImages.length >= _maxPhotos) {
        _showError('Ya has alcanzado el máximo de $_maxPhotos fotos');
        return;
      }

      // Solo solicitar permisos si no es web
      if (!_isWeb) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          _showError('Se necesitan permisos de cámara para tomar fotos');
          return;
        }
      }

      final storageProvider = context.read<CloudinaryStorageProvider>();
      final photo = await storageProvider.takePhotoWithCamera();

      if (photo != null) {
        // NUEVO: Validar tamaño de la foto tomada
        final validPhotos = await _validateAndFilterImages([photo]);

        if (validPhotos.isNotEmpty) {
          print('✅ Foto tomada con cámara: ${photo.name}');
          setState(() {
            _selectedImages.add(photo);
          });
          print('Total de imágenes seleccionadas: ${_selectedImages.length}');
        } else {
          _showError(
              'La foto tomada es demasiado grande. Máximo permitido: 2MB');
        }
      } else {
        print('No se tomó foto con cámara');
      }
    } catch (e) {
      print('Error en cámara: $e');
      _showError('Error al tomar foto: $e');
    }
  }

  Future<void> _uploadPhotos() async {
    if (_selectedImages.isEmpty) return;

    print('=== INICIANDO UPLOAD DE FOTOS ===');
    print('Número de imágenes seleccionadas: ${_selectedImages.length}');

    setState(() {
      _isUploading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final storageProvider = context.read<CloudinaryStorageProvider>();

    final userId = authProvider.currentUser!.id;
    print('User ID: $userId');

    final existingPhotos = await storageProvider.getUserPhotos(userId);
    print('Fotos existentes: ${existingPhotos.length}');

    // Verificar límite total (existentes + nuevas)
    final totalAfterUpload = existingPhotos.length + _selectedImages.length;
    if (totalAfterUpload > _maxPhotos) {
      _showError(
          'No puedes tener más de $_maxPhotos fotos en total. Ya tienes ${existingPhotos.length} fotos.');
      setState(() {
        _isUploading = false;
      });
      return;
    }

    int startOrder = existingPhotos.length;
    print('Start order: $startOrder');

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        print('=== SUBIENDO IMAGEN ${i + 1} ===');
        print('Image name: ${image.name}');
        print('Display order: ${startOrder + i}');

        // Subir imagen a Cloudinary (usa XFile directamente)
        final success = await storageProvider.uploadUserPhoto(
          userId: userId,
          imageFile: image,
          displayOrder: startOrder + i,
        );

        print('Resultado subida imagen ${i + 1}: $success');

        if (!success) {
          throw Exception('Error al subir la imagen ${i + 1}');
        }
      }

      print('=== TODAS LAS IMÁGENES SUBIDAS EXITOSAMENTE ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotos subidas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('=== ERROR EN UPLOAD: $e ===');
      _showError('Error al subir fotos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final storageProvider = context.read<CloudinaryStorageProvider>();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: storageProvider.getUserPhotos(authProvider.currentUser!.id),
      builder: (context, snapshot) {
        final existingPhotosCount =
            snapshot.hasData ? snapshot.data!.length : 0;
        final remainingSlots = _maxPhotos - existingPhotosCount;

        return Scaffold(
          backgroundColor: const Color(0xFF0E0F0E),
          appBar: AppBar(
            title: const Text(
              'Agregar Fotos',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF0E0F0E),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (_selectedImages.isNotEmpty && !_isUploading)
                TextButton(
                  onPressed: _uploadPhotos,
                  child: const Text(
                    'Subir',
                    style: TextStyle(
                      color: Color(0xFF8B1538),
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Información de límites
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1A1B1A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fotos existentes: $existingPhotosCount/$_maxPhotos',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Puedes agregar: $remainingSlots',
                          style: const TextStyle(
                            color: Color(0xFF8B1538),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // NUEVO: Información sobre límite de tamaño
                    const Text(
                      'Límite por foto: 2MB máximo',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: remainingSlots > 0 ? _pickImages : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1538),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                    ),
                    if (!_isWeb)
                      ElevatedButton.icon(
                        onPressed: remainingSlots > 0 ? _takePhoto : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2B2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cámara'),
                      ),
                  ],
                ),
              ),
              if (_selectedImages.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: Colors.grey[400],
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Selecciona fotos para subir',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Máximo $_maxPhotos fotos en total',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // NUEVO: Información sobre límite de tamaño
                        const Text(
                          'Máximo 2MB por foto',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (remainingSlots == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'Ya tienes el máximo de fotos',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (_isWeb)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'Modo Web: Solo galería disponible',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: _isUploading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF8B1538),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Subiendo fotos...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // NUEVO: Información de imágenes seleccionadas
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '${_selectedImages.length} foto(s) seleccionada(s)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      // Para mostrar la imagen preview
                                      FutureBuilder<Uint8List>(
                                        future: _selectedImages[index]
                                            .readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                image: DecorationImage(
                                                  image: MemoryImage(
                                                      snapshot.data!),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          } else {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: const Color(0xFF2A2B2A),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Color(0xFF8B1538),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}
