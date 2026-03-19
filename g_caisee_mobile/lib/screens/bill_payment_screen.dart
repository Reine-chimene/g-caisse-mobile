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

  @override
  void dispose() {
    _contractController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Calcul dynamique
  double get _amount => double.tryParse(_amountController.text) ?? 0.0;
  double get _fees => _amount * 0.02;
  double get _total => _amount + _fees;

  // 1. LA NOUVELLE BOTTOM SHEET DE CONFIRMATION
  void _showConfirmationSheet() {
    if (_contractController.text.isEmpty || _amount < 500) {
      _showMsg("Veuillez remplir correctement les champs", Colors.red);
      return;
    }

    // Vérification du solde avant même d'ouvrir la confirmation
    double balance = double.tryParse(widget.userData['balance'].toString()) ?? 0;
    if (_total > balance) {
      _showMsg("Solde insuffisant (${balance.toInt()} F)", Colors.red);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Confirmation du Paiement", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow("Service", _selectedBill),
            _confirmRow("Référence", _contractController.text),
            _confirmRow("Montant facture", "${_amount.toInt()} FCFA"),
            _confirmRow("Frais service", "${_fees.toInt()} FCFA"),
            const Divider(),
            _confirmRow("Total à débiter", "${_total.toInt()} FCFA", isTotal: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedBill == 'ENEO' ? Colors.yellow.shade800 : Colors.blue.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Fermer la sheet
                  _handlePayment(); // Lancer l'API
                },
                child: const Text("PAYER MAINTENANT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: isTotal ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 15, color: isTotal ? Colors.black : Colors.grey[800])),
        ],
      ),
    );
  }

  // 2. LOGIQUE DE PAIEMENT MISE À JOUR
  void _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.payBill(
        userId: widget.userData['id'],
        contractNumber: _contractController.text,
        amount: _amount,
        billType: _selectedBill,
      );

      if (!mounted) return;

      _showSuccessDialog(
        "Paiement Réussi", 
        "Votre facture $_selectedBill de ${_amount.toInt()} F a été réglée avec succès.",
        res 
      );
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceFirst("Exception: ", ""), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color mainCol = _selectedBill == 'ENEO' ? Colors.yellow.shade800 : Colors.blue.shade800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Paiement $_selectedBill", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: mainCol,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choisissez le fournisseur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              children: [
                _billChip("ENEO", Icons.bolt, Colors.yellow.shade800),
                const SizedBox(width: 15),
                _billChip("CAMWATER", Icons.water_drop, Colors.blue.shade800),
              ],
            ),
            const SizedBox(height: 35),
            
            TextField(
              controller: _contractController,
              decoration: InputDecoration(
                labelText: _selectedBill == 'ENEO' ? "Numéro de Contrat / Compteur" : "Numéro de Police / Client",
                prefixIcon: Icon(Icons.receipt_long, color: mainCol),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: mainCol, width: 2), borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Montant à régler",
                prefixIcon: Icon(Icons.monetization_on_outlined, color: mainCol),
                suffixText: "FCFA",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: mainCol, width: 2), borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 30),

            _buildPricingCard(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainCol,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _showConfirmationSheet, // On appelle la sheet ici
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("VALIDER LE PAIEMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _summaryRow("Montant net", "${_amount.toInt()} F"),
          _summaryRow("Frais service (2%)", "+ ${_fees.toInt()} F", color: Colors.orange),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          _summaryRow("TOTAL DÉBITÉ", "${_total.toInt()} F", bold: true),
        ],
      ),
    );
  }

  Widget _billChip(String name, IconData icon, Color color) {
    bool isSel = _selectedBill == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedBill = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? color : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 1.5),
          boxShadow: isSel ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? Colors.white : color, size: 22),
            const SizedBox(width: 10),
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

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  void _showSuccessDialog(String title, String content, Map<String, dynamic> resData) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Icon(Icons.verified, color: Colors.green, size: 70),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(content, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    Navigator.pop(c);
                    await PdfReceiptService.generateAndPrintReceipt(resData);
                  }, 
                  child: const Text("TÉLÉCHARGER LE REÇU PDF", style: TextStyle(color: Colors.white)),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(c), child: const Text("TERMINER")),
            ],
          )
        ],
      )
    );
  }
}