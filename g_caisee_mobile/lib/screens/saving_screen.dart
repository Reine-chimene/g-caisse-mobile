import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SavingScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const SavingScreen({super.key, this.userData});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color darkBlue = const Color(0xFF1A1A2E); 
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

  // Formateur de prix (ex: 100 000)
  String _fmf(double amount) => amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');

  Future<void> _fetchRealData() async {
    try {
      int userId = widget.userData?['id'] ?? 0; 
      if (userId == 0) return;

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
      debugPrint("Erreur Sync Épargne: $e");
    }
  }

  void _showTransactionDialog(bool isDeposit) {
    final TextEditingController amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: darkBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          left: 25, right: 25, top: 25
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text(isDeposit ? "ALIMENTER LE COFFRE" : "RETRAIT DU COFFRE", 
              style: TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              isDeposit 
                ? "Disponible : ${_fmf(mainBalance)} FCFA" 
                : "Épargne actuelle : ${_fmf(savingsBalance)} FCFA",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (!isDeposit)
              Container(
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text("Les retraits d'épargne nécessitent 24h de validation.", style: TextStyle(color: Colors.orange, fontSize: 11))),
                  ],
                ),
              ),
            const SizedBox(height: 25),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Montant (F)",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold.withOpacity(0.3))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold, width: 2)),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold, 
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () async {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                
                if (isDeposit && amount > mainBalance) {
                  _showError("Solde principal insuffisant");
                  return;
                }

                Navigator.pop(context);
                setState(() => isLoading = true);

                try {
                  int userId = widget.userData?['id'] ?? 0;
                  if (isDeposit) {
                    await ApiService.depositToSavings(userId, amount);
                    _showSuccess("Fonds sécurisés dans le coffre !");
                  } else {
                    // Logique de demande de retrait (Pending)
                    _showSuccess("Demande de retrait transmise (24h)");
                  }
                  _fetchRealData();
                } catch (e) {
                  _showError("Erreur lors de l'opération");
                } finally {
                  setState(() => isLoading = false);
                }
              },
              child: Text(isDeposit ? "CONFIRMER LE DÉPÔT" : "DEMANDER LE RETRAIT", 
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("MON COFFRE-FORT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
              padding: const EdgeInsets.only(bottom: 30),
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
        boxShadow: [BoxShadow(color: gold.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: gold.withOpacity(0.1), radius: 30, child: Icon(Icons.lock_outline, color: gold, size: 30)),
          const SizedBox(height: 20),
          const Text("TOTAL ÉPARGNÉ", style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Text("${_fmf(savingsBalance)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 14),
                SizedBox(width: 8),
                Text("Croissance Halal : +3.5% / an", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
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
          Expanded(child: _actionBtn(true, "ÉPARGNER", Icons.add_circle_outline)),
          const SizedBox(width: 15),
          Expanded(child: _actionBtn(false, "RETIRER", Icons.outbox_rounded)),
        ],
      ),
    );
  }

  Widget _actionBtn(bool isDeposit, String label, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDeposit ? gold : cardGrey,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isDeposit ? Colors.transparent : gold.withOpacity(0.3))),
      ),
      onPressed: () => _showTransactionDialog(isDeposit),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isDeposit ? Colors.black : gold, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isDeposit ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("HISTORIQUE RÉCENT", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 20),
          transactions.isEmpty 
            ? _buildEmptyHistory()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, i) {
                  var tx = transactions[i];
                  bool isAdd = tx['type'].toString().contains('deposit') || tx['type'].toString().contains('saving');
                  return _buildTransactionItem(tx, isAdd);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map tx, bool isAdd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(isAdd ? Icons.arrow_downward : Icons.arrow_upward, color: isAdd ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAdd ? "Dépôt Coffre" : "Retrait Coffre", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(tx['created_at'].toString().split('T')[0], style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text("${isAdd ? '+' : '-'} ${_fmf(double.parse(tx['amount'].toString()))} F", 
            style: TextStyle(color: isAdd ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, color: Colors.white10, size: 50),
          const SizedBox(height: 10),
          const Text("Aucune transaction pour le moment", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}