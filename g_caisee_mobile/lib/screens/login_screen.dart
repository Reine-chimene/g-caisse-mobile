import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  final Color goldColor = const Color(0xFFD4AF37);

  void _login() async {
    if (_phoneController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // On récupère les infos de l'utilisateur depuis le serveur
      final userData = await ApiService.loginUser(_phoneController.text, _pinController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Bienvenue, ${userData['fullname']} !'),
            backgroundColor: Colors.green,
          ),
        );

        // On passe à l'accueil
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomeScreen())
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Numéro ou code PIN incorrect'), 
            backgroundColor: Colors.red
          ),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo avec bordure dorée
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor, width: 2),
                  boxShadow: [
                    BoxShadow(color: goldColor.withValues(alpha: 0.2), blurRadius: 15)
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/logo.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "G-CAISSE",
                style: TextStyle(
                  color: goldColor, 
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "Finance Éthique & Tontines",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 50),
              
              _buildField(_phoneController, "Téléphone", Icons.phone, false),
              const SizedBox(height: 20),
              _buildField(_pinController, "Code PIN", Icons.lock, true),
              
              const SizedBox(height: 40),
              
              // Bouton de connexion
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text(
                        "SE CONNECTER", 
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Nouveau membre ?", style: TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  RegisterScreen())),
                    child: Text("S'inscrire ici", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                  ),
                ],
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
      keyboardType: isPass ? TextInputType.number : TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: goldColor),
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: goldColor),
        ),
      ),
    );
  }
}