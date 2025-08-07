import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/Pdf/share_single_pdf.dart';
import 'package:four_secrets_wedding_app/Pdf/shcedule_pdf.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/pages/PdfViewPage.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/native_download_service.dart';
import 'package:four_secrets_wedding_app/services/wedding_day_schedule_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/widgets/swipeable_item_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

  /// Checks if items have been manually reordered by looking for
  /// order values that don't match the timestamp-based order
  bool _hasManualReordering(List<WeddingDayScheduleModel> items) {
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
      final sortedByOrder = List<WeddingDayScheduleModel>.from(items)
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
    final sortedByOrder = List<WeddingDayScheduleModel>.from(items)
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

  Future<void> _downloadWeddingSchedulePdf() async {
    try {
      print('🔵 ===== WEDDING SCHEDULE DOWNLOAD STARTED =====');

      // Use the same sorting logic as the main list display
      final sortedScheduleList = List<WeddingDayScheduleModel>.from(
          weddingDayScheduleService.weddingDayScheduleList
              .where((e) => e.time != null));

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
          await generateWeddingSchedulePdfBytes(sortedScheduleList);

      print('🔵 PDF bytes generated: ${pdfBytes.length} bytes');

      final filename =
          NativeDownloadService.generateTimestampedFilename('Tagesablauf');

      print('🔵 Generated filename: $filename');

      // Use native download service
      print('🔵 Calling native download service...');

      final result = await NativeDownloadService.downloadPdf(
        context: context,
        pdfBytes: pdfBytes,
        filename: filename,
        successMessage: 'Tagesablauf PDF erfolgreich heruntergeladen',
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
        text: 'Tagesablauf - 4secrets - Wedding Planner',
        subject: 'Tagesablauf PDF',
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

  /// Simple test download function to verify download functionality
  Future<void> _testDownload() async {
    try {
      print('🔵 ===== TEST DOWNLOAD STARTED =====');

      // Create a simple test PDF content
      final testContent = 'Test PDF Content - ${DateTime.now()}';
      final testBytes = Uint8List.fromList(testContent.codeUnits);
      final filename =
          'test_download_${DateTime.now().millisecondsSinceEpoch}.txt';

      print('🔵 Test file: $filename');
      print('🔵 Test content length: ${testBytes.length} bytes');

      // Use native download service
      final result = await NativeDownloadService.downloadPdf(
        context: context,
        pdfBytes: testBytes,
        filename: filename,
        successMessage: 'Test download completed',
      );

      print('🔵 Test download result: $result');
    } catch (e) {
      print('🔴 Error in test download: $e');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(context, 'Test download failed: $e');
      }
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
          title: Text(AppConstants.weddingAddPageTitle),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          actions: [
            IconButton(
                onPressed: () async {
                  // Use the same sorting logic as the main list display
                  final sortedScheduleList = List<WeddingDayScheduleModel>.from(
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
                      return aDateTime.compareTo(bDateTime); // Ascending order
                    });
                    print(
                        "🔵 PDF View: Applied automatic date/time ascending sort");
                  }

                  // Step 2: Pass it to the PDF generator
                  final pdfBytes =
                      await generateWeddingSchedulePdfBytes(sortedScheduleList);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PdfViewPage(
                        pdfBytes: pdfBytes,
                        title: 'Tagesablauf',
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
                    ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Center(
                                child: CustomTextWidget(
                                    textAlign: TextAlign.center,
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    text:
                                        "Noch Keine Punkte hinzugefügt. Tippe auf das + Symbol unten rechts.")),
                          ),
                          FourSecretsDivider()
                        ],
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
                              margin:
                                  EdgeInsets.only(bottom: 4, top: 4, left: 4),
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
