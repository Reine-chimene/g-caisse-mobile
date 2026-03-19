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

  double emergencyFund = 0.0;
  List<dynamic> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  // Formateur pour les montants (ex: 150 000 F)
  String _fmf(double amount) => amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');

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
        title: Text("SOLIDARITÉ & SOCIAL", 
          style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRealData)],
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
                    // 1. CARTE DU FONDS D'URGENCE
                    _buildEmergencyFundCard(),
                    
                    const SizedBox(height: 30),
                    _buildSectionTitle("Cotisations Sociales", "Aides obligatoires (Deuil, Naissances...)"),
                    const SizedBox(height: 15),
                    
                    // Exemples d'aides fixes (Saisie d'option de cotisation)
                    _buildFixedContributionTile("Aide au Deuil - Membre Famille X", 5000, true),
                    _buildFixedContributionTile("Soutien Naissance - Nouveau-né Y", 2000, false),

                    const SizedBox(height: 30),
                    _buildSectionTitle("Collectes Communautaires", "Soutiens volontaires et projets"),
                    const SizedBox(height: 20),

                    // 2. LISTE DES ÉVÉNEMENTS DYNAMIQUES
                    events.isEmpty 
                        ? _buildEmptyState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.length,
                            itemBuilder: (context, index) => _buildEventCard(events[index]),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildFixedContributionTile(String label, double amount, bool isPaid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPaid ? Colors.green.withOpacity(0.3) : gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isPaid ? Icons.check_circle : Icons.pending_actions, 
               color: isPaid ? Colors.green : gold, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Text("${_fmf(amount)} F", 
               style: TextStyle(color: isPaid ? Colors.white70 : gold, fontWeight: FontWeight.bold)),
        ],
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CAISSE DE SOLIDARITÉ", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Icon(Icons.shield_outlined, color: gold, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Text("${_fmf(emergencyFund)} FCFA", 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.history, color: Colors.white70, size: 14),
              SizedBox(width: 5),
              Text("Historique des décaissements", 
                style: TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map event) {
    double target = double.tryParse(event['target_amount'].toString()) ?? 0.0;
    double collected = double.tryParse(event['collected_amount'].toString()) ?? 0.0;
    double progress = target > 0 ? collected / target : 0.0;
    bool isCompleted = collected >= target;

    Color eventColor = event['event_type'] == 'death' ? Colors.redAccent : (event['event_type'] == 'birth' ? Colors.purpleAccent : Colors.blueAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: eventColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(event['event_type'].toString().toUpperCase(), 
                  style: TextStyle(color: eventColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              if (isCompleted) const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Text(event['description'] ?? "Collecte Spéciale", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${_fmf(collected)} F", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18)),
              Text("sur ${_fmf(target)} F", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: Colors.white10,
            color: isCompleted ? Colors.greenAccent : eventColor,
            minHeight: 6,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.white10 : gold,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isCompleted ? null : () => _showDonationDialog(context, event),
              child: Text(isCompleted ? "OBJECTIF ATTEINT" : "FAIRE UN DON", 
                style: TextStyle(color: isCompleted ? Colors.grey : Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            Icon(Icons.volunteer_activism_outlined, size: 60, color: Colors.grey.shade800),
            const SizedBox(height: 10),
            const Text("Aucune collecte active.", style: TextStyle(color: Colors.grey)),
          ],
        ),
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
                Text("Soutenir cette cause", style: TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Montant (FCFA)",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold.withOpacity(0.3))),
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
                                const SnackBar(content: Text("✅ Don enregistré avec succès !"), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("❌ Échec de la transaction."), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      child: const Text("CONFIRMER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
              ],
            ),
          );
        }
      ),
    );
  }
}