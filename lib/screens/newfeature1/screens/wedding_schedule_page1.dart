import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/pdf/share_single_pdf1.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/pdf/shcedule_pdf1.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:four_secrets_wedding_app/pages/PdfViewPage.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/native_download_service.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/wedding_day_schedule_service1.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/widgets/swipeable_item_widget1.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WeddingSchedulePage1 extends StatefulWidget {
  const WeddingSchedulePage1({super.key});

  @override
  State<WeddingSchedulePage1> createState() => _WeddingSchedulePage1State();
}

class _WeddingSchedulePage1State extends State<WeddingSchedulePage1> {
  final key = GlobalKey<MenueState>();
  late GoogleMapController _mapController;

  WeddingDayScheduleModel1? weddingDayScheduleModel;
  bool _isFirstLoad = true;
  bool isDeleting = false;
  bool isLoading = false;
  WeddingDayScheduleService1 weddingDayScheduleService =
      WeddingDayScheduleService1();
  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Checks if items have been manually reordered by looking for
  /// order values that don't match the timestamp-based order
  bool _hasManualReordering(List<WeddingDayScheduleModel1> items) {
    if (items.length <= 1) return false;

    // Check for problematic order values (all items have the same order)
    final uniqueOrders = items.map((item) => item.order).toSet();
    if (uniqueOrders.length == 1 && uniqueOrders.first == 0) {
      print("Problematic order values detected: all items have order 0");
      return false; // Use timestamp sorting
    }

    // Check if items are using manual ordering (small sequential numbers)
    final hasSmallOrders = items.any((item) => item.order < 1000);
    if (hasSmallOrders) {
      // Verify if this is valid manual ordering (sequential numbers)

      final sortedByOrder = List<WeddingDayScheduleModel1>.from(items)
        ..sort((a, b) => a.order.compareTo(b.order));

      // Check if orders are sequential or at least unique

      final orders = sortedByOrder.map((item) => item.order).toList();

      final hasUniqueOrders = orders.toSet().length == orders.length;

      if (hasUniqueOrders) {
        print("Valid manual reordering detected (sequential order values)");

        return true;
      }
    }

    // Additional check: if items are not in chronological order by their order field
    final sortedByOrder = List<WeddingDayScheduleModel1>.from(items)
      ..sort((a, b) => a.order.compareTo(b.order));

    for (int i = 0; i < sortedByOrder.length - 1; i++) {
      final current = sortedByOrder[i];
      final next = sortedByOrder[i + 1];

      // If a later item in order has an earlier time, manual reordering occurred
      if (current.time.isAfter(next.time)) {
        print(
            "Manual reordering detected: chronological order doesn't match order field");
        return true;
      }
    }

    return false;
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
      print('🔵 ===== WEDDING SCHEDULE DOWNLOAD STARTED =====');

      // Use the same sorting logic as the main list display
      final sortedScheduleList = List<WeddingDayScheduleModel1>.from(
          weddingDayScheduleService.weddingDayScheduleList);

      // Check if items have been manually reordered (same logic as service)
      final hasManualOrder = _hasManualReordering(sortedScheduleList);

      if (hasManualOrder) {
        // Use manual order (sort by order field)
        sortedScheduleList.sort((a, b) => a.order.compareTo(b.order));
        print(
            "🔵 PDF Download: Using manual order (items have been reordered)");
      } else {
        // Sort by date/time in ascending order (default behavior)
        sortedScheduleList.sort((a, b) {
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
          return aDateTime.compareTo(bDateTime); // Ascending order
        });
        print("🔵 PDF Download: Applied automatic date/time ascending sort");
      }

      print('🔵 Schedule list length: ${sortedScheduleList.length}');

      print('🔵 Generating PDF bytes...');
      final pdfBytes =
          await generateWeddingSchedulePdfBytes1(sortedScheduleList);
      print('🔵 PDF bytes generated: ${pdfBytes.length} bytes');

      final filename = NativeDownloadService.generateTimestampedFilename(
          'Eigene Dienstleister');
      print('🔵 Generated filename: $filename');

      // Use native download service
      print('🔵 Calling native download service...');
      final result = await NativeDownloadService.downloadPdf(
        context: context,
        pdfBytes: pdfBytes,
        filename: filename,
        successMessage: 'Eigene Dienstleister PDF erfolgreich heruntergeladen',
      );

      print('🔵 Download result: $result');

      // After successful download, also trigger share intent
      if (result == true && mounted) {
        try {
          print('🔵 Triggering share intent...');
          await _sharePdfFile(pdfBytes, filename);
        } catch (shareError) {
          print('🔴 Error sharing PDF: $shareError');
          // Don't show error to user as download was successful
        }
      }
    } catch (e) {
      print('🔴 Error in _downloadWeddingSchedulePdf: $e');
      print('🔴 Stack trace: ${StackTrace.current}');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, 'Fehler beim Herunterladen: $e');
      }
    }
  }

  /// Share PDF file using the share intent
  Future<void> _sharePdfFile(Uint8List pdfBytes, String filename) async {
    try {
      print('🔵 Creating temporary file for sharing...');

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');

      // Write PDF bytes to temporary file
      await tempFile.writeAsBytes(pdfBytes);
      print('🔵 Temporary file created: ${tempFile.path}');

      // Share the file using share_plus
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Eigene Dienstleister - 4secrets - Wedding Planner',
        subject: 'Eigene Dienstleister PDF',
      );

      print('🔵 Share intent triggered successfully');

      // Clean up temporary file after a delay to ensure sharing is complete
      Future.delayed(const Duration(seconds: 5), () {
        try {
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
            print('🔵 Temporary file cleaned up');
          }
        } catch (e) {
          print('🔴 Error cleaning up temporary file: $e');
        }
      });
    } catch (e) {
      print('🔴 Error in _sharePdfFile: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // backgroundColor: Colors.white,
        // resizeToAvoidBottomInset: false,
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: Text("Eigene Dienstleister"),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          actions: [
            IconButton(
                onPressed: () async {
                  try {
                    print('🔵 ===== PDF VIEW STARTED =====');

                    // Use the same sorting logic as the main list display
                    final sortedScheduleList =
                        List<WeddingDayScheduleModel1>.from(
                            weddingDayScheduleService.weddingDayScheduleList);

                    // Check if items have been manually reordered (same logic as service)
                    final hasManualOrder =
                        _hasManualReordering(sortedScheduleList);

                    if (hasManualOrder) {
                      // Use manual order (sort by order field)
                      sortedScheduleList
                          .sort((a, b) => a.order.compareTo(b.order));
                      print(
                          "🔵 PDF View: Using manual order (items have been reordered)");
                    } else {
                      // Sort by date/time in ascending order (default behavior)
                      sortedScheduleList.sort((a, b) {
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
                        return aDateTime
                            .compareTo(bDateTime); // Ascending order
                      });
                      print(
                          "🔵 PDF View: Applied automatic date/time ascending sort");
                    }

                    // Debug: Print order information for PDF view
                    for (int i = 0; i < sortedScheduleList.length; i++) {
                      final item = sortedScheduleList[i];
                      print(
                          '🔵 PDF View Item $i: "${item.title}" (order: ${item.order})');
                    }

                    print('🔵 Generating PDF bytes for view...');
                    // Step 2: Pass it to the PDF generator
                    final pdfBytes = await generateWeddingSchedulePdfBytes1(
                        sortedScheduleList);
                    print(
                        '🔵 PDF bytes generated successfully: ${pdfBytes.length} bytes');

                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PdfViewPage(
                            pdfBytes: pdfBytes,
                            title: 'Eigene Dienstleister',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    print('🔴 Error in PDF view: $e');
                    print('🔴 Stack trace: ${StackTrace.current}');
                    if (mounted) {
                      SnackBarHelper.showErrorSnackBar(
                          context, 'Fehler beim Anzeigen der PDF: $e');
                    }
                  }
                },
                icon: Icon(
                  FontAwesomeIcons.eye,
                  size: 18,
                )),
            IconButton(
                onPressed: () async {
                  try {
                    await _downloadWeddingSchedulePdf();
                  } catch (e) {
                    print('🔴 Error in download button: $e');
                    if (mounted) {
                      SnackBarHelper.showErrorSnackBar(
                          context, 'Fehler beim Herunterladen: $e');
                    }
                  }
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
                .pushNamed(RouteManager.addWedidngSchedulePage1, arguments: {
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
                "assets/images/eigene/eigene.jpg",
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
                                color: Colors.grey[600],
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
                            final list = List<WeddingDayScheduleModel1>.from(
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
                              margin:
                                  EdgeInsets.only(left: 4, top: 4, bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: SlidableItemWidget1(
                                    item: item,
                                    index: index,
                                    screenWidth: context.screenWidth,
                                    onShare: () async {
                                      try {
                                        print(
                                            '🔵 ===== SINGLE ITEM SHARE STARTED =====');
                                        print('🔵 Sharing item: ${item.title}');

                                        final pdfBytes =
                                            await generateSingleSchedulePdf1(
                                                item);
                                        print(
                                            '🔵 Single PDF bytes generated: ${pdfBytes.length} bytes');

                                        await Printing.sharePdf(
                                            bytes: pdfBytes,
                                            filename:
                                                'Eigene_Dienstleister_${item.title.replaceAll(' ', '_')}.pdf');
                                        print(
                                            '🔵 Single item share completed successfully');
                                      } catch (e) {
                                        print(
                                            '🔴 Error sharing single item: $e');
                                        print(
                                            '🔴 Stack trace: ${StackTrace.current}');
                                        if (mounted) {
                                          SnackBarHelper.showErrorSnackBar(
                                              context,
                                              'Fehler beim Teilen: $e');
                                        }
                                      }
                                    },
                                    onEdit: () {
                                      Navigator.of(context).pushNamed(
                                          RouteManager.addWedidngSchedulePage1,
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
            // if (weddingDayScheduleService.weddingDayScheduleList.isNotEmpty)
            FourSecretsDivider(),
            SpacerWidget(height: 18)
          ],
        ),
      ),
    );
  }
}
