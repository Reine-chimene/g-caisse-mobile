import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  // --- COULEURS COHÉRENTES AVEC LE RESTE DE L'APP ---
  final Color primaryColor = const Color(0xFFD4AF37); // Doré G-Caisse
  final Color backgroundColor = const Color(0xFFF8F9FA); // Fond très clair
  final Color textColor = const Color(0xFF1A1A1A); // Texte sombre
  final Color fieldColor = const Color(0xFFF5F6F8); // Champs gris clair

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  
  // Variables de simulation
  double maxLoan = 500000; 
  double fees = 2500; 
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Financement Islamique", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. EN-TÊTE VISUEL & CARTE DE CAPACITÉ
            _buildHeader(),
            const SizedBox(height: 30),

            Text("Simulateur de prêt", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 2. FORMULAIRE PROPRE
            _buildInputFields(),

            const SizedBox(height: 25),

            // 3. RÉSUMÉ DE LA SIMULATION (TICKET)
            _buildSimulationResult(),

            const SizedBox(height: 35),

            // 4. BOUTON D'ACTION
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: isLoading ? null : _submitLoanRequest,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SOUMETTRE LA DEMANDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Conforme aux principes de la finance islamique.\nSans intérêts (Riba). Gestion éthique.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET : EN-TÊTE & CARTE (Dégradé Premium) ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], // Dégradé très classe
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CAPACITÉ D'EMPRUNT", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("${maxLoan.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15), 
              borderRadius: BorderRadius.circular(20), 
              border: Border.all(color: primaryColor.withValues(alpha: 0.3))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: primaryColor, size: 14),
                const SizedBox(width: 5),
                Text("Éligible au prêt Qard Hasan", style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET : CHAMPS DE SAISIE (Style Banque) ---
  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Montant souhaité", style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor, fontSize: 16),
          onChanged: (val) => setState(() {}), 
          decoration: InputDecoration(
            hintText: "Ex: 150000",
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.monetization_on_outlined, color: Colors.grey.shade500),
            filled: true,
            fillColor: fieldColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Motif du financement", style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _purposeController,
          style: TextStyle(color: textColor, fontSize: 16),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Ex: Achat de matériel, Frais de santé...",
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 25), // Remonte l'icône car maxLines: 2
              child: Icon(Icons.description_outlined, color: Colors.grey.shade500),
            ),
            filled: true,
            fillColor: fieldColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
          ),
        ),
      ],
    );
  }

  // --- WIDGET : RÉSULTAT SIMULATION ---
  Widget _buildSimulationResult() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, spreadRadius: 2)],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _rowDetail("Montant du prêt", "${amount.toStringAsFixed(0)} FCFA", isBold: true),
          const SizedBox(height: 12),
          _rowDetail("Taux d'intérêt (Riba)", "0 %", isHighlight: true),
          const SizedBox(height: 12),
          _rowDetail("Frais de dossier", "${fees.toStringAsFixed(0)} FCFA"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL À REMBOURSER", style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                "${(amount > 0 ? amount + fees : 0).toStringAsFixed(0)} FCFA", 
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _rowDetail(String label, String value, {bool isHighlight = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            color: isHighlight ? Colors.green : textColor, 
            fontWeight: (isHighlight || isBold) ? FontWeight.bold : FontWeight.w500,
            fontSize: 14
          )
        ),
      ],
    );
  }

  // --- LOGIQUE : SOUMISSION ---
  Future<void> _submitLoanRequest() async {
    double amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0 || _purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Veuillez remplir tous les champs."), backgroundColor: Colors.orange)
      );
      return;
    }

    if (amount > maxLoan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Le montant dépasse votre limite."), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.requestIslamicLoan(1, amount, _purposeController.text);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.verified_user_rounded, color: primaryColor, size: 60),
            title: Text("Demande Envoyée", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            content: const Text(
              "Votre dossier est maintenant entre les mains de notre comité d'éthique. Vous recevrez une réponse sous 24h.", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey, height: 1.4)
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50)
                  ),
                  onPressed: () {
                    Navigator.pop(c); 
                    Navigator.pop(context); 
                  }, 
                  child: const Text("COMPRIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de communication avec le serveur."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}