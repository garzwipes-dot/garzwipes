import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cloudinary_storage_provider.dart';
import '../../providers/auth_provider.dart';
import 'photo_upload_screen.dart';

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({super.key});

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  bool _isReordering = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final storageProvider = context.read<CloudinaryStorageProvider>();

      final userId = authProvider.currentUser!.id;
      final photos = await storageProvider.getUserPhotos(userId);

      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePhoto(String photoId, String photoUrl, int index) async {
    // NO PERMITIR ELIMINAR SI SOLO HAY 1 FOTO
    if (_photos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No puedes eliminar tu única foto. Agrega otra foto primero.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar Foto',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta foto?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() {
        _isDeleting = true;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final storageProvider = context.read<CloudinaryStorageProvider>();

      final userId = authProvider.currentUser!.id;
      final success =
          await storageProvider.deletePhoto(userId, photoId, photoUrl);

      if (success && mounted) {
        setState(() {
          _photos.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto eliminada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la foto'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error deleting photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _toggleReorder() {
    setState(() {
      _isReordering = !_isReordering;
    });
  }

  Future<void> _saveNewOrder() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final storageProvider = context.read<CloudinaryStorageProvider>();

      final userId = authProvider.currentUser!.id;
      final success = await storageProvider.updatePhotoOrder(userId, _photos);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden guardado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _toggleReorder();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el orden'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error saving order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _photos.removeAt(oldIndex);
    _photos.insert(newIndex, item);

    for (int i = 0; i < _photos.length; i++) {
      _photos[i]['display_order'] = i;
    }

    setState(() {});
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhotoUploadScreen(),
      ),
    );

    if (result == true && mounted) {
      await _loadPhotos();
    }
  }

  // Widget para mostrar imagen con manejo de errores
  Widget _buildPhotoWidget(String photoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF2A2B2A),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B1538),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF2A2B2A),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        title: Text(
          _isReordering ? 'Ordenar Fotos' : 'Mis Fotos (${_photos.length}/3)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E0F0E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_photos.isNotEmpty && !_isReordering && _photos.length > 1)
            IconButton(
              onPressed: _toggleReorder,
              icon: const Icon(Icons.swap_vert),
              tooltip: 'Reordenar',
            ),
          if (_isReordering)
            TextButton(
              onPressed: _saveNewOrder,
              child: const Text(
                'Guardar',
                style: TextStyle(color: Color(0xFF8B1538)),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B1538),
              ),
            )
          : _photos.isEmpty
              ? Center(
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
                        'No hay fotos',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _navigateToUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1538),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Agregar Fotos'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_isDeleting)
                      const LinearProgressIndicator(
                        color: Color(0xFF8B1538),
                        backgroundColor: Color(0xFF2A2B2A),
                      ),
                    Expanded(
                      child: _isReordering
                          ? ReorderableListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _photos.length,
                              onReorder: _reorderPhotos,
                              itemBuilder: (context, index) {
                                final photo = _photos[index];
                                return Card(
                                  key: Key(photo['id']),
                                  color: const Color(0xFF1A1B1A),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image:
                                              NetworkImage(photo['photo_url']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      'Foto ${index + 1}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    trailing: const Icon(
                                      Icons.drag_handle,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: _photos.length,
                              itemBuilder: (context, index) {
                                final photo = _photos[index];
                                final canDelete = _photos.length >
                                    1; // Solo permitir eliminar si hay más de 1 foto

                                return Stack(
                                  children: [
                                    // Contenedor de la imagen con manejo de errores
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0xFF2A2B2A),
                                      ),
                                      child:
                                          _buildPhotoWidget(photo['photo_url']),
                                    ),
                                    if (canDelete) // Solo mostrar botón de eliminar si hay más de 1 foto
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: _isDeleting
                                              ? null
                                              : () => _deletePhoto(photo['id'],
                                                  photo['photo_url'], index),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: _isDeleting
                                                  ? Colors.grey
                                                  : Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.delete,
                                              color: _isDeleting
                                                  ? Colors.white30
                                                  : Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!_isReordering)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                    if (!_isReordering && _photos.length < 3)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: _navigateToUpload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1538),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            _photos.isEmpty
                                ? 'Agregar Fotos'
                                : 'Agregar Más Fotos',
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
