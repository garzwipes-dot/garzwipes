// lib/utils/validators.dart
class Validators {
  static bool isValidUAEHEmail(String email) {
    // Formato: 2 letras + 6 números + @uaeh.edu.mx
    final regex = RegExp(r'^[a-zA-Z]{2}\d{6}@uaeh\.edu\.mx$');
    return regex.hasMatch(email);
  }

  static String? validateUAEHEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo UAEH';
    }

    if (!isValidUAEHEmail(value)) {
      return 'Formato incorrecto. Debe ser: 2 letras + 6 números + @uaeh.edu.mx\nEjemplo: aa123456@uaeh.edu.mx';
    }

    return null;
  }
}
