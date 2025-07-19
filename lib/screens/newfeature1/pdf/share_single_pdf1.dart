import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:printing/printing.dart';

/// Generates a PDF document for a single wedding day schedule.
/// Takes a single wedding day schedule model and creates a PDF with its details.
Future<Uint8List> generateSingleSchedulePdf1(
  WeddingDayScheduleModel1 weddingSchedule,
) async {
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
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                    color: PdfColor.fromInt(0xffFF6B456A),
                    height: 120,
                    width: double.maxFinite,
                    child: pw.Row(children: [
                      pw.SizedBox(width: 10),
                      pw.ClipRRect(
                        verticalRadius: 20,
                        horizontalRadius: 20,
                        child: pw.Image(
                          logo,
                          width: 140,
                          height: 80,
                        ),
                      ),
                      pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          child: pw.Text('Eigene Dienstleister',
                              style: pw.TextStyle(
                                  fontSize: 24,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold))),
                    ])),
                pw.SizedBox(height: 10),
                pw.Padding(
                    padding:
                        pw.EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(AppConstants.weddingSchedulePageTitle,
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(weddingSchedule.title,
                            style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.normal)),
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
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.notes),
                        ],

                        if (weddingSchedule.responsiblePerson.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Verantwortliche Person',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.responsiblePerson),
                        ],

                        if (weddingSchedule.address.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Ort',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.address),
                        ],

                        // Service Provider Details
                        if (weddingSchedule.dienstleistername.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Dienstleistername',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.dienstleistername),
                        ],
                        if (weddingSchedule.kontaktperson.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Kontaktperson',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.kontaktperson),
                        ],
                        if (weddingSchedule.telefonnummer.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Telefonnummer',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.telefonnummer),
                        ],
                        if (weddingSchedule.email.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('E-Mail',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.email),
                        ],
                        if (weddingSchedule.homepage.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Homepage',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.homepage),
                        ],
                        if (weddingSchedule.instagram.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Instagram',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.instagram),
                        ],
                        if (weddingSchedule.addressDetails.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Adresse Details',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.addressDetails),
                        ],
                        if (weddingSchedule.angebotText.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Angebot Beschreibung',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.angebotText),
                        ],
                        if (weddingSchedule.angebotFileName.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Angebot Datei',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.angebotFileName),
                        ],
                        if (weddingSchedule.zahlungsstatus.isNotEmpty &&
                            weddingSchedule.zahlungsstatus != 'Unbezahlt') ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Zahlungsstatus',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(weddingSchedule.zahlungsstatus,
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                        if (weddingSchedule.probetermin != null) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Probetermin',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              '${weddingSchedule.probetermin!.day.toString().padLeft(2, '0')}.${weddingSchedule.probetermin!.month.toString().padLeft(2, '0')}.${weddingSchedule.probetermin!.year} um ${weddingSchedule.probetermin!.hour.toString().padLeft(2, '0')}:${weddingSchedule.probetermin!.minute.toString().padLeft(2, '0')} Uhr'),
                        ],
                      ],
                    )),
              ],
            ),
          ];
        }),
  );

  return pdf.save();
}
