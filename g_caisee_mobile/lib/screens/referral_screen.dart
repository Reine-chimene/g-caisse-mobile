import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ReferralScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ReferralScreen({super.key, required this.userData});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  Map<String, dynamic> _referralInfo = {};
  List<dynamic> _history = [];
  bool _isLoading = true;

  final Color gold = const Color(0xFFD4AF37);
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      final results = await Future.wait([
        ApiService.getReferralCode(userId),
        ApiService.getReferralHistory(userId),
      ]);
      if (mounted) {
        setState(() {
          _referralInfo = results[0] as Map<String, dynamic>;
          _history = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyCode() {
    final code = _referralInfo['referral_code'] ?? '';
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Code $code copié !"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _shareCode() {
    final code = _referralInfo['referral_code'] ?? '';
    // Share.share("Rejoins G-Caisse avec mon code parrain $code et reçois un bonus ! 🎉 Télécharge l'app : https://g-caisse.com");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("Parrainage", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: gold,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildReferralCard(),
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 25),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReferralCard() {
    final code = _referralInfo['referral_code'] ?? '---';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gold, const Color(0xFFB8860B)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text("INVITE & GAGNE", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text("500 FCFA par ami invité", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Text(code, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: gold, letterSpacing: 4)),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionBtn(Icons.copy, "Copier", _copyCode),
              const SizedBox(width: 15),
              _actionBtn(Icons.share, "Partager", _shareCode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _referralInfo['total_referrals'] ?? 0;
    final earned = (total as int) * 500;
    return Row(
      children: [
        Expanded(child: _statCard("Amis invités", "$total", Icons.people, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Gains totaux", currencyFormat.format(earned), Icons.monetization_on, Colors.green)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
      ]),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Historique des parrainages", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aucun parrainage pour l'instant", style: TextStyle(color: Colors.grey))))
        else
          ..._history.map((r) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green.withValues(alpha: 0.1), child: const Icon(Icons.person_add, color: Colors.green)),
              title: Text(r['referred_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(r['referred_phone'] ?? ''),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("+500 FCFA", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Text((r['created_at'] ?? '').toString().substring(0, 10), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          )),
      ],
    );
  }
}
