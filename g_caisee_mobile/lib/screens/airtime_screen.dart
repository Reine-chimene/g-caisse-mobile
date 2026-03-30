import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AirtimeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AirtimeScreen({super.key, required this.userData});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedOperator = 'cm.mtn';
  String _rechargeType = 'Crédit';
  String _dataPlan = 'Jour';
  bool _isLoading = false;

  static const List<String> _dataPlans = ['Jour', 'Semaine', 'Mois'];
  static const _quickAmounts = [100, 250, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.userData['phone']?.toString() ?? '';
  }

  @override
  void dispose() { _phoneCtrl.dispose(); _amountCtrl.dispose(); super.dispose(); }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;

  Color get _opColor => _selectedOperator == 'cm.orange' ? const Color(0xFFFF7900) : const Color(0xFFFFCC00);
  String get _opLabel => _selectedOperator == 'cm.orange' ? 'Orange' : 'MTN';
  String get _opLogo => _selectedOperator == 'cm.orange' ? 'assets/logo_orange.jpg' : 'assets/logo_mtn.jpg';

  Future<void> _submit() async {
    if (_phoneCtrl.text.isEmpty || _amount < 100) { _showMsg("Montant minimum : 100 FCFA", AppTheme.error); return; }
    setState(() => _isLoading = true);
    try {
      await ApiService.buyAirtimeOrData(
        userId: int.tryParse(widget.userData['id'].toString()) ?? 0,
        phoneNumber: _phoneCtrl.text.trim(),
        amount: _amount,
        operator: _selectedOperator,
        type: _rechargeType,
        plan: _rechargeType == 'Data' ? _dataPlan : null,
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
        const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 72),
        const SizedBox(height: 16),
        const Text("Recharge réussie !", style: TextStyle(color: AppTheme.textLight, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text("${_amount.toStringAsFixed(0)} FCFA envoyés sur ${_phoneCtrl.text}", textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      ]),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: _opColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
        child: const Text("TERMINER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(title: const Text("Recharge", style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: AppTheme.dark, foregroundColor: AppTheme.textLight, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildOperatorSelector(),
          const SizedBox(height: 24),
          _buildServiceType(),
          if (_rechargeType == 'Data') ...[const SizedBox(height: 16), _buildDataPlans()],
          const SizedBox(height: 24),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildQuickAmounts(),
          const SizedBox(height: 12),
          _buildAmountField(),
          const SizedBox(height: 28),
          _buildSubmitButton(),
          const SizedBox(height: 16),
          _buildInfoBox(),
        ]),
      ),
    );
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSel ? color.withValues(alpha: 0.1) : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSel ? color : Colors.transparent, width: 2),
            ),
            child: Column(children: [
              Image.asset(op['logo'] as String, width: 40, height: 40, errorBuilder: (_, __, ___) => Icon(Icons.phone_android, color: color, size: 40)),
              const SizedBox(height: 10),
              Text(op['label'] as String, style: TextStyle(color: isSel ? color : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
        ),
      );
    }).toList());
  }

  Widget _buildServiceType() {
    return Row(children: [
      _typeChip('Crédit', Icons.phone_in_talk_rounded),
      const SizedBox(width: 12),
      _typeChip('Data', Icons.wifi_rounded),
    ]);
  }

  Widget _typeChip(String type, IconData icon) {
    final isSel = _rechargeType == type;
    return GestureDetector(
      onTap: () => setState(() => _rechargeType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: isSel ? _opColor : AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, size: 16, color: isSel ? Colors.white : AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(type, style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildDataPlans() {
    return Row(children: _dataPlans.map((p) {
      final isSel = _dataPlan == p;
      return GestureDetector(
        onTap: () => setState(() => _dataPlan = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(color: isSel ? _opColor : AppTheme.darkSurface, borderRadius: BorderRadius.circular(12)),
          child: Text(p, style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
    }).toList());
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: "Numéro à recharger", labelStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.phone_android_rounded, color: AppTheme.textMuted),
        filled: true, fillColor: AppTheme.darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Wrap(spacing: 10, runSpacing: 10, children: _quickAmounts.map((a) {
      final isSel = _amount == a;
      return GestureDetector(
        onTap: () => setState(() => _amountCtrl.text = a.toString()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(color: isSel ? _opColor : AppTheme.darkCard, borderRadius: BorderRadius.circular(12)),
          child: Text("$a F", style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
    }).toList());
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppTheme.textLight, fontSize: 22, fontWeight: FontWeight.w800),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: "0", hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.3)),
        suffixText: "FCFA", suffixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
        filled: true, fillColor: AppTheme.darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: _opColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
      onPressed: _isLoading ? null : _submit,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text("RECHARGER ${_amount > 0 ? '${_amount.toStringAsFixed(0)} F' : ''}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
    ));
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text("Le montant est débité de ton solde G-Caisse et envoyé directement sur le numéro choisi.", style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8), fontSize: 12))),
      ]),
    );
  }
}
