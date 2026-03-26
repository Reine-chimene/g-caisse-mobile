import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final data = await ApiService.getUserTransactions(widget.userId);
      if (!mounted) return; // Sécurité : on vérifie si l'écran est toujours là
      setState(() {
        transactions = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7900)))
        : transactions.isEmpty 
          ? const Center(child: Text("Aucune transaction trouvée"))
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isDeposit = tx['type'] == 'deposit';
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDeposit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                      isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isDeposit ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(tx['description'] ?? (isDeposit ? "Dépôt" : "Retrait")),
                  subtitle: Text(tx['created_at'] != null 
                    ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tx['created_at'])) 
                    : ''),
                  trailing: Text(
                    "${isDeposit ? '+' : '-'} ${tx['amount']} F",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDeposit ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
    );
  }
}