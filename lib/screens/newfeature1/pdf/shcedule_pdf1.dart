import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateWeddingSchedulePdfBytes1(
    List<WeddingDayScheduleModel1> weddingSchedule) async {
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

  pdf.addPage(
    pw.MultiPage(
      margin: pw.EdgeInsets.only(top: 0),
      header: (pw.Context context) {
        if (context.pageNumber == 1) {
          return pw.SizedBox(height: 0);
        } else {
          return pw.SizedBox(height: 60);
        }
      },
      build: (pw.Context context) {
        return [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                color: PdfColor.fromInt(0xffFF6B456A),
                height: 140,
                width: double.maxFinite,
                child: pw.Row(children: [
                  pw.SizedBox(width: 10),
                  pw.ClipRRect(
                    verticalRadius: 20,
                    horizontalRadius: 20,
                    child: pw.Image(
                      logo,
                      width: 160,
                      height: 100,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Eigene Dienstleister',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Ihr perfekter Hochzeitstag1',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Zeitplan der Hochzeit1',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xffFF6B456A),
                ),
              ),
              pw.SizedBox(height: 20),
              ...weddingSchedule.map((item) {
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 20),
                  padding: pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xffFF6B456A),
                      width: 1,
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Image(logoClockk, width: 16, height: 16),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            "${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')} Uhr",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Image(logoCalendarIcon, width: 16, height: 16),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            "${item.time.day.toString().padLeft(2, '0')}.${item.time.month.toString().padLeft(2, '0')}.${item.time.year}",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        item.title,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xffFF6B456A),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Verantwortliche Person: ${item.responsiblePerson}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Notizen: ${item.notes}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Ort: ${item.address}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ];
      },
    ),
  );

  return pdf.save();
}
