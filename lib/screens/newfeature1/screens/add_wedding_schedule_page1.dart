import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';

import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/wedding_day_schedule_service1.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/file_upload_service1.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/widgets/wedding_schedule_page_widget.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class AddWeddingSchedulePage1 extends StatefulWidget {
  final WeddingDayScheduleModel1? weddingDayScheduleModel;
  const AddWeddingSchedulePage1({super.key, this.weddingDayScheduleModel});

  @override
  State<AddWeddingSchedulePage1> createState() =>
      _AddWeddingSchedulePage1State();
}

class _AddWeddingSchedulePage1State extends State<AddWeddingSchedulePage1> {
  final _descriptionController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  final _notesController = TextEditingController();
  final _bufferTimeController = TextEditingController();

  // New field controllers
  final _dienstleisternameController = TextEditingController();
  final _kontaktpersonController = TextEditingController();
  final _telefonnummerController = TextEditingController();
  final _emailController = TextEditingController();
  final _homepageController = TextEditingController();
  final _instagramController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _angebotTextController = TextEditingController();

  String? _titleController;
  TimeOfDay? _selectedTime;
  String? _selectedTimeText;
  DateTime? _selectedEventDate;
  String? _selectedEventDateText;
  TimeOfDay? _selectedReminder;
  DateTime? _selectedReminderDate;
  String? _selectedReminderText;
  String? _selectedReminderDateText;
  bool _reminderEnabled = false;
  bool isLoading = false;
  String? address;
  double? lat;
  double? long;

  // New field variables
  String _zahlungsstatus = 'Unbezahlt';
  String _angebotFileUrl = '';
  String _angebotFileName = '';
  DateTime? _probetermin;
  String? _probeterminText;
  bool _isUploadingFile = false;

  WeddingDayScheduleService1 weddingDayScheduleService =
      WeddingDayScheduleService1();

  @override
  void initState() {
    super.initState();

    if (widget.weddingDayScheduleModel != null) {
      print(widget.weddingDayScheduleModel);
      _titleController = widget.weddingDayScheduleModel!.title;
      _responsiblePersonController.text =
          widget.weddingDayScheduleModel!.responsiblePerson;
      _notesController.text = widget.weddingDayScheduleModel!.notes;
      address = widget.weddingDayScheduleModel!.address;
      lat = widget.weddingDayScheduleModel!.lat;
      long = widget.weddingDayScheduleModel!.long;

      // Initialize new fields
      _dienstleisternameController.text =
          widget.weddingDayScheduleModel!.dienstleistername;
      _kontaktpersonController.text =
          widget.weddingDayScheduleModel!.kontaktperson;
      _telefonnummerController.text =
          widget.weddingDayScheduleModel!.telefonnummer;
      _emailController.text = widget.weddingDayScheduleModel!.email;
      _homepageController.text = widget.weddingDayScheduleModel!.homepage;
      _instagramController.text = widget.weddingDayScheduleModel!.instagram;
      _addressDetailsController.text =
          widget.weddingDayScheduleModel!.addressDetails;
      _angebotTextController.text = widget.weddingDayScheduleModel!.angebotText;
      _zahlungsstatus = widget.weddingDayScheduleModel!.zahlungsstatus;
      _angebotFileUrl = widget.weddingDayScheduleModel!.angebotFileUrl;
      _angebotFileName = widget.weddingDayScheduleModel!.angebotFileName;
      _probetermin = widget.weddingDayScheduleModel!.probetermin;
      if (_probetermin != null) {
        _probeterminText =
            "${_probetermin!.day}/${_probetermin!.month}/${_probetermin!.year} ${_probetermin!.hour.toString().padLeft(2, '0')}:${_probetermin!.minute.toString().padLeft(2, '0')}";
      }

      // Set event date and time from existing item
      _selectedEventDate = widget.weddingDayScheduleModel!.time;
      _selectedEventDateText =
          "${_selectedEventDate!.day}/${_selectedEventDate!.month}/${_selectedEventDate!.year}";
      _selectedTime =
          TimeOfDay.fromDateTime(widget.weddingDayScheduleModel!.time);
      _selectedTimeText =
          "${widget.weddingDayScheduleModel!.time.hour > 12 ? (widget.weddingDayScheduleModel!.time.hour - 12).toString().padLeft(2, '0') : widget.weddingDayScheduleModel!.time.hour.toString().padLeft(2, '0')}:${widget.weddingDayScheduleModel!.time.minute.toString().padLeft(2, '0')} ${widget.weddingDayScheduleModel!.time.hour >= 12 ? 'PM' : 'AM'}";

      _reminderEnabled = widget.weddingDayScheduleModel!.reminderEnabled;
      if (widget.weddingDayScheduleModel!.reminderTime != null) {
        _selectedReminderDate = widget.weddingDayScheduleModel!.reminderTime;
        _selectedReminderDateText =
            "${_selectedReminderDate!.day}/${_selectedReminderDate!.month}/${_selectedReminderDate!.year}";
        _selectedReminder = TimeOfDay.fromDateTime(
            widget.weddingDayScheduleModel!.reminderTime!);
        _selectedReminderText =
            "${widget.weddingDayScheduleModel!.reminderTime!.hour > 12 ? (widget.weddingDayScheduleModel!.reminderTime!.hour - 12).toString().padLeft(2, '0') : widget.weddingDayScheduleModel!.reminderTime!.hour.toString().padLeft(2, '0')}:${widget.weddingDayScheduleModel!.reminderTime!.minute.toString().padLeft(2, '0')} ${widget.weddingDayScheduleModel!.reminderTime!.hour >= 12 ? 'PM' : 'AM'}";
      } else {
        _selectedReminderDate = null;
        _selectedReminderDateText = null;
        _selectedReminder = null;
        _selectedReminderText = null;
      }
    } else {
      // Reset fields for new item
      _selectedEventDate = null;
      _selectedEventDateText = null;
      _selectedTime = null;
      _selectedTimeText = null;
      _selectedReminderDate = null;
      _selectedReminderDateText = null;
      _selectedReminder = null;
      _selectedReminderText = null;
      _reminderEnabled = false;
    }
  }

  Future<void> _selectEventDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedEventDate) {
      setState(() {
        _selectedEventDate = picked;
        _selectedEventDateText = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectEventTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedTimeText =
            "${picked.hour > 12 ? (picked.hour - 12).toString().padLeft(2, '0') : picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ${picked.hour >= 12 ? 'Uhr' : 'Uhr'}";
      });
    }
  }

  Future<void> _selectReminderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedReminderDate) {
      setState(() {
        _selectedReminderDate = picked;
        _selectedReminderDateText =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedReminder ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedReminder = picked;
        _selectedReminderText =
            "${picked.hour > 12 ? (picked.hour - 12).toString().padLeft(2, '0') : picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ${picked.hour >= 12 ? 'Uhr' : 'Uhr'}";
      });
    }
  }

  Future<void> _selectProbetermin() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _probetermin ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _probetermin != null
            ? TimeOfDay.fromDateTime(_probetermin!)
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _probetermin = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _probeterminText =
              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year} ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
        });
      }
    }
  }

  // Validation methods
  bool _isValidEmail(String email) {
    if (email.isEmpty) return true; // Email is optional
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return true; // Phone is optional
    return RegExp(r'^[\+]?[0-9\s\-\(\)]{7,}$').hasMatch(phone);
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return true; // URL is optional
    return RegExp(r'^https?://[^\s/$.?#].[^\s]*$').hasMatch(url) ||
        RegExp(r'^www\.[^\s/$.?#].[^\s]*$').hasMatch(url) ||
        RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$')
            .hasMatch(url);
  }

  String? _validateEmail(String email) {
    if (email.isNotEmpty && !_isValidEmail(email)) {
      return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
    }
    return null;
  }

  String? _validatePhoneNumber(String phone) {
    if (phone.isNotEmpty && !_isValidPhoneNumber(phone)) {
      return 'Bitte geben Sie eine gültige Telefonnummer ein';
    }
    return null;
  }

  String? _validateUrl(String url, String fieldName) {
    if (url.isNotEmpty && !_isValidUrl(url)) {
      return 'Bitte geben Sie eine gültige $fieldName URL ein';
    }
    return null;
  }

  bool _validateAllFields() {
    List<String> errors = [];

    // Required field validations
    if (_titleController == null || _titleController!.trim().isEmpty) {
      errors.add('Titel ist erforderlich');
    }

    if (_dienstleisternameController.text.trim().isEmpty) {
      errors.add('Dienstleistername ist erforderlich');
    }

    if (_selectedEventDate == null) {
      errors.add('Datum ist erforderlich');
    }

    if (_selectedTime == null) {
      errors.add('Uhrzeit ist erforderlich');
    }

    // Optional field validations
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) errors.add(emailError);

    final phoneError = _validatePhoneNumber(_telefonnummerController.text);
    if (phoneError != null) errors.add(phoneError);

    final homepageError = _validateUrl(_homepageController.text, 'Homepage');
    if (homepageError != null) errors.add(homepageError);

    // Show errors if any
    if (errors.isNotEmpty) {
      SnackBarHelper.showErrorSnackBar(
        context,
        errors.join('\n'),
      );
      return false;
    }

    return true;
  }

  // File picker methods

  Future<void> _showFilePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF6B456A)),
                title: Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF6B456A)),
                title: Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file, color: Color(0xFF6B456A)),
                title: Text('Datei auswählen'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              if (_angebotFileUrl.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Datei entfernen'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeFile();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    setState(() {
      _isUploadingFile = true;
    });

    try {
      final result = await FileUploadService1.pickAndUploadImage(
        source: ImageSource.camera,
      );

      if (result != null && result.success) {
        setState(() {
          _angebotFileUrl = result.fileUrl;
          _angebotFileName = result.fileName;
        });
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Bild erfolgreich hochgeladen',
        );
      } else if (result != null) {
        SnackBarHelper.showErrorSnackBar(
          context,
          result.error ?? 'Upload fehlgeschlagen',
        );
      }
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        context,
        'Fehler beim Aufnehmen des Bildes: $e',
      );
    } finally {
      setState(() {
        _isUploadingFile = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isUploadingFile = true;
    });

    try {
      final result = await FileUploadService1.pickAndUploadImage(
        source: ImageSource.gallery,
      );

      if (result != null && result.success) {
        setState(() {
          _angebotFileUrl = result.fileUrl;
          _angebotFileName = result.fileName;
        });
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Bild erfolgreich hochgeladen',
        );
      } else if (result != null) {
        SnackBarHelper.showErrorSnackBar(
          context,
          result.error ?? 'Upload fehlgeschlagen',
        );
      }
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        context,
        'Fehler beim Auswählen des Bildes: $e',
      );
    } finally {
      setState(() {
        _isUploadingFile = false;
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isUploadingFile = true;
    });

    try {
      final result = await FileUploadService1.pickAndUploadOfferFile();

      if (result != null && result.success) {
        setState(() {
          _angebotFileUrl = result.fileUrl;
          _angebotFileName = result.fileName;
        });
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Datei erfolgreich hochgeladen',
        );
      } else if (result != null) {
        SnackBarHelper.showErrorSnackBar(
          context,
          result.error ?? 'Upload fehlgeschlagen',
        );
      }
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        context,
        'Fehler beim Auswählen der Datei: $e',
      );
    } finally {
      setState(() {
        _isUploadingFile = false;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _angebotFileUrl = '';
      _angebotFileName = '';
    });
    SnackBarHelper.showSuccessSnackBar(
      context,
      'Datei entfernt',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(widget.weddingDayScheduleModel != null
            ? "Eigene Dienstleister"
            : "Eigene Dienstleister"),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SpacerWidget(height: 4),
                CustomTextWidget(text: "${AppConstants.kategorie} *"),
                SpacerWidget(height: 2),
                GestureDetector(
                  onTap: () async {
                    print("Navigating to category page...");
                    final result = await Navigator.of(context)
                        .pushNamed(RouteManager.weddingCategoryTitlePage1);

                    print(
                        "Returned value: $result"); // <-- You should see this when popped

                    if (result != null && result is String) {
                      setState(() {
                        _titleController = result;
                      });
                    }
                  },
                  child: Container(
                    width: context.screenWidth,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 18)
                        .copyWith(right: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      border: Border.all(
                        color: (_titleController == null ||
                                _titleController!.trim().isEmpty)
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomTextWidget(
                      text: _titleController ?? "Kategorie auswählen",
                    ),
                  ),
                ),

                SpacerWidget(height: 4),
                CustomTextWidget(text: "Dienstleistername *"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: _dienstleisternameController.text.trim().isEmpty
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _dienstleisternameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Dienstleistername eingeben",
                    ),
                    onChanged: (value) {
                      setState(() {}); // Refresh validation styling
                    },
                  ),
                ),
                SpacerWidget(height: 4),

                // Dienstleistername field (Required)

                // Kontaktperson field
                WeddingSchedulePageWidget(
                  titleController: _kontaktpersonController,
                  text: "Kontaktperson",
                  maxLines: 1,
                ),
                SpacerWidget(height: 4),

                // Telefonnummer field with call option and validation
                CustomTextWidget(text: "Telefonnummer"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                      .copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: _telefonnummerController.text.isNotEmpty &&
                              !_isValidPhoneNumber(
                                  _telefonnummerController.text)
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _telefonnummerController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            // hintText: "Telefonnummer eingeben",
                          ),
                          onChanged: (value) {
                            setState(
                                () {}); // Refresh to show/hide phone icon and validation
                          },
                        ),
                      ),
                      if (_telefonnummerController.text.isNotEmpty &&
                          _isValidPhoneNumber(_telefonnummerController.text))
                        IconButton(
                          onPressed: () async {
                            final phoneNumber = _telefonnummerController.text;
                            final uri = Uri.parse('tel:$phoneNumber');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: Icon(Icons.phone, color: Color(0xFF6B456A)),
                        ),
                    ],
                  ),
                ),
                if (_telefonnummerController.text.isNotEmpty &&
                    !_isValidPhoneNumber(_telefonnummerController.text))
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 10),
                    child: Text(
                      'Bitte geben Sie eine gültige Telefonnummer ein',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                SpacerWidget(height: 4),

                // E-Mail field with validation
                CustomTextWidget(text: "E-Mail"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: _emailController.text.isNotEmpty &&
                              !_isValidEmail(_emailController.text)
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      // hintText: "E-Mail-Adresse eingeben",
                    ),
                    onChanged: (value) {
                      setState(() {}); // Refresh validation styling
                    },
                  ),
                ),
                if (_emailController.text.isNotEmpty &&
                    !_isValidEmail(_emailController.text))
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 10),
                    child: Text(
                      'Bitte geben Sie eine gültige E-Mail-Adresse ein',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                SpacerWidget(height: 4),

                // Homepage field with validation
                CustomTextWidget(text: "Homepage"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: _homepageController.text.isNotEmpty &&
                              !_isValidUrl(_homepageController.text)
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _homepageController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      // hintText: "https://www.beispiel.de",
                    ),
                    onChanged: (value) {
                      setState(() {}); // Refresh validation styling
                    },
                  ),
                ),
                if (_homepageController.text.isNotEmpty &&
                    !_isValidUrl(_homepageController.text))
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 10),
                    child: Text(
                      'Bitte geben Sie eine gültige Homepage URL ein',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                SpacerWidget(height: 4),

                // Instagram field
                WeddingSchedulePageWidget(
                  titleController: _instagramController,
                  text: "Instagram",
                  maxLines: 1,
                ),

                // Event Date Section

                // SpacerWidget(height: 4),
                // WeddingSchedulePageWidget(
                //   titleController: _responsiblePersonController,
                //   // label: AppConstants.weddingSchedulePageResponsiblePerson,
                //   text: AppConstants.weddingSchedulePageResponsiblePerson,
                //   maxLines: 1,
                // ),

                SpacerWidget(height: 4),

                CustomTextWidget(
                    text: AppConstants.weddingSchedulePageLocation),
                SpacerWidget(height: 2),
                GestureDetector(
                  onTap: () async {
                    var g = await Navigator.pushNamed(
                        context, RouteManager.weddingCategoryMap, arguments: {
                      'address': address ?? "",
                      'lat': lat ?? 0.00,
                      'long': long ?? 0.00
                    });

                    if (g != null) {
                      final map = g as Map<String, dynamic>;
                      setState(() {
                        lat = map['lat'];
                        long = map['long'];
                        address = map['address'];
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                        .copyWith(right: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomTextWidget(text: address ?? ""),
                        ),
                        IconButton(
                          onPressed: () async {
                            var g = await Navigator.pushNamed(
                                context, RouteManager.weddingCategoryMap,
                                arguments: {
                                  'address': address ?? "",
                                  'lat': lat ?? 0.00,
                                  'long': long ?? 0.00
                                });

                            if (g != null) {
                              final map = g as Map<String, dynamic>;
                              setState(() {
                                lat = map['lat'];
                                long = map['long'];
                                address = map['address'];
                              });
                            }
                          },
                          icon: Icon(
                            FontAwesomeIcons.mapLocation,
                            color: Color.fromARGB(255, 126, 80, 123),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SpacerWidget(height: 4),

                // Address Details field
                WeddingSchedulePageWidget(
                  titleController: _addressDetailsController,
                  text: "Adresse Details",
                  maxLines: 2,
                ),
                SpacerWidget(height: 4),

                WeddingSchedulePageWidget(
                  titleController: _notesController,

                  // label: AppConstants.weddingSchedulePageNotes,
                  text: "${AppConstants.weddingSchedulePageNotes}",
                  maxLines: 3,
                ),
                SpacerWidget(height: 4),

                // Angebot text field
                WeddingSchedulePageWidget(
                  titleController: _angebotTextController,
                  text: "Angebot Beschreibung",
                  maxLines: 3,
                ),
                SpacerWidget(height: 4),

                // Angebot file upload
                CustomTextWidget(text: "Angebot Datei"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 18)
                      .copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextWidget(
                              text: _angebotFileName.isEmpty
                                  ? "Keine Datei ausgewählt"
                                  : _angebotFileName,
                            ),
                            if (_angebotFileName.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      FileUploadService1.getFileIcon(
                                          _angebotFileName),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      FileUploadService1.isImageFile(
                                              _angebotFileName)
                                          ? 'Bild'
                                          : FileUploadService1.isPdfFile(
                                                  _angebotFileName)
                                              ? 'PDF'
                                              : 'Datei',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_isUploadingFile)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6B456A)),
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: _showFilePickerOptions,
                          icon: Icon(
                            _angebotFileName.isEmpty
                                ? Icons.attach_file
                                : Icons.edit,
                            color: Color(0xFF6B456A),
                          ),
                        ),
                    ],
                  ),
                ),
                SpacerWidget(height: 4),

                // Zahlungsstatus dropdown
                CustomTextWidget(text: "Zahlungsstatus"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _zahlungsstatus,
                      isExpanded: true,
                      items: ['Unbezahlt', 'Teilweise bezahlt', 'Bezahlt']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: CustomTextWidget(text: value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _zahlungsstatus = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                SpacerWidget(height: 4),

                CustomTextWidget(text: "Probetermin Datum *"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                      .copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: _selectedEventDate == null
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextWidget(
                            text: _selectedEventDateText ?? ""),
                      ),
                      IconButton(
                        onPressed: _selectEventDate,
                        icon: Icon(Icons.calendar_today,
                            color: Color(0xFF6B456A)),
                      ),
                    ],
                  ),
                ),

                SpacerWidget(height: 4),

                // Event Time Section
                CustomTextWidget(
                    text:
                        "Probetermin ${AppConstants.weddingSchedulePageDate} *"),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                      .copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: _selectedTime == null
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectEventTime,
                          child:
                              CustomTextWidget(text: _selectedTimeText ?? ""),
                        ),
                      ),
                      IconButton(
                        onPressed: _selectEventTime,
                        icon: Icon(Icons.timer, color: Color(0xFF6B456A)),
                      ),
                    ],
                  ),
                ),

                SpacerWidget(height: 4),
                // SpacerWidget(height: 4),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 18)
                      .copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextWidget(
                            text:
                                "${AppConstants.weddingSchedulePageReminder} aktivieren"),
                      ),
                      FlutterSwitch(
                        height: 25,
                        width: 50,
                        activeColor: Color.fromARGB(255, 126, 80, 123),
                        inactiveColor: Colors.grey,
                        borderRadius: 15,
                        value: _reminderEnabled,
                        onToggle: (bool value) {
                          setState(() {
                            _reminderEnabled = value;
                          });
                        },
                      ),
                      SizedBox(width: 10),
                    ],
                  ),
                ),

                // Show reminder date and time fields only if reminder is enabled
                if (_reminderEnabled) ...[
                  SpacerWidget(height: 4),
                  CustomTextWidget(
                      text: AppConstants.weddingSchedulePageReminderDate1),
                  SpacerWidget(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                        .copyWith(right: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomTextWidget(
                              text: _selectedReminderDateText ?? ""),
                        ),
                        IconButton(
                          onPressed: _selectReminderDate,
                          icon: Icon(Icons.calendar_today,
                              color: Color(0xFF6B456A)),
                        ),
                      ],
                    ),
                  ),
                  SpacerWidget(height: 4),
                  CustomTextWidget(
                      text: AppConstants.weddingSchedulePageReminderTime),
                  SpacerWidget(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                        .copyWith(right: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectReminderTime,
                            child: CustomTextWidget(
                                text: _selectedReminderText ?? ""),
                          ),
                        ),
                        IconButton(
                          onPressed: _selectReminderTime,
                          icon: Icon(Icons.timer, color: Color(0xFF6B456A)),
                        ),
                      ],
                    ),
                  ),
                ],

                // // Probetermin field
                // CustomTextWidget(text: "Probetermin"),
                // SpacerWidget(height: 2),
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                //       .copyWith(right: 0),
                //   decoration: BoxDecoration(
                //     color: Colors.grey.withValues(alpha: 0.2),
                //     border: Border.all(color: Colors.white),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Expanded(
                //         child: CustomTextWidget(text: _probeterminText ?? ""),
                //       ),
                //       IconButton(
                //         onPressed: _selectProbetermin,
                //         icon: Icon(Icons.calendar_today,
                //             color: Color(0xFF6B456A)),
                //       ),
                //     ],
                //   ),
                // ),
                SpacerWidget(height: 4),

                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: CustomButtonWidget(
                        text: AppConstants.weddingSchedulePageCancel,
                        color: Colors.white,
                        onPressed: () {
                          _selectedTimeText = null;
                          _selectedTime = null;
                          _selectedEventDate = null;
                          _selectedEventDateText = null;
                          _selectedReminderDate = null;
                          _selectedReminderDateText = null;
                          _selectedReminder = null;
                          _selectedReminderText = null;
                          _titleController = null;
                          _descriptionController.clear();
                          _responsiblePersonController.clear();
                          _notesController.clear();
                          _bufferTimeController.clear();
                          // Clear new field controllers
                          _dienstleisternameController.clear();
                          _kontaktpersonController.clear();
                          _telefonnummerController.clear();
                          _emailController.clear();
                          _homepageController.clear();
                          _instagramController.clear();
                          _addressDetailsController.clear();
                          _angebotTextController.clear();
                          _angebotFileUrl = '';
                          _angebotFileName = '';
                          _zahlungsstatus = 'Unbezahlt';
                          _probetermin = null;
                          _probeterminText = null;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomButtonWidget(
                          isLoading: isLoading,
                          text: widget.weddingDayScheduleModel != null
                              ? AppConstants.weddingSchedulePageUpdate
                              : AppConstants.weddingSchedulePageSave,
                          color: Color.fromARGB(255, 107, 69, 106),
                          textColor: Colors.white,
                          onPressed: () async {
                            setState(() => isLoading = true);

                            // Use comprehensive validation
                            if (!_validateAllFields()) {
                              setState(() => isLoading = false);
                              return;
                            }

                            // Event time with selected date and time
                            DateTime eventTime = DateTime(
                              _selectedEventDate!.year,
                              _selectedEventDate!.month,
                              _selectedEventDate!.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );

                            // Reminder time (if enabled and selected)
                            DateTime? reminderTime;
                            if (_reminderEnabled &&
                                _selectedReminderDate != null &&
                                _selectedReminder != null) {
                              reminderTime = DateTime(
                                _selectedReminderDate!.year,
                                _selectedReminderDate!.month,
                                _selectedReminderDate!.day,
                                _selectedReminder!.hour,
                                _selectedReminder!.minute,
                              );
                            }

                            print(reminderTime);
                            print(eventTime);

                            if (widget.weddingDayScheduleModel == null) {
                              await weddingDayScheduleService.addScheduleItem(
                                  title: _titleController!,
                                  time: eventTime,
                                  reminderEnabled: _reminderEnabled,
                                  responsiblePerson:
                                      _responsiblePersonController.text,
                                  notes: _notesController.text,
                                  reminderTime:
                                      reminderTime, // Remove the ! - allow null
                                  address: address ?? "",
                                  lat: lat ?? 0.00,
                                  long: long ?? 0.00,
                                  // New fields
                                  dienstleistername:
                                      _dienstleisternameController.text,
                                  kontaktperson: _kontaktpersonController.text,
                                  telefonnummer: _telefonnummerController.text,
                                  email: _emailController.text,
                                  homepage: _homepageController.text,
                                  instagram: _instagramController.text,
                                  addressDetails:
                                      _addressDetailsController.text,
                                  angebotText: _angebotTextController.text,
                                  angebotFileUrl: _angebotFileUrl,
                                  angebotFileName: _angebotFileName,
                                  zahlungsstatus: _zahlungsstatus,
                                  probetermin: _probetermin);
                              // SnackBarHelper.showSuccessSnackBar(context, "Event Scheduled for $reminderTime");

                              setState(() {
                                isLoading = false;
                              });
                            } else {
                              weddingDayScheduleService.updateOrder(
                                WeddingDayScheduleModel1(
                                  id: widget.weddingDayScheduleModel!.id,
                                  title: _titleController!,
                                  time: eventTime,
                                  reminderEnabled: _reminderEnabled,
                                  reminderTime:
                                      reminderTime, // Remove the ! - allow null
                                  userId: weddingDayScheduleService.userId!,
                                  responsiblePerson:
                                      _responsiblePersonController.text,
                                  notes: _notesController.text,
                                  address: address ?? "no address",
                                  lat: lat ?? 0.00,
                                  long: long ?? 0.00,
                                  order: weddingDayScheduleService
                                      .weddingDayScheduleList
                                      .indexWhere((element) =>
                                          element.id ==
                                          widget.weddingDayScheduleModel!.id),
                                  // New fields
                                  dienstleistername:
                                      _dienstleisternameController.text,
                                  kontaktperson: _kontaktpersonController.text,
                                  telefonnummer: _telefonnummerController.text,
                                  email: _emailController.text,
                                  homepage: _homepageController.text,
                                  instagram: _instagramController.text,
                                  addressDetails:
                                      _addressDetailsController.text,
                                  angebotText: _angebotTextController.text,
                                  angebotFileUrl: _angebotFileUrl,
                                  angebotFileName: _angebotFileName,
                                  zahlungsstatus: _zahlungsstatus,
                                  probetermin: _probetermin,
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                            }
                            Navigator.of(context).pushReplacementNamed(
                                RouteManager.weddingSchedulePage1);
                            setState(() {
                              isLoading = false;
                            });
                          }),
                    ),
                  ],
                ),
                SpacerWidget(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
