import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_switch/flutter_switch.dart';

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
  double? lat;
  double? long;

  WeddingDayScheduleService weddingDayScheduleService =
      WeddingDayScheduleService();

  @override
  void initState() {
    super.initState();

    if (widget.weddingDayScheduleModel != null) {
      print(widget.weddingDayScheduleModel);
      _titleController = widget.weddingDayScheduleModel!.title;
      // _descriptionController.text = widget.weddingDayScheduleModel!.description;
      _responsiblePersonController.text =
          widget.weddingDayScheduleModel!.responsiblePerson;
      _notesController.text = widget.weddingDayScheduleModel!.notes;
      address = widget.weddingDayScheduleModel!.address;
      lat = widget.weddingDayScheduleModel!.lat;
      long = widget.weddingDayScheduleModel!.long;

      print(lat);
      print(long);
      print(widget.weddingDayScheduleModel!.address);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
                  onTap: () async {
                    print("Navigating to category page...");
                    final result = await Navigator.of(context)
                        .pushNamed(RouteManager.weddingCategoryTitlePage);

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
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomTextWidget(text: _titleController ?? ""),
                  ),
                ),

                SpacerWidget(height: 4),
                // Event Date Section
                CustomTextWidget(text: "Datum"),
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
                CustomTextWidget(text: AppConstants.weddingSchedulePageDate),
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

                WeddingSchedulePageWidget(
                  titleController: _notesController,

                  // label: AppConstants.weddingSchedulePageNotes,
                  text: "Beschreibung/${AppConstants.weddingSchedulePageNotes}",
                  maxLines: 3,
                ),
                // SpacerWidget(height: 4),
                // WeddingSchedulePageWidget(
                //   titleController: _descriptionController,
                //   // label: AppConstants.weddingSchedulePageDescription,
                //   text: AppConstants.weddingSchedulePageDescription,
                //   maxLines: 3,
                // ),
                SpacerWidget(height: 4),
                WeddingSchedulePageWidget(
                  titleController: _responsiblePersonController,
                  // label: AppConstants.weddingSchedulePageResponsiblePerson,
                  text: AppConstants.weddingSchedulePageResponsiblePerson,
                  maxLines: 1,
                ),

                SpacerWidget(height: 4),

                // Reminder Section
                // CustomTextWidget(text: AppConstants.weddingSchedulePageReminder),

                CustomTextWidget(
                    text: AppConstants.weddingSchedulePageLocation),
                SpacerWidget(height: 2),
                Container(
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
                        icon: Icon(FontAwesomeIcons.mapLocation),
                      ),
                    ],
                  ),
                ),
                SpacerWidget(height: 4),

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
                      text: AppConstants.weddingSchedulePageReminderDate),
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
                          text: widget.weddingDayScheduleModel != null
                              ? AppConstants.weddingSchedulePageUpdate
                              : AppConstants.weddingSchedulePageSave,
                          color: Color.fromARGB(255, 107, 69, 106),
                          textColor: Colors.white,
                          onPressed: () async {
                            setState(() => isLoading = true);

                            if (_titleController == "" &&
                                _titleController!.isEmpty) {
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
                                  // description: _descriptionController.text,
                                  time: eventTime,
                                  reminderEnabled: _reminderEnabled,
                                  responsiblePerson:
                                      _responsiblePersonController.text,
                                  notes: _notesController.text,
                                  reminderTime:
                                      reminderTime, // Remove the ! - allow null
                                  address: address ?? "",
                                  lat: lat ?? 0.00,
                                  long: long ?? 0.00);
                              // SnackBarHelper.showSuccessSnackBar(context, "Event Scheduled for $reminderTime");

                              setState(() {
                                isLoading = false;
                              });
                            } else {
                              weddingDayScheduleService.updateOrder(
                                WeddingDayScheduleModel(
                                  id: widget.weddingDayScheduleModel!.id,
                                  title: _titleController!,
                                  // description: _descriptionController.text,
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
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                            }
                            Navigator.of(context).pushReplacementNamed(
                                RouteManager.weddingSchedulePage);
                            setState(() {
                              isLoading = false;
                            });
                          }),
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
