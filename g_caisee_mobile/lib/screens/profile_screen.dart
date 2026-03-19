import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g_caisee_mobile/screens/login_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryColor = const Color(0xFFFF7900); // Orange G-CAISE
  final Color backgroundColor = const Color(0xFFF5F6F8);

  bool isDarkMode = false;
  bool pushNotifications = true;
  double balance = 0.0;
  int trustScore = 0;
  bool isLoading = true;
  File? _imageFile;

  late String localFullname;
  late String localPhone;

  @override
  void initState() {
    super.initState();
    localFullname = widget.userData?['fullname'] ?? "Membre G-CAISE";
    localPhone = widget.userData?['phone'] ?? "+237 ---";
    _loadSettings();
    _loadProfileData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = value;
      prefs.setBool('isDarkMode', value);
    });
  }

  Future<void> _loadProfileData() async {
    try {
      int userId = widget.userData?['id'] ?? 0;
      final results = await Future.wait([
        ApiService.getUserBalance(userId),
        ApiService.getTrustScore(userId),
      ]);

      if (mounted) {
        setState(() {
          balance = (results[0] as num).toDouble();
          trustScore = (results[1] as num).toInt();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Photo de profil"),
        message: const Text("Choisissez une source pour votre photo"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _getFromSource(ImageSource.camera); },
            child: const Text("Prendre une photo"),
          ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _getFromSource(ImageSource.gallery); },
            child: const Text("Choisir dans la galerie"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
      ),
    );
  }

  Future<void> _getFromSource(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 50);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkMode;
    final Color currentBg = dark ? const Color(0xFF121212) : backgroundColor;
    final Color currentCard = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color currentText = dark ? Colors.white : const Color(0xFF1A1A1A);
    final Color currentSubText = dark ? Colors.white70 : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: currentBg,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: currentBg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                _buildHeader(currentText, currentSubText),
                const SizedBox(height: 35),
                _buildStatsRow(currentCard, currentText, currentSubText),
                const SizedBox(height: 30),
                
                _buildSectionTitle("Compte", currentText),
                _buildSettingsBlock(currentCard, [
                  _buildActionTile(Icons.person_outline, "Informations personnelles", currentText, () async {
                    final result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (c) => EditProfileScreen(
                        userId: widget.userData?['id'] ?? 0, 
                        currentName: localFullname, 
                        currentPhone: localPhone
                      ))
                    );
                    if (result != null && result is Map<String, String> && mounted) {
                      setState(() {
                        localFullname = result['name']!;
                        localPhone = result['phone']!;
                      });
                    }
                  }),
                  _buildDivider(),
                  _buildActionTile(Icons.lock_outline, "Sécurité et PIN", currentText, () {}),
                ]),

                const SizedBox(height: 25),

                _buildSectionTitle("Préférences", currentText),
                _buildSettingsBlock(currentCard, [
                  _buildToggleTile(Icons.dark_mode_outlined, "Mode Sombre", isDarkMode, currentText, (val) {
                    _toggleDarkMode(val);
                  }),
                  _buildDivider(),
                  _buildToggleTile(Icons.notifications_none, "Notifications push", pushNotifications, currentText, (val) {
                    setState(() => pushNotifications = val);
                  }),
                ]),

                const SizedBox(height: 40),
                _buildLogoutButton(),
                const SizedBox(height: 20),
                Text("G-CAISE v1.0.2 - Yaoundé, CM", 
                  style: TextStyle(color: currentSubText.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color txtColor, Color subTxtColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null 
                    ? FileImage(_imageFile!) 
                    : const AssetImage('assets/logo.jpeg') as ImageProvider,
                ),
              ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor,
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            )
          ],
        ),
        const SizedBox(height: 15),
        Text(localFullname, style: TextStyle(color: txtColor, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(localPhone, style: TextStyle(color: subTxtColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatsRow(Color cardCol, Color txtCol, Color subTxtCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: cardCol, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Expanded(child: _buildStatItem("Solde", "${balance.toStringAsFixed(0)} F", txtCol, subTxtCol)),
          Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
          Expanded(child: _buildStatItem("Score", "$trustScore%", txtCol, subTxtCol)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color txtCol, Color subTxtCol) {
    return Column(children: [
      Text(label, style: TextStyle(color: subTxtCol, fontSize: 12)),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(color: txtCol, fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSectionTitle(String title, Color textColor) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 10),
    child: Align(alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold))),
  );

  Widget _buildSettingsBlock(Color bgColor, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
    child: Column(children: children),
  );

  Widget _buildActionTile(IconData icon, String title, Color txtColor, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: primaryColor),
    title: Text(title, style: TextStyle(color: txtColor, fontSize: 14)),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );

  Widget _buildToggleTile(IconData icon, String title, bool val, Color txtColor, ValueChanged<bool> onChanged) => ListTile(
    leading: Icon(icon, color: primaryColor),
    title: Text(title, style: TextStyle(color: txtColor, fontSize: 14)),
    trailing: CupertinoSwitch(activeColor: primaryColor, value: val, onChanged: onChanged),
  );

  Widget _buildDivider() => Divider(height: 1, indent: 50, endIndent: 20, color: Colors.grey.withValues(alpha: 0.1));

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.08), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        icon: const Icon(Icons.logout, color: Colors.red, size: 20),
        label: const Text("DÉCONNEXION", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onPressed: () => _showLogoutConfirmation(),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Quitter ?"),
        content: const Text("Vous devrez vous reconnecter pour accéder à vos tontines."),
        actions: [
          CupertinoDialogAction(child: const Text("Annuler"), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false),
            child: const Text("Déconnexion"),
          ),
        ],
      ),
    );
  }
}

// --- CLASSE CORRECTIVE POUR LA NAVIGATION ---
class EditProfileScreen extends StatelessWidget {
  final int userId;
  final String currentName;
  final String currentPhone;

  const EditProfileScreen({
    super.key, 
    required this.userId, 
    required this.currentName, 
    required this.currentPhone
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le profil", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            Text("Interface en cours de développement pour $currentName", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Retour")
            )
          ],
        ),
      ),
    );
  }
}