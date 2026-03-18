import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Pour QR flutter sur Flutter
import 'dart:ui' as ui;

class PdfReceiptService {
  static Future<void> generateAndPrintReceipt(Map<String, dynamic> txData) async {
    final pdf = pw.Document();

    // Chargement du logo (Assure-toi d'avoir un logo blanc dans tes assets)
    final logoImage = pw.MemoryImage((await rootBundle.load('assets/logo_gcaisse.png')).buffer.asUint8List());

    // Génération du QR Code (Validation juridique)
    final qrValidationLink = "https://g-caise.cm/verify/${txData['id']}";
    final qrCodeImage = await _generateQrCode(qrValidationLink);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER (Logo + Nom)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 80),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text("G-CAISE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text("Reçu de Transaction Officiel", style: pw.TextStyle(color: PdfColors.grey700)),
                  ]),
                ],
              ),
              pw.Divider(color: PdfColors.grey),
              pw.SizedBox(height: 30),

              // INFOS REÇU
              pw.Text("DÉTAILS DU REÇU", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              _receiptRow("Numéro de reçu :", "GC-${txData['id']}"),
              _receiptRow("Date :", txData['created_at'].toString()),
              _receiptRow("Client :", txData['fullname']),
              _receiptRow("Type de service :", txData['description'].toString().toUpperCase()),
              pw.SizedBox(height: 30),

              // RÉCAPITULATIF FINANCIER (Effet PRO)
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))),
                child: pw.Column(children: [
                  _receiptRow("Montant Principal :", "${(txData['amount'] / 1.02).toInt()} FCFA", isBold: true),
                  _receiptRow("Frais G-CAISE (2%) :", "${(txData['amount'] * 0.02).toInt()} FCFA", isFee: true),
                  pw.Divider(),
                  _receiptRow("TOTAL PAYÉ :", "${txData['amount'].toInt()} FCFA", isBold: true, isTotal: true),
                ]),
              ),
              pw.Spacer(),

              // FOOTER (QR CODE & Légalité)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("Validé numériquement par G-CAISE CM", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("En cas de litige, présentez ce reçu en agence.", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ]),
                  // QR CODE DE VALIDATION
                  pw.Image(pw.MemoryImage(qrCodeImage), width: 70),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Lance l'aperçu et l'impression (Génère le PDF en mémoire)
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _receiptRow(String label, String value, {bool isBold = false, bool isFee = false, bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: isFee ? PdfColors.orange : (isTotal ? PdfColors.blue : PdfColors.black), fontSize: isTotal ? 16 : 12)),
        ],
      ),
    );
  }

  // Génère l'image du QR Code pour l'insérer dans le PDF
  static Future<Uint8List> _generateQrCode(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      errorCorrectionLevel: QrErrorCorrectLevel.Q,
    );
    final imageData = await painter.toImageData(200);
    return imageData!.buffer.asUint8List();
  }
}