import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:marcket_app/models/order.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generatePaymentTicketPdf(Order order) async {
  final pdf = pw.Document();

  // Load app logo
  final ByteData bytes = await rootBundle.load('assets/images/logoapp.jpg');
  final Uint8List logoBytes = bytes.buffer.asUint8List();

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80, // A common format for receipts
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Image(pw.MemoryImage(logoBytes), height: 50),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'RECIBO DE COMPRA',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Divider(),
            pw.Text('ID del Pedido: ${order.id}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Fecha: ${dateFormat.format(order.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('Productos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.TableHelper.fromTextArray(
              headers: ['Producto', 'Cant.', 'P. Unit.', 'Total'],
              data: order.items.map((item) {
                return [
                  item.name,
                  item.quantity.toString(),
                  '${item.price.toStringAsFixed(2)} \$',
                  '${(item.price * item.quantity).toStringAsFixed(2)} \$',
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('${order.totalPrice.toStringAsFixed(2)} \$', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Center(
              child: pw.Text(
                '¡Gracias por tu compra!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
