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

  late Future<List<dynamic>> _auctionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAuctions();
  }

  // ✅ Méthode pour rafraîchir les enchères
  void _refreshAuctions() {
    setState(() {
      _auctionsFuture = ApiService.getAuctions(widget.tontineId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("ENCHÈRES DU TOUR", 
          style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAuctions,
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _auctionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: gold));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement", style: TextStyle(color: Colors.red.shade300)));
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

          return RefreshIndicator(
            color: gold,
            backgroundColor: cardGrey,
            onRefresh: () async => _refreshAuctions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, i) {
                var auction = snapshot.data![i];
                return _buildAuctionCard(auction);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuctionCard(Map auction) {
    // Calcul de la mise actuelle (logique backend-ready)
    double currentBid = double.tryParse(auction['current_highest_bid']?.toString() ?? 
                        auction['minimum_bid'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        // ✅ Correction : withValues au lieu de withOpacity
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  // ✅ Correction : withValues
                  color: Colors.red.withValues(alpha: 0.2), 
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer, color: Colors.red, size: 14),
                    SizedBox(width: 5),
                    Text("LIVE", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBidInfo("Mise minimale", "${auction['minimum_bid']} FCFA", CrossAxisAlignment.start),
              _buildBidInfo("Meilleure offre", "$currentBid FCFA", CrossAxisAlignment.end, isHighlight: true),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => _showBidDialog(context, auction, currentBid),
              icon: const Icon(Icons.gavel_rounded),
              label: const Text("PLACER UNE MISE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidInfo(String label, String value, CrossAxisAlignment align, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          color: isHighlight ? gold : Colors.white, 
          fontSize: isHighlight ? 18 : 15, 
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal
        )),
      ],
    );
  }

  void _showBidDialog(BuildContext context, Map auction, double currentBid) {
    TextEditingController bidController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardGrey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Nouvelle Mise", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("L'offre actuelle est de $currentBid FCFA", 
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Entrez votre montant",
                    hintStyle: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold.withValues(alpha: 0.5))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context), 
                child: const Text("Annuler", style: TextStyle(color: Colors.grey))
              ),
              if (isSubmitting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    double? userBid = double.tryParse(bidController.text);
                    
                    if (userBid == null || userBid <= currentBid) {
                      _showSnackBar("Votre mise doit être supérieure à $currentBid FCFA", Colors.orange);
                      return;
                    }

                    setDialogState(() => isSubmitting = true);
                    
                    try {
                      // Appel API (à décommenter quand ton ApiService sera prêt)
                      // await ApiService.placeBid(auction['id'], userBid);
                      await Future.delayed(const Duration(milliseconds: 1200));

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _refreshAuctions();
                      _showSnackBar("Mise enregistrée avec succès !", Colors.green);
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      _showSnackBar("Erreur lors de la mise", Colors.red);
                    }
                  },
                  child: const Text("CONFIRMER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating)
    );
  }
}