import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
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

  WeddingDayScheduleModel? weddingDayScheduleModel;
bool _isFirstLoad = true;
  WeddingDayScheduleService weddingDayScheduleService = WeddingDayScheduleService();
  @override
  void initState() {
    super.initState();
    loadData();
  }

@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Skip the first call (which happens after initState)
    if (!_isFirstLoad) {
      loadData();
    }
    _isFirstLoad = false;
  }

  loadData(){
    setState(() {
      // isLoading = true;
    });
    weddingDayScheduleService.loadData().then((v){
      setState(() {
      // isLoading = false;
    });
    });
    
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
          onPressed:(){
             Navigator.of(context).pushNamed(RouteManager.addWedidngSchedulePage, arguments: {
             "weddingDayScheduleModel" : weddingDayScheduleModel,
             });
          },
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

        
         SizedBox(
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
                 onTap: () {
                   Navigator.of(context).pushNamed(RouteManager.addWedidngSchedulePage, arguments: {
                    "weddingDayScheduleModel" : item,
                   });
                 },
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



