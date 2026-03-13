import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tontine_details_screen.dart'; 
import 'create_tontine_screen.dart'; 

class TontineListScreen extends StatefulWidget {
  final int userId; 
  final Map<String, dynamic>? userData;

  const TontineListScreen({super.key, required this.userId, this.userData});

  @override
  State<TontineListScreen> createState() => _TontineListScreenState();
}

class _TontineListScreenState extends State<TontineListScreen> {
  List<dynamic> tontines = [];
  bool isLoading = true;
  String? errorMessage; // Ajout pour afficher l'erreur à l'écran
  
  final Color primaryColor = const Color(0xFFFF7900); // Orange Orange
  final Color backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

  Future<void> _fetchTontines() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null; // On réinitialise l'erreur
    }); 
    try {
      debugPrint("--- DÉBUT FETCH TONTINES pour User ID: ${widget.userId} ---");
      final data = await ApiService.getTontines(widget.userId); 
      debugPrint("--- DATA REÇUES: $data ---");

      if (mounted) {
        setState(() {
          // Sécurité : on s'assure que data est bien une liste avant de l'assigner
          if (data is List) {
             tontines = data;
          } else {
             debugPrint("Attention : data n'est pas une liste !");
             tontines = []; // Fallback
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("--- ERREUR FETCH TONTINES: $e ---");
      if (mounted) {
        setState(() {
           isLoading = false;
           errorMessage = e.toString(); // On stocke l'erreur pour l'afficher
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("MES GROUPES", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.sync, color: primaryColor), onPressed: _fetchTontines)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CreateTontineScreen(userId: widget.userId))).then((_) => _fetchTontines()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : errorMessage != null // S'il y a une erreur, on l'affiche
            ? _buildErrorState()
            : tontines.isEmpty ? _buildEmptyState() : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: tontines.length,
      itemBuilder: (context, i) {
        var t = tontines[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: CircleAvatar(
              backgroundColor: primaryColor.withValues(alpha: 0.1), // Correction warning
              child: Icon(Icons.group, color: primaryColor),
            ),
            title: Text(t['name'] ?? "Groupe", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text("${t['amount_to_pay'] ?? 0} FCFA • ${t['frequency'] ?? 'N/A'}"), // Sécurité sur les champs
                const SizedBox(height: 5),
                // ✅ SYSTEME DE TRAÇAGE (MAC) : Indicateur visuel
                Row(
                  children: [
                    const Icon(Icons.radar, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text("Traçage actif : ${t['member_count'] ?? '0'} membres", style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TontineDetailsScreen(
              tontine: t, userId: widget.userId, userData: widget.userData ?? {}
            ))),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("Vous n'avez pas encore de groupe.", style: TextStyle(color: Colors.grey)),
        ],
      )
    );
  }

  // NOUVEAU : Widget pour afficher l'erreur
  Widget _buildErrorState() {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Erreur de chargement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(errorMessage ?? "Une erreur est survenue", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchTontines,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text("Réessayer", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      )
    );
  }
}