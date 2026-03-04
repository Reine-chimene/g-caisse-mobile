import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tontine_details_screen.dart'; 
import 'create_tontine_screen.dart'; 

class TontineListScreen extends StatefulWidget {
  // NOUVEAUTÉ : La page EXIGE le vrai ID de l'utilisateur
  final int userId; 

  const TontineListScreen({super.key, required this.userId});

  @override
  State<TontineListScreen> createState() => _TontineListScreenState();
}

class _TontineListScreenState extends State<TontineListScreen> {
  List<dynamic> tontines = [];
  bool isLoading = true;
  
  // Couleurs "Mode Jour" (Style Banque)
  final Color primaryColor = const Color(0xFFD4AF37);
  final Color backgroundColor = const Color(0xFFF5F6F8);
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

  Future<void> _fetchTontines() async {
    if (!mounted) return;
    
    setState(() => isLoading = true); 
    try {
      // NOUVEAUTÉ : On passe le vrai userId au serveur !
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
        title: Text("Mes Tontines", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _fetchTontines,
          )
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const CreateTontineScreen()) 
          ).then((_) => _fetchTontines()); // Rafraîchit au retour si on a créé une tontine
        },
        label: const Text("CRÉER UN GROUPE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.groups_rounded, color: primaryColor, size: 28),
                          ),
                          title: Text(
                            t['name'] ?? "Tontine sans nom", 
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(Icons.monetization_on, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  "${amount.toStringAsFixed(0)} FCFA", 
                                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 13)
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  "${t['frequency'] ?? 'Mensuel'}", 
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12)
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
                            child: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14)
                          ),
                          
                          onTap: () async {
                            final result = await Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (c) => TontineDetailsScreen(
                                tontine: t,
                                userId: widget.userId // NOUVEAUTÉ : On transmet l'ID au détail
                              ))
                            );
                            
                            // Si l'utilisateur a cliqué sur Quitter, on rafraîchit la liste !
                            if (result == true) {
                              _fetchTontines();
                            }
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
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
            child: Icon(Icons.groups_outlined, size: 80, color: Colors.grey[300]),
          ),
          const SizedBox(height: 30),
          Text("Aucun groupe pour le moment", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            "Créez ou rejoignez une tontine\npour commencer à cotiser.", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5)
          ),
        ],
      ),
    );
  }
}