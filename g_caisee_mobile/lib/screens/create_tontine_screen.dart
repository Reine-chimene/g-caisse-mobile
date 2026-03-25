import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateTontineScreen extends StatefulWidget {
  final int userId; // 👈 1. LA SOLUTION EST ICI : La page sait maintenant QUI crée la tontine

  const CreateTontineScreen({super.key, required this.userId}); 

  @override
  State<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends State<CreateTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _chiefController = TextEditingController(); 
  final TextEditingController _amountController = TextEditingController();
  
  // Couleurs "Style Banque" (Mode Jour)
  final Color primaryColor = const Color(0xFFD4AF37); // Doré
  final Color backgroundColor = Colors.white;
  final Color textColor = const Color(0xFF1A1A1A);
  final Color fieldColor = const Color(0xFFF5F6F8); // Gris très clair

  String _frequency = 'mensuel'; 
  bool _isLoading = false;
  bool _acceptRules = false; 

  void _submitTontine() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptRules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vous devez accepter les conditions.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double amount = double.parse(_amountController.text);
      double commission = 2.0; 

      await ApiService.createTontine(
        _nameController.text,
        widget.userId,
        _frequency,
        amount,
        commission
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tontine créée avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // On renvoie 'true' pour dire que c'est un succès
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Nouvelle Tontine", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- EN-TÊTE VISUEL ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_rounded, size: 50, color: primaryColor),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text("Créer un groupe de tontine", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
              ),
              const SizedBox(height: 30),

              Text("Détails du groupe", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // --- CHAMP NOM DU GROUPE ---
              _buildInputLabel("Nom du Groupe"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: "Ex: Tontine Familiale",
                icon: Icons.edit_outlined,
                validator: (v) => v!.isEmpty ? "Nom obligatoire" : null,
              ),
              const SizedBox(height: 20),

              // --- CHAMP NOM DU CHEF ---
              _buildInputLabel("Nom du Chef de Tontine"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _chiefController,
                hint: "Ex: Reine Ngono",
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? "Le nom du chef est obligatoire" : null,
              ),
              const SizedBox(height: 20),

              // --- CHAMP MONTANT ---
              _buildInputLabel("Montant par tour (FCFA)"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _amountController,
                hint: "Ex: 10000",
                icon: Icons.monetization_on_outlined,
                isNumber: true,
                validator: (v) => v!.isEmpty ? "Montant obligatoire" : null,
              ),
              const SizedBox(height: 20),

              // --- DROPDOWN FRÉQUENCE ---
              _buildInputLabel("Fréquence des cotisations"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonFormField<String>(
                  value: _frequency,
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[500]),
                  ),
                  style: TextStyle(color: textColor, fontSize: 16),
                  items: const [
                    DropdownMenuItem(value: 'journalier', child: Text("Journalière (Chaque jour)")),
                    DropdownMenuItem(value: 'hebdo', child: Text("Hebdomadaire (Chaque semaine)")),
                    DropdownMenuItem(value: 'mensuel', child: Text("Mensuelle (Chaque mois)")),
                  ], 
                  onChanged: (val) => setState(() => _frequency = val!),
                ),
              ),
              const SizedBox(height: 25),

              // --- INFO COMMISSION ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Bleu très clair
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Une commission de 2% sera appliquée pour la sécurité et la maintenance de la plateforme G-Caisse.",
                        style: TextStyle(color: Colors.blue[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // --- CASE À COCHER (VALIDATION DES RÈGLES) ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _acceptRules ? primaryColor : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  value: _acceptRules,
                  activeColor: primaryColor,
                  checkColor: Colors.white,
                  title: RichText(
                    text: TextSpan(
                      text: "Je confirme être le chef de cette tontine et ",
                      style: TextStyle(color: textColor, fontSize: 13),
                      children: [
                        TextSpan(
                          text: "j'accepte le règlement intérieur ainsi que les conditions de gestion.",
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  onChanged: (val) => setState(() => _acceptRules = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                ),
              ),
              const SizedBox(height: 35),

              // --- BOUTON VALIDER ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_acceptRules && !_isLoading) ? _submitTontine : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: Colors.grey[300], 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "LANCER LA TONTINE", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS PERSONNALISÉS ---

  Widget _buildInputLabel(String label) {
    return Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1)),
      ),
      validator: validator,
    );
  }
}