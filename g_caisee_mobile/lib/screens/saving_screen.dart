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

  double savingsBalance = 0.0; 
  double mainBalance = 0.0;    
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    try {
      // Pour la démo, on utilise l'ID 1 ou celui récupéré lors du login
      int userId = 1; 

      final balance = await ApiService.getUserBalance(userId);
      final sBalance = await ApiService.getSavingsBalance(userId);
      final txHistory = await ApiService.getSavingsTransactions(userId);
      
      if (mounted) {
        setState(() {
          mainBalance = balance;
          savingsBalance = sBalance;
          transactions = txHistory;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
                  ? "Transférer depuis votre compte principal\n(Disponible: ${mainBalance.toStringAsFixed(0)} FCFA)"
                  : "Retirer vers votre compte principal\n(Épargne: ${savingsBalance.toStringAsFixed(0)} FCFA)",
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

              Navigator.pop(context);
              setState(() => isLoading = true);

              try {
                if (isDeposit) {
                  if (amount > mainBalance) {
                    _showError("Solde principal insuffisant !");
                  } else {
                    await ApiService.depositToSavings(1, amount);
                  }
                } else {
                   // Logique de retrait simulée ou via une autre route API
                   _showError("Le retrait d'épargne nécessite 24h de préavis (Règle G-Caisse).");
                }

                await _fetchRealData(); 
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("✅ Opération réussie !"), backgroundColor: Colors.green)
                  );
                }
              } catch (e) {
                _showError("Erreur lors de la transaction.");
              } finally {
                if (mounted) setState(() => isLoading = false);
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
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: gold)) 
        : Column(
            children: [
              _buildSavingsCard(),
              _buildActionButtons(),
              const SizedBox(height: 30),
              _buildHistoryHeader(),
              _buildHistoryList(),
            ],
          ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gold, const Color(0xFF8B6914)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
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
          const Text("Intérêts annuels : +3.5% (Halal)", style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(true, "Déposer", Icons.arrow_downward),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _actionButton(false, "Retirer", Icons.arrow_upward),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(bool isDeposit, String label, IconData icon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: cardGrey,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () => _showTransactionDialog(isDeposit),
      icon: Icon(icon, color: isDeposit ? gold : Colors.orangeAccent),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  Widget _buildHistoryHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("Dernières activités", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHistoryList() {
    return Expanded(
      child: transactions.isEmpty 
        ? Center(child: Text("Aucune opération d'épargne", style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, i) {
              var tx = transactions[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Icon(Icons.savings, color: gold),
                  title: Text(tx['type'] == 'deposit' ? "Dépôt Épargne" : "Retrait", style: const TextStyle(color: Colors.white)),
                  subtitle: Text(tx['created_at'].toString().split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Text("+ ${tx['amount']} F", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
    );
  }
}