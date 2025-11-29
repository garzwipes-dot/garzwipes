import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/validators.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signUpWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        birthDate: _birthDateController.text.isEmpty
            ? null
            : _birthDateController.text, // ✅ ENVÍA birthDate
      );

      if (success && context.mounted) {
        // Mostrar diálogo de éxito
        await _showSuccessDialog(context);
      } else if (!success && context.mounted) {
        _showErrorDialog(context, authProvider.error);
      }
    }
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text(
              'Cuenta Creada',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read, size: 50, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Tu cuenta ha sido creada exitosamente.\n\nRevisa tu correo electrónico para verificar tu cuenta antes de iniciar sesión.\n\nTu perfil básico ha sido guardado.',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Redirigir al login
            },
            child: const Text(
              'Ir al Login',
              style: TextStyle(
                color: Color(0xFF8B1538),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String? error) {
    String errorMessage = error ?? 'Error al crear la cuenta';

    // Si es un error de "cuenta ya existe", mostrar un diálogo más específico
    if (errorMessage.contains('Ya existe una cuenta')) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1B1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Cuenta Ya Existe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 50, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Si olvidaste tu contraseña, contacta con soporte.',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
              },
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: Color(0xFF8B1538),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Para otros errores, usar SnackBar normal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
            'Creando cuenta...',
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  bool _isOver18(DateTime birthDate) {
    final today = DateTime.now();
    final age = today.year -
        birthDate.year -
        (today.month > birthDate.month ||
                (today.month == birthDate.month && today.day >= birthDate.day)
            ? 0
            : 1);
    return age >= 18;
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
                          'Crear cuenta',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Completa los datos básicos para comenzar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Campos del formulario
                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo UAEH',
                          icon: Icons.email,
                          hintText: 'aa123456@uaeh.edu.mx',
                          validator: Validators.validateUAEHEmail,
                          isMobile: isMobile,
                        ),
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
                          validator: _validatePassword,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar contraseña',
                          icon: Icons.lock,
                          obscureText: _obscureConfirmPassword,
                          showSuffixIcon: true,
                          onSuffixPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          validator: _validateConfirmPassword,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _nameController,
                          label: 'Nombre completo',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu nombre completo';
                            }
                            return null;
                          },
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _birthDateController,
                          label: 'Fecha de nacimiento',
                          icon: Icons.cake,
                          hintText: 'DD/MM/AAAA',
                          readOnly: true,
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now()
                                  .subtract(const Duration(days: 365 * 18)),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now()
                                  .subtract(const Duration(days: 365 * 18)),
                            );
                            if (picked != null) {
                              _birthDateController.text =
                                  "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu fecha de nacimiento';
                            }

                            try {
                              final parts = value.split('/');
                              if (parts.length != 3) {
                                return 'Formato inválido. Usa DD/MM/AAAA';
                              }

                              final day = int.parse(parts[0]);
                              final month = int.parse(parts[1]);
                              final year = int.parse(parts[2]);

                              final birthDate = DateTime(year, month, day);

                              if (!_isOver18(birthDate)) {
                                return 'Debes ser mayor de 18 años para registrarte';
                              }
                            } catch (e) {
                              return 'Fecha inválida. Usa el formato DD/MM/AAAA';
                            }

                            return null;
                          },
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 32),

                        // Botón de registro
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.isLoading) {
                              return _buildLoadingIndicator(isMobile);
                            }

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _register,
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
                                  'Crear cuenta',
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

                        // Información adicional
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
                              Icon(Icons.info,
                                  color: Colors.grey[400],
                                  size: isMobile ? 40 : 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Completa tu perfil después',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Podrás agregar tu bio, intereses y más información después de crear tu cuenta.',
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
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}
