// lib/presentation/screens/welcome/welcome_screen.dart
import 'package:flutter/material.dart';
import '../auth/login_register_screen.dart';
import 'privacy_policy_screen.dart'; // Agregar esta importación

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 600;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 24.0 : 48.0),
                child: Column(
                  children: [
                    // Espacio superior
                    SizedBox(height: isMobile ? 20 : 40),

                    // Logo con imagen de garza DIRECTA
                    Image.asset(
                      'assets/images/Garza.png',
                      width: isMobile ? 180 : 250,
                      height: isMobile ? 180 : 250,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Título
                    Text(
                      'GarZwipes',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isMobile ? 42 : 56,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6A0D37),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'La app de citas exclusiva para la comunidad UAEH',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isMobile ? 16 : 20,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Estadísticas o números
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2B2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6A0D37).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            number: '500+',
                            label: 'Estudiantes',
                            isMobile: isMobile,
                          ),
                          _buildStat(
                            number: '95%',
                            label: 'Verificados',
                            isMobile: isMobile,
                          ),
                          _buildStat(
                            number: '24/7',
                            label: 'Activos',
                            isMobile: isMobile,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Características principales
                    const Text(
                      '¿Por qué GarZwipes?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descubre la diferencia de una comunidad universitaria real',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    _buildFeature(
                      icon: Icons.school_rounded,
                      title: 'Comunidad UAEH',
                      subtitle:
                          'Conecta exclusivamente con estudiantes de tu universidad',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.verified_user_rounded,
                      title: 'Perfiles Verificados',
                      subtitle:
                          'Todos los usuarios están validados con correo institucional',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.people_alt_rounded,
                      title: 'Matches Reales',
                      subtitle:
                          'Encuentra personas con intereses y carreras afines',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.security_rounded,
                      title: 'Ambiente Seguro',
                      subtitle:
                          'Espacio diseñado para estudiantes universitarios',
                      isMobile: isMobile,
                    ),

                    const SizedBox(height: 40),

                    // Testimonios
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A0D37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6A0D37).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            color: Color(0xFF6A0D37),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '"GarZwipes me ayudó a conocer a mi actual pareja, ambos estudiamos en la UAEH y compartimos la misma pasión por la música."',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '- Ana, Estudiante de Psicología',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Botón de comenzar
                    SizedBox(
                      width: isMobile ? double.infinity : 400,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginRegisterScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A0D37),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF6A0D37).withOpacity(0.5),
                        ),
                        child: Text(
                          'Comenzar Ahora',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Texto informativo con enlace a políticas
                    SizedBox(
                      width: isMobile ? double.infinity : 400,
                      child: Column(
                        children: [
                          Text(
                            'Al continuar, aceptas nuestros ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Términos de Servicio y Política de Privacidad',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isMobile ? 12 : 14,
                                color: const Color(0xFF6A0D37),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6A0D37).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6A0D37),
              size: isMobile ? 24 : 28,
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String number,
    required String label,
    required bool isMobile,
  }) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6A0D37),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isMobile ? 12 : 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
