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
  double maxLoan = 500000; // Capacité (viendra de l'API plus tard)
  double fees = 2500; // Frais de dossier fixes (Halal)
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
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading ? null : _submitLoanRequest,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("SOUMETTRE LA DEMANDE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 15),
            const Center(
              child: Text(
                "Conforme aux principes de la finance islamique.\nSans intérêts (Riba).",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade900, Colors.purple.shade600]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("CAPACITÉ D'EMPRUNT", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Icon(Icons.account_balance, color: Colors.white),
            ],
          ),
          const SizedBox(height: 5),
          Text("${maxLoan.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: const Text("Eligible au prêt Qard Hasan", style: TextStyle(color: Colors.white, fontSize: 11)),
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
          onChanged: (val) => setState(() {}), // Rafraîchir le simulateur
          decoration: InputDecoration(
            labelText: "Montant souhaité (FCFA)",
            labelStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.money, color: gold),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800), borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold), borderRadius: BorderRadius.circular(10)),
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
            labelText: "Motif (Commerce, Santé...)",
            labelStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.edit_note, color: gold),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800), borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold), borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _rowDetail("Montant demandé", "${amount.toStringAsFixed(0)} FCFA"),
          const SizedBox(height: 10),
          _rowDetail("Intérêts (0%)", "0 FCFA", isHighlight: true),
          const SizedBox(height: 10),
          _rowDetail("Frais de dossier", "${fees.toStringAsFixed(0)} FCFA"),
          const Divider(color: Colors.grey, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL À REMBOURSER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${(amount + fees).toStringAsFixed(0)} FCFA", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18)),
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
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(color: isHighlight ? Colors.green : Colors.white, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  // --- LOGIQUE : SOUMISSION ---
  Future<void> _submitLoanRequest() async {
    double amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0 || _purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs correctement.")));
      return;
    }

    if (amount > maxLoan) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le montant dépasse votre capacité d'emprunt.")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // APPEL API RÉEL
      await ApiService.requestIslamicLoan(1, amount, _purposeController.text);
      
      if (mounted) {
        // Succès
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: cardGrey,
            icon: Icon(Icons.check_circle, color: gold, size: 50),
            title: Text("Demande Envoyée", style: TextStyle(color: gold)),
            content: const Text("Votre dossier est en cours d'analyse. Vous recevrez une réponse sous 24h.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(onPressed: () {
                Navigator.pop(c); // Ferme Dialog
                Navigator.pop(context); // Retour Accueil
              }, child: const Text("OK", style: TextStyle(color: Colors.white)))
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion. Réessayez.")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}