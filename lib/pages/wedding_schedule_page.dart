import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';
import 'package:four_secrets_wedding_app/services/wedding_day_schedule_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/widgets/wedding_schedule_page_widget.dart';
import 'package:see_more/see_more_widget.dart';

class WeddingSchedulePage extends StatefulWidget {
  const WeddingSchedulePage({super.key});

  @override
  State<WeddingSchedulePage> createState() => _WeddingSchedulePageState();
}

class _WeddingSchedulePageState extends State<WeddingSchedulePage> {

  final key = GlobalKey<MenueState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  final _notesController = TextEditingController();
  final _bufferTimeController = TextEditingController();
  final _reminderTimeController = TextEditingController();


  TimeOfDay? _selectedTime;
  String? _selectedTimeText;

  TimeOfDay? _selectedReminder;
  String? _selectedReminderText;
  bool _reminderEnabled = false;
  bool isLoading = false;


  WeddingDayScheduleService weddingDayScheduleService = WeddingDayScheduleService();
  @override
  void initState() {
    super.initState();
    loadData();
  }



  loadData(){
    setState(() {
      isLoading = true;
    });
    weddingDayScheduleService.loadData().then((v){
      setState(() {
      isLoading = false;
    });
    });
    
  }


  addAndUpdateDialog({String? id,
    WeddingDayScheduleModel? scheduleItem,}
    
   ) {
      if(id != null){
        print(scheduleItem!.id ?? "No Id");
        id = scheduleItem.id;
        _titleController.text = scheduleItem.title;
        _descriptionController.text = scheduleItem.description;
        _responsiblePersonController.text = scheduleItem.responsiblePerson;
        _notesController.text = scheduleItem.notes;
        _selectedTimeText = scheduleItem.time.toString();
        _selectedTime = TimeOfDay.fromDateTime(scheduleItem.time);
        _selectedTimeText = "${scheduleItem.time.hour > 12 ? (scheduleItem.time.hour - 12).toString().padLeft(2, '0') :
        scheduleItem.time.hour.toString().padLeft(2, '0')}:${scheduleItem.time.minute.toString().padLeft(2, '0')} ${scheduleItem.time.hour >= 12 ? 'PM' : 'AM'}";
        // _bufferTimeController.text = scheduleItem.bufferTime.toString();
        _reminderTimeController.text = scheduleItem.reminderTime.toString();
        _selectedReminderText = scheduleItem.reminderTime.toString();
        _selectedReminder = TimeOfDay.fromDateTime(scheduleItem.reminderTime);
        _reminderEnabled = scheduleItem.reminderEnabled;
      }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          
          backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: context.screenWidth * 0.2 - 10,
                ),
                Expanded(child: CustomTextWidget(text: "Zeitplan hinzufügen", fontSize: 16, fontWeight: FontWeight.bold,)),
                GestureDetector(
                  onTap: (){
                    Navigator.of(context).pop();
                    _selectedTimeText = null;
                    _selectedTime = null;
                    _titleController.clear();
                    _descriptionController.clear();
                    _responsiblePersonController.clear();
                    _notesController.clear();
                    _bufferTimeController.clear();
                    _reminderTimeController.clear();

                    // _reminderEnabled = false;
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Icon(Icons.close, color: Colors.black.withValues(alpha: 0.4),),
                    ),
                  ),
                )
              ],
            ),
          content: StatefulBuilder(
           
            builder: (context, stateDialog) {
              return Container(
                 height: context.screenHeight * 0.5,
                  width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        SpacerWidget(height: 4),
                            
                        WeddingSchedulePageWidget(titleController: _titleController,
                        maxLines: 1, text: "Programmpunkt / Titel", label: "Programmpunkt / Titel",),
                  
                        SpacerWidget(height: 4),
                  
                        CustomTextWidget(text: "Uhrzeit",),
                        SpacerWidget(height: 2),
                  
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                            
                          ).copyWith(right: 0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: CustomTextWidget(text: _selectedTimeText ?? "Uhrzeit",)),
                             
                              IconButton(onPressed: (){
                                showTimePicker(context: context, initialTime: TimeOfDay.now()).then((value) {
                                  stateDialog(() {
                                    _selectedTime = value;
                                    _selectedTimeText = value!.format(context);
                                  });
                                });
                              }, icon: Icon(Icons.timer)),
                            ],
                          ),
                        ), 
                  
                        SpacerWidget(height: 4),
                        WeddingSchedulePageWidget(titleController: _descriptionController, label: "Beschreibung", 
                        text: "Beschreibung", maxLines: 3, ),
                        SpacerWidget(height: 4),
                        WeddingSchedulePageWidget(titleController: _responsiblePersonController, label: "Verantwortliche Person oder Dienstleister", 
                        text: "Verantwortliche Person oder Dienstleister", maxLines: 1, ),
                        SpacerWidget(height: 4),
                       
                        WeddingSchedulePageWidget(titleController: _notesController, label: "Notizen", 
                        text: "Notizen", maxLines: 3, ),
                        SpacerWidget(height: 4),
                  
                          // CustomTextWidget(text: "Erinnerung",),
                          // SpacerWidget(height: 2),

                          Container(
                             padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                            
                          ).copyWith(right: 0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(5),
                          ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: (){
                                   showTimePicker(context: context, initialTime: TimeOfDay.now()).then((value) {
                                    stateDialog(() {
                                      _selectedReminder = value;
                                      _selectedReminderText = value!.format(context);
                                    });
                                  });
                                    },
                                    child:  CustomTextWidget(text: _selectedReminderText ?? "Pufferzeit",),
                                   
                                  ),
                                ),
                               Switch(
                                     value: _reminderEnabled,
                                     onChanged: (value) {
                                       stateDialog(() {
                                         _reminderEnabled = value;
                                       });
                                     },
                                   ),
                            ],
                            ),
                          ),
                  ],),
                ),
              );
            }
          ),
          actions: [
           Row(
            spacing: 10,
             children: [
               Expanded(
                 child: CustomButtonWidget(text: "Abbrechen", color: Colors.white, onPressed: (){
                  _selectedTimeText = null;
                  _selectedTime = null;
                  _titleController.clear();
                  _descriptionController.clear();
                  _responsiblePersonController.clear();
                  _notesController.clear();
                  _bufferTimeController.clear();
                  Navigator.of(context).pop();
                           },),
               ),
                         Expanded(
                           child: CustomButtonWidget(text: "Speichern", color: Color.fromARGB(255, 107, 69, 106), textColor: Colors.white, onPressed: ()async{
                                           if (_titleController.text.isEmpty) {
                                             SnackBarHelper.showErrorSnackBar(context, "Bitte geben Sie einen Titel ein.");
                                             return;
                                           }
                                           if (_selectedTime == null) {
                                             SnackBarHelper.showErrorSnackBar(context, "Bitte wählen Sie eine Uhrzeit aus.");
                                             return;
                                           }

                                          // Define the event date (could be a specific wedding date in the future)
    DateTime eventDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Event time
    DateTime eventTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Reminder time (if enabled and selected)
    DateTime? reminderTime;
    if (_reminderEnabled && _selectedReminder != null) {
      reminderTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        _selectedReminder!.hour,
        _selectedReminder!.minute,
      );
    } else {
      reminderTime = null; // No reminder if not enabled or not selected
    }

                                           if(id == null) {
                                         await  weddingDayScheduleService.addScheduleItem(
                                             title: _titleController.text,
                                             description: _descriptionController.text,
                                             time: DateTime(
                                               DateTime.now().year,
                                               DateTime.now().month,
                                               DateTime.now().day,
                                               _selectedTime!.hour,
                                               _selectedTime!.minute,
                                             ),
                                             reminderEnabled: _reminderEnabled,
                                             responsiblePerson:  _responsiblePersonController.text,
                                             notes: _notesController.text,
                                             reminderTime: reminderTime!,
                                           );

                                           // Then, use the newItemId
  

                                           } else {
                                             weddingDayScheduleService.updateOrder(

                                               WeddingDayScheduleModel(
                                                 id: id,
                                                 title: _titleController.text,
                                                 description: _descriptionController.text,
                                                 time: DateTime(
                                                   DateTime.now().year,
                                                   DateTime.now().month,
                                                   DateTime.now().day,
                                                   _selectedTime!.hour,
                                                   _selectedTime!.minute,
                                                 ),
                                                 reminderEnabled: _reminderEnabled,
                                                 reminderTime: reminderTime!,
                                                 userId: weddingDayScheduleService.userId!,
                                                 responsiblePerson:  _responsiblePersonController.text,
                                                 notes: _notesController.text,
                                                 order: weddingDayScheduleService.weddingDayScheduleList.indexWhere((element) => element.id == id),
                                               ),
                                             );
                          }
                                           Navigator.of(context).pop();
                                           loadData();
                           },),
                         ),
             ],
           ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // resizeToAvoidBottomInset: false,
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text('Inspirationsordner'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed:()=> addAndUpdateDialog(),
          child: const Icon(Icons.add),
        ),
       body: ListView(
        
          children: [
          //  SpacerWidget(height: 17),
            SizedBox(
            
              child: Image.asset(
                "assets/images/background/wedding_sche.png",
                fit: BoxFit.cover,
              ),
            ),
            Transform.translate(
              offset: Offset(0, -30),
              child: Container(
                height: 30,
                width: context.screenWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                    Colors.transparent,
                    Color(0xffFFF7FF).withValues(alpha: 0.1),
                    Color(0xffFFF7FF).withValues(alpha: 0.2),
                    Color(0xffFFF7FF),
                  ])
                ),
              ),
            ),
          FourSecretsDivider(), 

         isLoading ? 
          CupertinoActivityIndicator()
   : SizedBox(
    width: context.screenWidth,
    
     child: ReorderableListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      buildDefaultDragHandles: false,
       padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
       itemCount: weddingDayScheduleService.weddingDayScheduleList.length,
       onReorder: (oldIndex, newIndex) async {
         final list = List<WeddingDayScheduleModel>.from(
             weddingDayScheduleService.weddingDayScheduleList);
         if (newIndex > oldIndex) newIndex--;
         final item = list.removeAt(oldIndex);
         list.insert(newIndex, item);
     
         // Persist the new order in Firestore:
         await weddingDayScheduleService.updateOrderItemsList(list);
     
         setState(() {
           // Reflect the change immediately:
           weddingDayScheduleService.weddingDayScheduleList = list;
         });
       },
       itemBuilder: (context, index) {
         final item = weddingDayScheduleService.weddingDayScheduleList[index];
         // Give each child a Unique Key from its ID:
         return Container(
           key: ValueKey(item.id),
           margin: EdgeInsets.symmetric(vertical: 4),
           child: Row(
             children: [
               Expanded(child: _buildSlidableItem(item, index)),
              ReorderableDragStartListener(
                key: ValueKey(item.id),
                index: index,
                child: Icon(FontAwesomeIcons.gripVertical, color: Colors.grey.withValues(alpha: 0.6),),
              )
             ],
           ),
         );
       },
     ),
   ),
          
          SpacerWidget(height: 12)
         
          ],
         ),
       ),
      
    );
    
  }
  Widget _buildSlidableItem(WeddingDayScheduleModel item, int index) {
  return Slidable(
    key: ValueKey(item.id),
    endActionPane: ActionPane(
      motion: StretchMotion(),
      children: [
        SlidableAction(
          onPressed: (_) {
            weddingDayScheduleService.deleteScheduleItem(item.id!);
            loadData();
          },
          icon: Icons.delete,
          backgroundColor: Colors.red.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    ),
    child: Container(
        width: context.screenWidth,
        // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.grey.shade300],
          ),
        ),
      
      
      child: ExpansionTile(
        title: CustomTextWidget(text: item.title, fontSize: 14, fontWeight: FontWeight.bold,),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: OutlineInputBorder(
          borderSide: BorderSide.none
        ),
        childrenPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        children: [ 
          Row(
            children: [
              Expanded(
                child: CustomTextWidget(
                    text: "Bearbeiten und Teilen",
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
    
              Icon(FontAwesomeIcons.share, size: 16,),
              SizedBox(width: 15,), 
              GestureDetector(
                 onTap: () => addAndUpdateDialog(
        id: item.id,
        scheduleItem: item,
      ),
                child: Icon(FontAwesomeIcons.penToSquare, size: 16,))
            ],
          ),
          FourSecretsDivider(),

           CustomTextWidget(text: "Verantwortliche Person ", fontSize: 14, fontWeight: FontWeight.bold,),
          CustomTextWidget(text: item.responsiblePerson, fontSize: 14),
                  FourSecretsDivider(),
          CustomTextWidget(text: "Notizen", fontSize: 14, fontWeight: FontWeight.bold,),
         SeeMoreWidget(item.notes, textStyle: TextStyle(fontSize: 14, color: Colors.black), trimLength: 90,
          seeMoreStyle: TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
          seeLessStyle:  TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
           ),
                   FourSecretsDivider(),

          CustomTextWidget(text: "Beschreibung", fontSize: 14, fontWeight: FontWeight.bold,),
          SeeMoreWidget(item.description, textStyle: TextStyle(fontSize: 14, color: Colors.black), trimLength: 90,
          seeMoreStyle: TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
          seeLessStyle:  TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
           ),
                  FourSecretsDivider(),

          CustomTextWidget(text: "Uhrzeit", fontSize: 14, fontWeight: FontWeight.bold,),
          CustomTextWidget(text: "${item.time.hour}:${item.time.minute} ${item.time.hour > 12 ? 'PM' : 'AM'}", fontSize: 14),
                   FourSecretsDivider(),

          CustomTextWidget(text: "Erinnerung", fontSize: 14, fontWeight: FontWeight.bold,),
          CustomTextWidget(text: "${item.reminderTime.hour}:${item.reminderTime.minute} ${item.reminderTime.hour > 12 ? 'PM' : 'AM'}", fontSize: 14),
          FourSecretsDivider(),

        ]
      ),
    ),
  );
}
}




/*
 Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextWidget(
                  text: item.title,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
    
              Icon(FontAwesomeIcons.share, size: 16,),
              SizedBox(width: 15,), 
              GestureDetector(
                 onTap: () => addAndUpdateDialog(
        id: item.id,
        scheduleItem: item,
      ),
                child: Icon(FontAwesomeIcons.penToSquare, size: 16,))
            ],
          ),
          Divider(),
          CustomTextWidget(text: "Verantwortliche Person ", fontSize: 14, fontWeight: FontWeight.bold,),
          CustomTextWidget(text: item.responsiblePerson, fontSize: 14),
          Divider(),
          CustomTextWidget(text: "Notizen", fontSize: 14, fontWeight: FontWeight.bold,),
         SeeMoreWidget(item.notes, textStyle: TextStyle(fontSize: 14, color: Colors.black), trimLength: 90,
          seeMoreStyle: TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
          seeLessStyle:  TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
           ),
          Divider(),
          CustomTextWidget(text: "Beschreibung", fontSize: 14, fontWeight: FontWeight.bold,),
          SeeMoreWidget(item.description, textStyle: TextStyle(fontSize: 14, color: Colors.black), trimLength: 90,
          seeMoreStyle: TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
          seeLessStyle:  TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
           ),
          Divider(),
          CustomTextWidget(text: "Uhrzeit", fontSize: 14, fontWeight: FontWeight.bold,),
          CustomTextWidget(text: item.time.toString(), fontSize: 14),
          Divider(),
          CustomTextWidget(text: "Uhrzeit", fontSize: 14, fontWeight: FontWeight.bold,),
          CustomTextWidget(text: item.time.toString(), fontSize: 14),
        ],
      ),


*/












