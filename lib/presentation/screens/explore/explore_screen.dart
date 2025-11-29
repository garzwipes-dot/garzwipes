import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PageController _pageController = PageController();
  final List<Map<String, dynamic>> _profiles = [];
  final List<Map<String, dynamic>> _swipeHistory = [];
  int _currentProfileIndex = 0;
  bool _isLoading = true;
  bool _showUndoButton = false;
  bool _isDisposed = false;

  // Variables para animaciones de swipe
  late AnimationController _animationController;
  double _dragPosition = 0.0;
  bool _isDragging = false;
  final double _swipeThreshold = 120.0;
  final double _maxDragDistance = 400.0;

  // Variables para el match animation
  bool _showMatchOverlay = false;
  Map<String, dynamic>? _matchedProfile;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadProfiles();
    _debugCompleteProfileSituation(); // 🔥 DEBUG TEMPORAL
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 🔥 DEBUG COMPLETO TEMPORAL
  // 🔥 DEBUG COMPLETO TEMPORAL - ACTUALIZADO
  Future<void> _debugCompleteProfileSituation() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      print('=== 🐛 DEBUG COMPLETO DEL PROBLEMA ===');

      // 1. Obtener MI perfil completo
      final myProfile = await _supabase.from('profiles').select('''
          *,
          genders(name)
        ''').eq('id', currentUserId).single();

      print('👤 MI PERFIL:');
      print('   - ID: ${myProfile['id']}');
      print('   - Nombre: ${myProfile['full_name']}');
      print('   - Género ID: ${myProfile['gender_id']}');
      print(
          '   - Género Name: ${myProfile['genders'] != null ? (myProfile['genders'] as Map)['name'] : 'N/A'}');
      print('   - Busca géneros: ${myProfile['looking_for_gender_ids']}');
      print('   - Show profile: ${myProfile['show_profile']}');

      // 2. Obtener TODOS los perfiles existentes
      final allProfiles = await _supabase.from('profiles').select('''
          id,
          full_name,
          gender_id,
          looking_for_gender_ids,
          show_profile,
          genders(name)
        ''');

      print('\n📊 TODOS LOS PERFILES EN LA BD (${allProfiles.length}):');
      for (var profile in allProfiles) {
        final genderName = profile['genders'] != null
            ? (profile['genders'] as Map<String, dynamic>)['name']
            : 'N/A';
        final lookingFor = profile['looking_for_gender_ids'] ?? [];
        final includesMyGender = lookingFor.contains(myProfile['gender_id']);

        print('   👤 ${profile['full_name']}');
        print('      - ID: ${profile['id']}');
        print('      - Género: $genderName (${profile['gender_id']})');
        print('      - Busca: $lookingFor');
        print('      - Incluye mi género? $includesMyGender');
        print('      - Show profile: ${profile['show_profile']}');
        print('      - Es mi perfil: ${profile['id'] == currentUserId}');
        print('      ---');
      }

      // 3. Verificar swipes
      final swipes = await _supabase
          .from('swipes')
          .select('swiper_id, swiped_id, type')
          .eq('swiper_id', currentUserId);

      print('\n💔 MIS SWIPES (${swipes.length}):');
      for (var swipe in swipes) {
        print('   - Swiped: ${swipe['swiped_id']}, Type: ${swipe['type']}');
      }

      print('\n=== FIN DEBUG ===\n');
    } catch (e) {
      print('❌ Error en debug: $e');
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadProfiles() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      print('🔍 Cargando perfiles para usuario: $currentUserId');

      // 1. Obtener el perfil completo del usuario actual
      final currentUserProfile = await _supabase
          .from('profiles')
          .select('gender_id, looking_for_gender_ids, full_name')
          .eq('id', currentUserId)
          .single();

      final currentUserGenderId = currentUserProfile['gender_id'] as String?;
      final lookingForGenderIds =
          List<String>.from(currentUserProfile['looking_for_gender_ids'] ?? []);
      final currentUserName = currentUserProfile['full_name'] as String;

      print('👤 Usuario actual: $currentUserName');
      print('   - Género: $currentUserGenderId');
      print('   - Busca: $lookingForGenderIds');

      // 2. Obtener swipes existentes
      final existingSwipes = await _supabase
          .from('swipes')
          .select('swiped_id, type')
          .eq('swiper_id', currentUserId);

      final swipedIds =
          existingSwipes.map((swipe) => swipe['swiped_id'] as String).toList();

      print('📋 IDs ya swiped: ${swipedIds.length}');

      // 3. CONSULTA MEJORADA - Verificar match bidireccional de preferencias
      var query = _supabase.from('profiles').select('''
          *,
          genders(name),
          user_photos(photo_url, display_order),
          user_interests(interests(name))
        ''').neq('id', currentUserId).eq('show_profile', true);

      // Excluir perfiles ya swipedados
      if (swipedIds.isNotEmpty) {
        query = query.not('id', 'in', swipedIds);
      }

      // 🔥 FILTRO BIDIRECCIONAL MEJORADO
      if (lookingForGenderIds.isNotEmpty && currentUserGenderId != null) {
        print('🎯 Aplicando filtro bidireccional de género...');

        // Filtro 1: Usuario actual debe estar interesado en el género del perfil
        query = query.inFilter('gender_id', lookingForGenderIds);

        // Filtro 2: El perfil debe estar interesado en el género del usuario actual
        // ✅ CORREGIDO: Usar el método contains() con formato de array correcto
        query = query.contains('looking_for_gender_ids', [currentUserGenderId]);

        print('   - Yo busco estos géneros: $lookingForGenderIds');
        print('   - El perfil debe buscar mi género: $currentUserGenderId');
      } else {
        print('⚠️ Sin filtros de género - mostrando todos los perfiles');
      }

      // 4. Ejecutar consulta final
      final response = await query.limit(20);

      _safeSetState(() {
        _profiles.clear();
        _profiles.addAll(response);
        _isLoading = false;
      });

      print('🎯 Perfiles finales después de filtros: ${_profiles.length}');

      // DEBUG DETALLADO
      print('=== PERFILES ENCONTRADOS ===');
      for (var profile in _profiles) {
        final genderName = profile['genders'] != null
            ? (profile['genders'] as Map<String, dynamic>)['name']
            : 'Sin género';
        final lookingFor = profile['looking_for_gender_ids'] ?? [];
        final photos = List.from(profile['user_photos'] ?? []);

        print('👤 ${profile['full_name']}');
        print('   - Género: $genderName (${profile['gender_id']})');
        print('   - Busca: $lookingFor');
        print('   - Fotos: ${photos.length}');
        print(
            '   - Incluye mi género? ${lookingFor.contains(currentUserGenderId)}');
        print('---');
      }
    } catch (e) {
      print('❌ Error loading profiles: $e');
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _animationController.stop();
    _safeSetState(() {
      _isDragging = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _safeSetState(() {
      _dragPosition += details.primaryDelta!;
      // Limitar la distancia máxima de arrastre
      if (_dragPosition.abs() > _maxDragDistance) {
        _dragPosition = _dragPosition.sign * _maxDragDistance;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _safeSetState(() {
      _isDragging = false;
    });

    // Determinar si fue un swipe suficiente
    if (_dragPosition.abs() > _swipeThreshold) {
      if (_dragPosition > 0) {
        // Swipe a la derecha - LIKE
        _performSwipe('like');
      } else {
        // Swipe a la izquierda - DISLIKE
        _performSwipe('dislike');
      }
    } else {
      // Volver a la posición original
      _resetCardPosition();
    }
  }

  void _resetCardPosition() {
    final animation = Tween<double>(
      begin: _dragPosition,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    animation.addListener(() {
      _safeSetState(() {
        _dragPosition = animation.value;
      });
    });

    _animationController.forward();
  }

  Future<void> _performSwipe(String type) async {
    if (_profiles.isEmpty) return;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final currentProfile = _profiles[_currentProfileIndex];

    // Animación de salida suave
    final double endPosition =
        type == 'like' ? _maxDragDistance : -_maxDragDistance;
    final animation = Tween<double>(
      begin: _dragPosition,
      end: endPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    animation.addListener(() {
      _safeSetState(() {
        _dragPosition = animation.value;
      });
    });

    _animationController.forward().then((_) async {
      // Guardar en historial para poder deshacer (SOLO para likes)
      if (type == 'like') {
        _swipeHistory.add({
          'profile': currentProfile,
          'type': type,
          'index': _currentProfileIndex,
        });
      }

      // Registrar swipe en la base de datos
      try {
        await _supabase.from('swipes').insert({
          'swiper_id': currentUserId,
          'swiped_id': currentProfile['id'],
          'type': type,
        });

        // Verificar si hay match
        if (type == 'like') {
          final matchCheck = await _supabase
              .from('swipes')
              .select()
              .eq('swiper_id', currentProfile['id'])
              .eq('swiped_id', currentUserId)
              .eq('type', 'like')
              .maybeSingle();

          if (matchCheck != null) {
            await _createMatch(currentUserId, currentProfile['id'] as String);
            _showMatchOverlayFunc(currentProfile);
          }
        }

        // Mostrar botón de deshacer temporalmente SOLO para likes
        if (type == 'like') {
          _safeSetState(() {
            _showUndoButton = true;
          });

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _safeSetState(() {
                _showUndoButton = false;
              });
            }
          });
        }

        // Mover al siguiente perfil
        _goToNextProfile();
        _safeSetState(() {
          _dragPosition = 0.0;
        });
      } catch (e) {
        print('Error saving swipe: $e');
      }
    });
  }

  Future<void> _createMatch(String user1Id, String user2Id) async {
    final sortedIds = [user1Id, user2Id]..sort();

    await _supabase.from('matches').insert({
      'user1_id': sortedIds[0],
      'user2_id': sortedIds[1],
    });

    print('✅ MATCH CREADO: ${sortedIds[0]} y ${sortedIds[1]}');
  }

  void _showMatchOverlayFunc(Map<String, dynamic> profile) {
    _safeSetState(() {
      _matchedProfile = profile;
      _showMatchOverlay = true;
    });

    // Reiniciar el animation controller para la animación de match
    _animationController.reset();
    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _safeSetState(() {
          _showMatchOverlay = false;
          _matchedProfile = null;
        });
      }
    });
  }

  void _undoSwipe() async {
    if (_swipeHistory.isEmpty) return;

    final lastSwipe = _swipeHistory.removeLast();
    final currentUserId = _supabase.auth.currentUser?.id;

    if (currentUserId == null) return;

    try {
      await _supabase
          .from('swipes')
          .delete()
          .eq('swiper_id', currentUserId)
          .eq('swiped_id', lastSwipe['profile']['id']);

      if (lastSwipe['type'] == 'like') {
        final user1 = currentUserId;
        final user2 = lastSwipe['profile']['id'] as String;
        final sortedIds = [user1, user2]..sort();

        await _supabase
            .from('matches')
            .delete()
            .eq('user1_id', sortedIds[0])
            .eq('user2_id', sortedIds[1]);
      }

      _safeSetState(() {
        _profiles.insert(lastSwipe['index'], lastSwipe['profile']);
        _currentProfileIndex = lastSwipe['index'];
        _showUndoButton = false;
      });
      _pageController.jumpToPage(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Like deshecho'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error undoing swipe: $e');
    }
  }

  void _goToNextProfile() {
    if (!mounted || _profiles.isEmpty) return;

    if (_currentProfileIndex < _profiles.length - 1) {
      _safeSetState(() {
        _currentProfileIndex++;
      });
    } else {
      _safeSetState(() {
        _profiles.clear();
        _currentProfileIndex = 0;
        _isLoading = true;
      });
      _loadProfiles();
    }

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  Widget _buildMatchOverlay() {
    if (!_showMatchOverlay || _matchedProfile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xE6000000),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación de corazones latiendo
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 1.0, end: 1.2),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFF8B1538),
                    size: 100,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Foto con animación de aparición
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _animationController,
                curve: Curves.elasticOut,
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  _matchedProfile!['user_photos']?.isNotEmpty == true
                      ? _matchedProfile!['user_photos'][0]['photo_url']
                          as String
                      : 'https://via.placeholder.com/150',
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Texto con animación
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeIn,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '¡Match con ${_matchedProfile!['full_name']}! 💖',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ya pueden empezar a chatear',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    final photos = List<Map<String, dynamic>>.from(profile['user_photos'] ?? [])
      ..sort((a, b) =>
          (a['display_order'] ?? 0).compareTo(b['display_order'] ?? 0));

    final interests =
        List<Map<String, dynamic>>.from(profile['user_interests'] ?? []);
    final gender = profile['genders'] is Map
        ? profile['genders']['name'] as String?
        : 'No especificado';

    // Calcular valores de animación de forma segura
    double rotation = (_dragPosition / _maxDragDistance) * 0.1;
    double opacity =
        1.0 - (_dragPosition.abs() / _maxDragDistance * 0.3).clamp(0.0, 0.3);
    double scale =
        1.0 - (_dragPosition.abs() / _maxDragDistance * 0.05).clamp(0.0, 0.05);

    // Calcular opacidades para los indicadores de forma segura
    double likeOpacity = (_dragPosition > 50)
        ? ((_dragPosition - 50) / 100).clamp(0.0, 1.0)
        : 0.0;
    double nopeOpacity = (_dragPosition < -50)
        ? ((_dragPosition.abs() - 50) / 100).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Transform.translate(
        offset: Offset(_dragPosition, 0),
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0), // Asegurar que esté entre 0 y 1
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF1A1B1A),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: photos.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                child: Image.network(
                                  photos[index]['photo_url'] as String,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
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
                                          Icons.person,
                                          size: 80,
                                          color: Color(0xFF808080),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _pageController.hasClients &&
                                              (_pageController.page?.round() ??
                                                      0) ==
                                                  index
                                          ? const Color(0xFF8B1538)
                                          : const Color(0x80FFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Indicadores de swipe mejorados
                          if (_isDragging)
                            Positioned(
                              top: 50,
                              left: 20,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: likeOpacity,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B1538),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.favorite,
                                          color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'LIKE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_isDragging)
                            Positioned(
                              top: 50,
                              right: 20,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: nopeOpacity,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.close,
                                          color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'NOPE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Efecto de superposición de color
                          if (_isDragging && _dragPosition.abs() > 50)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: _dragPosition > 0
                                    ? const Color(
                                        0x338B1538) // Verde suave para like
                                    : const Color(
                                        0x33FF0000), // Rojo suave para dislike
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile['full_name'] as String? ??
                                      'Nombre no disponible',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_calculateAge(profile['birth_date'] as String?)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF808080),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (profile['major'] != null &&
                              profile['year'] != null)
                            Text(
                              '${profile['major']} • Año ${profile['year']}',
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF808080)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (gender != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              gender,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF808080)),
                            ),
                          ],
                          if (profile['height'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${profile['height']} cm',
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF808080)),
                            ),
                          ],
                          if (profile['bio'] != null &&
                              (profile['bio'] as String).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2B2A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile['bio'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (interests.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: interests.take(5).map((interest) {
                                final interestName = interest['interests']
                                        is Map
                                    ? interest['interests']['name'] as String
                                    : 'Interés';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0x338B1538),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0x808B1538),
                                    ),
                                  ),
                                  child: Text(
                                    interestName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B1538)))
              : _profiles.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Color(0xFF808080),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay más perfiles',
                            style: TextStyle(
                              color: Color(0xFF808080),
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Vuelve más tarde para descubrir nuevas personas',
                              style: TextStyle(
                                color: Color(0xFF808080),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildProfileCard(
                                _profiles[_currentProfileIndex]),
                          ),
                        ),
                        if (_showUndoButton && _swipeHistory.isNotEmpty)
                          Positioned(
                            top: 50,
                            left: 20,
                            child: GestureDetector(
                              onTap: _undoSwipe,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B1538),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x80000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.undo,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Deshacer Like',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 30,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.close,
                                color: Colors.red,
                                onTap: () => _performSwipe('dislike'),
                              ),
                              _buildActionButton(
                                icon: Icons.favorite,
                                color: const Color(0xFF8B1538),
                                onTap: () => _performSwipe('like'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          if (_showMatchOverlay) _buildMatchOverlay(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
