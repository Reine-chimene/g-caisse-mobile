import 'package:flutter/material.dart';
import '../services/notchpay_service.dart';
import '../services/pdf_receipt_service.dart';

class BillPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BillPaymentScreen({super.key, required this.userData});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final _contractController = TextEditingController();
  final _amountController   = TextEditingController();

  String _selectedBill     = 'ENEO';
  String _selectedOperator = 'cm.mtn';
  bool   _isLoading        = false;

  @override
  void dispose() {
    _contractController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0.0;
  double get _fees   => _amount * 0.02;
  double get _total  => _amount + _fees;

  Color get _mainColor =>
      _selectedBill == 'ENEO' ? Colors.yellow.shade800 : Colors.blue.shade800;

  // ── CONFIRMATION ────────────────────────────────────────

  void _showConfirmationSheet() {
    if (_contractController.text.isEmpty || _amount < 500) {
      _showMsg("Veuillez remplir correctement les champs", Colors.red);
      return;
    }
    final balance =
        double.tryParse(widget.userData['balance']?.toString() ?? '0') ?? 0.0;
    if (_total > balance) {
      _showMsg("Solde insuffisant (${balance.toInt()} F) - Actualisez l'accueil",
          Colors.red);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Confirmation du Paiement",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow("Service", _selectedBill),
            _confirmRow("Référence contrat", _contractController.text),
            _confirmRow("Opérateur",
                _selectedOperator == 'cm.mtn' ? 'MTN MoMo' : 'Orange Money'),
            _confirmRow("Numéro Mobile Money",
                widget.userData['phone']?.toString() ?? ''),
            _confirmRow("Montant facture", "${_amount.toInt()} FCFA"),
            _confirmRow("Frais service (2%)", "${_fees.toInt()} FCFA"),
            const Divider(),
            _confirmRow("Total à débiter", "${_total.toInt()} FCFA",
                isTotal: true),
            const SizedBox(height: 16),
            // Info USSD
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Après validation, composez "
                      "${_selectedOperator == 'cm.mtn' ? '*126#' : '*150*3#'} "
                      "sur votre téléphone pour confirmer.",
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _handlePayment();
                },
                child: const Text("PAYER MAINTENANT",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: isTotal ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTotal ? 18 : 15,
                  color: isTotal ? Colors.black : Colors.grey[800])),
        ],
      ),
    );
  }

  // ── PAIEMENT ────────────────────────────────────────────

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      final res = await NotchPayService.payBill(
        context:        context,
        userId:         widget.userData['id'],
        contractNumber: _contractController.text,
        amount:         _amount,
        billType:       _selectedBill,
        phone:          widget.userData['phone']?.toString() ?? '',
        operator:       _selectedOperator,
      );
      if (!mounted) return;
      _showSuccessDialog(res);
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── DIALOGS ─────────────────────────────────────────────

  void _showSuccessDialog(Map transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Icon(Icons.verified, color: Colors.green, size: 70),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Paiement Réussi !",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "Votre facture $_selectedBill de ${_amount.toInt()} F a été réglée avec succès.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await PdfReceiptService.generateAndPrintReceipt(
                        Map<String, dynamic>.from(transaction));
                  },
                  child: const Text("TÉLÉCHARGER LE REÇU PDF",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("TERMINER")),
            ],
          )
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Paiement $_selectedBill",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _mainColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sélecteur fournisseur ──
            const Text("Choisissez le fournisseur",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              children: [
                _billChip("ENEO", Icons.bolt, Colors.yellow.shade800),
                const SizedBox(width: 15),
                _billChip("CAMWATER", Icons.water_drop, Colors.blue.shade800),
              ],
            ),
            const SizedBox(height: 25),

            // ── Sélecteur opérateur ──
            const Text("Opérateur Mobile Money",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _operatorChip("cm.mtn", "MTN MoMo", 'assets/logo_mtn.jpg',
                    Colors.yellow.shade700),
                const SizedBox(width: 15),
                _operatorChip("cm.orange", "Orange Money",
                    'assets/logo_orange.jpg', Colors.orange),
              ],
            ),
            const SizedBox(height: 25),

            // ── Numéro de contrat ──
            TextField(
              controller: _contractController,
              decoration: InputDecoration(
                labelText: _selectedBill == 'ENEO'
                    ? "Numéro de Contrat / Compteur"
                    : "Numéro de Police / Client",
                prefixIcon: Icon(Icons.receipt_long, color: _mainColor),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _mainColor, width: 2),
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Montant ──
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Montant à régler",
                prefixIcon:
                    Icon(Icons.monetization_on_outlined, color: _mainColor),
                suffixText: "FCFA",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _mainColor, width: 2),
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 25),

            _buildPricingCard(),
            const SizedBox(height: 16),

            // Info USSD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.dialpad_rounded,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedOperator == 'cm.mtn'
                          ? "Le paiement sera confirmé via *126# (MTN MoMo)"
                          : "Le paiement sera confirmé via *150*3# (Orange Money)",
                      style: TextStyle(
                          color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _showConfirmationSheet,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("VALIDER LE PAIEMENT",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS ──────────────────────────────────────────────

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
          _summaryRow("Frais service (2%)", "+ ${_fees.toInt()} F",
              color: Colors.orange),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          _summaryRow("TOTAL DÉBITÉ", "${_total.toInt()} F", bold: true),
        ],
      ),
    );
  }

  Widget _billChip(String name, IconData icon, Color color) {
    final isSel = _selectedBill == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedBill = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? color : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 1.5),
          boxShadow: isSel
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? Colors.white : color, size: 22),
            const SizedBox(width: 10),
            Text(name,
                style: TextStyle(
                    color: isSel ? Colors.white : color,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _operatorChip(
      String value, String label, String logoPath, Color color) {
    final isSel = _selectedOperator == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedOperator = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSel ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isSel ? color : Colors.grey.shade300, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(logoPath,
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.phone_android, color: color)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSel ? color : Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {Color color = Colors.black, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 18 : 14)),
      ],
    );
  }

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));
}
