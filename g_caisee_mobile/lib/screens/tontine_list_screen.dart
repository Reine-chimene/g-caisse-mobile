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
  
  final Color primaryColor = const Color(0xFFFF7900); // Orange Orange
  final Color backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

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
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.group, color: primaryColor),
            ),
            title: Text(t['name'] ?? "Groupe", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text("${t['amount_to_pay']} FCFA • ${t['frequency']}"),
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
    return Center(child: Text("Vous n'avez pas encore de groupe."));
  }
}