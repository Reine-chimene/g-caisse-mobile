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
  String? errorMessage; 
  
  final Color primaryColor = const Color(0xFFFF7900); 

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

  String _formatPrice(dynamic price) {
    if (price == null) return "0";
    String p = price.toString();
    if (p.length > 3) {
      return p.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
    }
    return p;
  }

  Future<void> _fetchTontines() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    }); 
    try {
      final data = await ApiService.getTontines(widget.userId); 
      if (mounted) {
        setState(() {
          tontines = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Erreur de connexion au serveur.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("MES GROUPES", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (c) => CreateTontineScreen(userId: widget.userId))
        ).then((_) => _fetchTontines()),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("CRÉER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTontines,
        color: primaryColor,
        child: isLoading 
          ? _buildLoadingState()
          : errorMessage != null 
              ? _buildErrorState() // Correction de l'erreur "undefined_method"
              : tontines.isEmpty ? _buildEmptyState() : _buildList(),
      ),
    );
  }

  // --- LES WIDGETS DE CONSTRUCTION (MANQUANTS DANS TON CODE) ---

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 20),
          const Text("Chargement de vos tontines...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 70, color: Colors.red),
            const SizedBox(height: 20),
            Text(errorMessage ?? "Une erreur est survenue", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchTontines,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text("RÉESSAYER", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_3_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text("Aucun groupe trouvé", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text("Créez votre premier groupe maintenant.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tontines.length,
      itemBuilder: (context, i) {
        var t = tontines[i];
        return Container(
          margin: const EdgeInsetsDirectional.only(bottom: 12), // Utilisation de propriétés logiques
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: primaryColor.withValues(alpha: 0.1), 
              child: Icon(Icons.account_balance_wallet_outlined, color: primaryColor),
            ),
            title: Text(t['name'] ?? "Groupe", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${_formatPrice(t['amount_to_pay'])} FCFA • ${t['frequency'] ?? 'N/A'}"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text("TRAÇAGE ACTIF : ${t['member_count'] ?? '0'} MB", 
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TontineDetailsScreen(
              tontine: t, userId: widget.userId, userData: widget.userData ?? {}
            ))),
          ),
        );
      },
    );
  }
}