import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/pdf_receipt_service.dart';

class BillPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BillPaymentScreen({super.key, required this.userData});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final _contractController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedBill = 'ENEO';
  bool _isLoading = false;

  // Calcul dynamique
  double get _amount => double.tryParse(_amountController.text) ?? 0.0;
  double get _fees => _amount * 0.02;
  double get _total => _amount + _fees;

  void _handlePayment() async {
    if (_contractController.text.isEmpty || _amount < 500) {
      _showMsg("Veuillez entrer un numéro de contrat et un montant (min 500F)", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.payBill(
        userId: widget.userData['id'],
        contractNumber: _contractController.text,
        amount: _amount,
        billType: _selectedBill,
      );

      _showSuccessDialog(
        "Paiement Réussi", 
        "Votre facture $_selectedBill de ${_amount.toInt()} F a été réglée avec succès.",
        res // On passe les données reçues pour le PDF
      );
    } catch (e) {
      _showMsg(e.toString().replaceFirst("Exception: ", ""), Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color mainCol = _selectedBill == 'ENEO' ? Colors.yellow.shade800 : Colors.blue.shade800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Factures $_selectedBill", style: const TextStyle(color: Colors.white)),
        backgroundColor: mainCol,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Type de facture", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              children: [
                _billChip("ENEO", Icons.lightbulb_outline, Colors.yellow.shade800),
                const SizedBox(width: 15),
                _billChip("CAMWATER", Icons.water_drop_outlined, Colors.blue.shade800),
              ],
            ),
            const SizedBox(height: 30),
            
            TextField(
              controller: _contractController,
              decoration: InputDecoration(
                labelText: _selectedBill == 'ENEO' ? "Numéro de Compteur / Contrat" : "Numéro de Police",
                prefixIcon: Icon(Icons.receipt_long, color: mainCol),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Montant à payer",
                prefixIcon: Icon(Icons.payments_outlined, color: mainCol),
                suffixText: "FCFA",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 25),

            // RÉCAPITULATIF AVEC TES 2%
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _summaryRow("Montant Facture", "${_amount.toInt()} F"),
                  _summaryRow("Frais G-CAISE (2%)", "+ ${_fees.toInt()} F", color: Colors.orange),
                  const Divider(height: 25),
                  _summaryRow("TOTAL À DÉDUIRE", "${_total.toInt()} F", bold: true),
                ],
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainCol,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _handlePayment,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("CONFIRMER LE PAIEMENT", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billChip(String name, IconData icon, Color color) {
    bool isSel = _selectedBill == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedBill = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? Colors.white : color, size: 20),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(color: isSel ? Colors.white : color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color color = Colors.black, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
      ],
    );
  }

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  void _showSuccessDialog(String title, String content, Map<String, dynamic> resData) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 10),
          Text(title)
        ]),
        content: Text(content, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(c);
              // Lancement de la génération du reçu PDF
              await PdfReceiptService.generateAndPrintReceipt(resData);
            }, 
            child: const Text("VOIR LE REÇU PDF", style: TextStyle(fontWeight: FontWeight.bold))
          ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("FERMER")),
        ],
      )
    );
  }
}