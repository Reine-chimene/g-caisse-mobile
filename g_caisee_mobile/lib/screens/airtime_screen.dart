import 'package:flutter/material.dart';
import '../services/notchpay_service.dart';

class AirtimeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AirtimeScreen({super.key, required this.userData});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();

  String  _selectedOperator = 'cm.mtn';
  String  _rechargeType     = 'Crédit';
  String  _dataPlan         = 'Jour';
  bool    _isLoading        = false;

  static const Color _orange = Color(0xFFFF7900);

  // Mapping opérateur → infos affichage
  static const Map<String, Map<String, dynamic>> _operators = {
    'cm.mtn': {
      'label': 'MTN MoMo',
      'logo':  'assets/logo_mtn.jpg',
      'color': Color(0xFFFFCC00),
    },
    'cm.orange': {
      'label': 'Orange Money',
      'logo':  'assets/logo_orange.jpg',
      'color': Color(0xFFFF7900),
    },
  };

  static const List<String> _dataPlans = ['Jour', 'Semaine', 'Mois'];

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec le numéro de l'utilisateur connecté
    _phoneCtrl.text = widget.userData['phone']?.toString() ?? '';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0.0;
  double get _fees   => _amount * 0.02;
  double get _total  => _amount + _fees;

  // ── VALIDATION ──────────────────────────────────────────

  void _showConfirmation() {
    if (_phoneCtrl.text.isEmpty || _amount < 100) {
      _showMsg("Veuillez remplir tous les champs (montant min. 100 F)", Colors.red);
      return;
    }

    final opInfo = _operators[_selectedOperator]!;
    final serviceLabel = _rechargeType == 'Crédit'
        ? 'Recharge Crédit'
        : 'Forfait Data ($_dataPlan)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 50, height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Confirmation de la Recharge",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _row("Service",    serviceLabel),
            _row("Opérateur",  opInfo['label'] as String),
            _row("Numéro",     _phoneCtrl.text),
            _row("Montant",    "${_amount.toInt()} FCFA"),
            _row("Frais (2%)", "${_fees.toInt()} FCFA"),
            const Divider(),
            _row("Total débité", "${_total.toInt()} FCFA", bold: true),
            const SizedBox(height: 16),

            // Info PIN
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Vous recevrez une demande de PIN ${opInfo['label']} "
                      "sur votre téléphone pour valider.",
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: opInfo['color'] as Color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _submitRecharge();
                },
                child: const Text("CONFIRMER ET PAYER",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ── PAIEMENT ────────────────────────────────────────────

  Future<void> _submitRecharge() async {
    setState(() => _isLoading = true);
    try {
      await NotchPayService.buyAirtime(
        context: context,
        userId:        widget.userData['id'],
        receiverPhone: _phoneCtrl.text.trim(),
        amount:        _amount,
        operator:      _selectedOperator,
        type:          _rechargeType,
        plan:          _rechargeType == 'Data' ? _dataPlan : null,
      );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final serviceLabel = _rechargeType == 'Crédit'
        ? 'Recharge Crédit'
        : 'Forfait Data ($_dataPlan)';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text("Recharge Réussie !",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "$serviceLabel de ${_amount.toInt()} FCFA activée sur ${_phoneCtrl.text}.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("TERMINER",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final opColor = _operators[_selectedOperator]!['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Recharge & Data",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Opérateur ──
            const Text("Opérateur",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: _operators.entries.map((e) {
                final isSel = _selectedOperator == e.key;
                final info  = e.value;
                final color = info['color'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOperator = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSel ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: isSel ? color : Colors.grey.shade300,
                            width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Image.asset(info['logo'] as String,
                              width: 36, height: 36,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.phone_android, color: color, size: 36)),
                          const SizedBox(height: 6),
                          Text(info['label'] as String,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSel ? color : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),

            // ── Type de service ──
            const Text("Type de service",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                _typeChip('Crédit', Icons.phone_in_talk_rounded),
                const SizedBox(width: 12),
                _typeChip('Data', Icons.wifi_rounded),
              ],
            ),

            if (_rechargeType == 'Data') ...[
              const SizedBox(height: 16),
              const Text("Validité du forfait",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: _dataPlans.map((p) {
                  final isSel = _dataPlan == p;
                  return GestureDetector(
                    onTap: () => setState(() => _dataPlan = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? _orange : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(p,
                          style: TextStyle(
                              color: isSel ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 25),

            // ── Numéro ──
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Numéro à recharger",
                hintText: "6XXXXXXXX",
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: opColor, width: 2),
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),

            // ── Montant ──
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Montant (FCFA)",
                prefixIcon: const Icon(Icons.monetization_on_outlined),
                suffixText: "FCFA",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: opColor, width: 2),
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Récap frais ──
            if (_amount > 0) _buildPricingCard(opColor),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: opColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
                onPressed: _isLoading ? null : _showConfirmation,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("VALIDER LA RECHARGE",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS ──────────────────────────────────────────────

  Widget _buildPricingCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _row("Montant net",    "${_amount.toInt()} F"),
          _row("Frais (2%)",     "+ ${_fees.toInt()} F", color: Colors.orange),
          const Divider(height: 16),
          _row("Total débité",   "${_total.toInt()} F", bold: true),
        ],
      ),
    );
  }

  Widget _typeChip(String type, IconData icon) {
    final isSel = _rechargeType == type;
    return GestureDetector(
      onTap: () => setState(() => _rechargeType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? _orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSel ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Text(type,
                style: TextStyle(
                    color: isSel ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {Color color = Colors.black87, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  fontSize: bold ? 16 : 13)),
        ],
      ),
    );
  }

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));
}
