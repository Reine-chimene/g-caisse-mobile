import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class BillPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BillPaymentScreen({super.key, required this.userData});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final _contractCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedBill = 'ENEO';
  String _selectedOperator = 'cm.mtn';
  bool _isLoading = false;

  static const _bills = [
    {'key': 'ENEO', 'label': 'ENEO', 'icon': Icons.bolt_rounded, 'color': Color(0xFFFBBF24), 'hint': 'Numéro de compteur'},
    {'key': 'CAMWATER', 'label': 'CamWater', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF3B82F6), 'hint': 'Numéro de police'},
    {'key': 'CANAL', 'label': 'Canal+', 'icon': Icons.tv_rounded, 'color': Color(0xFF1E1E1E), 'hint': 'Numéro abonné'},
    {'key': 'INTERNET', 'label': 'Internet', 'icon': Icons.wifi_rounded, 'color': Color(0xFF8B5CF6), 'hint': 'Numéro de compte'},
  ];

  Map<String, dynamic> get _bill => _bills.firstWhere((b) => b['key'] == _selectedBill, orElse: () => _bills.first);

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  String get _opLabel => _selectedOperator == 'cm.mtn' ? 'MTN MoMo' : 'Orange Money';

  Future<void> _pay() async {
    if (_contractCtrl.text.isEmpty || _amount < 100) { _showMsg("Remplis tous les champs (min 100 F)", AppTheme.error); return; }
    setState(() => _isLoading = true);
    try {
      await ApiService.payBill(
        userId: int.tryParse(widget.userData['id'].toString()) ?? 0,
        contractNumber: _contractCtrl.text,
        amount: _amount,
        billType: _selectedBill,
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
    final bill = _bill;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: bill['color'] as Color, size: 72),
        const SizedBox(height: 16),
        Text("Facture ${bill['label']} payée !", style: const TextStyle(color: AppTheme.textLight, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text("${_amount.toStringAsFixed(0)} FCFA payés via $_opLabel", textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      ]),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: bill['color'] as Color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
        child: const Text("TERMINER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    final color = bill['color'] as Color;

    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(title: const Text("Paiement Factures", style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: AppTheme.dark, foregroundColor: AppTheme.textLight, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildBillSelector(),
          const SizedBox(height: 24),
          _buildOperatorSelector(),
          const SizedBox(height: 24),
          _field(_contractCtrl, bill['hint'] as String, bill['icon'] as IconData, color),
          const SizedBox(height: 14),
          _field(_amountCtrl, "Montant (FCFA)", Icons.monetization_on_rounded, color, TextInputType.number, (_) => setState(() {})),
          const SizedBox(height: 24),
          _buildSummary(color),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            onPressed: _isLoading ? null : _pay,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text("PAYER ${_amount > 0 ? '${_amount.toStringAsFixed(0)} F' : ''}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          )),
          const SizedBox(height: 16),
          _buildInfoBox(),
        ]),
      ),
    );
  }

  Widget _buildBillSelector() {
    return SizedBox(height: 90, child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _bills.length,
      itemBuilder: (context, i) {
        final b = _bills[i];
        final isSel = _selectedBill == b['key'];
        final color = b['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _selectedBill = b['key'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100, margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSel ? color.withValues(alpha: 0.12) : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSel ? color : Colors.transparent, width: 2),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(b['icon'] as IconData, color: isSel ? color : AppTheme.textMuted, size: 28),
              const SizedBox(height: 8),
              Text(b['label'] as String, style: TextStyle(color: isSel ? color : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
          ),
        );
      },
    ));
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
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: isSel ? color.withValues(alpha: 0.1) : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSel ? color : Colors.transparent, width: 2),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(op['logo'] as String, width: 28, height: 28, errorBuilder: (_, __, ___) => Icon(Icons.phone_android, color: color, size: 28)),
              const SizedBox(width: 8),
              Flexible(child: Text(op['label'] as String, style: TextStyle(color: isSel ? color : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 12))),
            ]),
          ),
        ),
      );
    }).toList());
  }

  Widget _buildSummary(Color color) {
    final fees = _amount * 0.02;
    final total = _amount + fees;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _row("Montant", "${_amount.toStringAsFixed(0)} F"),
        _row("Frais (2%)", "+ ${fees.toStringAsFixed(0)} F", color: AppTheme.warning),
        const Divider(color: AppTheme.darkSurface, height: 24),
        _row("TOTAL", "${total.toStringAsFixed(0)} F", bold: true, color: color),
      ]),
    );
  }

  Widget _row(String label, String value, {Color color = AppTheme.textLight, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 18 : 14)),
      ]),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text("Le paiement se fait via $_opLabel. Le montant est débité de ton solde G-Caisse.", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, Color color, [TextInputType type = TextInputType.text, ValueChanged<String>? onChanged]) {
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
