import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class FinancialDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FinancialDashboardScreen({super.key, required this.userData});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  // Données calculées
  double _totalIn    = 0;
  double _totalOut   = 0;
  double _balance    = 0;
  Map<String, double> _byCategory = {};
  List<FlSpot> _balanceSpots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final id = widget.userData['id'] as int;
      final results = await Future.wait([
        ApiService.getUserTransactions(id),
        ApiService.getUserBalance(id),
      ]);
      _transactions = results[0] as List<dynamic>;
      _balance      = results[1] as double;
      _compute();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _compute() {
    _totalIn  = 0;
    _totalOut = 0;
    _byCategory = {};

    for (final tx in _transactions) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0;
      final type   = tx['type'] as String? ?? '';

      if (['deposit'].contains(type)) {
        _totalIn += amount;
      } else {
        _totalOut += amount;
      }

      // Catégories
      final cat = _categoryLabel(type);
      _byCategory[cat] = (_byCategory[cat] ?? 0) + amount;
    }

    // Courbe de solde simulée sur 7 jours
    _balanceSpots = List.generate(7, (i) {
      final variation = (i % 3 == 0 ? 1 : -0.5) * (_totalIn / 10);
      return FlSpot(i.toDouble(), (_balance + variation).clamp(0, double.infinity));
    });
  }

  String _categoryLabel(String type) {
    switch (type) {
      case 'deposit':    return 'Dépôts';
      case 'withdrawal': return 'Retraits';
      case 'transfer':   return 'Transferts';
      case 'tontine_pay':return 'Tontines';
      case 'airtime':    return 'Recharges';
      case 'bill':       return 'Factures';
      default:           return 'Autres';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textLight,
        title: const Text('Tableau de bord',
            style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
            onPressed: () { setState(() => _isLoading = true); _loadData(); },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Résumé solde ──────────────────────────────
                    _buildBalanceSummary(),
                    const SizedBox(height: 24),

                    // ── Courbe de solde ───────────────────────────
                    _sectionTitle('Évolution du solde (7 jours)'),
                    const SizedBox(height: 12),
                    _buildLineChart(),
                    const SizedBox(height: 24),

                    // ── Répartition dépenses ──────────────────────
                    _sectionTitle('Répartition des dépenses'),
                    const SizedBox(height: 12),
                    _buildPieChart(),
                    const SizedBox(height: 24),

                    // ── Score santé financière ────────────────────
                    _sectionTitle('Score de santé financière'),
                    const SizedBox(height: 12),
                    _buildHealthScore(),
                    const SizedBox(height: 24),

                    // ── Alertes intelligentes ─────────────────────
                    _sectionTitle('Alertes & Recommandations'),
                    const SizedBox(height: 12),
                    _buildAlerts(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceSummary() {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Row(
      children: [
        Expanded(child: _statCard('Solde actuel', '${fmt.format(_balance)} F',
            AppTheme.primary, Icons.account_balance_wallet_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Entrées', '+${fmt.format(_totalIn)} F',
            AppTheme.success, Icons.arrow_downward_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Sorties', '-${fmt.format(_totalOut)} F',
            AppTheme.error, Icons.arrow_upward_rounded)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: _balanceSpots.isEmpty
          ? const Center(child: Text('Pas assez de données', style: TextStyle(color: AppTheme.textMuted)))
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.textMuted.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                        return Text(days[val.toInt() % 7],
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _balanceSpots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPieChart() {
    if (_byCategory.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Text('Aucune transaction', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final colors = [AppTheme.primary, AppTheme.success, AppTheme.error,
        AppTheme.warning, Colors.purple, Colors.cyan];
    final entries = _byCategory.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: List.generate(entries.length, (i) {
                  final total = _byCategory.values.fold(0.0, (a, b) => a + b);
                  return PieChartSectionData(
                    value: entries[i].value,
                    color: colors[i % colors.length],
                    radius: 50,
                    title: '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entries[i].key,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 12))),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    // Score basé sur ratio entrées/sorties
    final score = _totalIn > 0
        ? ((_totalIn - _totalOut) / _totalIn * 100).clamp(0, 100).toInt()
        : 50;
    final color = score >= 70 ? AppTheme.success : score >= 40 ? AppTheme.warning : AppTheme.error;
    final label = score >= 70 ? 'Excellent' : score >= 40 ? 'Moyen' : 'À améliorer';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: AppTheme.darkSurface,
                  color: color,
                  strokeWidth: 8,
                ),
                Text('$score', style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  score >= 70
                      ? 'Vos finances sont bien gérées. Continuez ainsi !'
                      : score >= 40
                          ? 'Réduisez vos dépenses pour améliorer votre score.'
                          : 'Attention : vos dépenses dépassent vos revenus.',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    final alerts = <Map<String, dynamic>>[];

    if (_totalOut > _totalIn * 0.8) {
      alerts.add({
        'icon': Icons.warning_amber_rounded,
        'color': AppTheme.warning,
        'text': 'Vos dépenses représentent plus de 80% de vos revenus ce mois.',
      });
    }
    if (_balance < 5000) {
      alerts.add({
        'icon': Icons.account_balance_wallet_outlined,
        'color': AppTheme.error,
        'text': 'Solde bas (${_balance.toInt()} F). Pensez à recharger votre compte.',
      });
    }
    if (alerts.isEmpty) {
      alerts.add({
        'icon': Icons.check_circle_outline_rounded,
        'color': AppTheme.success,
        'text': 'Tout va bien ! Aucune alerte financière ce mois.',
      });
    }

    return Column(
      children: alerts.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (a['color'] as Color).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(a['icon'] as IconData, color: a['color'] as Color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(a['text'] as String,
                style: TextStyle(color: a['color'] as Color, fontSize: 13, height: 1.4))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
        color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700),
  );
}
