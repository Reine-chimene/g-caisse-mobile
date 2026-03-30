import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RoundUpSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const RoundUpSettingsScreen({super.key, required this.userData});

  @override
  State<RoundUpSettingsScreen> createState() => _RoundUpSettingsScreenState();
}

class _RoundUpSettingsScreenState extends State<RoundUpSettingsScreen> {
  bool _isEnabled = false;
  double _totalSaved = 0;
  int _txCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      final stats = await ApiService.getRoundUpStats(userId);
      if (mounted) setState(() {
        _isEnabled = stats['enabled'] ?? false;
        _totalSaved = double.tryParse(stats['total_saved'].toString()) ?? 0;
        _txCount = stats['transaction_count'] ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _isEnabled = value);
    try {
      final userId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      await ApiService.setRoundUp(userId, value);
      _showMsg(value ? "Épargne automatique activée" : "Épargne automatique désactivée", AppTheme.success);
    } catch (_) {
      setState(() => _isEnabled = !value);
    }
  }

  void _showMsg(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: const Text("Épargne automatique", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.dark,
        foregroundColor: AppTheme.textLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.savings_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text("${_totalSaved.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text("Épargné automatiquement · $_txCount transactions", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("Round-Up", style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(_isEnabled ? "Activé — chaque paiement est arrondi" : "Désactivé", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ]),
                        ),
                        Switch(value: _isEnabled, onChanged: _toggle, activeColor: AppTheme.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _howItWorks(),
                ],
              ),
            ),
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Comment ça marche ?", style: TextStyle(color: AppTheme.textLight, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _step("1", "Tu paies 1,750 FCFA", "Le système arrondit à 1,800 FCFA"),
          _step("2", "Les 50 FCFA de différence", "Sont épargnés automatiquement"),
          _step("3", "Petit à petit", "Tu constitues une épargne sans effort"),
        ],
      ),
    );
  }

  Widget _step(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: AppTheme.primary.withValues(alpha: 0.15), child: Text(num, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 13)),
            Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
        ],
      ),
    );
  }
}
