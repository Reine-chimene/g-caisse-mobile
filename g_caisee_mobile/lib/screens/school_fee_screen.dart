import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SchoolFeeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SchoolFeeScreen({super.key, required this.userData});

  @override
  State<SchoolFeeScreen> createState() => _SchoolFeeScreenState();
}

class _SchoolFeeScreenState extends State<SchoolFeeScreen> {
  final _schoolCtrl = TextEditingController();
  final _studentNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  String _selectedOperator = 'cm.mtn';
  String _feeType = 'Frais scolaires';
  String _level = 'Université';
  bool _isLoading = false;
  List<dynamic> _history = [];

  static const _feeTypes = ['Frais scolaires', 'Frais d\'inscription', 'Frais d\'examen', 'Frais de laboratoire', 'Pensionnat'];
  static const _levels = ['Maternelle', 'Primaire', 'Secondaire', 'Université'];
  static const _popularSchools = [
    'Université de Yaoundé I', 'Université de Douala', 'ENSET', 'ESSEC', 'Polytechnique',
    'College Vogt', 'Lycée Général Leclerc', 'Lycée de Mbankomo',
  ];

  @override
  void initState() {
    super.initState();
    _studentNameCtrl.text = widget.userData['fullname']?.toString() ?? '';
    _loadHistory();
  }

  @override
  void dispose() {
    _schoolCtrl.dispose(); _studentNameCtrl.dispose();
    _studentIdCtrl.dispose(); _amountCtrl.dispose(); _matriculeCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  String get _opLabel => _selectedOperator == 'cm.mtn' ? 'MTN MoMo' : 'Orange Money';

  Future<void> _loadHistory() async {
    try {
      final userId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      final txs = await ApiService.getUserTransactions(userId);
      if (mounted) setState(() => _history = txs.where((t) => (t['description']?.toString() ?? '').toLowerCase().contains('scolar') || (t['description']?.toString() ?? '').toLowerCase().contains('école')).toList());
    } catch (_) {}
  }

  Future<void> _pay() async {
    if (_schoolCtrl.text.isEmpty || _studentNameCtrl.text.isEmpty || _amount < 500) {
      _showMsg("Remplis tous les champs (min 500 F)", AppTheme.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      await ApiService.payBill(
        userId: userId,
        contractNumber: _matriculeCtrl.text.isNotEmpty ? _matriculeCtrl.text : 'SCOL_${DateTime.now().millisecondsSinceEpoch}',
        amount: _amount,
        billType: 'SCHOOL',
        phone: widget.userData['phone']?.toString() ?? '',
        operator: _selectedOperator,
      );
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceAll('Exception: ', ''), AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  void _showSuccess() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.school_rounded, color: Color(0xFF6366F1), size: 72),
        const SizedBox(height: 16),
        const Text("Paiement réussi !", style: TextStyle(color: AppTheme.textLight, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text("${_amount.toStringAsFixed(0)} FCFA payés pour ${_studentNameCtrl.text}", textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 4),
        Text("École: ${_schoolCtrl.text}", textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
        child: const Text("TERMINER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(title: const Text("Paiement Scolarité", style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: AppTheme.dark, foregroundColor: AppTheme.textLight, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeroCard(),
          const SizedBox(height: 24),
          _buildSchoolSelector(),
          const SizedBox(height: 16),
          _field(_studentNameCtrl, "Nom de l'étudiant", Icons.person_rounded),
          const SizedBox(height: 12),
          _field(_matriculeCtrl, "Matricule / N° étudiant (optionnel)", Icons.badge_rounded),
          const SizedBox(height: 16),
          _buildFeeTypeSelector(),
          const SizedBox(height: 16),
          _buildLevelSelector(),
          const SizedBox(height: 16),
          _field(_amountCtrl, "Montant (FCFA)", Icons.monetization_on_rounded, TextInputType.number, (_) => setState(() {})),
          const SizedBox(height: 16),
          _buildOperatorSelector(),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            onPressed: _isLoading ? null : _pay,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text("PAYER ${_amount > 0 ? '${_amount.toStringAsFixed(0)} F' : ''}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          )),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text("Paiements précédents", style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._history.take(5).map((tx) {
              final amount = double.tryParse(tx['amount'].toString()) ?? 0;
              final date = tx['created_at']?.toString().split('T').first ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.school_rounded, color: Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tx['description'] ?? 'Frais scolaires', style: const TextStyle(color: AppTheme.textLight, fontSize: 13))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text("${amount.toStringAsFixed(0)} F", style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ]),
                ]),
              );
            }),
          ],
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const Row(children: [
        Icon(Icons.school_rounded, color: Colors.white, size: 40),
        SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Frais de scolarité", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text("Paye tes frais scolaires directement depuis l'app", style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildSchoolSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("École / Université", style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 10),
      TextField(
        controller: _schoolCtrl,
        style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Nom de l'établissement", hintStyle: const TextStyle(color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.textMuted),
          filled: true, fillColor: AppTheme.darkCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(height: 36, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _popularSchools.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => setState(() => _schoolCtrl.text = _popularSchools[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(10)),
            child: Text(_popularSchools[i], style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ),
        ),
      )),
    ]);
  }

  Widget _buildFeeTypeSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Type de frais", style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _feeTypes.map((t) {
        final isSel = _feeType == t;
        return GestureDetector(
          onTap: () => setState(() => _feeType = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: isSel ? const Color(0xFF6366F1) : AppTheme.darkCard, borderRadius: BorderRadius.circular(12)),
            child: Text(t, style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildLevelSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Niveau", style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 10),
      Row(children: _levels.map((l) {
        final isSel = _level == l;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _level = l),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: isSel ? const Color(0xFF6366F1) : AppTheme.darkCard, borderRadius: BorderRadius.circular(10)),
              child: Text(l, textAlign: TextAlign.center, style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 10)),
            ),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildOperatorSelector() {
    return Row(children: [
      {'key': 'cm.mtn', 'label': 'MTN MoMo', 'logo': 'assets/logo_mtn.jpg', 'color': const Color(0xFFFFCC00)},
      {'key': 'cm.orange', 'label': 'Orange Money', 'logo': 'assets/logo_orange.jpg', 'color': const Color(0xFFFF7900)},
    ].map((op) {
      final isSel = _selectedOperator == op['key'];
      final color = op['color'] as Color;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedOperator = op['key'] as String),
          child: Container(
            margin: EdgeInsets.only(right: op['key'] == 'cm.mtn' ? 10 : 0, left: op['key'] == 'cm.orange' ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSel ? color.withValues(alpha: 0.1) : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSel ? color : Colors.transparent, width: 2),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(op['logo'] as String, width: 24, height: 24, errorBuilder: (_, __, ___) => Icon(Icons.phone_android, color: color, size: 24)),
              const SizedBox(width: 6),
              Text(op['label'] as String, style: TextStyle(color: isSel ? color : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
          ),
        ),
      );
    }).toList());
  }

  Widget _field(TextEditingController ctrl, String hint, [IconData icon = Icons.edit, TextInputType type = TextInputType.text, ValueChanged<String>? onChanged]) {
    return TextField(
      controller: ctrl, keyboardType: type, onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        filled: true, fillColor: AppTheme.darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
