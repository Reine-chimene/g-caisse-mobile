import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tontine_details_screen.dart'; // Remplace par ton vrai nom de fichier si différent
import 'create_tontine_screen.dart'; 

class TontineListScreen extends StatefulWidget {
  const TontineListScreen({super.key});

  @override
  State<TontineListScreen> createState() => _TontineListScreenState();
}

class _TontineListScreenState extends State<TontineListScreen> {
  // Variables pour gérer l'état de la liste
  List<dynamic> tontines = [];
  bool isLoading = true;
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

  // Fonction pour charger les tontines et mettre à jour l'écran
  Future<void> _fetchTontines() async {
    if (!mounted) return;
    
    setState(() => isLoading = true); 
    try {
      final data = await ApiService.getTontines();
      if (mounted) {
        setState(() {
          tontines = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // --- APP BAR ---
      appBar: AppBar(
        title: Text("MES GROUPES", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTontines,
          )
        ],
      ),

      // --- LE BOUTON CRÉER ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        onPressed: () {
          // Navigation vers l'écran de création
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const CreateTontineScreen()) 
          ).then((_) {
            // QUAND ON REVIENT : On rafraîchit la liste !
            _fetchTontines();
          });
        },
        label: const Text("Nouveau Groupe", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
      ),

      // --- LA LISTE ---
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: gold))
          : tontines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_3, size: 80, color: Colors.grey.shade800),
                      const SizedBox(height: 10),
                      const Text("Aucune tontine active", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text("Créez votre premier groupe !", style: TextStyle(color: gold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 80), // Espace pour le bouton FAB
                  itemCount: tontines.length,
                  itemBuilder: (context, i) {
                    var t = tontines[i];
                    
                    // On récupère le montant de la base de données de façon sécurisée
                    double amount = double.tryParse(t['amount'].toString()) ?? 0.0;

                    return Card(
                      color: cardGrey,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: gold.withOpacity(0.2),
                          child: Icon(Icons.savings, color: gold),
                        ),
                        title: Text(
                          t['name'] ?? "Tontine", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                "${amount.toStringAsFixed(0)} FCFA / ${t['frequency'] ?? 'mois'}", 
                                style: TextStyle(color: Colors.grey.shade400)
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                        onTap: () {
                          // On entre dans l'écran de détails
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (c) => TontineDetailsScreen(tontine: t))
                          );
                        }
                      ),
                    );
                  },
                ),
    );
  }
}