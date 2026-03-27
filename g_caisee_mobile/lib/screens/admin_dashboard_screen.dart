import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart'; // N'oublie pas d'ajouter intl dans ton pubspec.yaml

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Couleurs Identité G-CAISE Premium
  final Color gold = const Color(0xFFD4AF37);
  final Color dark = const Color(0xFF1A1A2E);
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  // Pour forcer le rafraîchissement du FutureBuilder
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text("G-CAISE ADMIN", 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: gold)),
        backgroundColor: dark,
        elevation: 10,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _refreshKey = UniqueKey()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
            onPressed: () => Navigator.pop(context)
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _refreshKey = UniqueKey()),
        child: FutureBuilder<Map<String, dynamic>>(
          key: _refreshKey,
          future: ApiService.getAdminStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 10),
                    Text("Erreur de connexion au serveur", style: TextStyle(color: dark)),
                    TextButton(onPressed: () => setState(() => _refreshKey = UniqueKey()), child: const Text("Réessayer"))
                  ],
                ),
              );
            }

            final stats = snapshot.data ?? {"total_fees": 0, "total_volume": 0, "user_count": 0, "tontine_count": 0, "recent_commissions": []};
            final commissions = (stats['recent_commissions'] as List?) ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("Résumé des performances"),
                  const SizedBox(height: 20),
                  
                  // CARTE DES GAINS (PRINCIPALE)
                  _statCard(
                    "COMMISSIONS GÉNÉRÉES (2%)", 
                    currencyFormat.format(stats['total_fees']), 
                    Icons.account_balance_wallet_rounded, 
                    Colors.green,
                    isMain: true
                  ),
                  const SizedBox(height: 15),
                  
                  // GRILLE DES STATS SECONDAIRES
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "UTILISATEURS", 
                          "${stats['user_count']}", 
                          Icons.people_alt_rounded, 
                          Colors.orange
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _statCard(
                          "TONTINES ACTIVES", 
                          "${stats['tontine_count'] ?? 0}", 
                          Icons.groups_3_rounded, 
                          Colors.blue
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "FLUX TOTAL", 
                          currencyFormat.format(stats['total_volume']), 
                          Icons.insights_rounded, 
                          Colors.purple
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  _buildHeader("Actions de supervision"),
                  const SizedBox(height: 15),
                  
                  _actionTile(
                    "Envoyer une alerte Push", 
                    "Notifier tous les membres", 
                    Icons.notifications_active, 
                    Colors.redAccent,
                    () => _showNotificationDialog(context)
                  ),
                  _actionTile(
                    "Gestion des Tontines", 
                    "Voir les cycles en cours", 
                    Icons.groups_3_rounded, 
                    dark,
                    () {}
                  ),
                  _actionTile(
                    "Audit des transactions", 
                    "Historique global sécurisé", 
                    Icons.security_rounded, 
                    gold,
                    () {}
                  ),

                  if (commissions.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    _buildHeader("Commissions récentes (2%)"),
                    const SizedBox(height: 15),
                    ...commissions.map((c) => _commissionTile(c)),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- COMPOSANTS UI RÉUTILISABLES ---

  Widget _buildHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: dark, letterSpacing: 0.5));
  }

  Widget _statCard(String title, String value, IconData icon, Color color, {bool isMain = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isMain ? dark : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
              if(isMain) Icon(Icons.trending_up, color: gold, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Text(title, style: TextStyle(color: isMain ? Colors.white70 : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, 
              style: TextStyle(
                fontSize: isMain ? 28 : 20, 
                fontWeight: FontWeight.w900, 
                color: isMain ? gold : dark
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _commissionTile(Map<String, dynamic> c) {
    final amount = double.tryParse(c['commission_amount']?.toString() ?? '0') ?? 0;
    final gross = double.tryParse(c['gross_amount']?.toString() ?? '0') ?? 0;
    final tontineName = c['tontine_name'] ?? 'Tontine';
    final date = c['created_at']?.toString().substring(0, 10) ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.monetization_on_rounded, color: Colors.green, size: 22),
        ),
        title: Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        subtitle: Text("$tontineName — sur ${currencyFormat.format(gross)}", style: const TextStyle(fontSize: 11)),
        trailing: Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alerte Générale"),
        content: const TextField(decoration: InputDecoration(hintText: "Entrez votre message...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Envoyer")),
        ],
      ),
    );
  }
}