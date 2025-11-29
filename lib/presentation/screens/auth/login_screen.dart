import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../profile/complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _showInstructions = false;
  bool _obscurePassword = true;

  void _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && context.mounted) {
        // Navegar automaticamente después del login exitoso
        _navigateAfterLogin(context, authProvider);
      } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'Error al iniciar sesión',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateAfterLogin(BuildContext context, AuthProvider authProvider) {
    // Verificar si el perfil está completo
    if (authProvider.isProfileComplete) {
      // Navegar al HomeScreen (que muestra ExploreScreen por defecto)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // Elimina todas las rutas anteriores
      );
    } else {
      // Navegar a CompleteProfileScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
        (route) => false, // Elimina todas las rutas anteriores
      );
    }
  }

  Widget _buildLoadingIndicator(bool isMobile) {
    // 🔥 AHORA EL LOADING TIENE EL MISMO ALTO QUE EL BOTÓN NORMAL
    return Container(
      height: isMobile ? 56 : 64, // Mismo alto que el botón
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B1538).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF8B1538)),
              backgroundColor: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Iniciando sesión...',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool? showSuffixIcon,
    VoidCallback? onSuffixPressed,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
    required bool isMobile,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.grey,
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.grey,
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: showSuffixIcon == true
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: onSuffixPressed,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF2A2B2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isMobile ? 16 : 20,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 24.0 : 48.0;
    final maxWidth = isMobile ? double.infinity : 400.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMobile) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: Image.asset(
                              'assets/images/Garza.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'GarZwipes',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8B1538),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa a tu cuenta',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo UAEH',
                          icon: Icons.email,
                          hintText: 'aa123456@uaeh.edu.mx',
                          validator: Validators.validateUAEHEmail,
                          isMobile: isMobile,
                        ),
                        if (_showInstructions) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B1538).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFF8B1538)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info,
                                    color: Color(0xFF8B1538), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ingresa un correo válido, ejemplo: ss676767@uaeh.edu.mx',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: isMobile ? 12 : 14,
                                      color: const Color(0xFF8B1538),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          showSuffixIcon: true,
                          onSuffixPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            return null;
                          },
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Funcionalidad en desarrollo',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF8B1538),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.isLoading) {
                              return _buildLoadingIndicator(isMobile);
                            }

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _handleLogin(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1538),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 16 : 20,
                                    horizontal: 32,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  shadowColor:
                                      const Color(0xFF8B1538).withOpacity(0.3),
                                ),
                                child: Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2B2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[800]!,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.security,
                                  color: Colors.grey[400],
                                  size: isMobile ? 40 : 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Cuenta Segura',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tu información está protegida. Solo estudiantes UAEH verificados.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: isMobile ? 12 : 14,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (isMobile) const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
