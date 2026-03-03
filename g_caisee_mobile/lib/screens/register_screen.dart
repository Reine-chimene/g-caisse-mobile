import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart'; // On redirige vers Login pour rafraîchir les données

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  final Color goldColor = const Color(0xFFD4AF37);
  final Color darkGrey = const Color(0xFF1C1C1E);

  void _submitRegistration() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir tous les champs')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      await ApiService.registerUser(
        _nameController.text,
        _phoneController.text,
        _pinController.text,
      );
      
      if (mounted) {
        // Succès -> On informe l'utilisateur et on le renvoie au LOGIN
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Compte créé ! Veuillez vous connecter.'), 
            backgroundColor: Colors.green
          ),
        );
        
        // On retourne à l'écran de connexion pour forcer une session propre
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erreur inscription. Numéro déjà utilisé ?'), backgroundColor: Colors.red)
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
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: goldColor),
          onPressed: () => Navigator.pop(context), 
        ),
        elevation: 0,
      ),
      body: Center( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 60, color: goldColor),
              const SizedBox(height: 10),
              const Text("NOUVEAU COMPTE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Rejoignez la communauté G-Caisse", style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: darkGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    _buildField(_nameController, "Nom Complet", Icons.person, false),
                    const SizedBox(height: 15),
                    _buildField(_phoneController, "Téléphone", Icons.phone_android, false),
                    const SizedBox(height: 15),
                    _buildField(_pinController, "Créer un Code PIN (4 chiffres)", Icons.lock_outline, true),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text("S'INSCRIRE MAINTENANT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, bool isPass) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      keyboardType: isPass ? TextInputType.number : TextInputType.text,
      maxLength: isPass ? 4 : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        counterStyle: const TextStyle(color: Colors.white24),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
      ),
    );
  }
}