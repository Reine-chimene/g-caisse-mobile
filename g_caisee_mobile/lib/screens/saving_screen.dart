import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SavingScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const SavingScreen({super.key, this.userData});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  double savingsBalance = 0.0;
  double mainBalance = 0.0;
  double roundUpSaved = 0.0;
  List<dynamic> transactions = [];
  bool isLoading = true;
  bool roundUpEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final userId = int.tryParse(widget.userData?['id'].toString() ?? '0') ?? 0;
      if (userId == 0) return;
      final results = await Future.wait([
        ApiService.getUserBalance(userId),
        ApiService.getSavingsBalance(userId),
        ApiService.getSavingsTransactions(userId),
        ApiService.getRoundUpStats(userId),
      ]);
      if (mounted) setState(() {
        mainBalance = results[0] as double;
        savingsBalance = results[1] as double;
        transactions = results[2] as List<dynamic>;
        final stats = results[3] as Map<String, dynamic>;
        roundUpSaved = double.tryParse(stats['total_saved'].toString()) ?? 0;
        roundUpEnabled = stats['enabled'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  void _showTxDialog(bool isDeposit) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 30, left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 24),
          Text(isDeposit ? "ALIMENTER L'ÉPARGNE" : "RETIRER DE L'ÉPARGNE",
              style: const TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(isDeposit ? "Solde disponible : ${_fmt(mainBalance)} FCFA" : "Épargne : ${_fmt(savingsBalance)} FCFA",
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            controller: ctrl, keyboardType: TextInputType.number, autofocus: true, textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 28, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: "0", hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.3)),
              suffixText: "FCFA", suffixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
              filled: true, fillColor: AppTheme.darkSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isDeposit ? AppTheme.success : AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () async {
                final amount = double.tryParse(ctrl.text) ?? 0;
                if (amount <= 0) return;
                if (isDeposit && amount > mainBalance) { _showMsg("Solde insuffisant", AppTheme.error); return; }
                if (!isDeposit && amount > savingsBalance) { _showMsg("Épargne insuffisante", AppTheme.error); return; }
                Navigator.pop(ctx);
                try {
                  final userId = int.tryParse(widget.userData?['id'].toString() ?? '0') ?? 0;
                  await ApiService.transferMoney(userId, '', amount); // Internal saving transfer
                  _fetchData();
                  _showMsg(isDeposit ? "Épargne alimentée !" : "Retrait effectué !", AppTheme.success);
                } catch (e) {
                  _showMsg(e.toString().replaceAll('Exception: ', ''), AppTheme.error);
                }
              },
              child: Text(isDeposit ? "ÉPARGNER" : "RETIRER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  void _showMsg(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: const Text("Épargne", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.dark,
        foregroundColor: AppTheme.textLight,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.success))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppTheme.success,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  _buildMainCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  _buildRoundUpCard(),
                  const SizedBox(height: 24),
                  _buildHistory(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF15803D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 24),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text("+3.5%", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 24),
        const Text("TOTAL ÉPARGNÉ", style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text("${_fmt(savingsBalance)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 16),
        Row(children: [
          _miniStat("Solde principal", "${_fmt(mainBalance)} F"),
          const SizedBox(width: 24),
          _miniStat("Round-Up", "${_fmt(roundUpSaved)} F"),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(child: _actionBtn(true, "Épargner", Icons.add_circle_outline_rounded, AppTheme.success)),
      const SizedBox(width: 14),
      Expanded(child: _actionBtn(false, "Retirer", Icons.remove_circle_outline_rounded, AppTheme.primary)),
    ]);
  }

  Widget _actionBtn(bool isDeposit, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _showTxDialog(isDeposit),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildRoundUpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: const Color(0xFF22D3EE).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF22D3EE), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Round-Up", style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(roundUpEnabled ? "${_fmt(roundUpSaved)} F épargnés automatiquement" : "Active l'épargne automatique",
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ])),
        Switch(
          value: roundUpEnabled,
          onChanged: (v) async {
            setState(() => roundUpEnabled = v);
            final userId = int.tryParse(widget.userData?['id'].toString() ?? '0') ?? 0;
            await ApiService.setRoundUp(userId, v);
          },
          activeColor: const Color(0xFF22D3EE),
        ),
      ]),
    );
  }

  Widget _buildHistory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Historique", style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      if (transactions.isEmpty)
        Container(
          width: double.infinity, padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Icon(Icons.savings_outlined, color: AppTheme.textMuted.withValues(alpha: 0.3), size: 48),
            const SizedBox(height: 12),
            const Text("Aucune transaction", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ]),
        )
      else
        ...transactions.map((tx) {
          final isAdd = tx['type'].toString().contains('saving') || tx['type'].toString().contains('deposit');
          final amount = double.tryParse(tx['amount'].toString()) ?? 0;
          final date = tx['created_at']?.toString().split('T').first ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: (isAdd ? AppTheme.success : AppTheme.error).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(isAdd ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isAdd ? AppTheme.success : AppTheme.error, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAdd ? "Dépôt épargne" : "Retrait épargne", style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ])),
              Text("${isAdd ? '+' : '-'} ${_fmt(amount)} F", style: TextStyle(color: isAdd ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          );
        }),
    ]);
  }
}
