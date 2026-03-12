import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SavingScreen extends StatefulWidget {
  final Map<String, dynamic>? userData; // Ajout pour récupérer l'ID réel
  const SavingScreen({super.key, this.userData});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color darkBlue = const Color(0xFF1A1A2E); // Cohérence avec ton Home
  final Color cardGrey = const Color(0xFF252525);

  double savingsBalance = 0.0; 
  double mainBalance = 0.0;    
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  // RÉEL : Récupération des données depuis ton backend Render
  Future<void> _fetchRealData() async {
    try {
      int userId = widget.userData?['id'] ?? 1; 

      // Appels API réels
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
      _showError("Erreur de synchronisation");
    }
  }

  void _showTransactionDialog(bool isDeposit) {
    final TextEditingController amountController = TextEditingController();
    String actionName = isDeposit ? "Épargner" : "Retirer";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(actionName, style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDeposit
                  ? "Transférer du solde principal vers l'épargne\n(Max: ${mainBalance.toStringAsFixed(0)} F)"
                  : "Transférer de l'épargne vers le solde principal\n(Max: ${savingsBalance.toStringAsFixed(0)} F)",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Montant FCFA",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: gold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) return;

              Navigator.pop(context);
              setState(() => isLoading = true);

              try {
                int userId = widget.userData?['id'] ?? 1;
                if (isDeposit) {
                  if (amount > mainBalance) {
                    _showError("Fonds insuffisants sur le compte principal");
                  } else {
                    await ApiService.depositToSavings(userId, amount);
                    _showSuccess("Épargne réussie !");
                  }
                } else {
                  // RÉEL : Ici tu appelles ta route de retrait d'épargne si elle existe
                  // Pour l'instant, on applique la logique métier G-Caisse
                   _showError("Le retrait d'épargne est soumis à une validation de 24h.");
                }
                await _fetchRealData(); 
              } catch (e) {
                _showError("La transaction a échoué");
              } finally {
                if (mounted) setState(() => isLoading = false);
              }
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Noir profond
      appBar: AppBar(
        title: const Text("COFFRE-FORT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: gold)) 
        : RefreshIndicator(
            onRefresh: _fetchRealData,
            color: gold,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildSavingsCard(),
                  const SizedBox(height: 10),
                  _buildActionButtons(),
                  const SizedBox(height: 35),
                  _buildHistorySection(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 20)],
        image: const DecorationImage(
          image: AssetImage('assets/card_bg.png'), // Utilise ton image de fond
          opacity: 0.05,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_person_rounded, color: gold, size: 40),
          const SizedBox(height: 15),
          const Text("TOTAL ÉPARGNÉ", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            "${savingsBalance.toStringAsFixed(0)} FCFA", 
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text("Croissance Halal : +3.5% / an", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _actionBtn(true, "Épargner", Icons.add_moderator_rounded)),
          const SizedBox(width: 15),
        
               Expanded(child: _actionBtn(false, "Retirer", Icons.upload_rounded)),
        ],
      ),
    );
  }

  Widget _actionBtn(bool isDeposit, String label, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDeposit ? gold : Colors.white10,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      onPressed: () => _showTransactionDialog(isDeposit),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isDeposit ? Colors.black : Colors.white),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: isDeposit ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Historique du coffre", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          transactions.isEmpty 
            ? const Center(child: Padding(
                padding: EdgeInsets.only(top: 50),
                child: Text("Aucun mouvement détecté", style: TextStyle(color: Colors.white24)),
              ))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, i) {
                  var tx = transactions[i];
                  bool isAdd = tx['type'] == 'deposit' || tx['type'] == 'saving';
                  return _buildTransactionItem(tx, isAdd);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map tx, bool isAdd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAdd ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Icon(isAdd ? Icons.south_west : Icons.north_east, color: isAdd ? Colors.green : Colors.red, size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAdd ? "Dépôt coffre" : "Retrait coffre", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(tx['created_at'].toString().split('T')[0], style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            "${isAdd ? '+' : '-'} ${tx['amount']} F", 
            style: TextStyle(color: isAdd ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 16)
          ),
        ],
      ),
    );
  }
}