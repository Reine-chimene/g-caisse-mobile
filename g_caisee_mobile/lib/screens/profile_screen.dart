import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Pour le style de switch "iPhone"
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
  final Color primaryColor = const Color(0xFFD4AF37); // Ton Doré
  final Color backgroundColor = const Color(0xFFF5F6F8); // Fond gris très clair
  final Color cardColor = Colors.white;

  // Variables d'état
  bool isDarkMode = false; // Par défaut, on est en mode clair
  bool pushNotifications = true;
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
    String fullname = widget.userData?['fullname'] ?? "Membre G-Caisse";
    String phone = widget.userData?['phone'] ?? "+237 ---";
    int userId = widget.userData?['id'] ?? 1;

    // Couleurs dynamiques selon le mode (Clair ou Sombre)
    Color currentBg = isDarkMode ? const Color(0xFF121212) : backgroundColor;
    Color currentCard = isDarkMode ? const Color(0xFF1E1E1E) : cardColor;
    Color currentText = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    Color currentSubText = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: currentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- EN-TÊTE PROFIL (Avatar + Nom) ---
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 15)],
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/logo.jpeg'),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    // Le petit bouton "+" ou "appareil photo" sur l'avatar
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: currentBg, width: 3)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(fullname, style: TextStyle(color: currentText, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(phone, style: TextStyle(color: currentSubText, fontSize: 15)),
              
              const SizedBox(height: 35),

              // --- STATISTIQUES (Style Banque) ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: currentCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Solde Actuel", "${balance.toStringAsFixed(0)} F", currentText, currentSubText),
                    Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
                    _buildStatItem("Confiance", "$trustScore / 100", currentText, currentSubText),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- SECTIONS DE PARAMÈTRES ---
              
              // 1. Compte
              _buildSectionTitle("Compte", currentText),
              _buildSettingsBlock(currentCard, [
                _buildActionTile(Icons.person_outline, "Informations personnelles", currentText, currentSubText, () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userId: userId, currentName: fullname, currentPhone: phone)));
                }),
                _buildDivider(),
                _buildActionTile(Icons.lock_outline, "Sécurité et PIN", currentText, currentSubText, () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ChangePinScreen()));
                }),
              ]),

              const SizedBox(height: 25),

              // 2. Préférences & Apparence
              _buildSectionTitle("Préférences", currentText),
              _buildSettingsBlock(currentCard, [
                _buildToggleTile(Icons.dark_mode_outlined, "Mode Sombre", isDarkMode, currentText, currentSubText, (val) {
                  setState(() => isDarkMode = val);
                }),
                _buildDivider(),
                _buildToggleTile(Icons.notifications_none, "Notifications push", pushNotifications, currentText, currentSubText, (val) {
                  setState(() => pushNotifications = val);
                }),
              ]),

              const SizedBox(height: 25),

              // 3. À propos
              _buildSectionTitle("À propos", currentText),
              _buildSettingsBlock(currentCard, [
                _buildActionTile(Icons.gavel_outlined, "Règlement Intérieur", currentText, currentSubText, () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const RulesScreen()));
                }),
                _buildDivider(),
                _buildActionTile(Icons.help_outline, "Centre d'aide", currentText, currentSubText, () {}),
              ]),

              const SizedBox(height: 35),

              // --- BOUTON DÉCONNEXION ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.red, size: 22),
                  label: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _showLogoutConfirmation(context, currentCard, currentText),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPOSANTS VISUELS ---

  Widget _buildStatItem(String label, String value, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 13)),
        const SizedBox(height: 8),
        isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSettingsBlock(Color bgColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color textColor, Color iconColor, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(IconData icon, String title, bool value, Color textColor, Color iconColor, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: CupertinoSwitch(
        activeColor: primaryColor,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.withOpacity(0.1));
  }

  void _showLogoutConfirmation(BuildContext context, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Déconnexion", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: const Text("Voulez-vous vraiment vous déconnecter de G-Caisse ?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
            child: const Text("Déconnexion", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// --- PAGE ÉDITION PROFIL (GARDÉE INTACTE) ---
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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    phoneController = TextEditingController(text: widget.currentPhone);
  }

  Future<void> _handleUpdate() async {
    setState(() => isUpdating = true);
    try {
      await ApiService.updateProfile(widget.userId, nameController.text, phoneController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Profil mis à jour !"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Erreur"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Modifier le profil", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nom complet", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Numéro", border: OutlineInputBorder())),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 55)),
              onPressed: isUpdating ? null : _handleUpdate,
              child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- PAGE CHANGEMENT CODE PIN (GARDÉE INTACTE) ---
// ==========================================
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Sécurité PIN", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), elevation: 0),
      body: const Center(child: Text("Page en construction pour la démo", style: TextStyle(color: Colors.grey))),
    );
  }
}