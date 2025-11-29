import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cloudinary_storage_provider.dart';
import 'photo_upload_screen.dart';
import 'photo_manager_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<String> _userPhotos = [];
  bool _isLoadingPhotos = true;
  bool _hasError = false;

  // Mapa de emojis para los intereses existentes
  final Map<String, String> _interestEmojis = {
    'Música': '🎵',
    'Deportes': '⚽',
    'Arte': '🎨',
    'Tecnología': '💻',
    'Cine': '🎬',
    'Libros': '📚',
    'Viajes': '✈️',
    'Comida': '🍕',
    'Videojuegos': '🎮',
    'Fotografía': '📷',
    'Baile': '💃',
    'Naturaleza': '🌿',
    'Moda': '👗',
    'Cocina': '👨‍🍳',
    'Animales': '🐾',
    'Series': '📺',
    'Ejercicio': '💪',
    'Café': '☕',
    'Cerveza': '🍺',
    'Té': '🍵',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPhotos();
    });
  }

  Future<void> _loadUserPhotos() async {
    try {
      setState(() {
        _isLoadingPhotos = true;
        _hasError = false;
      });

      final authProvider = context.read<AuthProvider>();
      final storageProvider = context.read<CloudinaryStorageProvider>();
      final userId = authProvider.currentUser!.id;

      final photos = await storageProvider.getUserPhotos(userId);

      setState(() {
        _userPhotos = photos
            .map<String>((photo) => photo['photo_url'] as String)
            .toList();
        _isLoadingPhotos = false;
      });
    } catch (e) {
      print('Error loading photos: $e');
      setState(() {
        _isLoadingPhotos = false;
        _hasError = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar fotos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPhotoUpload() async {
    print('=== NAVEGANDO A PHOTO UPLOAD ===');
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PhotoUploadScreen(),
        ),
      );

      print('Resultado de PhotoUploadScreen: $result');

      if (result == true) {
        await _loadUserPhotos();
      }
    } catch (e) {
      print('Error en navegación: $e');
    }
  }

  void _navigateToPhotoManager() async {
    print('=== NAVEGANDO A PHOTO MANAGER ===');
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PhotoManagerScreen(),
        ),
      );

      print('Resultado de PhotoManagerScreen: $result');

      if (result == true) {
        await _loadUserPhotos();
      }
    } catch (e) {
      print('Error en navegación: $e');
    }
  }

  void _navigateToEditProfile() async {
    print('=== NAVEGANDO A EDIT PROFILE ===');
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EditProfileScreen(),
        ),
      );
      // Recargar datos después de editar
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadCurrentUser();
      setState(() {});
    } catch (e) {
      print('Error en navegación a edit profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _retryLoadPhotos() {
    _loadUserPhotos();
  }

  String _getInterestsText(Map<String, dynamic> userProfile) {
    final userInterests = userProfile['user_interests'];
    if (userInterests is List && userInterests.isNotEmpty) {
      final interestNames = userInterests
          .map((interest) {
            final interestData = interest['interests'];
            if (interestData != null) {
              final name = interestData['name'];
              final emoji = _interestEmojis[name] ?? '❤️';
              return '$emoji $name';
            }
            return '';
          })
          .where((name) => name.isNotEmpty)
          .toList();

      if (interestNames.isNotEmpty) {
        return interestNames.join(', ');
      }
    }
    return 'No especificados';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.userProfile;
    final user = authProvider.currentUser;

    if (userProfile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0F0E),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B1538),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con foto de perfil
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _userPhotos.isNotEmpty
                            ? _navigateToPhotoManager
                            : _navigateToPhotoUpload,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF8B1538),
                              width: 3,
                            ),
                          ),
                          child: _userPhotos.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(_userPhotos.first),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Color(0xFF2A2B2A),
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _navigateToPhotoUpload,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B1538),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile['full_name'] ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Fotos del usuario
            _buildPhotosSection(),

            const SizedBox(height: 24),

            // Información personal
            _buildInfoSection(userProfile),

            const SizedBox(height: 24),

            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mis Fotos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_userPhotos.isNotEmpty)
              TextButton(
                onPressed: _navigateToPhotoManager,
                child: const Text(
                  'Administrar',
                  style: TextStyle(
                    color: Color(0xFF8B1538),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingPhotos)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF8B1538),
                ),
                SizedBox(height: 8),
                Text(
                  'Cargando fotos...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else if (_hasError)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Error al cargar las fotos',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _retryLoadPhotos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1538),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (_userPhotos.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library,
                  color: Colors.grey[400],
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No hay fotos',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _navigateToPhotoUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1538),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Agregar Fotos'),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _userPhotos.length + (_userPhotos.length < 3 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _userPhotos.length && _userPhotos.length < 3) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2B2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B1538),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF8B1538)),
                      onPressed: _navigateToPhotoUpload,
                    ),
                  );
                }

                final photoIndex =
                    index < _userPhotos.length ? index : index - 1;
                return GestureDetector(
                  onTap: _navigateToPhotoManager,
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(_userPhotos[photoIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${photoIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> userProfile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Biografía', userProfile['bio'] ?? 'No especificada'),
          _buildInfoItem('Carrera', userProfile['major'] ?? 'No especificada'),
          _buildInfoItem(
              'Año', '${userProfile['year'] ?? 'No especificado'}° Año'),
          _buildInfoItem(
              'Altura', '${userProfile['height'] ?? 'No especificada'} cm'),
          _buildInfoItem(
              'Género', userProfile['genders']?['name'] ?? 'No especificado'),
          _buildInfoItem('Intereses', _getInterestsText(userProfile)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _navigateToEditProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2B2A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Editar Perfil'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _navigateToPhotoUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1538),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Agregar Fotos'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
