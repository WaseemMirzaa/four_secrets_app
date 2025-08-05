import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

/// Helper function to fetch attachment from URL
Future<Uint8List?> _fetchAttachment(String url) async {
  try {
    print('🔵 Fetching attachment from: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print(
          '🔵 Successfully fetched attachment: ${response.bodyBytes.length} bytes');
      return response.bodyBytes;
    } else {
      print('🔴 Failed to fetch attachment: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('🔴 Error fetching attachment: $e');
    return null;
  }
}

/// Helper function to determine if URL is an image
bool _isImageUrl(String url) {
  final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  final lowerUrl = url.toLowerCase();
  return imageExtensions.any((ext) => lowerUrl.contains(ext));
}

/// Helper function to determine if URL is a PDF
bool _isPdfUrl(String url) {
  return url.toLowerCase().contains('.pdf');
}

/// Helper function to create enhanced PDF attachment widget
pw.Widget _createPdfAttachmentWidget(
    Uint8List pdfBytes, String fileName, String fileUrl) {
  return pw.Container(
    width: double.infinity,
    margin: pw.EdgeInsets.symmetric(vertical: 10),
    padding: pw.EdgeInsets.all(15),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.blue300),
      borderRadius: pw.BorderRadius.circular(8),
      color: PdfColors.blue50,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 50,
              height: 50,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text('PDF',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ),
            ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PDF Anhang',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text(fileName,
                      style:
                          pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'Größe: ${(pdfBytes.length / 1024).toStringAsFixed(1)} KB',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('Download Link:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Text(fileUrl,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.blue)),
      ],
    ),
  );
}

/// Helper function to create consistent header
pw.Widget _buildHeader(pw.MemoryImage logo) {
  return pw.Container(
    color: PdfColor.fromInt(0xffFF6B456A),
    height: 80,
    width: double.maxFinite,
    child: pw.Row(children: [
      pw.SizedBox(width: 10),
      pw.ClipRRect(
        verticalRadius: 20,
        horizontalRadius: 20,
        child: pw.Image(
          logo,
          width: 140,
          height: 60,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: pw.Text('Eigene Dienstleister',
            style: pw.TextStyle(
                fontSize: 24,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold)),
      ),
    ]),
  );
}

Future<Uint8List> generateWeddingSchedulePdfBytes1(
    List<WeddingDayScheduleModel1> weddingScheduleList) async {
  print('🔵 ===== MULTI PDF GENERATION STARTED =====');
  print('🔵 Generating PDF for ${weddingScheduleList.length} items');

  final pdf = pw.Document();
  final logoPath = 'assets/images/logo/secrets-logo.jpg';
  final logoClock = 'assets/images/logo/time.png';
  final logoCalendar = 'assets/images/logo/calendar.png';
  final ByteData bytes = await rootBundle.load(logoPath);
  final ByteData logoClockByte = await rootBundle.load(logoClock);
  final ByteData logoCalendarbyte = await rootBundle.load(logoCalendar);
  final Uint8List imageData = bytes.buffer.asUint8List();
  final Uint8List logoClockData = logoClockByte.buffer.asUint8List();
  final Uint8List logoCalendarLogo = logoCalendarbyte.buffer.asUint8List();
  final logo = pw.MemoryImage(imageData);
  final logoClockk = pw.MemoryImage(logoClockData);
  final logoCalendarIcon = pw.MemoryImage(logoCalendarLogo);

  // Pre-fetch all attachments
  Map<String, Uint8List?> attachmentCache = {};
  for (final item in weddingScheduleList) {
    if (item.angebotFileUrl.isNotEmpty) {
      print('🔵 Pre-fetching attachment for: ${item.title}');
      attachmentCache[item.id ?? ''] =
          await _fetchAttachment(item.angebotFileUrl);
    }
  }

  // Create a single MultiPage with all items and consistent header
  pdf.addPage(
    pw.MultiPage(
      margin: pw.EdgeInsets.only(top: 0),
      header: (pw.Context context) {
        // Show header on every page
        return _buildHeader(logo);
      },
      build: (pw.Context context) {
        List<pw.Widget> widgets = [];

        // Add spacing after header on first page
        widgets.add(pw.SizedBox(height: 10));

        // Add all schedule items with 20pt spacing between them
        for (int i = 0; i < weddingScheduleList.length; i++) {
          final weddingSchedule = weddingScheduleList[i];

          // Add the schedule item content
          widgets.add(
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(AppConstants.weddingSchedulePageTitle,
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(weddingSchedule.title,
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.normal)),
                  pw.SizedBox(height: 5),
                  pw.Text("Datum & Zeit",
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Row(children: [
                    pw.SizedBox(width: 5),
                    pw.Image(logoClockk, height: 20, width: 20),
                    pw.SizedBox(width: 5),
                    pw.Text(
                        '${weddingSchedule.time.hour.toString().padLeft(2, '0')}:${weddingSchedule.time.minute.toString().padLeft(2, '0')} Uhr'),
                  ]),
                  pw.SizedBox(height: 5),
                  pw.Row(children: [
                    pw.SizedBox(width: 5),
                    pw.Image(logoCalendarIcon, height: 20, width: 20),
                    pw.SizedBox(width: 5),
                    pw.Text(
                        '${weddingSchedule.time.day.toString().padLeft(2, '0')}.${weddingSchedule.time.month.toString().padLeft(2, '0')}.${weddingSchedule.time.year}'),
                  ]),

                  // Only show fields that have content
                  if (weddingSchedule.notes.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Notizen',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.notes),
                  ],

                  if (weddingSchedule.responsiblePerson.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Zuständige Person',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.responsiblePerson),
                  ],

                  if (weddingSchedule.address.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Ort',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.address),
                  ],

                  // Service Provider Details
                  if (weddingSchedule.dienstleistername.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Dienstleistername',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.dienstleistername),
                  ],
                  if (weddingSchedule.kontaktperson.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Kontaktperson',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.kontaktperson),
                  ],
                  if (weddingSchedule.telefonnummer.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Telefonnummer',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.telefonnummer),
                  ],
                  if (weddingSchedule.email.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('E-Mail',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.email),
                  ],
                  if (weddingSchedule.homepage.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Homepage',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.homepage),
                  ],
                  if (weddingSchedule.instagram.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Instagram',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.instagram),
                  ],
                  if (weddingSchedule.addressDetails.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Adressdetails',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.addressDetails),
                  ],
                  if (weddingSchedule.angebotText.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Angebot',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.angebotText),
                  ],
                  if (weddingSchedule.angebotFileName.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Angebotsdatei',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.angebotFileName),
                  ],
                  if (weddingSchedule.zahlungsstatus.isNotEmpty &&
                      weddingSchedule.zahlungsstatus != 'Unbezahlt') ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Zahlungsstatus',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(weddingSchedule.zahlungsstatus,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                  if (weddingSchedule.probetermin != null) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Probetermin',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                        '${weddingSchedule.probetermin!.day.toString().padLeft(2, '0')}.${weddingSchedule.probetermin!.month.toString().padLeft(2, '0')}.${weddingSchedule.probetermin!.year} um ${weddingSchedule.probetermin!.hour.toString().padLeft(2, '0')}:${weddingSchedule.probetermin!.minute.toString().padLeft(2, '0')} Uhr'),
                  ],
                ],
              ),
            ),
          );

          // Add inline attachment if it exists
          if (weddingSchedule.angebotFileUrl.isNotEmpty) {
            final attachmentBytes = attachmentCache[weddingSchedule.id ?? ''];
            if (attachmentBytes != null) {
              widgets.add(pw.SizedBox(height: 10));
              widgets.add(
                pw.Padding(
                  padding:
                      pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Anhang',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('Dateiname: ${weddingSchedule.angebotFileName}',
                          style: pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 10),
                      // Build attachment widget based on type
                      if (_isImageUrl(weddingSchedule.angebotFileUrl))
                        pw.Container(
                          height: 300,
                          width: double.infinity,
                          child: pw.Center(
                            child: pw.Container(
                              constraints: pw.BoxConstraints(
                                maxHeight: 300,
                                maxWidth: 400,
                              ),
                              child: pw.Image(
                                pw.MemoryImage(attachmentBytes),
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      else if (_isPdfUrl(weddingSchedule.angebotFileUrl))
                        _createPdfAttachmentWidget(
                          attachmentBytes,
                          weddingSchedule.angebotFileName,
                          weddingSchedule.angebotFileUrl,
                        )
                      else
                        pw.Container(
                          height: 150,
                          width: double.infinity,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Center(
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: 40,
                                  height: 40,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.blue,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text('FILE',
                                        style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.white)),
                                  ),
                                ),
                                pw.SizedBox(width: 10),
                                pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Datei Anhang',
                                        style: pw.TextStyle(
                                            fontSize: 14,
                                            fontWeight: pw.FontWeight.bold)),
                                    pw.Text(
                                        '${weddingSchedule.angebotFileName}',
                                        style: pw.TextStyle(fontSize: 10)),
                                    pw.Text(
                                        'Größe: ${(attachmentBytes.length / 1024).toStringAsFixed(1)} KB',
                                        style: pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            } else {
              // Show error message for failed attachment
              widgets.add(pw.SizedBox(height: 10));
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 30),
                  child: pw.Container(
                    height: 100,
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text('⚠️ Anhang konnte nicht geladen werden',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red)),
                    ),
                  ),
                ),
              );
            }
          }

          // Add 20pt spacing between items (except after the last item)
          if (i < weddingScheduleList.length - 1) {
            widgets.add(pw.SizedBox(height: 20));
          }
        }

        return widgets;
      },
    ),
  );

  final pdfBytes = await pdf.save();
  print(
      '🔵 Multi PDF generation completed successfully: ${pdfBytes.length} bytes');
  print('🔵 ===== MULTI PDF GENERATION FINISHED =====');
  return pdfBytes;
}
