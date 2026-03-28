import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AdminBankDepositsScreen extends StatefulWidget {
  const AdminBankDepositsScreen({super.key});

  @override
  State<AdminBankDepositsScreen> createState() => _AdminBankDepositsScreenState();
}

class _AdminBankDepositsScreenState extends State<AdminBankDepositsScreen> {
  List<dynamic> _pendingDeposits = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    setState(() => _isLoading = true);
    try {
      final deposits = await ApiService.getPendingBankDeposits();
      if (mounted) setState(() => _pendingDeposits = deposits);
    } catch (e) {
      if (mounted) _showMsg("Erreur de chargement", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateDeposit(int id, String userName, double amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Valider le virement"),
        content: Text("Créditer ${currencyFormat.format(amount)} au compte de $userName ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NON")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("OUI, CRÉDITER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.validateBankDeposit(id);
      if (mounted) {
        _showMsg("Compte crédité avec succès", Colors.green);
        _loadDeposits();
      }
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceAll('Exception:', ''), Colors.red);
    }
  }

  Future<void> _rejectDeposit(int id) async {
    try {
      await ApiService.rejectBankDeposit(id, note: 'Non vérifié');
      if (mounted) {
        _showMsg("Virement rejeté", Colors.orange);
        _loadDeposits();
      }
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceAll('Exception:', ''), Colors.red);
    }
  }

  void _showMsg(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("Virements en attente", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDeposits)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingDeposits.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                    SizedBox(height: 10),
                    Text("Aucun virement en attente", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadDeposits,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingDeposits.length,
                    itemBuilder: (context, index) => _buildDepositCard(_pendingDeposits[index]),
                  ),
                ),
    );
  }

  Widget _buildDepositCard(Map<String, dynamic> d) {
    final amount = double.tryParse(d['amount'].toString()) ?? 0;
    final date = d['created_at']?.toString().substring(0, 16) ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Text("EN ATTENTE", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const Divider(),
            _detailRow("Membre", d['user_name'] ?? ''),
            _detailRow("Téléphone", d['user_phone'] ?? ''),
            _detailRow("Banque expéditeur", d['bank_name'] ?? ''),
            _detailRow("Nom expéditeur", d['sender_name'] ?? 'Non précisé'),
            _detailRow("Référence", d['reference'] ?? ''),
            _detailRow("Date", date),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectDeposit(d['id']),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text("REJETER", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validateDeposit(d['id'], d['user_name'] ?? '', amount),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("CRÉDITER", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
