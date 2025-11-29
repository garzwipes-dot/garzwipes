import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _heightController = TextEditingController();

  String? _selectedMajor;
  String? _selectedGender;
  final List<String> _selectedLookingFor = [];
  final List<String> _selectedInterests = [];
  int? _selectedYear;

  List<Map<String, dynamic>> _genders = [];
  List<Map<String, dynamic>> _interests = [];
  final List<int> _years = [1, 2, 3, 4, 5, 6];

  // Lista de áreas académicas
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

  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadGenders();
      await _loadInterests();
      await _loadCurrentProfile();
    } catch (e) {
      print('Error initializing edit profile: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _loadGenders() async {
    try {
      final response =
          await Supabase.instance.client.from('genders').select('id, name');

      setState(() {
        _genders = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading genders: $e');
    }
  }

  Future<void> _loadInterests() async {
    try {
      final response =
          await Supabase.instance.client.from('interests').select('id, name');

      setState(() {
        _interests = List<Map<String, dynamic>>.from(response);
        // Ordenar intereses alfabéticamente
        _interests.sort((a, b) => a['name'].compareTo(b['name']));
      });
    } catch (e) {
      print('Error loading interests: $e');
    }
  }

  Future<void> _loadCurrentProfile() async {
    final authProvider = context.read<AuthProvider>();
    final userProfile = authProvider.userProfile;

    if (userProfile != null) {
      setState(() {
        _bioController.text = userProfile['bio'] ?? '';
        _selectedMajor = userProfile['major'] ?? '';
        _heightController.text = userProfile['height']?.toString() ?? '';
        _selectedGender = userProfile['gender_id']?.toString();
        _selectedYear = userProfile['year'];

        // Cargar looking_for_gender_ids
        final lookingFor = userProfile['looking_for_gender_ids'];
        if (lookingFor is List) {
          _selectedLookingFor.addAll(lookingFor.map((e) => e.toString()));
        }

        // Cargar intereses del usuario
        final userInterests = userProfile['user_interests'];
        if (userInterests is List) {
          _selectedInterests
              .addAll(userInterests.map((e) => e['interest_id'].toString()));
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLookingFor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona al menos un género que buscas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedInterests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona al menos un interés'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final authProvider = context.read<AuthProvider>();

      // Debug detallado
      print('=== DEBUG PROFILE DATA ===');
      print('Selected Looking For IDs: $_selectedLookingFor');
      print('Selected Interests IDs: $_selectedInterests');

      // Verificar el tipo de datos de los IDs
      for (var i = 0; i < _selectedLookingFor.length; i++) {
        print(
            'LookingFor[$i]: ${_selectedLookingFor[i]} (type: ${_selectedLookingFor[i].runtimeType})');
      }
      for (var i = 0; i < _selectedInterests.length; i++) {
        print(
            'Interest[$i]: ${_selectedInterests[i]} (type: ${_selectedInterests[i].runtimeType})');
      }

      // Convertir looking_for_gender_ids a formato correcto para UUID array
      final lookingForGenderIds = _selectedLookingFor.map((id) {
        return id.toString();
      }).toList();

      final profileData = {
        'bio': _bioController.text.trim(),
        'gender_id': _selectedGender,
        'looking_for_gender_ids': lookingForGenderIds,
        'interests_ids': _selectedInterests,
        'height': int.tryParse(_heightController.text) ?? 170,
        'major': _selectedMajor?.trim(),
        'year': _selectedYear,
      };

      print('Final Profile Data: $profileData');
      print('==================');

      final success = await authProvider.updateProfile(profileData);

      setState(() {
        _isLoading = false;
      });

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Error al actualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0F0E),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B1538),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F0E),
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E0F0E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Color(0xFF8B1538),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B1538),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSection(
                      'Biografía',
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Cuéntanos sobre ti...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2A2B2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor escribe una biografía';
                          }
                          if (value.length < 20) {
                            return 'La biografía debe tener al menos 20 caracteres';
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildSection(
                      'Carrera',
                      DropdownButtonFormField<String>(
                        value: _selectedMajor,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2B2A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Selecciona tu área académica',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2A2B2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _majors.map<DropdownMenuItem<String>>((major) {
                          return DropdownMenuItem<String>(
                            value: major,
                            child: Text(major),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMajor = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor selecciona tu área académica';
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildSection(
                      'Altura (cm)',
                      TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '170',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2A2B2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor escribe tu altura';
                          }
                          final height = int.tryParse(value);
                          if (height == null || height < 140 || height > 220) {
                            return 'Altura debe ser entre 140 y 220 cm';
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildSection(
                      'Año de estudio',
                      DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2B2A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Selecciona tu año',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2A2B2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _years.map<DropdownMenuItem<int>>((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text('$year° Año'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor selecciona tu año';
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildSection(
                      'Género',
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2B2A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Selecciona tu género',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2A2B2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _genders.map<DropdownMenuItem<String>>((gender) {
                          return DropdownMenuItem<String>(
                            value: gender['id'].toString(),
                            child: Text(gender['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor selecciona tu género';
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildSection(
                      'Me interesa',
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
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[300],
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF8B1538),
                                backgroundColor: const Color(0xFF2A2B2A),
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
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Selecciona al menos un género',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildSection(
                      'Mis Intereses',
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
                              final emoji =
                                  _interestEmojis[interestName] ?? '❤️';

                              return ChoiceChip(
                                label: Text(
                                  '$emoji $interestName',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontSize: 12,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF8B1538),
                                backgroundColor: isDisabled
                                    ? const Color(0xFF1A1B1A).withOpacity(0.5)
                                    : const Color(0xFF2A2B2A),
                                onSelected: isDisabled
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          if (selected) {
                                            if (_selectedInterests.length < 3) {
                                              _selectedInterests.add(
                                                  interest['id'].toString());
                                            }
                                          } else {
                                            _selectedInterests.remove(
                                                interest['id'].toString());
                                          }
                                        });
                                      },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: _selectedInterests.isEmpty
                                    ? Colors.orange[300]
                                    : _selectedInterests.length == 3
                                        ? Colors.green[300]
                                        : Colors.grey[400],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedInterests.isEmpty
                                    ? 'Selecciona al menos 1 interés'
                                    : '${_selectedInterests.length}/3 intereses seleccionados',
                                style: TextStyle(
                                  color: _selectedInterests.isEmpty
                                      ? Colors.orange[300]
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
