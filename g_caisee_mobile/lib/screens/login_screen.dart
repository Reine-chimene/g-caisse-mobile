import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart'; // 👈 L'importation qui manquait est bien là !
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

  // Couleurs inspirées de tes captures (Style Mendo / Banque)
  final Color primaryColor = const Color(0xFFD4AF37); // Ton Doré G-Caisse
  final Color backgroundColor = Colors.white; // Fond blanc pur
  final Color textColor = const Color(0xFF1A1A1A); // Noir très lisible
  final Color fieldColor = const Color(0xFFF5F6F8); // Gris très clair pour les champs

  void _login() async {
    if (_phoneController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir tous les champs'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await ApiService.loginUser(
        _phoneController.text,
        _pinController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userData: userData)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Numéro ou code PIN incorrect'),
            backgroundColor: Colors.red,
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
                // 1. L'Image / Logo en haut (très épuré)
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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

                // 2. Les Titres
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
                  "Connectez-vous pour gérer vos tontines",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),

                // 3. Les Champs de saisie (Style moderne arrondi)
                _buildInputLabel("Numéro de téléphone"),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _phoneController,
                  hint: "Ex: 690 00 00 00",
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                  isPassword: false,
                ),
                const SizedBox(height: 20),

                _buildInputLabel("Code PIN"),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _pinController,
                  hint: "••••",
                  icon: Icons.lock_outline,
                  type: TextInputType.number,
                  isPassword: true,
                ),

                const SizedBox(height: 15),

                // 4. Mot de passe oublié (Aligné à droite)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, // Action à définir plus tard
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      "Code PIN oublié ?",
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 5. Le Bouton Principal
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Bouton bien arrondi
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SE CONNECTER",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // 6. Lien vers l'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pas encore de compte ? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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

  // --- WIDGETS PERSONNALISÉS POUR LE DESIGN ---

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
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
      style: TextStyle(color: textColor, fontSize: 16, letterSpacing: isPassword ? 5 : 0),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 0),
        counterText: "", // Cache le compteur de caractères en bas
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey[500],
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Pas de bordure par défaut
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5), // Bordure dorée au clic
        ),
      ),
    );
  }
}