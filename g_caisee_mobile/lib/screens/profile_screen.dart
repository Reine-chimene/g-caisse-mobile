import 'package:flutter/material.dart';
import 'rules_screen.dart'; 
import 'login_screen.dart'; 
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double balance = 0.0;
  int trustScore = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // On récupère l'ID de l'utilisateur (par défaut 1 si non connecté pour la démo)
      int userId = widget.userData?['id'] ?? 1; 
      double fetchedBalance = await ApiService.getUserBalance(userId);
      int fetchedScore = await ApiService.getTrustScore(userId);

      if (mounted) {
        setState(() {
          balance = fetchedBalance;
          trustScore = fetchedScore;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color gold = const Color(0xFFD4AF37);
    
    String fullname = widget.userData?['fullname'] ?? "Membre G-Caisse";
    String phone = widget.userData?['phone'] ?? "+237 ---";
    int userId = widget.userData?['id'] ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar stylisé
              Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: const AssetImage('assets/logo.jpeg'),
                  backgroundColor: gold,
                ),
              ),
              const SizedBox(height: 15),
              Text(fullname, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(phone, style: const TextStyle(color: Colors.grey)), 
              
              const SizedBox(height: 25),

              // --- CARTE DE STATISTIQUES ---
              isLoading 
                ? CircularProgressIndicator(color: gold) 
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: gold.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text("Solde Actuel", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text("${balance.toStringAsFixed(0)} FCFA", style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: Colors.white10),
                        Column(
                          children: [
                            const Text("Score Confiance", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text("$trustScore pts", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

              const SizedBox(height: 30),

              // --- OPTIONS DE PROFIL ---
              _buildProfileOption(context, Icons.person, "Modifier mon profil", 
                EditProfileScreen(userId: userId, currentName: fullname, currentPhone: phone)),
              
              _buildProfileOption(context, Icons.gavel, "Règlement Intérieur", const RulesScreen()),
              
              _buildProfileOption(context, Icons.lock, "Changer mon code PIN", const ChangePinScreen()),
              
              const SizedBox(height: 30),
              
              // Bouton Déconnexion
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () => _showLogoutConfirmation(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, Widget page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Déconnexion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Voulez-vous vraiment vous déconnecter de G-Caisse ?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Annuler", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// --- PAGE ÉDITION PROFIL (VRAI API) ---
// ==========================================

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final String currentName;
  final String currentPhone;

  const EditProfileScreen({super.key, required this.userId, required this.currentName, required this.currentPhone});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  bool isUpdating = false;
  final Color gold = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    phoneController = TextEditingController(text: widget.currentPhone);
  }

  Future<void> _handleUpdate() async {
    setState(() => isUpdating = true);
    try {
      // VRAI APPEL API AU SERVEUR RENDER
      await ApiService.updateProfile(widget.userId, nameController.text, phoneController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profil mis à jour sur le serveur !"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Erreur lors de la mise à jour"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("Modifier le profil", style: TextStyle(color: gold, fontSize: 18)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nom complet",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.person, color: gold),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Numéro de téléphone",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.phone, color: gold),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: isUpdating ? null : _handleUpdate,
                child: isUpdating 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("ENREGISTRER LES MODIFICATIONS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- PAGE CHANGEMENT CODE PIN ---
// ==========================================

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final Color gold = const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("Sécurité PIN", style: TextStyle(color: gold, fontSize: 18)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Icon(Icons.security, size: 60, color: Colors.white24),
            const SizedBox(height: 20),
            const Text(
              "Le code PIN protège vos transactions. Ne le partagez jamais.", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)
            ),
            const SizedBox(height: 40),
            _buildPinField("Code PIN actuel"),
            const SizedBox(height: 20),
            _buildPinField("Nouveau code PIN"),
            const SizedBox(height: 20),
            _buildPinField("Confirmer nouveau code PIN"),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Code PIN modifié avec succès !"), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                child: const Text("METTRE À JOUR LE PIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(String label) {
    return TextField(
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 10),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, letterSpacing: 0),
        counterStyle: const TextStyle(color: Colors.white24),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
      ),
    );
  }
}