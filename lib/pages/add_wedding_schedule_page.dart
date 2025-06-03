import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/pages/map_picker_page.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/wedding_day_schedule_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/widgets/wedding_schedule_page_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AddWeddingSchedulePage extends StatefulWidget {
  final WeddingDayScheduleModel? weddingDayScheduleModel;
  const AddWeddingSchedulePage({super.key, this.weddingDayScheduleModel});

  @override
  State<AddWeddingSchedulePage> createState() => _AddWeddingSchedulePageState();
}

class _AddWeddingSchedulePageState extends State<AddWeddingSchedulePage> {
  final _descriptionController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  final _notesController = TextEditingController();
  final _bufferTimeController = TextEditingController();
  final _reminderTimeController = TextEditingController();
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
  Prediction? initialValue;
  Position? position;

  WeddingDayScheduleService weddingDayScheduleService = WeddingDayScheduleService();


  



  @override
  void initState() {
    super.initState();

    if (widget.weddingDayScheduleModel != null) {
      _titleController = widget.weddingDayScheduleModel!.title;
      _descriptionController.text = widget.weddingDayScheduleModel!.description;
      _responsiblePersonController.text = widget.weddingDayScheduleModel!.responsiblePerson;
      _notesController.text = widget.weddingDayScheduleModel!.notes;
      
      // Set event date and time from existing item
      _selectedEventDate = widget.weddingDayScheduleModel!.time;
      _selectedEventDateText = "${_selectedEventDate!.day}/${_selectedEventDate!.month}/${_selectedEventDate!.year}";
      _selectedTime = TimeOfDay.fromDateTime(widget.weddingDayScheduleModel!.time);
      _selectedTimeText = "${widget.weddingDayScheduleModel!.time.hour > 12 ? (widget.weddingDayScheduleModel!.time.hour - 12).toString().padLeft(2, '0') : widget.weddingDayScheduleModel!.time.hour.toString().padLeft(2, '0')}:${widget.weddingDayScheduleModel!.time.minute.toString().padLeft(2, '0')} ${widget.weddingDayScheduleModel!.time.hour >= 12 ? 'PM' : 'AM'}";
      
      _reminderEnabled = widget.weddingDayScheduleModel!.reminderEnabled;
      if (widget.weddingDayScheduleModel!.reminderTime != null) {
        _selectedReminderDate = widget.weddingDayScheduleModel!.reminderTime;
        _selectedReminderDateText = "${_selectedReminderDate!.day}/${_selectedReminderDate!.month}/${_selectedReminderDate!.year}";
        _selectedReminder = TimeOfDay.fromDateTime(widget.weddingDayScheduleModel!.reminderTime!);
        _selectedReminderText = "${widget.weddingDayScheduleModel!.reminderTime!.hour > 12 ? (widget.weddingDayScheduleModel!.reminderTime!.hour - 12).toString().padLeft(2, '0') : widget.weddingDayScheduleModel!.reminderTime!.hour.toString().padLeft(2, '0')}:${widget.weddingDayScheduleModel!.reminderTime!.minute.toString().padLeft(2, '0')} ${widget.weddingDayScheduleModel!.reminderTime!.hour >= 12 ? 'PM' : 'AM'}";
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
    _setCurrentLocationAsInitial();
  }


Future<void> _setCurrentLocationAsInitial() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

     position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      initialValue = Prediction(
        description: "Your Current Location",
        placeId: "",
        structuredFormatting: StructuredFormatting(
          mainText: "Current Location",
          secondaryText: "${position!.latitude}, ${position!.longitude}",
        ),
      
      );
    });
  } catch (e) {
    print("Error getting location: $e");
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
        _selectedTimeText = "${picked.hour > 12 ? (picked.hour - 12).toString().padLeft(2, '0') : picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ${picked.hour >= 12 ? 'Uhr' : 'Uhr'}";
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
        _selectedReminderDateText = "${picked.day}/${picked.month}/${picked.year}";
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
        _selectedReminderText = "${picked.hour > 12 ? (picked.hour - 12).toString().padLeft(2, '0') : 
        picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ${picked.hour >= 12 ? 'Uhr' : 'Uhr'}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(AppConstants.weddingAddPageTitle),
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
                CustomTextWidget(text: AppConstants.weddingSchedulePageTitle),
                SpacerWidget(height: 2),
                  GestureDetector(
                    onTap: ()async{
                    print("Navigating to category page...");
    final result = await Navigator.of(context).pushNamed(RouteManager.weddingCategoryTitlePage);

    print("Returned value: $result"); // <-- You should see this when popped

    if (result != null && result is String) {
      setState(() {
        _titleController = result;
      });
    }
                     
                    },
                    child: Container(
                      width: context.screenWidth,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 18).copyWith(right: 0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: CustomTextWidget(text: _titleController ?? "${AppConstants.weddingSchedulePageTitle} eingeben"),
                    ),
                  ),

                SpacerWidget(height: 4),
                // Event Date Section
                CustomTextWidget(text: AppConstants.weddingSchedulePageDate),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4).copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextWidget(text: _selectedEventDateText ?? "${AppConstants.weddingSchedulePageDate} auswählen"),
                      ),
                      IconButton(
                        onPressed: _selectEventDate,
                        icon: Icon(Icons.calendar_today),
                      ),
                    ],
                  ),
                ),
        
                SpacerWidget(height: 4),
        
                // Event Time Section
                CustomTextWidget(text: AppConstants.weddingSchedulePageDate),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4).copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectEventTime,
                          child: CustomTextWidget(text: _selectedTimeText ?? "${AppConstants.weddingSchedulePageDate} Uhrzeit auswählen"),
                        ),
                      ),
                      IconButton(
                        onPressed: _selectEventTime,
                        icon: Icon(Icons.timer),
                      ),
                    ],
                  ),
                ),
        
                SpacerWidget(height: 4),
                WeddingSchedulePageWidget(
                  titleController: _descriptionController,
                  label: AppConstants.weddingSchedulePageDescription,
                  text: AppConstants.weddingSchedulePageDescription,
                  maxLines: 3,
                ),
                SpacerWidget(height: 4),
                WeddingSchedulePageWidget(
                  titleController: _responsiblePersonController,
                  label: AppConstants.weddingSchedulePageResponsiblePerson,
                  text: AppConstants.weddingSchedulePageResponsiblePerson,
                  maxLines: 1,
                ),
                SpacerWidget(height: 4),
               
                WeddingSchedulePageWidget(
                  titleController: _notesController,
                  label: AppConstants.weddingSchedulePageNotes,
                  text: AppConstants.weddingSchedulePageNotes,
                  maxLines: 3,
                ),
                SpacerWidget(height: 4),
        
                // Reminder Section
                CustomTextWidget(text: AppConstants.weddingSchedulePageReminder),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4).copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextWidget(text: "${AppConstants.weddingSchedulePageReminder} aktivieren"),
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: (value) {
                          setState(() {
                            _reminderEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                 CustomTextWidget(text: AppConstants.weddingSchedulePageLocation),
                SpacerWidget(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4).copyWith(right: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: ()async{
                            final result = await showDialog<Prediction>(
      context: context,
      builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: MapLocationPicker(
              apiKey: "AIzaSyBD7O6PQXXb5wrigZ6WOTn2VwTRFxCb9KU",
              currentLatLng: LatLng(position!.latitude, position!.longitude),
              onNext: (result) {
                if (result != null) {
                  setState(() {
                    address = result.formattedAddress;
                  });
                  Navigator.of(context).pop(); // close the dialogs
                }
              },
              onSuggestionSelected: (details) {
                debugPrint('Suggestion selected: ${details?.result.name}');
              },
            ),
          ),
        ));

    if (result != null) {
      setState(() {
        initialValue = result;
        address = result.description ?? "No description";
      });
    }
  
                          },
                          child: CustomTextWidget(text: "${AppConstants.weddingSchedulePageDate} Uhrzeit auswählen"),
                        ),
                      ),
                      // IconButton(
                      //   onPressed: _selectEventTime,
                      //   icon: Icon(Icons.timer),
                      // ),
                    ],
                  ),
                ),
        
                // Show reminder date and time fields only if reminder is enabled
                if (_reminderEnabled) ...[
                  SpacerWidget(height: 4),
                  CustomTextWidget(text: AppConstants.weddingSchedulePageReminderDate),
                  SpacerWidget(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4).copyWith(right: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomTextWidget(text: _selectedReminderDateText ?? "${AppConstants.weddingSchedulePageReminderDate} auswählen"),
                        ),
                        IconButton(
                          onPressed: _selectReminderDate,
                          icon: Icon(Icons.calendar_today),
                        ),
                      ],
                    ),
                  ),
                  SpacerWidget(height: 4),
                  CustomTextWidget(text: AppConstants.weddingSchedulePageReminderTime),
                  SpacerWidget(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4).copyWith(right: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectReminderTime,
                            child: CustomTextWidget(text: _selectedReminderText ?? AppConstants.weddingSchedulePageReminderTime),
                          ),
                        ),
                        IconButton(
                          onPressed: _selectReminderTime,
                          icon: Icon(Icons.timer),
                        ),
                      ],
                    ),
                  ),
                ],
        
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
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomButtonWidget(
                        isLoading: isLoading,
                        text: widget.weddingDayScheduleModel != null ? AppConstants.weddingSchedulePageUpdate  :  AppConstants.weddingSchedulePageSave,
                        color: Color.fromARGB(255, 107, 69, 106),
                        textColor: Colors.white,
                        onPressed: () async {
                          setState(() => isLoading = true);

          if (_titleController == "" && _titleController!.isEmpty ) {
            SnackBarHelper.showErrorSnackBar(
              context,
              AppConstants.weddingSchedulePageTitleError,
            );
            setState(() => isLoading = false);
            return;
          }

          if (_selectedEventDate == null) {
            SnackBarHelper.showErrorSnackBar(
              context,
              AppConstants.weddingSchedulePageDateError,
            );
            setState(() => isLoading = false);
            return;
          }

          if (_selectedTime == null) {
            SnackBarHelper.showErrorSnackBar(
              context,
              AppConstants.weddingSchedulePageTimeError,
            );
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
                          if (_reminderEnabled) {
                            if (_selectedReminderDate == null || _selectedReminder == null) {
                              SnackBarHelper.showErrorSnackBar(context, AppConstants.weddingSchedulePageReminderDateError);
                               setState(() {
                            isLoading = false;
                          });
                              return;
                            }
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
                              description: _descriptionController.text,
                              time: eventTime,
                              reminderEnabled: _reminderEnabled,
                              responsiblePerson: _responsiblePersonController.text,
                              notes: _notesController.text,
                              reminderTime: reminderTime!,
                              address: ""
                                                          );
                             setState(() {
                            isLoading = false;
                          });
                          } else {
                            weddingDayScheduleService.updateOrder(
                              WeddingDayScheduleModel(
                                id: widget.weddingDayScheduleModel!.id,
                                title: _titleController!,
                                description: _descriptionController.text,
                                time: eventTime,
                                reminderEnabled: _reminderEnabled,
                                reminderTime: reminderTime!,
                                userId: weddingDayScheduleService.userId!,
                                responsiblePerson: _responsiblePersonController.text,
                                notes: _notesController.text,
                                address: "no address",
                                order: weddingDayScheduleService.weddingDayScheduleList.indexWhere((element) => element.id == widget.weddingDayScheduleModel!.id),
                              ),
                            );
                             setState(() {
                            isLoading = false;
                          });
                          }
                          Navigator.of(context).pushReplacementNamed(RouteManager.weddingSchedulePage);
                          setState(() {
                            isLoading = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SpacerWidget(height: 7),
        
              ],
            ),
          ),
        ),
      ),
    );
  }
}