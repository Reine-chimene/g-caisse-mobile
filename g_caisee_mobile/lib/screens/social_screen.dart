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

  // Chargement des données réelles depuis PostgreSQL sur Render
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
      debugPrint("Erreur Social: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("SOLIDARITÉ & SOCIAL", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRealData)
        ],
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: gold)) 
          : RefreshIndicator(
              onRefresh: _fetchRealData,
              color: gold,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. LA CAISSE DE SECOURS (VRAI MONTANT)
                    _buildEmergencyFundCard(),

                    const SizedBox(height: 30),
                    const Text("Collectes Communautaires", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text("Soutenez les membres de la G-Caisse dans leurs projets et épreuves.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 20),

                    // 2. LISTE DES ÉVÉNEMENTS
                    events.isEmpty 
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: Column(
                                children: [
                                  Icon(Icons.volunteer_activism_outlined, size: 60, color: Colors.grey.shade800),
                                  const SizedBox(height: 10),
                                  const Text("Aucune collecte active pour le moment.", style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            )
                          )
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
            ),
    );
  }

  Widget _buildEmergencyFundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade900, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("CAISSE DE SOLIDARITÉ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Icon(Icons.security, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 15),
          const Text("Réserve globale pour imprévus", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text("${emergencyFund.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map event) {
    double target = double.tryParse(event['target_amount'].toString()) ?? 0.0;
    double collected = double.tryParse(event['collected_amount'].toString()) ?? 0.0;
    double progress = target > 0 ? collected / target : 0.0;
    bool isCompleted = collected >= target;

    Color eventColor = Colors.blueAccent;
    if (event['event_type'] == 'emergency' || event['event_type'] == 'death') {
      eventColor = Colors.redAccent;
    } else if (event['event_type'] == 'joy' || event['event_type'] == 'birth') {
      eventColor = Colors.purpleAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: eventColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(event['event_type'].toString().toUpperCase(), style: TextStyle(color: eventColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (isCompleted) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
            ],
          ),
          const SizedBox(height: 15),
          Text(event['description'] ?? "Collecte Spéciale", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${collected.toStringAsFixed(0)} F récoltés", style: TextStyle(color: gold, fontWeight: FontWeight.w600)),
              Text("Obj: ${target.toStringAsFixed(0)} F", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: isCompleted ? Colors.greenAccent : eventColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.1) : gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isCompleted ? null : () => _showDonationDialog(context, event),
              child: Text(
                isCompleted ? "OBJECTIF ATTEINT" : "FAIRE UN DON",
                style: TextStyle(color: isCompleted ? Colors.greenAccent : Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showDonationDialog(BuildContext context, Map event) {
    final TextEditingController amountController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 30, 
              left: 25, right: 25, top: 25
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Contribuer à la solidarité", style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Montant (FCFA)",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold.withValues(alpha: 0.3))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold, width: 2)),
                  ),
                ),
                const SizedBox(height: 40),
                isProcessing 
                  ? CircularProgressIndicator(color: gold)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold, 
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () async {
                        double amount = double.tryParse(amountController.text) ?? 0;
                        if (amount > 0) {
                          setModalState(() => isProcessing = true);
                          try {
                            await ApiService.makeDonation(int.parse(event['id'].toString()), amount);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _fetchRealData(); 
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text("✅ Merci pour votre générosité !"), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text("❌ Une erreur est survenue."), backgroundColor: Colors.red),
                              );
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