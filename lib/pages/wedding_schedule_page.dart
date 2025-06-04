import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/wedding_day_schedule_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:see_more/see_more_widget.dart';
import 'package:share_plus/share_plus.dart';

class WeddingSchedulePage extends StatefulWidget {
  const WeddingSchedulePage({super.key});

  @override
  State<WeddingSchedulePage> createState() => _WeddingSchedulePageState();
}

class _WeddingSchedulePageState extends State<WeddingSchedulePage> {

  final key = GlobalKey<MenueState>();
  late GoogleMapController _mapController;

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
          centerTitle: true,
          foregroundColor: Colors.white,
          title: const Text('Hochzeitsplan'),
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
                "assets/images/background/inspirationbg.png",
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
       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                child: Icon(FontAwesomeIcons.gripVertical, size: 16, color: Colors.grey.withValues(alpha: 0.6),),
              )
             ],
           ),
         );
       },
     ),
   ),
          
          SpacerWidget(height: 18)
         
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
        
        title: Row(
          spacing: 6,
          children: [
            Expanded(child: CustomTextWidget(text: item.title, fontSize: 14, fontWeight: FontWeight.bold,)),

              GestureDetector(
                onTap: ()async {
                 await SharePlus.instance.share(
                  ShareParams(
                  text: "Hey, mein Hochzeits-Termin ist um ${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')} Uhr!, Location ${item.address}"
                  
                  )
                 );
                },
                child: Container(
                     padding: EdgeInsets.only(
                       bottom: 2, // Space between underline and text
                     ),
                     decoration: BoxDecoration(
                        //  border: Border(bottom: BorderSide(
                        //  color: Colors.black, 
                        //  width: 1.0, // Underline thickness
                        // ))
                      ),child: Icon(FontAwesomeIcons.share, size: 20, color: Colors.black,)),
              ),

              SizedBox(width: 15,), 
                GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(RouteManager.addWedidngSchedulePage, arguments: {
                  "weddingDayScheduleModel": item,
                  });
                },
                child:Container(
     padding: EdgeInsets.only(
       bottom: 2, // Space between underline and text
     ),
     decoration: BoxDecoration(
        //  border: Border(bottom: BorderSide(
        //  color: Colors.black, 
        //  width: 1.0, // Underline thickness
        // ))
      ),child: Icon(FontAwesomeIcons.penToSquare, size: 20, color: Colors.black,)),
                
                )
          ],
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: OutlineInputBorder(
          borderSide: BorderSide.none
        ),
        childrenPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        children: [ 
          CustomTextWidget(
              text: "Bearbeiten und Teilen",
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
            CustomTextWidget(
            text: "${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')} "
              "${item.time.hour >= 12 ? 'Uhr' : 'Uhr'}",
            fontSize: 14,
            ),
            FourSecretsDivider(),
          if(item.reminderTime != null)
          CustomTextWidget(text: "Erinnerung", fontSize: 14, fontWeight: FontWeight.bold,),
          if(item.reminderTime != null)
            CustomTextWidget(
            text: "${item.reminderTime!.hour.toString().padLeft(2, '0')}:${item.reminderTime!.minute.toString().padLeft(2, '0')} "
                "${item.reminderTime!.hour >= 12 ? 'Uhr' : 'Uhr'}",
            fontSize: 14,
            ),
          if(item.reminderTime != null)

          FourSecretsDivider(),
            CustomTextWidget(text: "Ort", fontSize: 14, fontWeight: FontWeight.bold,),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                height: context.screenHeight * 0.2,
                width: context.screenWidth,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey, 
                      blurRadius: 10, offset: Offset(10, 0)
                    )
                  ]
                ),
                child:GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(item.lat, item.long),
                  zoom: 14.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                
                markers: {
                  Marker(
                    markerId: const MarkerId("selected-location"),
                    position: LatLng(item.lat, item.long),
                  ),
                },
              ),
              ),
            ), 
                  FourSecretsDivider(),

            
        ]
      ),
    ),
  );
}
}



