import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GamificationScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const GamificationScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final score = userData['credibility_score'] as int? ?? 100;
    final badges = _computeBadges(score);

    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textLight,
        title: const Text('Récompenses & Badges',
            style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score global ──────────────────────────────────
            _buildScoreCard(score),
            const SizedBox(height: 24),

            // ── Badges ────────────────────────────────────────
            const Text('Mes Badges',
                style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: badges.map((b) => _buildBadge(b)).toList(),
            ),
            const SizedBox(height: 24),

            // ── Prochains objectifs ───────────────────────────
            const Text('Prochains Objectifs',
                style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ..._buildGoals(score),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(int score) {
    final level = score >= 90 ? 'Légende' : score >= 70 ? 'Expert' : score >= 50 ? 'Confirmé' : 'Débutant';
    final color = score >= 90 ? const Color(0xFFFFD700) : score >= 70 ? AppTheme.primary : score >= 50 ? AppTheme.success : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: AppTheme.darkSurface,
                  color: color,
                  strokeWidth: 6,
                ),
              ),
              Text('$score', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Score de crédibilité G-Caisse',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: AppTheme.darkSurface,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(Map<String, dynamic> badge) {
    final unlocked = badge['unlocked'] as bool;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? (badge['color'] as Color).withValues(alpha: 0.1) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: unlocked ? (badge['color'] as Color).withValues(alpha: 0.4) : AppTheme.darkSurface,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge['emoji'] as String,
              style: TextStyle(fontSize: 28, color: unlocked ? null : Colors.transparent)),
          if (!unlocked)
            const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 28),
          const SizedBox(height: 6),
          Text(
            badge['name'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: unlocked ? AppTheme.textLight : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGoals(int score) {
    final goals = [
      {'title': 'Atteindre 50 points', 'target': 50, 'reward': '+500 F de bonus'},
      {'title': 'Atteindre 70 points', 'target': 70, 'reward': 'Frais réduits à 1%'},
      {'title': 'Atteindre 90 points', 'target': 90, 'reward': 'Prêt jusqu\'à 500 000 F'},
    ];

    return goals.map((g) {
      final target = g['target'] as int;
      final done = score >= target;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: done ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.darkSurface,
          ),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: done ? AppTheme.success : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g['title'] as String,
                      style: TextStyle(
                        color: done ? AppTheme.textLight : AppTheme.textMuted,
                        fontSize: 14, fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      )),
                  Text('🎁 ${g['reward']}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                ],
              ),
            ),
            Text('$target pts',
                style: TextStyle(
                  color: done ? AppTheme.success : AppTheme.textMuted,
                  fontSize: 12, fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
    }).toList();
  }

  List<Map<String, dynamic>> _computeBadges(int score) => [
    {'emoji': '🌟', 'name': 'Premier Pas',   'color': AppTheme.primary, 'unlocked': true},
    {'emoji': '💰', 'name': 'Épargnant',      'color': AppTheme.success, 'unlocked': score >= 30},
    {'emoji': '🤝', 'name': 'Solidaire',      'color': Colors.blue,      'unlocked': score >= 40},
    {'emoji': '⏰', 'name': 'Ponctuel',        'color': AppTheme.warning, 'unlocked': score >= 50},
    {'emoji': '🏆', 'name': 'Champion',        'color': const Color(0xFFFFD700), 'unlocked': score >= 70},
    {'emoji': '💎', 'name': 'Diamant',         'color': Colors.cyan,      'unlocked': score >= 90},
  ];
}
