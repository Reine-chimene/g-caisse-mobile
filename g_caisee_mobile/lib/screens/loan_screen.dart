import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  
  // Variables de simulation
  double maxLoan = 500000; 
  double fees = 2500; 
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("FINANCEMENT ISLAMIQUE", style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CARTE DE CAPACITÉ D'EMPRUNT
            _buildCapacityCard(),

            const SizedBox(height: 25),
            const Text("Simulateur", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 2. FORMULAIRE
            _buildInputFields(),

            const SizedBox(height: 20),

            // 3. RÉSUMÉ DE LA SIMULATION
            _buildSimulationResult(),

            const SizedBox(height: 30),

            // 4. BOUTON D'ACTION
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: isLoading ? null : _submitLoanRequest,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("SOUMETTRE LA DEMANDE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 15),
            const Center(
              child: Text(
                "Conforme aux principes de la finance islamique.\nSans intérêts (Riba). Gestion éthique.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET : CARTE CAPACITÉ ---
  Widget _buildCapacityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade900, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("VOTRE CAPACITÉ MAXIMALE", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
              Icon(Icons.account_balance, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 10),
          Text("${maxLoan.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 14),
                SizedBox(width: 5),
                Text("Eligible au prêt Qard Hasan", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET : CHAMPS DE SAISIE ---
  Widget _buildInputFields() {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          onChanged: (val) => setState(() {}), 
          decoration: InputDecoration(
            labelText: "Montant souhaité (FCFA)",
            labelStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.monetization_on, color: gold),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800), borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold), borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: cardGrey,
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _purposeController,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            labelText: "Motif du financement",
            labelStyle: const TextStyle(color: Colors.grey),
            hintText: "Ex: Achat de matériel, Frais de santé...",
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            prefixIcon: Icon(Icons.description, color: gold),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800), borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold), borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: cardGrey,
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
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _rowDetail("Montant du prêt", "${amount.toStringAsFixed(0)} FCFA"),
          const SizedBox(height: 12),
          _rowDetail("Taux d'intérêt (Riba)", "0 %", isHighlight: true),
          const SizedBox(height: 12),
          _rowDetail("Frais de gestion", "${fees.toStringAsFixed(0)} FCFA"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL À REMBOURSER", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Text("${(amount + fees).toStringAsFixed(0)} FCFA", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          )
        ],
      ),
    );
  }

  Widget _rowDetail(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(color: isHighlight ? Colors.greenAccent : Colors.white, fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  // --- LOGIQUE : SOUMISSION ---
  Future<void> _submitLoanRequest() async {
    double amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0 || _purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oups ! Veuillez remplir tous les champs."), backgroundColor: Colors.orange)
      );
      return;
    }

    if (amount > maxLoan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le montant dépasse votre limite autorisée."), backgroundColor: Colors.redAccent)
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // APPEL API RÉEL
      await ApiService.requestIslamicLoan(1, amount, _purposeController.text);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            backgroundColor: cardGrey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.verified_user, color: gold, size: 60),
            title: Text("Demande Envoyée", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
            content: const Text(
              "Votre dossier est maintenant entre les mains de notre comité d'éthique. Réponse sous 24h.", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.white70, height: 1.4)
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    Navigator.pop(c); // Ferme Dialog
                    Navigator.pop(context); // Retour Accueil
                  }, 
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("COMPRIS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  )
                ),
              ),
              const SizedBox(height: 10),
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