import 'package:flutter/material.dart';
import 'rules_screen.dart'; // Importe ton écran règlement
import 'home_screen.dart'; // Pour revenir à l'accueil après la déconnexion

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color gold = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundImage: const AssetImage('assets/logo.jpeg'),
                backgroundColor: gold,
              ),
              const SizedBox(height: 15),
              const Text("Reine", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("+237 694 09 82 39", style: TextStyle(color: Colors.grey)), // 👈 Ton vrai numéro intégré !
              
              const SizedBox(height: 40),

              // Menu Options reliées aux pages
              _buildProfileOption(context, Icons.person, "Modifier mon profil", const EmptyServiceScreen(title: "Modifier Profil")),
              _buildProfileOption(context, Icons.gavel, "Règlement Intérieur", const RulesScreen()),
              _buildProfileOption(context, Icons.help, "Centre d'aide", const EmptyServiceScreen(title: "Centre d'aide")),
              _buildProfileOption(context, Icons.lock, "Changer mon code PIN", const EmptyServiceScreen(title: "Sécurité")),
              
              const SizedBox(height: 20),
              
              // Bouton Déconnexion
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  _showLogoutConfirmation(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget générique pour créer les lignes du menu
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, Widget page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => page));
        },
      ),
    );
  }

  // Boîte de dialogue de confirmation de déconnexion
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
              Navigator.pop(context); // Ferme la popup
              // Redirige vers la fausse page de connexion (Pour éviter les crashs pendant la démo)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DummyLoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Déconnexion", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- PAGE "Bientôt disponible" POUR LES OPTIONS NON TERMINÉES ---
class EmptyServiceScreen extends StatelessWidget {
  final String title;
  const EmptyServiceScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final Color gold = const Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: gold, fontSize: 18)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.engineering, size: 80, color: gold),
            const SizedBox(height: 20),
            const Text("Module en développement", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Sera disponible dans la version 2.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("RETOUR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// --- FAUX ÉCRAN DE CONNEXION POUR LA DÉMO ---
class DummyLoginScreen extends StatelessWidget {
  const DummyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color gold = const Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, backgroundImage: AssetImage('assets/logo.jpeg')),
            const SizedBox(height: 30),
            const Text("Vous êtes déconnecté", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("À bientôt sur G-Caisse !", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),
            
            // Bouton de reconnexion rapide pour ne pas rester bloqué pendant la présentation
            ElevatedButton.icon(
              icon: const Icon(Icons.login, color: Colors.black),
              label: const Text("Se reconnecter (Démo)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}