// lib/presentation/screens/auth/login_register_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0F0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GarZwipes',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF8B1538),
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B1538),
          labelColor: const Color(0xFF8B1538),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Iniciar Sesión'),
            Tab(text: 'Registrarse'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [LoginScreen(), RegisterScreen()],
      ),
    );
  }
}
