import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;

  const ProfileViewScreen({super.key, required this.userId});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _supabase.from('profiles').select('''
            *,
            genders(name),
            user_photos(photo_url, display_order),
            user_interests(interests(name))
          ''').eq('id', widget.userId).single();

      setState(() {
        _profile = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateAge(String? birthDate) {
    if (birthDate == null) return 0;
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      return now.year -
          birth.year -
          (now.month > birth.month ||
                  (now.month == birth.month && now.day >= birth.day)
              ? 0
              : 1);
    } catch (e) {
      return 0;
    }
  }

  void _showFullScreenPhotos(int initialIndex) {
    final photos =
        List<Map<String, dynamic>>.from(_profile!['user_photos'] ?? [])
          ..sort((a, b) =>
              (a['display_order'] ?? 0).compareTo(b['display_order'] ?? 0));

    if (photos.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => FullScreenPhotosView(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E0F0E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B1538)),
            )
          : _profile == null
              ? const Center(
                  child: Text(
                    'Error al cargar el perfil',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final photos =
        List<Map<String, dynamic>>.from(_profile!['user_photos'] ?? [])
          ..sort((a, b) =>
              (a['display_order'] ?? 0).compareTo(b['display_order'] ?? 0));

    final interests =
        List<Map<String, dynamic>>.from(_profile!['user_interests'] ?? []);
    final gender = _profile!['genders'] is Map
        ? _profile!['genders']['name'] as String?
        : 'No especificado';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Carrusel de fotos mejorado
          _buildEnhancedPhotoCarousel(photos),
          const SizedBox(height: 20),

          // Información básica
          _buildBasicInfo(gender),
          const SizedBox(height: 20),

          // Bio
          if (_profile!['bio'] != null &&
              (_profile!['bio'] as String).isNotEmpty)
            _buildBioSection(),

          // Intereses
          if (interests.isNotEmpty) _buildInterestsSection(interests),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnhancedPhotoCarousel(List<Map<String, dynamic>> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 400,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1B1A),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera,
                size: 80,
                color: Color(0xFF808080),
              ),
              SizedBox(height: 16),
              Text(
                'No hay fotos',
                style: TextStyle(
                  color: Color(0xFF808080),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // PageView para el carrusel
          GestureDetector(
            onTap: () => _showFullScreenPhotos(_currentPhotoIndex),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      photos[index]['photo_url'] as String,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF1A1B1A),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B1538),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1A1B1A),
                          child: const Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // Indicadores de fotos
          if (photos.length > 1)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPhotoIndex == index
                          ? const Color(0xFF8B1538)
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),

          // Contador de fotos
          if (photos.length > 1)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPhotoIndex + 1}/${photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Botón para ver en pantalla completa
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => _showFullScreenPhotos(_currentPhotoIndex),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(String? gender) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _profile!['full_name'] as String? ?? 'Nombre no disponible',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1538),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_calculateAge(_profile!['birth_date'] as String?)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_profile!['major'] != null && _profile!['year'] != null)
            _buildInfoRow(
              Icons.school,
              '${_profile!['major']} • Año ${_profile!['year']}',
            ),
          if (gender != null)
            _buildInfoRow(
              Icons.person_outline,
              gender,
            ),
          if (_profile!['height'] != null)
            _buildInfoRow(
              Icons.height,
              '${_profile!['height']} cm',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B1538), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: Color(0xFF8B1538), size: 20),
              SizedBox(width: 8),
              Text(
                'Bio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _profile!['bio'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(List<Map<String, dynamic>> interests) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.interests, color: Color(0xFF8B1538), size: 20),
              SizedBox(width: 8),
              Text(
                'Intereses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: interests.map((interest) {
              final interestName = interest['interests'] is Map
                  ? interest['interests']['name'] as String
                  : 'Interés';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1538),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1538).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  interestName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// NUEVA CLASE PARA VISOR DE FOTOS EN PANTALLA COMPLETA
class FullScreenPhotosView extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const FullScreenPhotosView({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<FullScreenPhotosView> createState() => _FullScreenPhotosViewState();
}

class _FullScreenPhotosViewState extends State<FullScreenPhotosView> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    widget.photos[index]['photo_url'] as String,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B1538),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 50,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Botón de cerrar
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            // Indicadores en la parte inferior
            if (widget.photos.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? const Color(0xFF8B1538)
                            : Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ),

            // Contador de fotos
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
