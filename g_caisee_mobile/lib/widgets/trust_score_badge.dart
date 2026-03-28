import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrustScoreBadge extends StatelessWidget {
  final int userId;
  final double size;

  const TrustScoreBadge({super.key, required this.userId, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getTrustDetails(userId),
      builder: (context, snapshot) {
        final score = snapshot.data?['score'] ?? 50;
        final color = score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;
        final icon = score >= 80 ? Icons.verified : score >= 50 ? Icons.shield : Icons.warning;

        return GestureDetector(
          onTap: () => _showDetails(context, snapshot.data ?? {}),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: size * 0.4),
                Text("$score%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: size * 0.22)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Score de Confiance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _row("Score", "${data['score'] ?? 50}%"),
            _row("Paiements à temps", "${data['on_time_payments'] ?? 0}"),
            _row("Paiements en retard", "${data['late_payments'] ?? 0}"),
            _row("Amis invités", "${data['referrals_count'] ?? 0}"),
            _row("Tontines rejointes", "${data['tontines_count'] ?? 0}"),
            const SizedBox(height: 10),
            Text("Membre depuis ${(data['member_since'] ?? '').toString().substring(0, 10)}",
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
