import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helper function to create consistent header
pw.Widget _buildHeaderOriginal(pw.MemoryImage logo) {
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
        child: pw.Text('Tagesablauf',
            style: pw.TextStyle(
                fontSize: 24,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold)),
      ),
    ]),
  );
}

Future<Uint8List> generateWeddingSchedulePdfBytes(
    List<WeddingDayScheduleModel> weddingSchedule) async {
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

  // Create a single MultiPage with all items and consistent header
  pdf.addPage(
    pw.MultiPage(
      margin: pw.EdgeInsets.only(top: 0),
      header: (pw.Context context) {
        // Show header on every page
        return _buildHeaderOriginal(logo);
      },
      build: (pw.Context context) {
        List<pw.Widget> widgets = [];

        // Add spacing after header on first page
        widgets.add(pw.SizedBox(height: 10));

        // Add all schedule items with 20pt spacing between them
        for (int i = 0; i < weddingSchedule.length; i++) {
          final table = weddingSchedule[i];

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
                  pw.Text(table.title,
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
                        '${table.time.hour.toString().padLeft(2, '0')}:${table.time.minute.toString().padLeft(2, '0')} Uhr'),
                  ]),
                  pw.SizedBox(height: 5),
                  pw.Row(children: [
                    pw.SizedBox(width: 5),
                    pw.Image(logoCalendarIcon, height: 20, width: 20),
                    pw.SizedBox(width: 5),
                    pw.Text(
                        '${table.time.day.toString().padLeft(2, '0')}.${table.time.month.toString().padLeft(2, '0')}.${table.time.year}'),
                  ]),

                  // Only show fields that have content
                  if (table.notes.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Notizen',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(table.notes),
                  ],

                  if (table.responsiblePerson.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Zuständige Person',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(table.responsiblePerson),
                  ],

                  if (table.address.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text('Ort',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(table.address),
                  ],
                ],
              ),
            ),
          );

          // Add 20pt spacing between items (except after the last item)
          if (i < weddingSchedule.length - 1) {
            widgets.add(pw.SizedBox(height: 20));
          }
        }

        return widgets;
      },
    ),
  );

  return pdf.save();
}
