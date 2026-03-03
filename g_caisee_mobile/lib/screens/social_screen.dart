import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);

  // Variables d'état
  double emergencyFund = 0.0;
  List<dynamic> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  // Chargement des données réelles depuis PostgreSQL
  Future<void> _fetchRealData() async {
    try {
      final fund = await ApiService.getSocialFund();
      final eventsList = await ApiService.getSocialEvents(); 
      
      if (mounted) {
        setState(() {
          emergencyFund = fund;
          events = eventsList;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Erreur Social: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("SOLIDARITÉ & SOCIAL", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRealData)
        ],
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: gold)) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LA CAISSE DE SECOURS (VRAI MONTANT)
                  _buildEmergencyFundCard(),

                  const SizedBox(height: 25),
                  const Text("Collectes en cours", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // 2. LISTE DES ÉVÉNEMENTS
                  events.isEmpty 
                      ? const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("Aucune collecte active.", style: TextStyle(color: Colors.grey))))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            return _buildEventCard(events[index]);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmergencyFundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("CAISSE DE SECOURS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Icon(Icons.shield, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Réserve disponible (Réelle)", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          // Affichage du vrai montant formaté
          Text("${emergencyFund.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map event) {
    // Conversion sécurisée
    double target = double.parse(event['target_amount'].toString());
    double collected = double.parse(event['collected_amount'].toString());
    double progress = target > 0 ? collected / target : 0.0;
    bool isCompleted = collected >= target;

    // Choix de la couleur
    Color eventColor = Colors.blue;
    if (event['type'] == 'emergency') eventColor = Colors.red;
    if (event['type'] == 'joy') eventColor = Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: eventColor.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
                child: Text(event['type'].toString().toUpperCase(), style: TextStyle(color: eventColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (isCompleted) const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          
          Text(event['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(event['description'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${collected.toStringAsFixed(0)} F", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
              Text("Obj: ${target.toStringAsFixed(0)} F", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: Colors.grey.shade800,
            color: eventColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(5),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey.shade800 : gold,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isCompleted ? null : () => _showDonationDialog(context, event),
              child: Text(
                isCompleted ? "OBJECTIF ATTEINT" : "SOUTENIR MAINTENANT",
                style: TextStyle(color: isCompleted ? Colors.white54 : Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showDonationDialog(BuildContext context, Map event) {
    TextEditingController amountController = TextEditingController();
    bool isProcessing = false; // Pour éviter le double clic

    showModalBottomSheet(
      context: context,
      backgroundColor: cardGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
              left: 20, right: 20, top: 20
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Faire un don", style: TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Pour : ${event['title']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Montant (FCFA)",
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold, width: 2)),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                isProcessing 
                  ? CircularProgressIndicator(color: gold)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: gold, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () async {
                        double amount = double.tryParse(amountController.text) ?? 0;
                        if (amount > 0) {
                          setModalState(() => isProcessing = true); // Affiche chargement
                          try {
                            // APPEL API RÉEL
                            await ApiService.makeDonation(event['id'], amount);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _fetchRealData(); // Rafraichir l'écran principal
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Don enregistré avec succès !")));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors du don. Réessayez.")));
                            }
                          }
                        }
                      },
                      child: const Text("CONFIRMER LE DON", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
              ],
            ),
          );
        }
      ),
    );
  }
}