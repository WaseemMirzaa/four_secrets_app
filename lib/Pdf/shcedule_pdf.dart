


import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';

/// Generates a PDF document for table management.
/// Takes a list of tables and a map of table IDs to their assigned guests.
/// Creates a PDF with table details, guest lists, and summary statistics.
Future<void> generateTableWeddingPdf(
  List<WeddingDayScheduleModel> weddingSchedule,
) async {
  final pdf = pw.Document();
  final logoPath = 'assets/images/logo/secrets-logo.jpg'; // Path to your logo
  final logoClock = 'assets/images/logo/time.png'; // Path to your logo
  final logoCalendar = 'assets/images/logo/calendar.png'; // Path to your logo
  final ByteData bytes = await rootBundle.load(logoPath);
  final ByteData logoClockByte = await rootBundle.load(logoClock);
  final ByteData logoCalendarbyte = await rootBundle.load(logoCalendar);
  final Uint8List imageData = bytes.buffer.asUint8List();
  final Uint8List logoClockData = logoClockByte.buffer.asUint8List();
  final Uint8List logoCalendarLogo = logoCalendarbyte.buffer.asUint8List();
  final logo = pw.MemoryImage(imageData);
  final logoClockk = pw.MemoryImage(logoClockData);
  final logoCalendarIcon = pw.MemoryImage(logoCalendarLogo);
  // final divider = 'assets/images/logo/secrets-logo.jpg'; // Path to your logo
  // final ByteData bytes = await rootBundle.load(logoPath);
  // final Uint8List imageData = bytes.buffer.asUint8List();
  // final logo = pw.MemoryImage(imageData);

  pdf.addPage(
    pw.MultiPage(
      margin: pw.EdgeInsets.only(top: 0, ),
       header: (pw.Context context) {
      if (context.pageNumber == 1) {
        return pw.SizedBox(height: 0); // No header on the first page
      } else {
        return pw.SizedBox(height: 60); // 20-unit top margin on subsequent pages
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
                pw.SizedBox(
                  width: 10
                ),
                pw.ClipRRect(
                  verticalRadius: 20,
                  horizontalRadius: 20,
                  child:  pw.Image(
              logo,
              width: 160,
              height: 100,
            ),
                ),
             

              ])
            ),

            pw.Padding(padding:  pw.EdgeInsets.symmetric(horizontal: 30, vertical: 20,),  
            child: 
            pw.Text('Tagesablauf', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),),
            pw.SizedBox(height: 20),
            for (var table in weddingSchedule)
             pw.Padding(padding:  pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10) , 
             child: 
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(AppConstants.weddingSchedulePageTitle, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                  
                  pw.Text(table.title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal)),
                    pw.SizedBox(height: 5),

                  pw.Text("Datum", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                  
                 pw.Row(
                  children: [
                   
                    pw.SizedBox(width: 5),
                   pw.Image(
                     logoClockk ,// Unicode for clock icon in Material Icons
                       // Unicode for calendar icon in Material Icons
                      
                     height: 20, 
                     width: 20
                    ),
                    pw.SizedBox(width: 5),
                     pw.Text(
                        '${table.time.hour.toString().padLeft(2, '0')}:${table.time.minute.toString().padLeft(2, '0')} Uhr'

                     ),
                  ]
                 ),
                    pw.SizedBox(height: 5),

                   pw.Row(
                  children: [
                   
                    pw.SizedBox(width: 5),
                    pw.Image(
                     logoCalendarIcon ,// Unicode for clock icon in Material Icons
                       // Unicode for calendar icon in Material Icons
                      
                     height: 20, 
                     width: 20
                    ),
                    pw.SizedBox(width: 5),
                     pw.Text('${table.time.day}-${table.time.month.toString().padLeft(2, '0' )}-${table.time.year} '  ),
                  ]
                 ),
                    pw.SizedBox(height: 5),

                  pw.Text('Notizen',style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${table.notes}'),
                // pw.Row(
                //   children: [

                //   ]
                // ),
                    pw.SizedBox(height: 5),


                  pw.Text('Verantwortliche Person',style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(table.responsiblePerson),
                    pw.SizedBox(height: 5),

                  pw.Text('Ort',style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(table.address),


                
              
             
            pw.SizedBox(height: 20),
            // pw.Padding(padding:pw.EdgeInsets.symmetric(horizontal: 30, vertical: 6), 
            // child: 
            // pw.Text('Gesamttische: ${tables.length}'),),
            //  pw.Padding(padding:pw.EdgeInsets.symmetric(horizontal: 30, vertical: 6), 
            // child: 
            // pw.Text('Gesamt zugewiesene Gäste: ${_getTotalAssignedGuests(tableGuestsMap)}'),),
          ],
        )
             )
          ]
        )
      
        ];
             
      }
    ),
  );

  Printing.layoutPdf(
   
    onLayout: (PdfPageFormat format) async {
    
      return pdf.save();
    },
    forceCustomPrintPaper: true
  );

  // await Printing.sharePdf(bytes: await pdf.save(), filename: 'tischverwaltung.pdf');
}