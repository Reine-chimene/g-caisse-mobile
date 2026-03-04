import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // Les mêmes couleurs "Style Banque" que l'écran de connexion
  final Color primaryColor = const Color(0xFFD4AF37);
  final Color backgroundColor = Colors.white;
  final Color textColor = const Color(0xFF1A1A1A);
  final Color fieldColor = const Color(0xFFF5F6F8); 

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ApiService.registerUser(_nameController.text, _phoneController.text, _pinController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Compte créé avec succès ! Connectez-vous.'), backgroundColor: Colors.green)
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Créer un compte", 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5)
                ),
                const SizedBox(height: 10),
                Text(
                  "Rejoignez la communauté G-Caisse en quelques secondes.", 
                  style: TextStyle(fontSize: 15, color: Colors.grey[600])
                ),
                const SizedBox(height: 40),

                // CHAMP NOM
                _buildInputLabel("Nom complet"),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _nameController, 
                  hint: "Ex: Reine Ngono", 
                  icon: Icons.person_outline, 
                  type: TextInputType.name, 
                  isPassword: false
                ),
                const SizedBox(height: 20),

                // CHAMP TÉLÉPHONE
                _buildInputLabel("Numéro de téléphone"),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _phoneController, 
                  hint: "Ex: 690 00 00 00", 
                  icon: Icons.phone_outlined, 
                  type: TextInputType.phone, 
                  isPassword: false
                ),
                const SizedBox(height: 20),

                // CHAMP CODE PIN
                _buildInputLabel("Créer un Code PIN secret"),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _pinController, 
                  hint: "••••", 
                  icon: Icons.lock_outline, 
                  type: TextInputType.number, 
                  isPassword: true, 
                  isPin: true
                ),
                const SizedBox(height: 40),

                // BOUTON D'INSCRIPTION
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("S'INSCRIRE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30),

                // LIEN VERS CONNEXION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà un compte ? ", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text("Se connecter", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS PERSONNALISÉS ---

  Widget _buildInputLabel(String label) {
    return Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildInputField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    required TextInputType type, 
    required bool isPassword, 
    bool isPin = false
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword ? _obscureText : false,
      maxLength: isPin ? 4 : null,
      style: TextStyle(color: textColor, fontSize: 16, letterSpacing: isPassword ? 5 : 0),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 0),
        counterText: "", 
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[500]),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Ce champ est obligatoire";
        if (isPin && value.length != 4) return "Le PIN doit contenir exactement 4 chiffres";
        return null;
      },
    );
  }
}