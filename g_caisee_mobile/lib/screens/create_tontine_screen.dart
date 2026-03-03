import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateTontineScreen extends StatefulWidget {
  const CreateTontineScreen({super.key});

  @override
  State<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends State<CreateTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  // Couleurs
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);

  String _frequency = 'mensuel'; 
  bool _isLoading = false;

  void _submitTontine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Admin ID hardcodé à 1 pour la démo (sera dynamique plus tard avec l'auth)
      int adminId = 1; 
      double amount = double.parse(_amountController.text);
      double commission = 2.0; 

      await ApiService.createTontine(
        _nameController.text,
        adminId,
        _frequency,
        amount,
        commission
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Tontine créée avec succès !'),
            backgroundColor: gold,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Retour à la liste
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erreur lors de la création'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("NOUVELLE TONTINE", style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête visuel
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: gold, width: 2),
                  ),
                  child: Icon(Icons.groups_3, size: 50, color: gold),
                ),
              ),
              const SizedBox(height: 30),

              const Text("Détails du groupe", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // Champ Nom
              _buildTextField(
                controller: _nameController,
                label: "Nom du Groupe",
                icon: Icons.edit,
                validator: (v) => v!.isEmpty ? "Nom obligatoire" : null,
              ),
              const SizedBox(height: 20),

              // Champ Montant
              _buildTextField(
                controller: _amountController,
                label: "Montant par tour (FCFA)",
                icon: Icons.monetization_on,
                isNumber: true,
                validator: (v) => v!.isEmpty ? "Montant obligatoire" : null,
              ),
              const SizedBox(height: 20),

              // Dropdown Fréquence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cardGrey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: DropdownButtonFormField<String>(
                  value: _frequency,
                  dropdownColor: cardGrey,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.timer, color: Colors.grey),
                    labelText: "Fréquence des cotisations",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: const [
                    DropdownMenuItem(value: 'journalier', child: Text("Journalière (Jour)")), // 👈 Voici le nouvel ajout !
                    DropdownMenuItem(value: 'hebdo', child: Text("Hebdomadaire (Semaine)")),
                    DropdownMenuItem(value: 'mensuel', child: Text("Mensuel (Mois)")),
                  ], 
                  onChanged: (val) => setState(() => _frequency = val!),
                ),
              ),

              const SizedBox(height: 30),

              // Note sur la commission
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Une commission de 2% sera appliquée pour la maintenance de la plateforme.",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Bouton Valider
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTontine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("LANCER LA TONTINE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget personnalisé pour les champs de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: gold),
        filled: true,
        fillColor: cardGrey,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }
}