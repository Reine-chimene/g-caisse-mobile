import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tontine_details_screen.dart'; 
import 'create_tontine_screen.dart'; 

class TontineListScreen extends StatefulWidget {
  const TontineListScreen({super.key});

  @override
  State<TontineListScreen> createState() => _TontineListScreenState();
}

class _TontineListScreenState extends State<TontineListScreen> {
  List<dynamic> tontines = [];
  bool isLoading = true;
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

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
      debugPrint("Erreur chargement tontines: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      appBar: AppBar(
        title: Text("MES TONTINES", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTontines,
          )
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const CreateTontineScreen()) 
          ).then((_) => _fetchTontines()); // Rafraîchit au retour
        },
        label: const Text("CRÉER UN GROUPE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: gold))
          : tontines.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchTontines,
                  color: gold,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 100),
                    itemCount: tontines.length,
                    itemBuilder: (context, i) {
                      var t = tontines[i];
                      
                      // Adapté à ton schéma : amount_to_pay
                      double amount = double.tryParse(t['amount_to_pay']?.toString() ?? "0") ?? 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardGrey,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.groups_rounded, color: gold),
                          ),
                          title: Text(
                            t['name'] ?? "Tontine sans nom", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              "${amount.toStringAsFixed(0)} FCFA • ${t['frequency'] ?? 'Mensuel'}", 
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (c) => TontineDetailsScreen(tontine: t))
                            );
                          }
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          const Text("Vous n'avez pas encore de groupe", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Créez-en un pour commencer à cotiser !", style: TextStyle(color: gold.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }
}