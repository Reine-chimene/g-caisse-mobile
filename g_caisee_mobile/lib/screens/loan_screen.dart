import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoanScreen extends StatefulWidget {
  final Map<String, dynamic>? userData; // On passe userData pour l'ID réel

  const LoanScreen({super.key, this.userData});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  // --- DESIGN SYSTEM ---
  final Color primaryColor = const Color(0xFFD4AF37); 
  final Color backgroundColor = const Color(0xFFF8F9FA); 
  final Color darkCard = const Color(0xFF1A1A2E);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  
  // Paramètres réels
  double maxLoan = 500000; 
  double fees = 2500; 
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMaxLoan();
  }

  // RÉEL : On récupère la capacité d'emprunt réelle via le score de confiance
  Future<void> _fetchMaxLoan() async {
    try {
      int userId = widget.userData?['id'] ?? 1;
      int score = await ApiService.getTrustScore(userId);
      setState(() {
        // Logique métier : 5000 FCFA de prêt possible par point de confiance
        maxLoan = score * 5000.0; 
      });
    } catch (e) {
      debugPrint("Erreur score: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("FINANCEMENT ÉTHIQUE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapacityCard(),
            const SizedBox(height: 35),
            const Text("Détails de la demande", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildCustomField(
              label: "Montant souhaité",
              controller: _amountController,
              hint: "Ex: 100,000",
              icon: Icons.account_balance_wallet_outlined,
              isNumber: true,
            ),
            const SizedBox(height: 20),
            _buildCustomField(
              label: "Motif ou Projet",
              controller: _purposeController,
              hint: "Expliquez l'usage des fonds...",
              icon: Icons.edit_note_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            _buildSummaryTable(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ÉLIGIBILITÉ MAXIMUM", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text("${maxLoan.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_moon_outlined, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                const Text("Finance Islamique : 0% Riba", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCustomField({required String label, required TextEditingController controller, required String hint, required IconData icon, bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryColor),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTable() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double total = amount > 0 ? amount + fees : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          _summaryRow("Principal", "${amount.toStringAsFixed(0)} FCFA"),
          const SizedBox(height: 12),
          _summaryRow("Frais de dossier", "${fees.toStringAsFixed(0)} FCFA"),
          const SizedBox(height: 12),
          _summaryRow("Taux de profit", "0%", isGreen: true),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total à rembourser", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text("${total.toStringAsFixed(0)} FCFA", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: isGreen ? Colors.green : Colors.black, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: isLoading ? null : _submitRealRequest,
        child: isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : const Text("SOUMETTRE LE DOSSIER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  // --- LOGIQUE RÉELLE (BACKEND) ---
  Future<void> _submitRealRequest() async {
    double amt = double.tryParse(_amountController.text) ?? 0;
    if (amt < 5000 || _purposeController.text.length < 5) {
      _showSnack("Veuillez remplir correctement les champs (min 5000 FCFA)", Colors.orange);
      return;
    }

    if (amt > maxLoan) {
      _showSnack("Le montant dépasse votre limite autorisée", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      int userId = widget.userData?['id'] ?? 1;
      await ApiService.requestIslamicLoan(userId, amt, _purposeController.text);
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showSnack("Serveur indisponible, réessayez plus tard", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Demande Enregistrée", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Notre comité d'éthique analyse votre dossier. Réponse sous 24h.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () { Navigator.pop(c); Navigator.pop(context); },
              child: const Text("RETOUR À L'ACCUEIL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}