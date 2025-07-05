import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/Pdf/share_single_pdf.dart';
import 'package:four_secrets_wedding_app/Pdf/shcedule_pdf.dart';
import 'package:four_secrets_wedding_app/services/native_download_service.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/wedding_day_schedule_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/widgets/swipeable_item_widget.dart';
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
  bool isLoading = false;
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
      isLoading = true;
    });
    weddingDayScheduleService.loadData().then((v) {
      setState(() {
        isLoading = false;
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
      final filename =
          NativeDownloadService.generateTimestampedFilename('Tagesablauf');

      // Use native download service
      await NativeDownloadService.downloadPdf(
        context: context,
        pdfBytes: pdfBytes,
        filename: filename,
        successMessage: 'Tagesablauf PDF erfolgreich heruntergeladen',
      );
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

            isLoading
                ? Center(child: CircularProgressIndicator())
                : weddingDayScheduleService.weddingDayScheduleList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Center(
                            child: CustomTextWidget(
                                textAlign: TextAlign.center,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                text:
                                    "Noch Keine Punkte hinzugefügt. Tippe auf das + Symbol unten rechts.")),
                      )
                    : SizedBox(
                        width: context.screenWidth,
                        child: ReorderableListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          buildDefaultDragHandles: false,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: weddingDayScheduleService
                              .weddingDayScheduleList.length,
                          onReorder: (oldIndex, newIndex) async {
                            final list = List<WeddingDayScheduleModel>.from(
                                weddingDayScheduleService
                                    .weddingDayScheduleList);
                            if (newIndex > oldIndex) newIndex--;
                            final item = list.removeAt(oldIndex);
                            list.insert(newIndex, item);

                            // Persist the new order in Firestore:
                            await weddingDayScheduleService
                                .updateOrderItemsList(list);

                            setState(() {
                              // Reflect the change immediately:
                              weddingDayScheduleService.weddingDayScheduleList =
                                  list;
                            });
                          },
                          itemBuilder: (context, index) {
                            final item = weddingDayScheduleService
                                .weddingDayScheduleList[index];
                            // Give each child a Unique Key from its ID:
                            return Container(
                              key: ValueKey(item.id),
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: SlidableItemWidget(
                                    item: item,
                                    index: index,
                                    screenWidth: context.screenWidth,
                                    onShare: () async {
                                      final pdfBytes =
                                          await generateSingleSchedulePdf(item);
                                      await Printing.sharePdf(
                                          bytes: pdfBytes,
                                          filename:
                                              'Zeitplan_der_Hochzeit.pdf');
                                    },
                                    onEdit: () {
                                      Navigator.of(context).pushNamed(
                                          RouteManager.addWedidngSchedulePage,
                                          arguments: {
                                            "weddingDayScheduleModel": item,
                                          });
                                    },
                                    onDelete: () async {
                                      var g = await showDialog(
                                          context: context,
                                          builder: (context) => StatefulBuilder(
                                                  builder:
                                                      (context, stateeBuilder) {
                                                return CustomDialog(
                                                    isLoading: isDeleting,
                                                    title: "Löschen",
                                                    message:
                                                        "Möchtest du diesen Punkt wirklich löschen?",
                                                    confirmText: "Löschen",
                                                    cancelText: "Abbrechen",
                                                    onConfirm: () async {
                                                      stateeBuilder(() {
                                                        isDeleting = true;
                                                      });
                                                      await weddingDayScheduleService
                                                          .deleteScheduleItem(
                                                              item.id!);
                                                      Navigator.of(context)
                                                          .pop(true);
                                                      stateeBuilder(() {
                                                        isDeleting = false;
                                                      });
                                                    },
                                                    onCancel: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    });
                                              }));
                                      if (g == true) {
                                        await loadData();
                                      }
                                    },
                                    isDeleting: isDeleting,
                                    onReload: () async {
                                      await loadData();
                                    },
                                  )),
                                  ReorderableDragStartListener(
                                    key: ValueKey(item.id),
                                    index: index,
                                    child: Icon(
                                      FontAwesomeIcons.gripVertical,
                                      size: 24,
                                      color: Color(0xFF6B456A),
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
}
