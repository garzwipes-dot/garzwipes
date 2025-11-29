import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_provider.dart';
import '/presentation/screens/welcome/welcome_screen.dart';
import '/utils/mutex.dart'; // 🔥 RUTA CORRECTA

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  bool _isProfileComplete = false;

  // 🔥 VARIABLES MEJORADAS CON MUTEX
  bool _isInitializingChat = false;
  bool _hasInitializedChat = false;
  String? _lastUserIdForChat;
  ChatProvider? _chatProvider;
  bool _isLoggingOut = false;

  // 🔥 NUEVO: Mutex y control de tiempo
  final Mutex _authMutex = Mutex();
  bool _isProcessingAuthChange = false;
  DateTime? _lastChatInitTime;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isProfileComplete => _isProfileComplete;
  bool get isEmailConfirmed => _currentUser?.emailConfirmedAt != null;
  bool get isInitializingChat => _isInitializingChat;
  bool get hasInitializedChat => _hasInitializedChat;
  bool get isLoggingOut => _isLoggingOut;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _currentUser = _supabase.auth.currentUser;
      print('AuthProvider initialized - User: ${_currentUser?.email}');

      if (_currentUser != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      print('Error initializing auth: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // 🔥 MEJORADO: Inicializar con contexto
  void initializeWithContext(BuildContext context) {
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    print('🔧 AUTHPROVIDER: Contexto inicializado con ChatProvider');

    // Inicializar chat si hay usuario autenticado y NO estamos haciendo logout
    if (_currentUser != null && isEmailConfirmed && !_isLoggingOut) {
      _safeInitializeChat();
    }
  }

  // 🔥 NUEVO MÉTODO: Manejo seguro de cambios de auth
  Future<void> handleAuthStateChange({bool isLogout = false}) async {
    // Throttling: máximo una llamada cada 500ms
    if (_isProcessingAuthChange) {
      print(
          '⏸️ AUTHPROVIDER: Procesamiento en curso, ignorando llamada duplicada');
      return;
    }

    await _authMutex.protect(() async {
      _isProcessingAuthChange = true;

      try {
        print('🔄 AUTHPROVIDER: handleAuthStateChange (isLogout: $isLogout)');
        print('   - User: ${_currentUser?.email}');
        print('   - Email confirmado: $isEmailConfirmed');
        print('   - IsLoggingOut: $_isLoggingOut');

        // 🔥 CLAVE MEJORADA: Si es logout o estamos en proceso de logout, NO inicializar chat
        if (isLogout || _isLoggingOut) {
          print(
              '🚫 AUTHPROVIDER: Logout detectado, omitiendo inicialización de chat');
          return;
        }

        final currentUserId = _currentUser?.id;

        // Si el usuario cambió, resetear estado del chat
        if (_lastUserIdForChat != currentUserId) {
          print(
              '🔄 AUTHPROVIDER: Usuario cambió de $_lastUserIdForChat a $currentUserId');
          _resetChatFlags();
          _lastUserIdForChat = currentUserId;

          // Inicializar chat para el nuevo usuario solo si no es logout
          if (currentUserId != null &&
              isEmailConfirmed &&
              _chatProvider != null) {
            await _safeInitializeChat();
          }
        } else if (currentUserId != null &&
            isEmailConfirmed &&
            _chatProvider != null &&
            !_hasInitializedChat) {
          // Si es el mismo usuario pero el chat no se inicializó
          print(
              '🔄 AUTHPROVIDER: Re-inicializando chat para usuario existente');
          await _safeInitializeChat();
        }
      } finally {
        _isProcessingAuthChange = false;
      }
    });
  }

  // 🔥 NUEVO: Inicialización segura del chat con throttling
  Future<void> _safeInitializeChat() async {
    final now = DateTime.now();

    // Throttling: máximo un intento cada 3 segundos
    if (_lastChatInitTime != null &&
        now.difference(_lastChatInitTime!) < Duration(seconds: 3)) {
      print('⏰ AUTHPROVIDER: Throttling activado, esperando...');
      return;
    }

    _lastChatInitTime = now;
    await _initializeChat();
  }

  // 🔥 MEJORADO: Inicializar chat de forma segura
  Future<void> _initializeChat() async {
    if (_isInitializingChat || _chatProvider == null || _isLoggingOut) {
      print(
          '⏸️ AUTHPROVIDER: Chat ya se está inicializando, ChatProvider es null o estamos en logout');
      return;
    }

    // 🔥 VERIFICACIÓN MEJORADA: Esperar si el provider está en transición
    if (_chatProvider!.isConnecting || _chatProvider!.isDisconnecting) {
      print('⏳ AUTHPROVIDER: ChatProvider en transición, esperando...');
      await Future.delayed(const Duration(seconds: 1));

      // Verificar nuevamente después de esperar
      if (_chatProvider!.isConnecting ||
          _chatProvider!.isDisconnecting ||
          _isLoggingOut) {
        print(
            '❌ AUTHPROVIDER: ChatProvider sigue en transición o logout iniciado, cancelando inicialización');
        return;
      }
    }

    print('🎯 AUTHPROVIDER: Verificando condiciones para Stream Chat...');
    print('   - User: ${_currentUser?.email}');
    print('   - Email confirmado: $isEmailConfirmed');
    print('   - IsInitializingChat: $_isInitializingChat');
    print('   - IsLoggingOut: $_isLoggingOut');
    print('   - ChatProvider isConnected: ${_chatProvider!.isConnected}');
    print('   - ChatProvider isConnecting: ${_chatProvider!.isConnecting}');
    print(
        '   - ChatProvider isDisconnecting: ${_chatProvider!.isDisconnecting}');

    final shouldInitialize = _currentUser != null &&
        isEmailConfirmed &&
        !_isInitializingChat &&
        !_isLoggingOut &&
        !_chatProvider!.isConnecting &&
        !_chatProvider!.isDisconnecting &&
        !_chatProvider!.isConnected;

    if (shouldInitialize) {
      _isInitializingChat = true;
      notifyListeners();

      print(
          '🎯🎯🎯 AUTHPROVIDER: INICIANDO STREAM CHAT PARA: ${_currentUser!.email}');

      try {
        print('1️⃣ AUTHPROVIDER: Inicializando cliente de Stream Chat...');
        await _chatProvider!.initializeClient();

        print('2️⃣ AUTHPROVIDER: Conectando usuario a Stream Chat...');
        final connected = await _chatProvider!.connectUser(
          _currentUser!.id,
          _userProfile?['full_name'] ?? _currentUser!.email!.split('@').first,
          _currentUser!.email!,
        );

        if (connected) {
          print('✅✅✅ AUTHPROVIDER: STREAM CHAT CONECTADO EXITOSAMENTE');
          _hasInitializedChat = true;
        } else {
          print('❌❌❌ AUTHPROVIDER: ERROR CONECTANDO A STREAM CHAT');
          _resetChatFlags();
        }
      } catch (e) {
        print('💥💥💥 AUTHPROVIDER: ERROR INICIALIZANDO STREAM CHAT: $e');
        _resetChatFlags();
      } finally {
        _isInitializingChat = false;
        notifyListeners();
        print('🏁 AUTHPROVIDER: Proceso de inicialización completado');
      }
    } else {
      if (_currentUser != null && isEmailConfirmed) {
        print('⏸️ AUTHPROVIDER: Condiciones no cumplidas para Stream Chat:');
        print('   - IsInitializingChat: $_isInitializingChat');
        print('   - HasInitializedChat: $_hasInitializedChat');
        print('   - IsLoggingOut: $_isLoggingOut');
        print('   - Chat isConnected: ${_chatProvider!.isConnected}');
        print('   - Chat isConnecting: ${_chatProvider!.isConnecting}');
        print('   - Chat isDisconnecting: ${_chatProvider!.isDisconnecting}');
      }
    }
  }

  void _resetChatFlags() {
    _isInitializingChat = false;
    _hasInitializedChat = false;
  }

  // 🔥 MEJORADO: Forzar inicialización del chat con verificación de logout
  void initializeChat() {
    if (_chatProvider != null &&
        _currentUser != null &&
        isEmailConfirmed &&
        !_isLoggingOut) {
      _safeInitializeChat();
    }
  }

  // 🔥 MÉTODO DE LOGOUT COMPLETAMENTE REESCRITO
  Future<void> signOut() async {
    // Evitar múltiples llamadas simultáneas a logout
    if (_isLoggingOut) {
      print('⏸️ AUTH: Logout ya en progreso, ignorando llamada duplicada');
      return;
    }

    try {
      _isLoggingOut = true;
      notifyListeners();

      print('=== INICIANDO CIERRE DE SESIÓN ===');

      // 1. DETENER CUALQUIER INICIALIZACIÓN DE CHAT EN CURSO
      print('🛑 AUTH: Deteniendo inicializaciones de chat...');
      _isInitializingChat = false;
      _hasInitializedChat = false;

      // 2. DESCONECTAR DE STREAM CHAT
      try {
        print('🔌 AUTH: Desconectando de Stream Chat...');
        if (_chatProvider != null) {
          await _chatProvider!.disconnectUser();
          print('✅ AUTH: Desconectado de Stream Chat');
        } else {
          print('⚠️ AUTH: ChatProvider no disponible para desconexión');
        }
      } catch (e) {
        print('⚠️ AUTH: Error desconectando Stream Chat: $e');
        // Continuar con el logout incluso si hay error en Stream Chat
      }

      // 3. ESPERAR BREVEMENTE PARA ASEGURAR DESCONEXIÓN
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. CERRAR SESIÓN EN SUPABASE
      print('🚪 AUTH: Cerrando sesión en Supabase...');
      await _supabase.auth.signOut(scope: SignOutScope.global);
      print('✅ AUTH: Sesión de Supabase cerrada');

      // 5. LIMPIAR ESTADO LOCAL COMPLETAMENTE
      print('🧹 AUTH: Limpiando estado local...');
      _currentUser = null;
      _userProfile = null;
      _isProfileComplete = false;
      _error = null;

      // 🔥 LIMPIAR ESTADO DEL CHAT COMPLETAMENTE
      _resetChatFlags();
      _lastUserIdForChat = null;
      _lastChatInitTime = null;

      print('✅ AUTH: Estado local limpiado');

      // 6. NOTIFICAR CAMBIOS
      notifyListeners();

      // 7. NAVEGAR A WELCOMESCREEN
      print('🧭 AUTH: Navegando a WelcomeScreen...');
      _navigateToWelcomeScreen();

      print('=== CIERRE DE SESIÓN COMPLETADO ===');
    } catch (e) {
      print('💥 AUTH: Error durante sign out: $e');

      // 🔥 FORZAR LIMPIEZA INCLUSO SI HAY ERROR
      _forceCleanup();

      // Intentar navegar de todos modos
      _navigateToWelcomeScreen();

      print('🔄 AUTH: Sesión forzada a cerrar debido a error');
    } finally {
      // 🔥 IMPORTANTE: Siempre resetear el flag de logout
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  // 🔥 NUEVO: Limpieza forzada
  void _forceCleanup() {
    _currentUser = null;
    _userProfile = null;
    _isProfileComplete = false;
    _error = null;
    _resetChatFlags();
    _lastUserIdForChat = null;
    _lastChatInitTime = null;
    notifyListeners();
  }

  // 🔥 NUEVO MÉTODO: Navegar a WelcomeScreen
  void _navigateToWelcomeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null &&
          navigatorKey.currentState!.mounted) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
        print('✅ AUTH: Navegación a WelcomeScreen completada');
      } else {
        print('⚠️ AUTH: NavigatorState no disponible para navegación');
      }
    });
  }

  // 🔥 MÉTODO MEJORADO: Cargar usuario actual
  Future<void> loadCurrentUser() async {
    try {
      _currentUser = _supabase.auth.currentUser;
      if (_currentUser != null && !_isLoggingOut) {
        await _loadUserProfile();
        // 🔥 SOLO manejar cambio de estado si NO estamos en logout
        if (!_isLoggingOut) {
          await handleAuthStateChange();
        }
      }
    } catch (e) {
      print('❌ Error loading current user: $e');
    }
  }

  // 🔥 MÉTODO DE REGISTRO CORREGIDO - AHORA GUARDA birth_date
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
    String? birthDate,
  }) async {
    try {
      setLoading(true);
      _error = null;

      print('=== INICIANDO REGISTRO ===');
      print('Email: $email');
      print('Nombre: $fullName');
      print('Fecha de nacimiento: $birthDate');

      final cleanEmail = email.trim().toLowerCase();

      // 🔥 VERIFICACIÓN ROBUSTA: Buscar en profiles
      print('🔍 Verificando si el usuario ya existe...');

      try {
        final existingProfile = await _supabase
            .from('profiles')
            .select('id, email')
            .eq('email', cleanEmail)
            .maybeSingle();

        if (existingProfile != null) {
          _error =
              'Ya existe una cuenta con este correo electrónico. ¿Olvidaste tu contraseña?';
          print('❌ REGISTRO: Correo ya existe en profiles: $cleanEmail');
          return false;
        }
      } catch (e) {
        print('⚠️ REGISTRO: Error en verificación previa: $e');
      }

      // 🔥 INTENTAR REGISTRO
      print('🎯 Intentando registrar usuario...');
      final AuthResponse response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': fullName,
          'email': cleanEmail,
        },
      );

      print('📨 Respuesta de Supabase:');
      print('   - User ID: ${response.user?.id}');
      print('   - Email: ${response.user?.email}');
      print('   - Email confirmado: ${response.user?.emailConfirmedAt}');
      print('   - Session: ${response.session != null ? "SI" : "NO"}');

      if (response.user != null) {
        if (response.user?.emailConfirmedAt != null) {
          _error =
              'Ya existe una cuenta con este correo electrónico. ¿Olvidaste tu contraseña?';
          print('❌ REGISTRO: Usuario ya existía y confirmado: $cleanEmail');
          await _supabase.auth.signOut();
          _currentUser = null;
          return false;
        } else if (response.session != null) {
          _error =
              'Error inesperado en el registro. Por favor contacta soporte.';
          print('⚠️ REGISTRO: Sesión creada automáticamente (inesperado)');
          await _supabase.auth.signOut();
          _currentUser = null;
          return false;
        } else {
          print(
              '✅ REGISTRO: Usuario nuevo creado, email pendiente de confirmación: $cleanEmail');

          // 🔥 CORRECCIÓN: CREAR PERFIL CON birth_date
          try {
            String? formattedBirthDate;
            if (birthDate != null && birthDate.isNotEmpty) {
              final parts = birthDate.split('/');
              if (parts.length == 3) {
                final day = parts[0];
                final month = parts[1];
                final year = parts[2];
                formattedBirthDate = '$year-$month-$day';
                print('📅 Fecha convertida: $formattedBirthDate');
              }
            }

            final profileData = {
              'id': response.user!.id,
              'email': cleanEmail,
              'full_name': fullName,
              'show_profile': false,
            };

            if (formattedBirthDate != null) {
              profileData['birth_date'] = formattedBirthDate;
            }

            await _supabase.from('profiles').insert(profileData);
            print('✅ Perfil básico creado exitosamente con birth_date');
          } catch (e) {
            print('⚠️ Error creando perfil básico: $e');
          }

          await _supabase.auth.signOut();
          _currentUser = null;

          print('📧 Email de confirmación enviado a: $cleanEmail');
          return true;
        }
      } else {
        print('❌ REGISTRO: Usuario es null en la respuesta');
        _error = 'Error desconocido durante el registro';
        return false;
      }
    } on AuthException catch (e) {
      print('🔴 ERROR AUTH: ${e.message}');
      _error = _parseAuthError(e.message);
      return false;
    } catch (e) {
      _error = 'Error inesperado durante el registro: $e';
      print('❌ ERROR GENERAL: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 🔥 MÉTODO PARA ANALIZAR ERRORES DE AUTH
  String _parseAuthError(String errorMessage) {
    print('🔍 Analizando error: $errorMessage');

    if (errorMessage.contains('already registered') ||
        errorMessage.contains('User already exists') ||
        errorMessage.contains('user_already_exists') ||
        errorMessage.contains('email_taken') ||
        errorMessage.contains('already in use') ||
        errorMessage.contains('duplicate key') ||
        errorMessage.contains('unique constraint')) {
      return 'Ya existe una cuenta con este correo electrónico. ¿Olvidaste tu contraseña?';
    } else if (errorMessage.contains('invalid email')) {
      return 'Correo electrónico inválido. Usa tu correo UAEH.';
    } else if (errorMessage.contains('Password should')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    } else if (errorMessage.contains('email confirmation')) {
      return 'Ya existe una cuenta con este correo. Revisa tu bandeja de entrada para confirmar tu email.';
    } else if (errorMessage.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    } else {
      return 'Error durante el registro: E-Mail no confirmado';
    }
  }

  Future<bool> signInWithPassword(String email, String password) async {
    try {
      setLoading(true);
      _error = null;

      final cleanEmail = email.trim().toLowerCase();

      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;

        if (_currentUser!.emailConfirmedAt == null) {
          _error =
              'Por favor confirma tu email antes de iniciar sesión. Revisa tu bandeja de entrada.';
          _currentUser = null;
          await _supabase.auth.signOut();

          try {
            await _supabase.auth.resend(
              type: OtpType.signup,
              email: cleanEmail,
            );
            print('📧 Email de confirmación reenviado a: $cleanEmail');
          } catch (e) {
            print('⚠️ Error reenviando email de confirmación: $e');
          }

          return false;
        }

        await _ensureProfileExists();
        await _loadUserProfile();

        print('✅ Login exitoso para: ${_currentUser!.email}');

        // 🔥 NUEVO: Manejar cambio de estado después del login
        if (!_isLoggingOut) {
          await handleAuthStateChange();
        }

        return true;
      }
      return false;
    } on AuthException catch (e) {
      _error = _parseAuthError(e.message);
      return false;
    } catch (e) {
      _error = 'Error durante el inicio de sesión: $e';
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> resendConfirmationEmail(String email) async {
    try {
      setLoading(true);
      _error = null;

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );

      print('✅ Email de confirmación reenviado a: $email');
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Error al reenviar email de confirmación: $e';
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _ensureProfileExists() async {
    try {
      if (_currentUser == null) return;

      final profileResponse = await _supabase
          .from('profiles')
          .select('id, show_profile')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (profileResponse == null) {
        print(
            '🆕 Perfil no encontrado, creando perfil para usuario: ${_currentUser!.id}');
        await _supabase.from('profiles').insert({
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'full_name': _currentUser!.userMetadata?['full_name'] ?? 'Usuario',
          'show_profile': true,
        });
        print('✅ Perfil creado exitosamente');
      } else {
        if (profileResponse['show_profile'] == false) {
          print(
              '🔄 Actualizando show_profile a true para usuario: ${_currentUser!.id}');
          await _supabase
              .from('profiles')
              .update({'show_profile': true}).eq('id', _currentUser!.id);
          print('✅ show_profile actualizado a true');
        } else {
          print(
              '✅ Perfil ya existe y show_profile es true para usuario: ${_currentUser!.id}');
        }
      }
    } catch (e) {
      print('❌ Error asegurando que el perfil existe: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      if (_currentUser == null) return;

      final response = await _supabase.from('profiles').select('''
            *,
            genders(name),
            user_interests(
              interest_id,
              interests(name)
            )
          ''').eq('id', _currentUser!.id).single();

      _userProfile = response;
      _checkProfileCompletion();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }
  }

  void _checkProfileCompletion() {
    if (_userProfile == null) {
      _isProfileComplete = false;
      return;
    }

    final requiredFields = [
      _userProfile!['gender_id'],
      _userProfile!['height'],
      _userProfile!['major'],
    ];

    _isProfileComplete = requiredFields.every((field) =>
        field != null && field != '' && (field is! num || field > 0));

    print('✅ Profile completion checked: $_isProfileComplete');
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      setLoading(true);
      _error = null;

      final userId = _currentUser!.id;

      print('=== INICIANDO ACTUALIZACION DE PERFIL ===');
      print('User ID: $userId');
      print('Datos recibidos: $profileData');

      if (profileData['gender_id'] == null) {
        throw Exception('El genero es requerido');
      }
      if (profileData['height'] == null) {
        throw Exception('La altura es requerida');
      }
      if (profileData['major'] == null ||
          profileData['major'].toString().isEmpty) {
        throw Exception('La carrera es requerida');
      }

      final cleanedData = <String, dynamic>{};

      cleanedData['gender_id'] = profileData['gender_id'].toString();
      cleanedData['height'] = _parseInt(profileData['height']) ?? 170;
      cleanedData['major'] = profileData['major'].toString().trim();

      cleanedData['bio'] = profileData['bio']?.toString().trim();
      cleanedData['year'] = _parseInt(profileData['year']);

      cleanedData['looking_for_gender_ids'] =
          profileData['looking_for_gender_ids'] ?? [];

      print('Datos limpios para guardar: $cleanedData');

      await _supabase.from('profiles').update(cleanedData).eq('id', userId);

      print('✅ Perfil principal actualizado');

      final List<String>? interestsIds = profileData['interests_ids'] is List
          ? List<String>.from(profileData['interests_ids'])
          : null;

      if (interestsIds != null && interestsIds.isNotEmpty) {
        print('🔄 Actualizando intereses: $interestsIds');
        await _updateUserInterests(userId, interestsIds);
      } else {
        print('ℹ️ No hay intereses para actualizar');
      }

      await _loadUserProfile();

      print('=== PERFIL ACTUALIZADO EXITOSAMENTE ===');
      return true;
    } catch (e) {
      print('❌ ERROR: $e');
      print('Stack trace: ${e.toString()}');

      _error = e.toString();

      if (e is PostgrestException) {
        _error = 'Error de base de datos: ${e.message}';
        print('Detalles PostgREST: ${e.details}');
      }

      return false;
    } finally {
      setLoading(false);
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> _updateUserInterests(
      String userId, List<String> interestIds) async {
    try {
      print('=== ACTUALIZANDO INTERESES ===');
      print('User ID: $userId');
      print('Interest IDs: $interestIds');

      final validInterestIds =
          interestIds.where((id) => id.isNotEmpty).toList();

      if (validInterestIds.isEmpty) {
        print('ℹ️ No hay interest IDs validos');
        return;
      }

      print('🗑️ Eliminando intereses existentes...');
      await _supabase.from('user_interests').delete().eq('user_id', userId);

      print('➕ Insertando nuevos intereses...');
      final interestData = validInterestIds
          .map((interestId) => {
                'user_id': userId,
                'interest_id': interestId,
              })
          .toList();

      await _supabase.from('user_interests').insert(interestData);

      print('✅ Intereses actualizados exitosamente');
    } catch (e) {
      print('❌ Error actualizando intereses: $e');
      rethrow;
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
