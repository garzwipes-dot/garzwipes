// lib/presentation/screens/welcome/privacy_policy_screen.dart
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      body: CustomScrollView(
        slivers: [
          // AppBar con efecto de desvanecimiento
          SliverAppBar(
            backgroundColor: const Color(0xFF0E0F0E),
            foregroundColor: Colors.white,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Política de Privacidad',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF6A0D37).withOpacity(0.8),
                      const Color(0xFF0E0F0E).withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // Contenido de las políticas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado principal
                  _buildHeaderSection(),
                  const SizedBox(height: 32),

                  // Última actualización
                  _buildUpdateCard(),
                  const SizedBox(height: 32),

                  // Índice de contenidos
                  _buildTableOfContents(),
                  const SizedBox(height: 40),

                  // Sección 1: Introducción
                  _buildSection(
                    number: '01',
                    title: 'Introducción y Alcance',
                    content:
                        'GarZwipes ("nosotros", "nuestra", "la aplicación") es una plataforma de conexión social desarrollada exclusivamente para la comunidad estudiantil de la Universidad Autónoma del Estado de Hidalgo (UAEH). Esta Política de Privacidad detalla cómo recopilamos, utilizamos, almacenamos y protegemos tu información personal cuando utilizas nuestra aplicación.',
                    additionalContent:
                        'Al acceder y utilizar GarZwipes, aceptas los términos descritos en esta política. Esta aplicación está diseñada como un proyecto académico-profesional con el objetivo de fomentar conexiones sociales seguras y verificadas dentro del entorno universitario.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 2: Base Legal
                  _buildSection(
                    number: '02',
                    title: 'Base Legal y Consentimiento',
                    content:
                        'El tratamiento de tus datos personales se basa en tu consentimiento explícito, que otorgas al crear una cuenta en GarZwipes y aceptar esta Política de Privacidad.',
                    points: [
                      'Consentimiento informado para el procesamiento de datos',
                      'Ejecución de contrato al proporcionar los servicios',
                      'Interés legítimo en mantener la seguridad de la plataforma',
                      'Cumplimiento de obligaciones legales aplicables'
                    ],
                    additionalContent:
                        'Puedes retirar tu consentimiento en cualquier momento contactando al soporte técnico para solicitar la eliminación de tu cuenta. Sin embargo, esto no afectará la legalidad del procesamiento realizado antes del retiro.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 3: Información Recopilada
                  _buildSection(
                    number: '03',
                    title: 'Información que Recopilamos',
                    content:
                        'Recopilamos diferentes tipos de información para proporcionar y mejorar nuestros servicios:',
                    subsections: [
                      _buildSubsection(
                        title: '3.1 Información de Registro',
                        content: '• Correo institucional UAEH (@uaeh.edu.mx)\n'
                            '• Nombre completo\n'
                            '• Edad y fecha de nacimiento\n'
                            '• Carrera o programa académico\n'
                            '• Semestre o año de estudio\n'
                            '• Contraseña encriptada',
                      ),
                      _buildSubsection(
                        title: '3.2 Información de Perfil',
                        content: '• Fotografías de perfil\n'
                            '• Biografía personal\n'
                            '• Intereses y hobbies\n'
                            '• Preferencias de conexión\n'
                            '• Información académica adicional',
                      ),
                      _buildSubsection(
                        title: '3.3 Información de Uso',
                        content:
                            '• Actividad en la aplicación (swipes, matches)\n'
                            '• Mensajes y conversaciones\n'
                            '• Preferencias mostradas\n'
                            '• Tiempo de uso y frecuencia\n'
                            '• Interacciones con otros usuarios',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Sección 4: Uso de Información
                  _buildSection(
                    number: '04',
                    title: 'Finalidades del Tratamiento',
                    content:
                        'Utilizamos tu información para las siguientes finalidades específicas:',
                    points: [
                      'Verificar tu condición de estudiante UAEH mediante correo institucional',
                      'Crear y mantener tu perfil de usuario',
                      'Facilitar conexiones entre estudiantes con intereses afines',
                      'Personalizar tu experiencia y mostrar perfiles relevantes',
                      'Mantener la seguridad e integridad de la plataforma',
                      'Prevenir fraudes y actividades inapropiadas',
                      'Proporcionar soporte técnico y atención al usuario',
                      'Mejorar y optimizar nuestros servicios',
                      'Cumplir con obligaciones legales y regulatorias',
                    ],
                    additionalContent:
                        'No utilizamos tus datos para decisiones automatizadas con efectos legales significativos. Toda personalización se basa en preferencias explícitas que tú proporcionas.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 5: Compartición de Datos
                  _buildSection(
                    number: '05',
                    title: 'Compartición de Información',
                    content:
                        'Tu privacidad es fundamental. Compartimos información únicamente en las siguientes circunstancias:',
                    subsections: [
                      _buildSubsection(
                        title: '5.1 Con Otros Usuarios',
                        content:
                            '• Información básica de perfil (nombre, fotos, carrera)\n'
                            '• Intereses y biografía (según tu configuración)\n'
                            '• Estado de conexión mutua (matches)',
                      ),
                      _buildSubsection(
                        title: '5.2 Con Terceros Proveedores',
                        content:
                            '• Supabase: Base de datos y autenticación segura\n'
                            '• GetStream.io: Servicios de chat en tiempo real\n'
                            '• Cloudinary: Almacenamiento y gestión de imágenes\n'
                            '• Todos bajo estrictos acuerdos de confidencialidad y protección de datos',
                      ),
                      _buildSubsection(
                          title: '5.3 Requerimientos Legales',
                          content:
                              '• Cumplimiento de órdenes judiciales válidas\n'
                              '• Protección de derechos y seguridad de usuarios\n'),
                    ],
                    additionalContent:
                        'NO vendemos, comercializamos ni alquilamos tu información personal a terceros con fines publicitarios. Los proveedores mencionados solo procesan datos bajo nuestras instrucciones.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 6: Seguridad
                  _buildSection(
                    number: '06',
                    title: 'Medidas de Seguridad',
                    content:
                        'Implementamos medidas técnicas y organizativas robustas para proteger tu información:',
                    points: [
                      'Encriptación de extremo a extremo para datos sensibles',
                      'Autenticación segura mediante Supabase Auth',
                      'Almacenamiento en servidores seguros con backups',
                      'Protección de imágenes mediante Cloudinary',
                      'Comunicaciones seguras en chat con GetStream.io',
                      'Monitoreo continuo de seguridad',
                      'Actualizaciones regulares de parches de seguridad',
                    ],
                    additionalContent:
                        'A pesar de estas medidas, ninguna transmisión por internet es 100% segura. Recomendamos no compartir información sensible como contraseñas, datos financieros o información médica a través de la plataforma.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 7: Derechos del Usuario (MODIFICADA)
                  _buildSection(
                    number: '07',
                    title: 'Tus Derechos y Control',
                    content:
                        'Como usuario de GarZwipes, tienes control sobre tu información y experiencia:',
                    points: [
                      'Modificar tu información de perfil en cualquier momento',
                      'Ajustar tus preferencias de privacidad y visibilidad',
                      'Corregir información inexacta en tu perfil',
                    ],
                    additionalContent:
                        'Para solicitudes específicas sobre tus datos personales o para solicitar la eliminación de tu cuenta, contacta a nuestro equipo de soporte técnico a través de la aplicación. Las solicitudes serán procesadas en un plazo máximo de 30 días hábiles.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 8: Retención de Datos (MODIFICADA)
                  _buildSection(
                    number: '08',
                    title: 'Conservación de Datos',
                    content:
                        'Mantenemos tu información durante los períodos necesarios para los fines descritos:',
                    points: [
                      'Cuentas activas: Mientras mantengas tu cuenta activa y uses la aplicación',
                      'Cuentas inactivas: Hasta 24 meses de inactividad continuada',
                      'Registros de seguridad: Hasta 12 meses para auditoría y seguridad',
                      'Datos anonimizados: Conservados indefinidamente para análisis estadísticos',
                    ],
                    additionalContent:
                        'Los datos son conservados para seguridad del  usuario',
                  ),
                  const SizedBox(height: 40),

                  // Sección 9: Menores de Edad
                  _buildSection(
                    number: '09',
                    title: 'Restricción de Edad',
                    content:
                        'GarZwipes está estrictamente dirigido a mayores de 18 años. Implementamos las siguientes medidas:',
                    points: [
                      'Verificación de edad durante el registro',
                      'Requerimiento de correo institucional UAEH (generalmente para mayores de 18)',
                      'Mecanismos de reporte para usuarios que no cumplan la edad mínima',
                      'Eliminación inmediata de cuentas que violen esta política',
                    ],
                    additionalContent:
                        'Si tenemos conocimiento de que un menor de 18 años ha proporcionado información personal, tomaremos medidas inmediatas para eliminar dicha información y cancelar la cuenta en todos nuestros sistemas.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 10: Transferencias Internacionales
                  _buildSection(
                    number: '10',
                    title: 'Servicios y Almacenamiento',
                    content:
                        'Utilizamos servicios de terceros confiables para el funcionamiento de la aplicación:',
                    points: [
                      'Supabase: Almacenamiento seguro de datos en la nube',
                      'GetStream.io: Servicios de mensajería en tiempo real',
                      'Cloudinary: Gestión y optimización de imágenes',
                      'Todos los servicios cumplen con estándares internacionales de seguridad',
                      'Protección de datos mediante encriptación y medidas de seguridad robustas',
                    ],
                    additionalContent:
                        'Cada proveedor cuenta con certificaciones de seguridad reconocidas y se adhiere a estrictos protocolos de protección de datos.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 11: Cookies
                  _buildSection(
                    number: '11',
                    title: 'Tecnologías de Seguimiento',
                    content:
                        'Utilizamos tecnologías estándar para mejorar tu experiencia:',
                    points: [
                      'Cookies esenciales: Para funcionalidad básica de la aplicación',
                      'Almacenamiento local: Para preferencias y datos de sesión',
                      'Tokens de autenticación: Para mantener tu sesión segura',
                      'Análisis anonimizado: Para mejorar el rendimiento de la aplicación',
                    ],
                    additionalContent:
                        'Estas tecnologías son necesarias para el funcionamiento básico de la aplicación y no se utilizan para seguimiento publicitario.',
                  ),
                  const SizedBox(height: 40),

                  // Sección 12: Cambios a la Política
                  _buildSection(
                    number: '12',
                    title: 'Modificaciones a la Política',
                    content:
                        'Nos reservamos el derecho de actualizar esta Política de Privacidad periódicamente:',
                    points: [
                      'Notificaremos cambios significativos mediante la aplicación',
                      'Versión actualizada disponible en todo momento',
                      'Uso continuado implica aceptación de modificaciones',
                      'Fechas de actualización claramente indicadas',
                    ],
                    additionalContent:
                        'Te recomendamos revisar periódicamente esta política para estar informado sobre cómo protegemos tu información.',
                  ),
                  const SizedBox(height: 40),

                  // Aceptación final
                  _buildAcceptanceCard(),
                  const SizedBox(height: 60),

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A0D37).withOpacity(0.1),
            const Color(0xFF2A2B2A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6A0D37).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 48,
            color: Color(0xFF6A0D37),
          ),
          const SizedBox(height: 16),
          const Text(
            'GarZwipes - Política de Privacidad',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Comprometidos con la protección y privacidad de tu información personal dentro de nuestra comunidad universitaria.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.grey[400],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6A0D37).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6A0D37).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.update_rounded,
            color: Color(0xFF6A0D37),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Última actualización',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Enero 2025',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
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

  Widget _buildTableOfContents() {
    final sections = [
      'Introducción y Alcance',
      'Base Legal y Consentimiento',
      'Información que Recopilamos',
      'Finalidades del Tratamiento',
      'Compartición de Información',
      'Medidas de Seguridad',
      'Tus Derechos y Control',
      'Conservación de Datos',
      'Restricción de Edad',
      'Servicios y Almacenamiento',
      'Tecnologías de Seguimiento',
      'Modificaciones',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Índice de Contenidos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A0D37),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sections.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final section = entry.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6A0D37).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$index. $section',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey[300],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    List<String>? points,
    List<Widget>? subsections,
    String? additionalContent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2B2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número y título de sección
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A0D37),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenido principal
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // Puntos si existen
          if (points != null) ...[
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 8),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: Color(0xFF6A0D37),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey[300],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Subsecciones si existen
          if (subsections != null) ...[
            ...subsections,
            const SizedBox(height: 16),
          ],

          // Contenido adicional si existe
          if (additionalContent != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                additionalContent,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubsection({
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A0D37),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A0D37).withOpacity(0.2),
            const Color(0xFF2A2B2A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6A0D37).withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.gpp_good_rounded,
            size: 48,
            color: Color(0xFF6A0D37),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aceptación de los Términos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Al utilizar GarZwipes, declaras y garantizas que:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0F0E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildAcceptanceItem('Tienes 18 años o más de edad'),
                _buildAcceptanceItem('Eres estudiante activo de la UAEH'),
                _buildAcceptanceItem(
                    'Proporcionas información veraz y actualizada'),
                _buildAcceptanceItem(
                    'Aceptas esta Política de Privacidad en su totalidad'),
                _buildAcceptanceItem(
                    'Comprendes el propósito social de la aplicación'),
                _buildAcceptanceItem(
                    'Actúas de manera responsable y respetuosa'),
                _buildAcceptanceItem(
                    'Aceptas el uso de Supabase, GetStream.io y Cloudinary para los servicios'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'GarZwipes se reserva el derecho de modificar, suspender o discontinuar cualquier aspecto de los servicios en cualquier momento. Como proyecto académico, la aplicación se proporciona "tal cual" sin garantías adicionales.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF6A0D37),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey[300],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'GarZwipes - Comunidad UAEH',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Proyecto académico-profesional dedicado a la comunidad universitaria',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            '© 2025 GarZwipes. Todos los derechos reservados.\n'
            'Esta aplicación es parte de un proyecto educativo de la UAEH.\n'
            'Servicios utilizados: Supabase, GetStream.io, Cloudinary',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
