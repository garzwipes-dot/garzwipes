import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream_chat;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatProvider with ChangeNotifier {
  stream_chat.StreamChatClient? _client;
  stream_chat.Channel? _currentChannel;
  List<stream_chat.Channel> _userChannels = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  static const String _streamApiKey = 'fx999b56gb4b';

  stream_chat.StreamChatClient? get client => _client;
  stream_chat.Channel? get currentChannel => _currentChannel;
  List<stream_chat.Channel> get userChannels => _userChannels;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  bool get isConnecting => _isConnecting;
  bool get isDisconnecting => _isDisconnecting;

  Future<void> initializeClient() async {
    try {
      print('🎯 CHATPROVIDER: initializeClient llamado');

      if (_isDisconnecting) {
        print(
            '⏸️ CHATPROVIDER: En proceso de desconexión, ignorando inicialización');
        return;
      }

      // 🔥 CORREGIDO: Siempre crear nuevo cliente para evitar problemas de estado
      print('🆕 CHATPROVIDER: Creando nuevo cliente Stream Chat...');
      _client = stream_chat.StreamChatClient(
        _streamApiKey,
        logLevel: stream_chat.Level.INFO,
      );
      print('✅ CHATPROVIDER: Cliente de Stream Chat inicializado');
    } catch (e) {
      _error = 'Error inicializando cliente: $e';
      print('❌ CHATPROVIDER: $_error');
      rethrow;
    }
  }

  Future<bool> connectUser(String userId, String userName, String email) async {
    if (_isConnecting) {
      print(
          '⏳ CHATPROVIDER: Ya se está conectando, ignorando llamada duplicada');
      return false;
    }

    if (_isDisconnecting) {
      print('⏸️ CHATPROVIDER: En proceso de desconexión, ignorando conexión');
      return false;
    }

    if (_isConnected && _client?.state.currentUser?.id == userId) {
      print('✅ CHATPROVIDER: Ya está conectado con el mismo usuario');
      return true;
    }

    try {
      _isConnecting = true;
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🎯 CHATPROVIDER: connectUser INICIADO - User: $userName');

      await initializeClient();
      if (_client == null) {
        throw Exception('Cliente no inicializado');
      }

      print('🔑 CHATPROVIDER: Obteniendo token JWT...');
      String token = await _getTokenFromSupabaseEdgeFunction(userId, userName);
      print('✅ CHATPROVIDER: Token obtenido de Supabase Edge Function');

      if (token.split('.').length != 3) {
        throw Exception('Token JWT no tiene formato válido');
      }

      print('3️⃣ CHATPROVIDER: Conectando usuario con token JWT...');
      print('   - Token length: ${token.length}');
      print('   - Token preview: ${token.substring(0, 50)}...');

      await _client!.connectUser(
        stream_chat.User(
          id: userId,
          name: userName,
          extraData: {'email': email},
        ),
        token,
      );

      _isConnected = true;
      _isConnecting = false;
      print('✅✅✅ CHATPROVIDER: USUARIO CONECTADO EXITOSAMENTE A STREAM CHAT');

      await Future.delayed(const Duration(milliseconds: 500));
      await loadMatchesChannels();

      return true;
    } catch (e) {
      _error = 'Error conectando usuario: $e';
      print('💥 CHATPROVIDER: ERROR EN connectUser: $e');
      _isConnected = false;
      _isConnecting = false;
      await _safeDisconnect();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _getTokenFromSupabaseEdgeFunction(
      String userId, String userName) async {
    try {
      print('🚀 CHATPROVIDER: Invocando Supabase Edge Function: stream-token');

      final supabase = Supabase.instance.client;

      final response = await supabase.functions.invoke(
        'stream-token',
        body: {
          'userId': userId,
          'userName': userName,
        },
      );

      print('📡 CHATPROVIDER: Respuesta de Edge Function recibida');

      if (response.data == null) {
        throw Exception('Respuesta vacía de Edge Function');
      }

      print('   - Response data: ${response.data}');

      if (response.data['success'] == true && response.data['token'] != null) {
        final token = response.data['token'] as String;
        return token;
      } else {
        throw Exception(
            'Error en respuesta: ${response.data['error'] ?? response.data['message']}');
      }
    } catch (e) {
      print('❌ CHATPROVIDER: Error con Supabase Edge Function: $e');
      rethrow;
    }
  }

  Future<void> loadMatchesChannels() async {
    if (_client == null || !_isConnected || _isDisconnecting) {
      print(
          '⚠️ CHATPROVIDER: No se puede cargar matches - No conectado o desconectando');
      return;
    }

    try {
      print('🔄 CHATPROVIDER: loadMatchesChannels iniciado');
      _isLoading = true;
      notifyListeners();

      final supabase = Supabase.instance.client;
      final currentUserId = _client!.state.currentUser!.id;

      print('🔍 CHATPROVIDER: Buscando matches para: $currentUserId');

      final matchesResponse = await supabase
          .from('matches')
          .select('*')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

      print(
          '📊 CHATPROVIDER: Encontrados ${matchesResponse.length} matches en la base de datos');

      List<stream_chat.Channel> matchChannels = [];

      for (final match in matchesResponse) {
        final user1Id = match['user1_id'] as String;
        final user2Id = match['user2_id'] as String;

        final otherUserId = user1Id == currentUserId ? user2Id : user1Id;

        try {
          print('👤 CHATPROVIDER: Cargando perfil de: $otherUserId');
          final otherUserResponse = await supabase
              .from('profiles')
              .select('full_name, email')
              .eq('id', otherUserId)
              .single();

          final otherUserName = otherUserResponse['full_name'] as String;
          print('✅ CHATPROVIDER: Perfil cargado - Nombre: $otherUserName');

          final channel =
              await getOrCreateMatchChannel(otherUserId, otherUserName);

          if (channel != null) {
            matchChannels.add(channel);
            print('✅ CHATPROVIDER: Canal agregado para $otherUserName');
          } else {
            print(
                '⚠️ CHATPROVIDER: No se pudo crear canal para $otherUserName');
          }
        } catch (e) {
          print('❌ CHATPROVIDER: Error cargando perfil de $otherUserId: $e');
        }
      }

      _userChannels = matchChannels;
      print(
          '✅ CHATPROVIDER: ${matchChannels.length} chats de matches cargados exitosamente');
    } catch (e) {
      _error = 'Error cargando matches: $e';
      print('❌ CHATPROVIDER: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<stream_chat.Channel?> getOrCreateMatchChannel(
      String otherUserId, String otherUserName) async {
    if (_client == null || !_isConnected || _isDisconnecting) {
      print(
          '⚠️ CHATPROVIDER: No se puede crear canal - No conectado o desconectando');
      return null;
    }

    try {
      final channelId =
          _generateChannelId(_client!.state.currentUser!.id, otherUserId);

      print('🔍 CHATPROVIDER: Buscando canal: $channelId');

      final channels = await _client!
          .queryChannels(
            filter: stream_chat.Filter.equal('id', channelId),
          )
          .first;

      if (channels.isNotEmpty) {
        print('✅ CHATPROVIDER: Canal existente encontrado');
        return channels.first;
      }

      print('🆕 CHATPROVIDER: Creando nuevo canal para: $otherUserName');
      final channel = _client!.channel(
        'messaging',
        id: channelId,
        extraData: {
          'name': 'Chat con $otherUserName',
          'members': [
            _client!.state.currentUser!.id,
            otherUserId,
          ],
          'created_by_id': _client!.state.currentUser!.id,
          'image': '',
          'match_channel': true,
        },
      );

      await channel.watch();
      print('✅ CHATPROVIDER: Nuevo canal creado');
      return channel;
    } catch (e) {
      _error = 'Error creando canal para match: $e';
      print('❌ CHATPROVIDER: $_error');
      return null;
    }
  }

  String _generateChannelId(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    final channelId = 'match_${ids[0]}_${ids[1]}';

    if (channelId.length > 64) {
      final shortId1 = user1Id.substring(0, 8);
      final shortId2 = user2Id.substring(0, 8);
      final shortIds = [shortId1, shortId2]..sort();
      return 'match_${shortIds[0]}_${shortIds[1]}';
    }

    return channelId;
  }

  Future<bool> deleteMatch(String otherUserId) async {
    try {
      print('🗑️ CHATPROVIDER: Eliminando match con usuario: $otherUserId');
      _isLoading = true;
      notifyListeners();

      final supabase = Supabase.instance.client;
      final currentUserId = _client!.state.currentUser!.id;

      await supabase
          .from('matches')
          .delete()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .or('user1_id.eq.$otherUserId,user2_id.eq.$otherUserId');

      print('✅ CHATPROVIDER: Match eliminado de la base de datos');

      final channelId = _generateChannelId(currentUserId, otherUserId);
      try {
        final channel = _client!.channel('messaging', id: channelId);
        await channel.delete();
        print('✅ CHATPROVIDER: Canal de chat eliminado de Stream');
      } catch (e) {
        print('⚠️ CHATPROVIDER: Error eliminando canal (puede ser normal): $e');
      }

      _userChannels.removeWhere((channel) => channel.id == channelId);

      if (_currentChannel?.id == channelId) {
        _currentChannel = null;
      }

      print('✅ CHATPROVIDER: Match eliminado completamente');
      return true;
    } catch (e) {
      _error = 'Error eliminando match: $e';
      print('❌ CHATPROVIDER: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnectUser() async {
    if (_isDisconnecting) {
      print(
          '⏸️ CHATPROVIDER: Ya se está desconectando, ignorando llamada duplicada');
      return;
    }

    try {
      _isDisconnecting = true;
      _isLoading = true;
      notifyListeners();

      print(
          '🔌 CHATPROVIDER: disconnectUser llamado - Limpiando todo el estado');

      await _safeDisconnect();

      print('✅ CHATPROVIDER: disconnectUser completado exitosamente');
    } catch (e) {
      print('❌ CHATPROVIDER: Error en disconnectUser: $e');
      await _forceCleanup();
    } finally {
      _isDisconnecting = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _safeDisconnect() async {
    try {
      if (_client != null) {
        print('🔌 CHATPROVIDER: Desconectando usuario de Stream Chat...');
        await _client!.disconnectUser();
        print('✅ CHATPROVIDER: Usuario desconectado de Stream Chat');
      }
    } catch (e) {
      print('⚠️ CHATPROVIDER: Error en _safeDisconnect: $e');
    } finally {
      await _forceCleanup();
    }
  }

  Future<void> _forceCleanup() async {
    print('🧹 CHATPROVIDER: Limpiando estado interno forzadamente...');

    _userChannels.clear();
    _currentChannel = null;
    _isConnected = false;
    _isConnecting = false;
    _error = null;
    _client = null;

    print('✅ CHATPROVIDER: Estado completamente limpiado');
  }

  void forceCleanup() {
    print('🔄 CHATPROVIDER: forceCleanup llamado externamente');
    Future.microtask(() async {
      await _forceCleanup();
      notifyListeners();
    });
  }

  void setCurrentChannel(stream_chat.Channel channel) {
    _currentChannel = channel;
    notifyListeners();
  }

  Future<void> refreshMatches() async {
    if (_isConnected && !_isDisconnecting) {
      print('🔄 CHATPROVIDER: refreshMatches llamado');
      await loadMatchesChannels();
    } else {
      print(
          '⚠️ CHATPROVIDER: No se puede refrescar - No conectado o desconectando');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
