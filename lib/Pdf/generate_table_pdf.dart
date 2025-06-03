import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/models/table_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Determines the status of a guest based on their attendance flags.
/// Returns a string representing the guest's status in German:
/// - "Bestätigt" if the guest has confirmed attendance (takePart is true).
/// - "Vielleicht" if the guest might attend (mayBeTakePart is true).
/// - "Abgelehnt" if the guest has canceled (canceled is true).
/// - "Unbekannt" if none of the above conditions are met.
String _getGuestStatus(Map<String, dynamic> guest) {
  if (guest['takePart'] == true) {
    return 'Bestätigt';
  } else if (guest['mayBeTakePart'] == true) {
    return 'Vielleicht';
  } else if (guest['canceled'] == true) {
    return 'Abgelehnt';
  }
  return 'Unbekannt';
}

/// Calculates the total number of guests assigned to all tables.
/// Iterates through the tableGuestsMap and sums the number of guests in each table's list.
/// Returns an integer representing the total count of assigned guests.
int _getTotalAssignedGuests(Map<String, List<Map<String, dynamic>>> tableGuestsMap) {
  return tableGuestsMap.values.fold(0, (int sum, List<Map<String, dynamic>> guests) => sum + guests.length);
}

/// Generates a PDF document for table management.
/// Takes a list of tables and a map of table IDs to their assigned guests.
/// Creates a PDF with table details, guest lists, and summary statistics.
Future<void> generateTableManagementPdf(
  List<TableModel> tables,
  Map<String, List<Map<String, dynamic>>> tableGuestsMap,
) async {
  final pdf = pw.Document();
  final logoPath = 'assets/images/logo/secrets-logo.jpg'; // Path to your logo
  final ByteData bytes = await rootBundle.load(logoPath);
  final Uint8List imageData = bytes.buffer.asUint8List();
  final logo = pw.MemoryImage(imageData);

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: 
               pw.Image(
              logo,
              width: 160,
              height: 100,
            ),
            ),
            pw.Text('Tischverwaltung', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            for (var table in tables)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(table.nameOrNumber, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Typ: ${table.tableType}'),
                  pw.Text('Max. Gäste: ${table.maxGuests}'),
                  pw.SizedBox(height: 5),
                  if (tableGuestsMap[table.id]?.isNotEmpty ?? false)
                    pw.TableHelper.fromTextArray(
                      headers: ['Gastname', 'Status'],
                      data: tableGuestsMap[table.id]!
                          .map((guest) => [
                                guest['name'],
                                _getGuestStatus(guest),
                              ])
                          .toList(),
                      border: pw.TableBorder.all(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      cellAlignment: pw.Alignment.centerLeft,
                    )
                  else
                    pw.Text('Keine Gäste zugewiesen'),
                  pw.SizedBox(height: 10),
                ],
              ),
            pw.SizedBox(height: 20),
            pw.Text('Gesamttische: ${tables.length}'),
            pw.Text('Gesamt zugewiesene Gäste: ${_getTotalAssignedGuests(tableGuestsMap)}'),
          ],
        );
      },
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