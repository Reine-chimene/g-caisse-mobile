import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SavingScreen extends StatefulWidget {
  const SavingScreen({super.key});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);

  // Variables qui recevront les vraies données de la BDD
  double savingsBalance = 0.0; 
  double mainBalance = 0.0;    
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  // --- RÉCUPÉRATION DES VRAIES DONNÉES VIA L'API ---
  Future<void> _fetchRealData() async {
    try {
      // On récupère le solde principal de l'utilisateur (ID 1 pour le moment)
      final balance = await ApiService.getUserBalance(1);
      
      // /!\ IMPORTANT: Tu devras créer ces deux fonctions dans ton api_service.dart
      // pour récupérer le solde d'épargne et l'historique depuis ta base de données.
      // final sBalance = await ApiService.getSavingsBalance(1);
      // final txHistory = await ApiService.getSavingsTransactions(1);
      
      if (mounted) {
        setState(() {
          mainBalance = balance;
          // savingsBalance = sBalance; // A décommenter quand l'API sera prête
          // transactions = txHistory; // A décommenter quand l'API sera prête
          
          // En attendant que l'API soit configurée pour l'épargne, on laisse à 0
          savingsBalance = 0.0;
          transactions = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération des données : $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- BOÎTE DE DIALOGUE POUR DÉPÔT / RETRAIT ---
  void _showTransactionDialog(bool isDeposit) {
    final TextEditingController amountController = TextEditingController();
    String actionName = isDeposit ? "Déposer" : "Retirer";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("$actionName de l'argent", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDeposit
                  ? "Transférer depuis votre compte principal\n(Solde dispo: ${mainBalance.toStringAsFixed(0)} FCFA)"
                  : "Transférer vers votre compte principal\n(Épargne dispo: ${savingsBalance.toStringAsFixed(0)} FCFA)",
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Montant (Ex: 5000)",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(isDeposit ? Icons.add_circle_outline : Icons.remove_circle_outline, color: gold),
                suffixText: "FCFA",
                suffixStyle: TextStyle(color: gold),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;

              Navigator.pop(context); // Ferme la popup
              
              setState(() => isLoading = true); // Affiche le chargement pendant l'envoi

              try {
                if (isDeposit) {
                  if (amount > mainBalance) {
                    _showError("Solde principal insuffisant !");
                    setState(() => isLoading = false);
                    return;
                  }
                  // /!\ APPEL API À CRÉER : await ApiService.depositToSavings(1, amount);
                } else {
                  if (amount > savingsBalance) {
                    _showError("Fonds d'épargne insuffisants !");
                    setState(() => isLoading = false);
                    return;
                  }
                  // /!\ APPEL API À CRÉER : await ApiService.withdrawFromSavings(1, amount);
                }

                // Si l'API réussit, on rafraîchit les vraies données depuis le serveur
                await _fetchRealData(); 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ Transaction de ${amount.toStringAsFixed(0)} FCFA réussie !"), backgroundColor: Colors.green)
                );
              } catch (e) {
                _showError("Erreur lors de la transaction.");
                setState(() => isLoading = false);
              }
            },
            child: const Text("Valider", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("COMPTE ÉPARGNE", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              setState(() => isLoading = true);
              _fetchRealData();
            }
          )
        ],
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: gold)) 
        : SafeArea(
          child: Column(
            children: [
              // --- CARTE D'ÉPARGNE PRINCIPALE ---
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [gold, const Color(0xFF8B6914)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    const Text("Solde Épargne", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      "${savingsBalance.toStringAsFixed(0)} FCFA", 
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 5),
                    const Text("Intérêts annuels : +3.5%", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),

              // --- BOUTONS D'ACTION (DÉPOSER / RETIRER) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardGrey,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => _showTransactionDialog(true), // Dépôt
                        icon: Icon(Icons.arrow_downward, color: gold),
                        label: const Text("Déposer", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardGrey,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => _showTransactionDialog(false), // Retrait
                        icon: const Icon(Icons.arrow_upward, color: Colors.orangeAccent),
                        label: const Text("Retirer", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- HISTORIQUE DES TRANSACTIONS D'ÉPARGNE ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Historique d'épargne", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              
              Expanded(
                child: transactions.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 50, color: Colors.grey.shade800),
                          const SizedBox(height: 10),
                          const Text("Aucune transaction d'épargne", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, i) {
                        var tx = transactions[i];
                        bool isDeposit = tx['type'] == 'depot';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDeposit ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              child: Icon(
                                isDeposit ? Icons.add : Icons.remove, 
                                color: isDeposit ? Colors.green : Colors.orangeAccent
                              ),
                            ),
                            title: Text(isDeposit ? "Dépôt sur épargne" : "Retrait vers compte", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(tx['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            trailing: Text(
                              "${isDeposit ? '+' : '-'} ${tx['amount']} F", 
                              style: TextStyle(color: isDeposit ? Colors.green : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
    );
  }
}