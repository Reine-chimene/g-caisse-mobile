import 'package:flutter/material.dart';
import 'register_screen.dart'; 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // Design G-CAISE (Yaoundé Style)
  final Color primaryColor = const Color(0xFFFF7900); 
  final Color textColor = const Color(0xFF1A1A1A);

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Logique de connexion ici
        await Future.delayed(const Duration(seconds: 2));
        // Navigator.push(...)
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Text("Bon retour !", 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
                const Text("Connectez-vous à votre compte G-CAISE"),
                const SizedBox(height: 40),

                // Champ Téléphone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Numéro de téléphone",
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? "Entrez votre numéro" : null,
                ),
                const SizedBox(height: 20),

                // Champ PIN
                TextFormField(
                  controller: _pinController,
                  obscureText: _obscureText,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Code PIN",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.length < 4 ? "PIN invalide" : null,
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                  },
                  child: Text("Pas de compte ? Créer un compte", style: TextStyle(color: primaryColor)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}