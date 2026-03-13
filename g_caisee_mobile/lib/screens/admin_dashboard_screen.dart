import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color dark = const Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("G-CAISE ADMIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: dark,
        foregroundColor: gold,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => Navigator.pop(context)
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getAdminStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final stats = snapshot.data ?? {"total_fees": 0, "total_volume": 0, "user_count": 0};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Résumé des gains", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // ✅ Le nom de la fonction est maintenant _statCard
                _statCard(
                  "COMMISSIONS GÉNÉRÉES (2%)", 
                  "${stats['total_fees']} FCFA", 
                  Icons.account_balance_wallet_rounded, 
                  Colors.green
                ),
                const SizedBox(height: 15),
                
                _statCard(
                  "VOLUME TOTAL DES DÉPÔTS", 
                  "${stats['total_volume']} FCFA", 
                  Icons.bar_chart_rounded, 
                  Colors.blue
                ),
                const SizedBox(height: 15),
                
                _statCard(
                  "NOMBRE D'UTILISATEURS", 
                  "${stats['user_count']}", 
                  Icons.people_alt_rounded, 
                  Colors.orange
                ),
                
                const SizedBox(height: 30),
                const Text("Actions Rapides", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Icons.notifications_active, color: Colors.red),
                  title: const Text("Envoyer une notification à tous"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ La fonction s'appelle bien _statCard
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Expanded( // Ajouté pour éviter les débordements de texte
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                FittedBox( // Ajuste le texte si le montant est trop grand
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}