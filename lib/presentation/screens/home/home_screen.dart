import 'package:flutter/material.dart';
import 'package:garzwipes/presentation/screens/explore/explore_screen.dart';
import 'package:garzwipes/presentation/screens/likes/likes_screen.dart';
import 'package:garzwipes/presentation/screens/profile/profile_screen.dart';
import 'package:garzwipes/presentation/screens/chat/chat_list_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    print('🏠 HOMESCREEN: initState llamado');
    _checkChatStatus();
  }

  void _checkChatStatus() {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>(); // ✅ AHORA SE USA

    print('🔍 HOMESCREEN: Verificando estado del chat...');
    print('   - ChatProvider isConnected: ${chatProvider.isConnected}');
    print('   - ChatProvider isLoading: ${chatProvider.isLoading}');
    print('   - ChatProvider error: ${chatProvider.error}');
    print('   - User: ${authProvider.currentUser?.email}'); // ✅ SE USA AQUÍ

    // Solo verificar estado, NO inicializar desde aquí
    if (!chatProvider.isConnected &&
        authProvider.currentUser != null && // ✅ SE USA AQUÍ
        authProvider.isEmailConfirmed) {
      // ✅ SE USA AQUÍ
      print('ℹ️ HOMESCREEN: Chat no conectado, AuthWrapper debería manejarlo');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      print('🚪 HOMESCREEN: Iniciando cierre de sesión...');
      await authProvider.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider =
        context.watch<ChatProvider>(); // ✅ Solo chatProvider necesario aquí

    final List<Widget> screens = [
      const ExploreScreen(),
      const LikesScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    print(
        '🏠 HOMESCREEN: Rebuilding - Index: $_currentIndex, Chat Connected: ${chatProvider.isConnected}');

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        title: const Text(
          'GarZwipes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0E0F0E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1A),
          border: Border(
            top: BorderSide(color: Colors.grey[800]!, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            print('📍 HOMESCREEN: Cambiando a pestaña: $index');
            setState(() {
              _currentIndex = index;
            });

            // Si vamos a la pestaña de chat y está conectado, refrescar matches
            if (index == 2 && chatProvider.isConnected) {
              print('🔄 HOMESCREEN: Refrescando chats...');
              chatProvider.refreshMatches();
            }
          },
          backgroundColor: const Color(0xFF1A1B1A),
          selectedItemColor: const Color(0xFF8B1538),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Gente',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Likes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
