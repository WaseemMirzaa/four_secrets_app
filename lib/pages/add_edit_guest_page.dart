import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/guest_service.dart';
import '../services/guest_type_service.dart';
import '../models/guest.dart';
import '../widgets/auth_text_field.dart';

class AddEditGuestPage extends StatefulWidget {
  final Guest? guest;

  const AddEditGuestPage({Key? key, this.guest}) : super(key: key);

  @override
  State<AddEditGuestPage> createState() => _AddEditGuestPageState();
}

class _AddEditGuestPageState extends State<AddEditGuestPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _newTypeController = TextEditingController();

  String? _selectedType;
  File? _imageFile;
  bool _isLoading = false;
  List<String> _guestTypes = [];

  final GuestService _guestService = GuestService();
  final GuestTypeService _guestTypeService = GuestTypeService();

  @override
  void initState() {
    super.initState();
    _loadGuestTypes();
    if (widget.guest != null) {
      _nameController.text = widget.guest!.name;
      _contactController.text = widget.guest!.contactNumber ?? '';
      _selectedType = widget.guest!.guestType;
    }
  }

  Future<void> _loadGuestTypes() async {
    try {
      final types = await _guestTypeService.getGuestTypes();
      setState(() {
        _guestTypes = types;
        if (_selectedType == null && types.isNotEmpty) {
          _selectedType = types.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load guest types: $e')),
      );
    }
  }

  // ignore: unused_element
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _showAddTypeDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 107, 69, 106),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Einen neuen Gasttyp hinzufügen',
          style: TextStyle(
            color: Color.fromARGB(255, 107, 69, 106),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _newTypeController,
          decoration: const InputDecoration(
            hintText: 'Geben Sie den Gasttyp ein',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 107, 69, 106),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 107, 69, 106),
                width: 2,
              ),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newTypeController.clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Stornieren',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_newTypeController.text.isNotEmpty) {
                final newType = _newTypeController.text.trim();
                await _guestTypeService.addGuestType(newType);
                await _loadGuestTypes();
                setState(() {
                  _selectedType = newType;
                });
                _newTypeController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text(
              'Hinzufügen',
              style: TextStyle(
                color: Color.fromARGB(255, 107, 69, 106),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGuest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.guest == null) {
        await _guestService.addGuest(
          name: _nameController.text,
          guestType: _selectedType!,
          contactNumber:
              _contactController.text.isEmpty ? null : _contactController.text,
          profilePicture: _imageFile,
        );
      } else {
        await _guestService.updateGuest(
          id: widget.guest!.id,
          name: _nameController.text,
          guestType: _selectedType!,
          contactNumber:
              _contactController.text.isEmpty ? null : _contactController.text,
          newProfilePicture: _imageFile,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gast konnte nicht gespeichert werden: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: const Color.fromARGB(255, 107, 69, 106),
            elevation: 0,
            title: Text(
              widget.guest == null
                  ? 'Neuen Gast hinzufügen'
                  : 'Gast bearbeiten',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      WhiteOutlinedTextField(
                        label: 'Name des Gastes',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte geben Sie den Namen des Gastes ein';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact Field
                      WhiteOutlinedTextField(
                        label: 'Kontaktnummer',
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Guest Type Section
                      GuestTypeSectionWidget(
                        selectedType: _selectedType,
                        guestTypes: _guestTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                        onAddType: _showAddTypeDialog,
                      ),
                      const SizedBox(height: 24),

                      // Save Button - Aligned to the right
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveGuest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 107, 69, 106),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor:
                                const Color.fromARGB(255, 107, 69, 106)
                                    .withOpacity(0.6),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Speichern Gast',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _newTypeController.dispose();
    super.dispose();
  }

  pop() {
    Navigator.of(context).pop();
  }
}

class GuestTypeSectionWidget extends StatelessWidget {
  final String? selectedType;
  final List<String> guestTypes;
  final void Function(String?)? onChanged;
  final VoidCallback? onAddType;

  const GuestTypeSectionWidget({
    Key? key,
    required this.selectedType,
    required this.guestTypes,
    this.onChanged,
    this.onAddType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Gasttyp',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 107, 69, 106),
                ),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte wählen Sie einen Gästetyp';
                }
                return null;
              },
              items: guestTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onAddType,
          icon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 107, 69, 106),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
