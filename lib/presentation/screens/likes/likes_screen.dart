import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _likes = [];
  final List<Map<String, dynamic>> _secondChances = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadLikes() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      _safeSetState(() {
        _isLoading = true;
        _likes.clear();
        _secondChances.clear();
      });

      print('🔍 Cargando likes para usuario: $currentUserId');

      // 1. Obtener likes DIRECTOS (personas que me dieron like y yo aún no he respondido)
      final directLikes = await _supabase
          .from('swipes')
          .select('''
          swiper_id,
          created_at,
          profiles!swipes_swiper_id_fkey(
            id,
            full_name,
            birth_date,
            bio,
            major,
            year,
            height,
            gender_id,
            looking_for_gender_ids,
            show_profile,
            genders(name),
            user_photos(photo_url, display_order),
            user_interests(interests(name))
          )
        ''')
          .eq('swiped_id', currentUserId)
          .eq('type', 'like')
          .order('created_at', ascending: false);

      print('📥 Likes directos recibidos de BD: ${directLikes.length}');

      // 2. Obtener mis swipes previos (todos)
      final mySwipes = await _supabase
          .from('swipes')
          .select('swiped_id, type')
          .eq('swiper_id', currentUserId);

      final myDislikedIds = mySwipes
          .where((swipe) => swipe['type'] == 'dislike')
          .map((dislike) => dislike['swiped_id'] as String)
          .toList();

      final myLikedIds = mySwipes
          .where((swipe) => swipe['type'] == 'like')
          .map((like) => like['swiped_id'] as String)
          .toList();

      print('👤 Mis dislikes: ${myDislikedIds.length}');
      print('👤 Mis likes: ${myLikedIds.length}');

      // 3. Filtrar likes directos
      final filteredDirectLikes = directLikes.where((like) {
        final swiperId = like['swiper_id'] as String;
        final isDisliked = myDislikedIds.contains(swiperId);
        final isLiked = myLikedIds.contains(swiperId);

        print(
            '👤 ${like['profiles']?['full_name']} - Disliked: $isDisliked, Liked: $isLiked');

        // Solo mostrar si no he interactuado previamente (ni like ni dislike)
        return !isDisliked && !isLiked;
      }).toList();

      // 4. Obtener SEGUNDAS OPORTUNIDADES (personas que me dieron like y yo les di dislike antes)
      final secondChanceLikes = directLikes.where((like) {
        final swiperId = like['swiper_id'] as String;
        return myDislikedIds.contains(swiperId);
      }).toList();

      print(
          '🔄 Segundas oportunidades encontradas: ${secondChanceLikes.length}');

      _safeSetState(() {
        _likes.addAll(filteredDirectLikes);
        _secondChances.addAll(secondChanceLikes);
        _isLoading = false;
      });

      print('💖 Likes directos finales: ${_likes.length}');
      print('🔄 Segundas oportunidades finales: ${_secondChances.length}');
    } catch (e) {
      print('❌ Error loading likes: $e');
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSwipeResponse(String swipedId, String type,
      {bool isSecondChance = false}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      print('🔄 Procesando respuesta para $swipedId - Tipo: $type');

      // Verificar si ya existe un swipe previo
      final existingSwipe = await _supabase
          .from('swipes')
          .select('type')
          .eq('swiper_id', currentUserId)
          .eq('swiped_id', swipedId)
          .maybeSingle();

      if (existingSwipe != null) {
        // ACTUALIZAR el swipe existente
        print('📝 Swipe existente encontrado, actualizando...');
        await _supabase
            .from('swipes')
            .update({
              'type': type,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('swiper_id', currentUserId)
            .eq('swiped_id', swipedId);

        print('✅ Swipe actualizado: $currentUserId -> $swipedId = $type');
      } else {
        // INSERTAR nuevo swipe
        print('🆕 Creando nuevo swipe...');
        await _supabase.from('swipes').insert({
          'swiper_id': currentUserId,
          'swiped_id': swipedId,
          'type': type,
        });

        print('✅ Nuevo swipe creado: $currentUserId -> $swipedId = $type');
      }

      // Si es like, verificar match
      if (type == 'like') {
        print('🔍 Verificando posible match...');
        final matchCheck = await _supabase
            .from('swipes')
            .select()
            .eq('swiper_id', swipedId)
            .eq('swiped_id', currentUserId)
            .eq('type', 'like')
            .maybeSingle();

        if (matchCheck != null) {
          print('💖 MATCH DETECTADO! Creando match...');
          await _createMatch(currentUserId, swipedId);
          _showMatchSuccess(context, swipedId);
        } else {
          print('💝 Like enviado, esperando reciprocidad...');
          _showLikeSent(context);
        }
      }

      // Actualizar la lista
      _safeSetState(() {
        if (isSecondChance) {
          _secondChances
              .removeWhere((chance) => chance['swiper_id'] == swipedId);
          print('🗑️ Segunda oportunidad removida: $swipedId');
        } else {
          _likes.removeWhere((like) => like['swiper_id'] == swipedId);
          print('🗑️ Like directo removido: $swipedId');
        }
      });

      // Mostrar feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(type == 'like' ? '¡Like enviado!' : 'Dislike registrado'),
            backgroundColor:
                type == 'like' ? const Color(0xFF8B1538) : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error handling swipe response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la acción'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMatch(String user1Id, String user2Id) async {
    try {
      final sortedIds = [user1Id, user2Id]..sort();

      // Verificar si el match ya existe
      final existingMatch = await _supabase
          .from('matches')
          .select()
          .eq('user1_id', sortedIds[0])
          .eq('user2_id', sortedIds[1])
          .maybeSingle();

      if (existingMatch == null) {
        await _supabase.from('matches').insert({
          'user1_id': sortedIds[0],
          'user2_id': sortedIds[1],
        });
        print('✅ NUEVO MATCH CREADO: ${sortedIds[0]} y ${sortedIds[1]}');
      } else {
        print('ℹ️ Match ya existía: ${sortedIds[0]} y ${sortedIds[1]}');
      }
    } catch (e) {
      print('❌ Error creando match: $e');
      rethrow;
    }
  }

  void _showMatchSuccess(BuildContext context, String matchedUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¡Match! 💖',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '¡Enhorabuena! Ahora pueden empezar a chatear',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF8B1538)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLikeSent(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Like enviado - Espera a ver si hay match'),
        backgroundColor: Color(0xFF8B1538),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> likeData,
      {bool isSecondChance = false}) {
    final profile = likeData['profiles'] as Map<String, dynamic>? ?? {};
    final photos = List<Map<String, dynamic>>.from(profile['user_photos'] ?? [])
      ..sort((a, b) =>
          (a['display_order'] ?? 0).compareTo(b['display_order'] ?? 0));

    final interests =
        List<Map<String, dynamic>>.from(profile['user_interests'] ?? []);
    final gender = profile['genders'] is Map
        ? profile['genders']['name'] as String?
        : 'No especificado';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Header con indicador de segunda oportunidad
          if (isSecondChance)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0x338B1538),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Segunda Oportunidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Foto del perfil
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isSecondChance ? 0 : 20),
              bottom: const Radius.circular(0),
            ),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: photos.isNotEmpty
                  ? Image.network(
                      photos[0]['photo_url'] as String,
                      fit: BoxFit.cover,
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
                              Icons.person,
                              size: 80,
                              color: Color(0xFF808080),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF2A2B2A),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Color(0xFF808080),
                        ),
                      ),
                    ),
            ),
          ),

          // Información del perfil
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
                if (profile['major'] != null && profile['year'] != null)
                  Text(
                    '${profile['major']} • Año ${profile['year']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF808080),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (gender != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    gender,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF808080),
                    ),
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
                      final interestName = interest['interests'] is Map
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

                // Botones de acción
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleSwipeResponse(
                          likeData['swiper_id'] as String,
                          'dislike',
                          isSecondChance: isSecondChance,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 20),
                            SizedBox(width: 8),
                            Text('Pass'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleSwipeResponse(
                          likeData['swiper_id'] as String,
                          'like',
                          isSecondChance: isSecondChance,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1538),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite, size: 20),
                            SizedBox(width: 8),
                            Text('Like'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      appBar: AppBar(
        title: const Text(
          'Likes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1B1A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B1538)),
            )
          : _likes.isEmpty && _secondChances.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Color(0xFF808080),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tienes likes aún',
                        style: TextStyle(
                          color: Color(0xFF808080),
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Sigue explorando para recibir más likes',
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
              : RefreshIndicator(
                  onRefresh: _loadLikes,
                  color: const Color(0xFF8B1538),
                  child: ListView(
                    children: [
                      // Segundas oportunidades primero
                      if (_secondChances.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Segundas Oportunidades',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._secondChances.map((chance) => _buildProfileCard(
                              chance,
                              isSecondChance: true,
                            )),
                        const SizedBox(height: 16),
                      ],

                      // Likes normales
                      if (_likes.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Nuevos Likes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._likes.map((like) => _buildProfileCard(like)),
                      ],
                    ],
                  ),
                ),
    );
  }
}
