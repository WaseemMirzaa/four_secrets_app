import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/Pdf/share_single_pdf.dart';
import 'package:four_secrets_wedding_app/Pdf/shcedule_pdf.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/wedding_day_schedule_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:printing/printing.dart';
import 'package:see_more/see_more_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:four_secrets_wedding_app/pages/PdfViewPage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

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
  bool isDeleting = false;
  WeddingDayScheduleService weddingDayScheduleService =
      WeddingDayScheduleService();
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

  loadData() {
    setState(() {
      // isLoading = true;
    });
    weddingDayScheduleService.loadData().then((v) {
      setState(() {
        // isLoading = false;
      });
    });
  }

  Future<void> _downloadWeddingSchedulePdf() async {
    try {
      final sortedScheduleList = weddingDayScheduleService
          .weddingDayScheduleList
          .where((e) => e.time != null)
          .toList()
        ..sort((b, a) {
          final aDateTime = DateTime(
            a.time.year,
            a.time.month,
            a.time.day,
            a.time.hour,
            a.time.minute,
          );

          final bDateTime = DateTime(
            b.time.year,
            b.time.month,
            b.time.day,
            b.time.hour,
            b.time.minute,
          );

          return bDateTime.compareTo(aDateTime);
        });

      final pdfBytes =
          await generateWeddingSchedulePdfBytes(sortedScheduleList);
      final now = DateTime.now();
      final filename =
          'Tagesablauf_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}.pdf';

      // Get documents directory for saving
      final documentsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${documentsDir.path}/Downloads');

      // Create Downloads directory if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$filename');
      print(file.path);
      // Write PDF bytes to file
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(
                  child: Text('PDF erfolgreich gespeichert: $filename'),
                ),
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PdfViewPage(
                          pdfBytes: pdfBytes,
                          title: 'Tagesablauf',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 107, 69, 106),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, 'Fehler beim Herunterladen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        // resizeToAvoidBottomInset: false,
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          centerTitle: true,
          foregroundColor: Colors.white,
          title: Text(AppConstants.weddingAddPageTitle),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          actions: [
            IconButton(
                onPressed: () async {
                  final sortedScheduleList =
                      weddingDayScheduleService.weddingDayScheduleList
                          .where((e) => e.time != null) // Filter if needed
                          .toList()
                        ..sort((b, a) {
                          final aDateTime = DateTime(
                            a.time.year,
                            a.time.month,
                            a.time.day,
                            a.time.hour,
                            a.time.minute,
                          );

                          final bDateTime = DateTime(
                            b.time.year,
                            b.time.month,
                            b.time.day,
                            b.time.hour,
                            b.time.minute,
                          );

                          return bDateTime.compareTo(aDateTime);
                        });

// Step 2: Pass it to the PDF generator
                  final pdfBytes =
                      await generateWeddingSchedulePdfBytes(sortedScheduleList);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PdfViewPage(
                        pdfBytes: pdfBytes,
                        title: 'Zeitplan der Hochzeit',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  FontAwesomeIcons.eye,
                  size: 18,
                )),
            IconButton(
                onPressed: () {
                  _downloadWeddingSchedulePdf();
                },
                icon: Icon(
                  FontAwesomeIcons.download,
                  size: 18,
                ))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .pushNamed(RouteManager.addWedidngSchedulePage, arguments: {
              "weddingDayScheduleModel": weddingDayScheduleModel,
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
                fit: BoxFit.fitWidth,
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
                    ])),
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
                itemCount:
                    weddingDayScheduleService.weddingDayScheduleList.length,
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
                  final item =
                      weddingDayScheduleService.weddingDayScheduleList[index];
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
                          child: Icon(
                            FontAwesomeIcons.gripVertical,
                            size: 16,
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            if (weddingDayScheduleService.weddingDayScheduleList.isNotEmpty)
              FourSecretsDivider(),
            SpacerWidget(height: 18)
          ],
        ),
      ),
    );
  }

  Widget _buildSlidableItem(WeddingDayScheduleModel item, int index) {
    return Container(
      width: context.screenWidth,
      // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
      ),

      child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              .copyWith(right: 4),
          title: Row(
            spacing: 6,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.clock, size: 16),
                      SizedBox(width: 4),
                      CustomTextWidget(
                        text:
                            "${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')} "
                            "${item.time.hour >= 12 ? 'Uhr' : 'Uhr'}",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15,
                    width: 16,
                    child: VerticalDivider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.calendar,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      CustomTextWidget(
                        text:
                            "${item.time.day.toString().padLeft(2, '0')},${item.time.month.toString().padLeft(2, '0')},${item.time.year}",
                        fontSize: 12,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final pdfBytes = await generateSingleSchedulePdf(item);
                      await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename: 'Zeitplan_der_Hochzeit.pdf');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        FontAwesomeIcons.share,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          RouteManager.addWedidngSchedulePage,
                          arguments: {
                            "weddingDayScheduleModel": item,
                          });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        FontAwesomeIcons.penToSquare,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: OutlineInputBorder(borderSide: BorderSide.none),
          childrenPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          children: [
            CustomTextWidget(
              text: item.title,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),

            // CustomTextWidget(
            //     text: "Bearbeiten und Teilen",
            //   fontSize: 16,
            //   fontWeight: FontWeight.bold,

            SpacerWidget(height: 3),

            CustomTextWidget(
              text: "Verantwortliche Person ",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            CustomTextWidget(text: item.responsiblePerson, fontSize: 14),
            SpacerWidget(height: 3),

            SpacerWidget(height: 3),

            CustomTextWidget(
              text: "Notizen",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            SeeMoreWidget(
              item.notes,
              textStyle: TextStyle(fontSize: 14, color: Colors.black),
              trimLength: 90,
              seeMoreStyle: TextStyle(
                  color: Color.fromARGB(255, 107, 69, 106),
                  fontWeight: FontWeight.bold),
              seeLessStyle: TextStyle(
                  color: Color.fromARGB(255, 107, 69, 106),
                  fontWeight: FontWeight.bold),
            ),
            SpacerWidget(height: 3),

            // CustomTextWidget(text: "Beschreibung", fontSize: 14, fontWeight: FontWeight.bold,),
            // SeeMoreWidget(item.description, textStyle: TextStyle(fontSize: 14, color: Colors.black), trimLength: 90,
            // seeMoreStyle: TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
            // seeLessStyle:  TextStyle(color: Color.fromARGB(255, 107, 69, 106), fontWeight:FontWeight.bold),
            //  ),
            //         FourSecretsDivider(),

            // CustomTextWidget(text: "Uhrzeit", fontSize: 14, fontWeight: FontWeight.bold,),

            // FourSecretsDivider(),
            // if (item.reminderTime != null) Divider(),
            SpacerWidget(height: 3),
            if (item.reminderTime != null)
              CustomTextWidget(
                text: "Erinnerung",
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),

            SpacerWidget(height: 2),
            if (item.reminderTime != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 10,
                children: [
                  Icon(FontAwesomeIcons.clock, size: 18),
                  CustomTextWidget(
                    text:
                        "${item.reminderTime!.hour.toString().padLeft(2, '0')}:${item.reminderTime!.minute.toString().padLeft(2, '0')} "
                        "${item.reminderTime!.hour >= 12 ? 'Uhr' : 'Uhr'}",
                    fontSize: 14,
                  ),
                  SizedBox(
                    height: 15,
                    child: VerticalDivider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    FontAwesomeIcons.calendar,
                    size: 18,
                  ),
                  CustomTextWidget(
                    text:
                        "${item.reminderTime!.day.toString().padLeft(2, '0')}-${item.reminderTime!.month.toString().padLeft(2, '0')}-${item.reminderTime!.year}",
                    fontSize: 14,
                  ),
                ],
              ),

            SpacerWidget(height: 3),

            CustomTextWidget(
              text: "Ort",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                height: context.screenHeight * 0.2,
                width: context.screenWidth,
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                      color: Colors.grey, blurRadius: 10, offset: Offset(10, 0))
                ]),
                child: GoogleMap(
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
            SpacerWidget(height: 4),
            CustomButtonWidget(
              width: context.screenWidth,
              color: Colors.red.shade300,
              textColor: Colors.white,
              text: "Löschen",
              isLoading: isDeleting,
              onPressed: () {
                setState(() {
                  isDeleting = true;
                });
                weddingDayScheduleService.deleteScheduleItem(item.id!);
                loadData();
                setState(() {
                  isDeleting = false;
                });
              },
            ),
            SpacerWidget(height: 1),
          ]),
    );
  }
}
