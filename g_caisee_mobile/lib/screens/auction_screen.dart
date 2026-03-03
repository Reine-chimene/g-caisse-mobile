import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuctionScreen extends StatefulWidget {
  final int tontineId;
  const AuctionScreen({super.key, required this.tontineId});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("ENCHÈRES DU TOUR", style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getAuctions(widget.tontineId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: gold));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 80, color: Colors.grey.shade800),
                  const SizedBox(height: 10),
                  const Text("Aucune enchère en cours", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              var auction = snapshot.data![i];
              return _buildAuctionCard(auction);
            },
          );
        },
      ),
    );
  }

  Widget _buildAuctionCard(Map auction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cycle n°${auction['cycle_number']}", 
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                child: Row(
                  children: const [
                    Icon(Icons.timer, color: Colors.red, size: 14),
                    SizedBox(width: 5),
                    Text("2h 15m", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Mise minimale", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("${auction['minimum_bid']} FCFA", style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Meilleure offre", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("${auction['current_highest_bid'] ?? auction['minimum_bid']} FCFA", 
                    style: TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showBidDialog(context, auction),
              icon: const Icon(Icons.gavel, color: Colors.black),
              label: const Text("PLACER UNE MISE", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBidDialog(BuildContext context, Map auction) {
    TextEditingController bidController = TextEditingController();
    bool isSubmitting = false; // Pour gérer l'animation de chargement

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardGrey,
            title: Text("Nouvelle Mise", style: TextStyle(color: gold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Votre mise doit être supérieure à l'offre actuelle.", 
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 15),
                TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Montant FCFA",
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Annuler", style: TextStyle(color: Colors.grey))
              ),
              isSubmitting
                ? Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: gold, strokeWidth: 2)
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: gold),
                    onPressed: () async {
                      if (bidController.text.isEmpty) return;
                      
                      // 1. On lance l'animation de chargement
                      setDialogState(() => isSubmitting = true);
                      
                      // 2. On fait "semblant" de contacter le serveur pendant 1.5 secondes
                      await Future.delayed(const Duration(milliseconds: 1500));
                      
                      // 3. On vérifie que la fenêtre est toujours ouverte avant d'agir
                      if (!context.mounted) return;
                      
                      // 4. On ferme la fenêtre et on affiche le succès
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Mise enregistrée avec succès !"), 
                          backgroundColor: Colors.green
                        )
                      );
                    },
                    child: const Text("CONFIRMER", style: TextStyle(color: Colors.black)),
                  ),
            ],
          );
        }
      ),
    );
  }
}