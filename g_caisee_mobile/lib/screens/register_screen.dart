import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  final Color goldColor = Color(0xFFD4AF37);
  final Color darkGrey = Color(0xFF1C1C1E);

  void _submitRegistration() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _pinController.text.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      await ApiService.registerUser(
        _nameController.text,
        _phoneController.text,
        _pinController.text,
      );
      
      // Succès -> Accueil
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erreur inscription'), backgroundColor: Colors.red));
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
          onPressed: () => Navigator.pop(context), // Retour connexion
        ),
        elevation: 0,
      ),
      body: Center( // 👈 TOUT EST CENTRÉ
        child: SingleChildScrollView(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 60, color: goldColor),
              SizedBox(height: 10),
              Text("NOUVEAU COMPTE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Rejoignez la communauté G-Caisse", style: TextStyle(color: Colors.grey)),
              
              SizedBox(height: 30),

              // FORMULAIRE DANS UNE CARTE SOMBRE
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: darkGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    _buildField(_nameController, "Nom Complet", Icons.person, false),
                    SizedBox(height: 15),
                    _buildField(_phoneController, "Téléphone", Icons.phone_android, false),
                    SizedBox(height: 15),
                    _buildField(_pinController, "Créer un Code PIN", Icons.lock_outline, true),
                  ],
                ),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.black) 
                    : Text("S'INSCRIRE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
      style: TextStyle(color: Colors.white),
      keyboardType: isPass ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
      ),
    );
  }
}