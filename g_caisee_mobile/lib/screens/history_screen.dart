import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> transactions = [];
  bool isLoading = true;
  String _filter = 'Tous';

  static const _filters = ['Tous', 'Entrées', 'Sorties'];
  static const _typeIcons = {
    'deposit': Icons.arrow_downward_rounded,
    'transfer_in': Icons.arrow_downward_rounded,
    'withdrawal': Icons.arrow_upward_rounded,
    'transfer_out': Icons.arrow_upward_rounded,
    'tontine_pay': Icons.groups_rounded,
    'tontine_payout': Icons.celebration_rounded,
    'airtime': Icons.phone_android_rounded,
    'bill': Icons.receipt_long_rounded,
    'saving': Icons.savings_rounded,
    'split_bill_pay': Icons.receipt_long_rounded,
    'referral_bonus': Icons.card_giftcard_rounded,
    'round_up': Icons.auto_awesome_rounded,
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.getUserTransactions(widget.userId);
      if (mounted) setState(() { transactions = data; isLoading = false; });
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'deposit': return 'Dépôt';
      case 'withdrawal': return 'Retrait';
      case 'transfer_in': return 'Transfert reçu';
      case 'transfer_out': return 'Transfert envoyé';
      case 'tontine_pay': return 'Cotisation tontine';
      case 'tontine_payout': return 'Cagnotte tontine';
      case 'airtime': return 'Recharge';
      case 'bill': return 'Facture';
      case 'saving': return 'Épargne';
      case 'round_up': return 'Round-Up';
      case 'referral_bonus': return 'Parrainage';
      default: return type;
    }
  }

  bool _isIncome(String type) => ['deposit', 'transfer_in', 'tontine_payout', 'referral_bonus', 'saving'].contains(type);

  List<dynamic> get _filtered {
    if (_filter == 'Tous') return transactions;
    if (_filter == 'Entrées') return transactions.where((t) => _isIncome(t['type'] ?? '')).toList();
    return transactions.where((t) => !_isIncome(t['type'] ?? '')).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: const Text("Historique", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.dark, foregroundColor: AppTheme.textLight, elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(children: [
              _buildFilters(),
              Expanded(child: _buildList()),
            ]),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: _filters.map((f) {
        final isSel = _filter == f;
        return GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(color: isSel ? AppTheme.primary : AppTheme.darkCard, borderRadius: BorderRadius.circular(12)),
            child: Text(f, style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted.withValues(alpha: 0.3), size: 64),
      const SizedBox(height: 16),
      const Text("Aucune transaction", style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
    ]));

    return RefreshIndicator(
      onRefresh: _load, color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final tx = items[i];
          final type = tx['type']?.toString() ?? '';
          final isIncome = _isIncome(type);
          final amount = double.tryParse(tx['amount'].toString()) ?? 0;
          final date = tx['created_at']?.toString().split('T').first ?? '';
          final time = tx['created_at']?.toString().split('T').last.substring(0, 5) ?? '';
          final desc = tx['description']?.toString() ?? _typeLabel(type);
          final icon = _typeIcons[type] ?? (isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);
          final iconColor = isIncome ? AppTheme.success : AppTheme.error;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(desc, style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text("$date · $time", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("${isIncome ? '+' : '-'} ${amount.toStringAsFixed(0)} F", style: TextStyle(color: iconColor, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(_typeLabel(type), style: TextStyle(color: iconColor, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
