import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart'; // ✅ IMPORT TRÈS IMPORTANT : Pour accéder au MainWrapper
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // ✅ NOUVEAU DESIGN G-CAISE (Style Max It)
  final Color primaryColor = const Color(0xFFFF7900); // Orange Max It
  final Color backgroundColor = Colors.white; 
  final Color textColor = const Color(0xFF1A1A1A); 
  final Color fieldColor = const Color(0xFFF5F6F8); 

  void _login() async {
    // Nettoyage des entrées
    final String phone = _phoneController.text.trim();
    final String pin = _pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir tous les champs'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await ApiService.loginUser(phone, pin);

      if (mounted) {
        // ✅ CORRECTION MAJEURE : On redirige vers MainWrapper pour avoir la NavBar !
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainWrapper(userData: userData)),
        );
      }
    } catch (e) {
      if (mounted) {
        // ✅ GESTION DES ERREURS POUR LE CLIENT
        String rawError = e.toString();
        String errorMessage = "Une erreur est survenue.";

        // Traduction des erreurs techniques en langage clair
        if (rawError.contains("SocketException") || 
            rawError.contains("Network is unreachable") || 
            rawError.contains("Failed host lookup")) {
          errorMessage = "Problème de connexion Internet. Veuillez vérifier votre réseau.";
        } else if (rawError.contains("Identifiants incorrects")) {
          errorMessage = "Numéro de téléphone ou code PIN incorrect.";
        } else {
          errorMessage = rawError.replaceAll("Exception: ", "");
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4), // Laisse le temps au client de lire
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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo G-CAISE
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  "Bienvenue",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Gérez vos tontines G-CAISE en toute sécurité",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),

                _buildInputLabel("Numéro de téléphone"),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _phoneController,
                  hint: "6xx xx xx xx",
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                  isPassword: false,
                ),
                const SizedBox(height: 20),

                _buildInputLabel("Code PIN"),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _pinController,
                  hint: "Code à 4 chiffres",
                  icon: Icons.lock_outline,
                  type: TextInputType.number,
                  isPassword: true,
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, 
                    child: Text(
                      "Code PIN oublié ?",
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton SE CONNECTER
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                            "SE CONNECTER",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Pas encore de compte ? ", style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterScreen())),
                      child: Text(
                        "S'inscrire",
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType type,
    required bool isPassword,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword ? _obscureText : false,
      maxLength: isPassword ? 4 : null,
      style: TextStyle(color: textColor, fontSize: 16, letterSpacing: isPassword ? 8 : 0),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 0),
        counterText: "",
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}