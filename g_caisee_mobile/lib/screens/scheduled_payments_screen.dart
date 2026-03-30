import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ScheduledPaymentsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ScheduledPaymentsScreen({super.key, required this.userData});

  @override
  State<ScheduledPaymentsScreen> createState() => _ScheduledPaymentsScreenState();
}

class _ScheduledPaymentsScreenState extends State<ScheduledPaymentsScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final data = await ApiService.getMyScheduledPayments();
      if (mounted) setState(() { _payments = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelPayment(int id) async {
    await ApiService.cancelScheduledPayment(id);
    _loadPayments();
  }

  String _freqLabel(String? freq) {
    switch (freq) {
      case 'daily': return 'Chaque jour';
      case 'weekly': return 'Chaque semaine';
      case 'monthly': return 'Chaque mois';
      default: return freq ?? '';
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'tontine': return Icons.groups_rounded;
      case 'saving': return Icons.savings_rounded;
      case 'transfer': return Icons.send_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: const Text("Paiements programmés", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.dark,
        foregroundColor: AppTheme.textLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _payments.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule_rounded, color: AppTheme.textMuted, size: 64),
                    SizedBox(height: 16),
                    Text("Aucun paiement programmé", style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                    SizedBox(height: 8),
                    Text("Programme tes cotisations tontine\nou transferts récurrents", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _payments.length,
                  itemBuilder: (context, i) {
                    final p = _payments[i];
                    final amount = double.tryParse(p['amount'].toString()) ?? 0;
                    final nextDate = p['next_payment_date']?.toString().split('T').first ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                            child: Icon(_typeIcon(p['payment_type']), color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("${amount.toStringAsFixed(0)} FCFA", style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text("${_freqLabel(p['frequency'])} · Prochain: $nextDate", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              if (p['description'] != null && p['description'].toString().isNotEmpty)
                                Text(p['description'], style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                            onPressed: () => _cancelPayment(p['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
