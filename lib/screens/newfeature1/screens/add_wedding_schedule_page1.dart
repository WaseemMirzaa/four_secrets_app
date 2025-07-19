import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:four_secrets_wedding_app/pages/map_picker_page.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/wedding_day_schedule_service1.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/widgets/wedding_schedule_page_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_switch/flutter_switch.dart';

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
        title: const Text("Tagesablauf1"),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _titleController ??
                                AppConstants.weddingCategorySelectCategory,
                            style: TextStyle(
                              fontSize: 16,
                              color: _titleController != null
                                  ? Colors.black
                                  : Colors.grey.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                SpacerWidget(height: 16),

                // Responsible person
                WeddingSchedulePageWidget(
                  titleController: _responsiblePersonController,
                  text: AppConstants.weddingSchedulePageResponsiblePerson,
                ),
                SpacerWidget(height: 16),

                // Notes
                WeddingSchedulePageWidget(
                  titleController: _notesController,
                  text: AppConstants.weddingSchedulePageNotes,
                  maxLines: 3,
                ),
                SpacerWidget(height: 16),

                // Event Date
                CustomTextWidget(text: AppConstants.weddingSchedulePageDate),
                SpacerWidget(height: 2),
                GestureDetector(
                  onTap: _selectEventDate,
                  child: Container(
                    width: context.screenWidth,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedEventDateText ??
                              AppConstants.weddingSchedulePageDate,
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedEventDateText != null
                                ? Colors.black
                                : Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                SpacerWidget(height: 16),

                // Event Time
                CustomTextWidget(text: AppConstants.weddingSchedulePageTime),
                SpacerWidget(height: 2),
                GestureDetector(
                  onTap: _selectEventTime,
                  child: Container(
                    width: context.screenWidth,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTimeText ??
                              AppConstants.weddingSchedulePageTime,
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedTimeText != null
                                ? Colors.black
                                : Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                        Icon(
                          Icons.access_time,
                          color: Colors.grey.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                SpacerWidget(height: 16),

                // Reminder toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomTextWidget(
                        text: AppConstants.weddingSchedulePageReminder),
                    FlutterSwitch(
                      width: 55.0,
                      height: 30.0,
                      valueFontSize: 25.0,
                      toggleSize: 25.0,
                      value: _reminderEnabled,
                      borderRadius: 30.0,
                      padding: 2.0,
                      showOnOff: false,
                      onToggle: (val) {
                        setState(() {
                          _reminderEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
                SpacerWidget(height: 16),

                // Reminder Date (if enabled)
                if (_reminderEnabled) ...[
                  CustomTextWidget(
                      text: AppConstants.weddingSchedulePageReminderDate),
                  SpacerWidget(height: 2),
                  GestureDetector(
                    onTap: _selectReminderDate,
                    child: Container(
                      width: context.screenWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedReminderDateText ??
                                AppConstants.weddingSchedulePageReminderDate,
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedReminderDateText != null
                                  ? Colors.black
                                  : Colors.grey.withValues(alpha: 0.8),
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SpacerWidget(height: 16),

                  // Reminder Time (if enabled)
                  CustomTextWidget(
                      text: AppConstants.weddingSchedulePageReminderTime),
                  SpacerWidget(height: 2),
                  GestureDetector(
                    onTap: _selectReminderTime,
                    child: Container(
                      width: context.screenWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedReminderText ??
                                AppConstants.weddingSchedulePageReminderTime,
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedReminderText != null
                                  ? Colors.black
                                  : Colors.grey.withValues(alpha: 0.8),
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SpacerWidget(height: 16),
                ],

                // Location selection
                CustomTextWidget(
                    text: AppConstants.weddingSchedulePageLocation),
                SpacerWidget(height: 2),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MapPickerPage(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        address = result['address'];
                        lat = result['lat'];
                        long = result['long'];
                      });
                    }
                  },
                  child: Container(
                    width: context.screenWidth,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            address ?? AppConstants.weddingSchedulePageLocation,
                            style: TextStyle(
                              fontSize: 16,
                              color: address != null
                                  ? Colors.black
                                  : Colors.grey.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          color: Colors.grey.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                SpacerWidget(height: 24),

                // Save/Update buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButtonWidget(
                        text: AppConstants.weddingSchedulePageCancel,
                        color: Colors.white,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomButtonWidget(
                          isLoading: isLoading,
                          text: widget.weddingDayScheduleModel != null
                              ? AppConstants.weddingSchedulePageUpdate
                              : AppConstants.weddingSchedulePageSave,
                          textColor: Colors.white,
                          color: const Color.fromARGB(255, 107, 69, 106),
                          onPressed: () async {
                            setState(() => isLoading = true);

                            // Validation
                            if (_titleController == null ||
                                _titleController!.isEmpty) {
                              SnackBarHelper.showErrorSnackBar(
                                context,
                                AppConstants.weddingSchedulePageTitleError,
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

                            if (_selectedEventDate == null) {
                              SnackBarHelper.showErrorSnackBar(
                                context,
                                AppConstants.weddingSchedulePageDateError,
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
                                  time: eventTime,
                                  reminderEnabled: _reminderEnabled,
                                  responsiblePerson:
                                      _responsiblePersonController.text,
                                  notes: _notesController.text,
                                  reminderTime: reminderTime,
                                  address: address ?? "",
                                  lat: lat ?? 0.00,
                                  long: long ?? 0.00);

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
                                  reminderTime: reminderTime,
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
                                RouteManager.weddingSchedulePage1);
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
