import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tontine_details_screen.dart'; 
import 'create_tontine_screen.dart'; 

class TontineListScreen extends StatefulWidget {
  final int userId; 
  final Map<String, dynamic>? userData; // Nécessaire pour transmettre au Chat

  const TontineListScreen({super.key, required this.userId, this.userData});

  @override
  State<TontineListScreen> createState() => _TontineListScreenState();
}

class _TontineListScreenState extends State<TontineListScreen> {
  List<dynamic> tontines = [];
  bool isLoading = true;
  
  // Couleurs G-Caisse
  final Color primaryColor = const Color(0xFFD4AF37);
  final Color backgroundColor = const Color(0xFFF5F6F8);
  final Color textColor = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

  // RÉEL : Appel API sans simulation
  Future<void> _fetchTontines() async {
    if (!mounted) return;
    setState(() => isLoading = true); 
    try {
      final data = await ApiService.getTontines(widget.userId); 
      if (mounted) {
        setState(() {
          tontines = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Erreur chargement tontines: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("MES GROUPES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTontines,
          )
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => CreateTontineScreen(userId: widget.userId))
          ).then((_) => _fetchTontines());
        },
        label: const Text("CRÉER UN GROUPE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : tontines.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchTontines,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: tontines.length,
                    itemBuilder: (context, i) {
                      var t = tontines[i];
                      double amount = double.tryParse(t['amount_to_pay']?.toString() ?? "0") ?? 0.0;

                      return _buildTontineCard(t, amount);
                    },
                  ),
                ),
    );
  }

  Widget _buildTontineCard(Map t, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, const Color(0xFF8B6914)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.groups_3_rounded, color: Colors.white, size: 28),
        ),
        title: Text(
          t['name'] ?? "Groupe de tontine", 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _badgeInfo(Icons.payments, "${amount.toStringAsFixed(0)} F"),
                const SizedBox(width: 10),
                _badgeInfo(Icons.repeat, t['frequency'] ?? "Mensuel"),
              ],
            ),
          ],
        ),
        onTap: () async {
          // ✅ CORRECTION : Transmission de userData au détail
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (c) => TontineDetailsScreen(
              tontine: t,
              userId: widget.userId,
              userData: widget.userData ?? {}, 
            ))
          );
          if (result == true) _fetchTontines();
        },
      ),
    );
  }

  Widget _badgeInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_2_outlined, size: 100, color: primaryColor.withOpacity(0.2)),
            const SizedBox(height: 20),
            const Text("Aucune tontine active", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Rejoignez un groupe pour commencer à épargner avec vos proches.", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }
}