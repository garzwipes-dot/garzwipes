import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cloudinary_storage_provider.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();

  String? _selectedGender;
  final List<String> _selectedLookingFor = [];
  final List<String> _selectedInterests = [];
  String? _selectedMajor;
  int? _selectedYear;
  double _heightValue = 170.0;

  List<Map<String, dynamic>> _genders = [];
  List<Map<String, dynamic>> _interests = [];
  final List<String> _majors = [
    'Área academica ciencias de la tierra y materiales',
    'Área academica comunicacion',
    'Área academica de administracion',
    'Área academica de artes visuales',
    'Área academica de biologia',
    'Área academica de ciencias agricolas y forestales',
    'Área academica de ciencias de la educacion',
    'Área academica de ciencias de la tierra',
    'Área academica de comercio exterior',
    'Área academica de computación y electrónica',
    'Área academica de contaduria',
    'Área academica de cs. politicas y admon. publica',
    'Área academica de danza',
    'Área academica de derecho y jurisprudencia',
    'Área academica de economia',
    'Área academica de enfermeria',
    'Área academica de farmacia',
    'Área academica de gerontologia',
    'Área academica de historia y antropologia',
    'Área academica de ing. agroindustrial y alimentos',
    'Área academica de ingenieria forestal',
    'Área academica de ingenieria y arquitectura',
    'Área academica de linguistica',
    'Área academica de matematicas y fisica',
    'Área academica de materiales y metalurgia',
    'Área academica de medicina',
    'Área academica de medicina tulancingo',
    'Área academica de medicina veterinaria y zootecnia',
    'Área academica de mercadotecnia',
    'Área academica de musica',
    'Área academica de nutricion',
    'Área academica de odontologia',
    'Área academica de psicologia',
    'Área academica de quimica',
    'Área academica de sociologia y demografia',
    'Área academica de teatro',
    'Área academica de trabajo social',
    'Área academica de turismo',
    'Colegio de posgrado',
    'Otra'
  ];

  final List<int> _years = [1, 2, 3, 4, 5, 6];

  // Variables para manejo de fotos (MÁXIMO 3)
  final List<String> _userPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhotos = false;

  // Mapa de emojis para los intereses existentes
  final Map<String, String> _interestEmojis = {
    'Música': '🎵',
    'Deportes': '⚽',
    'Arte': '🎨',
    'Tecnología': '💻',
    'Cine': '🎬',
    'Libros': '📚',
    'Viajes': '✈️',
    'Comida': '🍕',
    'Videojuegos': '🎮',
    'Fotografía': '📷',
    'Baile': '💃',
    'Naturaleza': '🌿',
    'Moda': '👗',
    'Cocina': '👨‍🍳',
    'Animales': '🐾',
    'Series': '📺',
    'Ejercicio': '💪',
    'Café': '☕',
    'Cerveza': '🍺',
    'Té': '🍵',
  };

  @override
  void initState() {
    super.initState();
    _loadGenders();
    _loadInterests();
  }

  Future<void> _loadGenders() async {
    try {
      final response =
          await Supabase.instance.client.from('genders').select('id, name');

      if (mounted) {
        setState(() {
          _genders = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error loading genders: $e');
    }
  }

  Future<void> _loadInterests() async {
    try {
      final response =
          await Supabase.instance.client.from('interests').select('id, name');

      if (mounted) {
        setState(() {
          _interests = List<Map<String, dynamic>>.from(response);
          // Ordenar intereses alfabéticamente
          _interests.sort((a, b) => a['name'].compareTo(b['name']));
        });
      }
    } catch (e) {
      print('Error loading interests: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      if (_userPhotos.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 3 fotos permitidas'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        // VALIDAR TAMAÑO
        final fileSize = await image.length();
        const maxFileSize = 2 * 1024 * 1024;

        if (fileSize > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'La imagen es muy grande (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB). El tamaño máximo permitido es 2MB.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        setState(() {
          _isUploadingPhotos = true;
        });

        // Si pasa la validación de tamaño, subir a Cloudinary
        final cloudinaryProvider = context.read<CloudinaryStorageProvider>();
        final imageUrl = await cloudinaryProvider.uploadImage(image.path);

        if (imageUrl != null) {
          setState(() {
            _userPhotos.add(imageUrl);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Foto agregada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Error al subir la foto'),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() {
          _isUploadingPhotos = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isUploadingPhotos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para guardar fotos en Supabase
  Future<void> _saveUserPhotos() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Eliminar fotos existentes primero
      await Supabase.instance.client
          .from('user_photos')
          .delete()
          .eq('user_id', currentUserId);

      // Insertar nuevas fotos
      for (int i = 0; i < _userPhotos.length; i++) {
        await Supabase.instance.client.from('user_photos').insert({
          'user_id': currentUserId,
          'photo_url': _userPhotos[i],
          'display_order': i,
        });
      }
    } catch (e) {
      print('Error saving user photos: $e');
      rethrow;
    }
  }

  Future<void> _submitProfile() async {
    // Validar campos obligatorios incluyendo fotos
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu género'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMajor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu área'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos 1 foto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final profileData = {
      'bio': _bioController.text.trim(),
      'gender_id': _selectedGender,
      'looking_for_gender_ids': _selectedLookingFor,
      'interests_ids': _selectedInterests,
      'height': _heightValue.round(),
      'major': _selectedMajor,
      'year': _selectedYear,
    };

    final success = await authProvider.updateProfile(profileData);

    if (success && context.mounted) {
      try {
        // Guardar fotos en la base de datos
        await _saveUserPhotos();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar fotos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Error al guardar perfil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSection(
      String title, String subtitle, IconData icon, Widget content,
      {bool isRequired = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2B2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1538).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF8B1538), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRequired)
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isRequired ? Colors.orange : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  // Widget para mostrar las fotos seleccionadas
  Widget _buildPhotosSection() {
    return _buildSection(
      'Mis Fotos',
      'Agrega al menos 1 foto (máximo 3) - Máximo 2MB por foto',
      Icons.photo_library,
      Column(
        children: [
          // Mostrar fotos seleccionadas
          if (_userPhotos.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _userPhotos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(_userPhotos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _userPhotos.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Botón para agregar fotos
          if (_userPhotos.length < 3)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _userPhotos.isEmpty ? Colors.orange : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: _userPhotos.isEmpty ? Colors.orange : Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userPhotos.isEmpty
                        ? 'Agrega al menos 1 foto'
                        : 'Agregar otra foto (${_userPhotos.length}/3)',
                    style: TextStyle(
                      color: _userPhotos.isEmpty ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  _isUploadingPhotos
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _pickAndUploadImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1538),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Seleccionar Foto'),
                        ),
                ],
              ),
            ),

          // Mensaje de validación
          if (_userPhotos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[300], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Es necesario agregar al menos 1 foto',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      isRequired: true, // ← Fotos son requeridas
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        title: const Text(
          'Completar Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0E0F0E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B1538).withOpacity(0.1),
                      const Color(0xFF0E0F0E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF8B1538).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B1538),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Casi listo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completa tu perfil para encontrar matches perfectos',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sección de Fotos (PRIMERO) - REQUERIDO
              _buildPhotosSection(),

              // Sección de Sobre ti - OPCIONAL
              _buildSection(
                'Sobre ti',
                'Cuéntanos quién eres - Opcional',
                Icons.description,
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Hola! Soy estudiante de UAEH, me gusta...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2B2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                isRequired: false,
              ),

              // Sección de Género - REQUERIDO
              _buildSection(
                'Género',
                'Selecciona tu género',
                Icons.person,
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2A2B2A),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Selecciona tu género',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2B2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _genders.map<DropdownMenuItem<String>>((gender) {
                    return DropdownMenuItem<String>(
                      value: gender['id'].toString(),
                      child: Text(
                        gender['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                isRequired: true,
              ),

              // Sección de "Me interesa" - REQUERIDO
              _buildSection(
                'Me interesa',
                'Selecciona los géneros que te interesan',
                Icons.favorite,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _genders.map((gender) {
                        final isSelected = _selectedLookingFor
                            .contains(gender['id'].toString());
                        return ChoiceChip(
                          label: Text(
                            gender['name'],
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF8B1538),
                          backgroundColor: const Color(0xFF2A2B2A),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedLookingFor
                                    .add(gender['id'].toString());
                              } else {
                                _selectedLookingFor
                                    .remove(gender['id'].toString());
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_selectedLookingFor.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.info,
                                color: Colors.orange[300], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Selecciona al menos un género',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                isRequired: true,
              ),

              // Sección de Intereses - OPCIONAL
              _buildSection(
                'Mis Intereses',
                'Selecciona hasta 3 intereses que te definan - Opcional',
                Icons.emoji_emotions,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interests.map((interest) {
                        final interestName = interest['name'];
                        final isSelected = _selectedInterests
                            .contains(interest['id'].toString());
                        final isDisabled =
                            _selectedInterests.length >= 3 && !isSelected;
                        final emoji = _interestEmojis[interestName] ?? '❤️';

                        return ChoiceChip(
                          label: Text(
                            '$emoji $interestName',
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF8B1538),
                          backgroundColor: isDisabled
                              ? const Color(0xFF1A1B1A).withOpacity(0.5)
                              : const Color(0xFF2A2B2A),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: isDisabled
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      if (_selectedInterests.length < 3) {
                                        _selectedInterests
                                            .add(interest['id'].toString());
                                      }
                                    } else {
                                      _selectedInterests
                                          .remove(interest['id'].toString());
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _selectedInterests.isEmpty
                              ? Colors.grey[400]
                              : _selectedInterests.length == 3
                                  ? Colors.green[300]
                                  : Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedInterests.isEmpty
                              ? 'Selecciona tus intereses (opcional)'
                              : '${_selectedInterests.length}/3 intereses seleccionados',
                          style: TextStyle(
                            color: _selectedInterests.isEmpty
                                ? Colors.grey[400]
                                : _selectedInterests.length == 3
                                    ? Colors.green[300]
                                    : Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isRequired: false,
              ),

              // Sección de Altura - OPCIONAL
              _buildSection(
                'Altura',
                'Selecciona tu altura en centímetros - Obligatorio, si no te diste cuenta...',
                Icons.height,
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2B2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.height,
                                  color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${_heightValue.round()} cm',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _heightValue,
                            min: 140,
                            max: 220,
                            divisions: 80,
                            activeColor: const Color(0xFF8B1538),
                            inactiveColor: const Color(0xFF3A3B3A),
                            thumbColor: Colors.white,
                            label: '${_heightValue.round()} cm',
                            onChanged: (value) {
                              setState(() {
                                _heightValue = value;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '140 cm',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                              Text(
                                '220 cm',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                isRequired: false,
              ),

              // Sección de Carrera - REQUERIDO
              _buildSection(
                'Área',
                'Qué estudias en UAEH',
                Icons.school,
                DropdownButtonFormField<String>(
                  initialValue: _selectedMajor,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2A2B2A),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Selecciona tu carrera',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2B2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _majors.map<DropdownMenuItem<String>>((major) {
                    return DropdownMenuItem<String>(
                      value: major,
                      child: Text(
                        major,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMajor = value;
                    });
                  },
                ),
                isRequired: true,
              ),

              // Sección de Año de estudio - OPCIONAL
              _buildSection(
                'Año de estudio',
                'En qué año de tu carrera estás - Opcional',
                Icons.calendar_today,
                DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2A2B2A),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Selecciona tu año',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2B2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _years.map<DropdownMenuItem<int>>((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        '$year° Año',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
                isRequired: false,
              ),

              // Botón de enviar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final isFormValid = _selectedGender != null &&
                        _selectedMajor != null &&
                        _userPhotos.isNotEmpty;

                    return Column(
                      children: [
                        if (authProvider.isLoading)
                          const CircularProgressIndicator(
                              color: Color(0xFF8B1538))
                        else
                          ElevatedButton(
                            onPressed: isFormValid ? _submitProfile : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFormValid
                                  ? const Color(0xFF8B1538)
                                  : Colors.grey[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 2,
                              shadowColor:
                                  const Color(0xFF8B1538).withOpacity(0.3),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Completar Perfil',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isFormValid)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              'Completa todos los campos requeridos (marcados con *) para continuar',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}
