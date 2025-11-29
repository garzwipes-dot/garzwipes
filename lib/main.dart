import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cloudinary_storage_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/screens/welcome/welcome_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/profile/complete_profile_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 MAIN: Iniciando aplicación...');
  await _initializeApp();
  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  const String supabaseUrl = 'https://rneestjobhdjyhlptmda.supabase.co';
  const String supabaseKey = 'sb_publishable_CYNs2szudojGEjm5Pyze9g_TWjaTaD1';

  try {
    print('🔧 MAIN: Inicializando Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      debug: false,
    );
    print('✅ MAIN: Supabase inicializado correctamente');
  } catch (e) {
    print('❌ MAIN: Error inicializando Supabase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ MYAPP: Construyendo aplicación...');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
            create: (context) => CloudinaryStorageProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: Builder(
        builder: (context) {
          return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              // 🔥 INICIALIZAR CONTEXTO EN AUTH PROVIDER DESPUÉS DE CONSTRUIR
              WidgetsBinding.instance.addPostFrameCallback((_) {
                authProvider.initializeWithContext(context);
              });

              return MaterialApp(
                title: 'GarZwipes',
                theme: AppTheme.lightTheme,
                home: const AuthWrapper(),
                debugShowCheckedModeBanner: false,
                navigatorKey: authProvider.navigatorKey,
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  bool _hasInitializedContext = false;
  DateTime? _lastChatInitAttempt;

  @override
  void initState() {
    super.initState();
    print('🔄 AUTHWRAPPER: initState llamado');
    _initializeApp();
  }

  // 🔥 CORREGIDO: Removí el parámetro no usado
  Future<void> _initializeApp() async {
    // Esperar a que auth se inicialice completamente
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isInitializing = false;
    });
  }

  void _initializeContextIfNeeded(
      AuthProvider authProvider, ChatProvider chatProvider) {
    if (!_hasInitializedContext) {
      _hasInitializedContext = true;
      authProvider.initializeWithContext(context);
    }
  }

  void _initializeChatIfNeeded(
      AuthProvider authProvider, ChatProvider chatProvider) {
    final now = DateTime.now();

    // 🔥 THROTTLING: Máximo un intento cada 3 segundos
    if (_lastChatInitAttempt != null &&
        now.difference(_lastChatInitAttempt!) < const Duration(seconds: 3)) {
      return;
    }

    final shouldInitialize = authProvider.currentUser != null &&
        authProvider.isEmailConfirmed &&
        !chatProvider.isConnected &&
        !chatProvider.isConnecting &&
        !chatProvider.isDisconnecting &&
        !authProvider.isInitializingChat &&
        !authProvider.isLoggingOut;

    if (shouldInitialize) {
      _lastChatInitAttempt = now;
      print('🎯 AUTHWRAPPER: Condiciones cumplidas, inicializando chat...');
      authProvider.initializeChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        print(
            '🔄 AUTHWRAPPER: Rebuild - User: ${authProvider.currentUser?.email}');

        if (_isInitializing) {
          return _buildLoadingScreen('Inicializando...');
        }

        // 🔥 INICIALIZACIÓN CONTROLADA
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeContextIfNeeded(authProvider, chatProvider);
          _initializeChatIfNeeded(authProvider, chatProvider);
        });

        // 🔥 ESTADO DE LOGOUT PRIORITARIO
        if (authProvider.isLoggingOut) {
          return _buildLoadingScreen('Cerrando sesión...');
        }

        if (authProvider.isInitializing) {
          return _buildLoadingScreen('Cargando...');
        }

        return _buildMainContent(authProvider, chatProvider);
      },
    );
  }

  Widget _buildMainContent(
      AuthProvider authProvider, ChatProvider chatProvider) {
    if (authProvider.currentUser == null) {
      print('👤 AUTHWRAPPER: No user found, showing WelcomeScreen');
      return const WelcomeScreen();
    }

    if (!authProvider.isEmailConfirmed) {
      print(
          '📧 AUTHWRAPPER: User email not confirmed, showing confirmation screen');
      return _EmailConfirmationScreen(authProvider: authProvider);
    }

    // 🔥 MEJORAR GESTIÓN DE ESTADO DEL CHAT
    if (authProvider.isInitializingChat || chatProvider.isConnecting) {
      return _buildLoadingScreen('Conectando chat...');
    }

    if (chatProvider.isDisconnecting) {
      return _buildLoadingScreen('Desconectando...');
    }

    if (!authProvider.isProfileComplete) {
      print(
          '📝 AUTHWRAPPER: Profile incomplete, showing CompleteProfileScreen');
      return const CompleteProfileScreen();
    }

    print('🏠 AUTHWRAPPER: Profile complete, showing HomeScreen');
    return const HomeScreen();
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF8B1538),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailConfirmationScreen extends StatelessWidget {
  final AuthProvider authProvider;

  const _EmailConfirmationScreen({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Color(0xFF8B1538),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirma tu email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hemos enviado un email de confirmación a:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              authProvider.currentUser!.email!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Por favor revisa tu bandeja de entrada y haz clic en el link de confirmación para activar tu cuenta.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => authProvider.signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1538),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Volver al Login',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final resent = await authProvider
                    .resendConfirmationEmail(authProvider.currentUser!.email!);
                if (resent && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Email reenviado a ${authProvider.currentUser!.email!}',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                'Reenviar email de confirmación',
                style: TextStyle(
                  color: Color(0xFF8B1538),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
