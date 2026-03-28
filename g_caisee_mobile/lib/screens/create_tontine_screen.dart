import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class CreateTontineScreen extends StatefulWidget {
  final int userId;
  const CreateTontineScreen({super.key, required this.userId});

  @override
  State<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends State<CreateTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _chiefCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _caisseCtrl = TextEditingController();

  final Color gold  = const Color(0xFFD4AF37);
  final Color bg    = Colors.white;
  final Color txt   = const Color(0xFF1A1A1A);
  final Color field = const Color(0xFFF5F6F8);

  String _frequency    = 'mensuel';
  TimeOfDay _deadline  = const TimeOfDay(hour: 23, minute: 59);
  int _deadlineDay     = 28;
  bool _hasCaisseFund  = false;
  bool _acceptRules    = false;
  bool _isLoading      = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _chiefCtrl.dispose();
    _amountCtrl.dispose(); _caisseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _deadline);
    if (t != null) setState(() => _deadline = t);
  }

  String get _deadlineStr =>
      '${_deadline.hour.toString().padLeft(2,'0')}:${_deadline.minute.toString().padLeft(2,'0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptRules) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous devez accepter les conditions.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.createTontine(
        _nameCtrl.text.trim(), widget.userId, _frequency,
        double.parse(_amountCtrl.text), 1.0,
        deadlineTime: _deadlineStr,
        deadlineDay: _deadlineDay,
        hasCaisseFund: _hasCaisseFund,
        caisseFundAmount: _hasCaisseFund
            ? (double.tryParse(_caisseCtrl.text) ?? 0) : 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tontine créée avec succès !'),
          backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        Navigator.pop(context, true);
      }
    } on TimeoutException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le serveur met trop de temps à répondre. Réessaie.'),
        backgroundColor: Colors.red));
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      debugPrint('[CREATE TONTINE ERROR] userId=${widget.userId} | $msg');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text("Nouvelle Tontine", style: TextStyle(color: txt, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: bg, elevation: 0,
        iconTheme: IconThemeData(color: txt), centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: gold.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.groups_rounded, size: 50, color: gold),
              )),
              const SizedBox(height: 10),
              Center(child: Text("Créer un groupe de tontine",
                style: TextStyle(color: Colors.grey[600], fontSize: 15))),
              const SizedBox(height: 30),

              _section("Informations du groupe"),
              _lbl("Nom du Groupe"),
              _field(_nameCtrl, "Ex: Tontine Familiale", Icons.edit_outlined,
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null),
              const SizedBox(height: 16),
              _lbl("Nom du Chef"),
              _field(_chiefCtrl, "Ex: Reine Ngono", Icons.person_outline,
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null),
              const SizedBox(height: 16),
              _lbl("Montant par tour (FCFA)"),
              _field(_amountCtrl, "Ex: 10000", Icons.monetization_on_outlined,
                  isNumber: true, validator: (v) => v!.isEmpty ? "Obligatoire" : null),
              const SizedBox(height: 16),

              _lbl("Fréquence des cotisations"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(16)),
                child: DropdownButtonFormField<String>(
                  value: _frequency,
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  decoration: InputDecoration(border: InputBorder.none,
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[500])),
                  style: TextStyle(color: txt, fontSize: 16),
                  items: const [
                    DropdownMenuItem(value: 'journalier', child: Text("Journalière")),
                    DropdownMenuItem(value: 'hebdo',      child: Text("Hebdomadaire")),
                    DropdownMenuItem(value: 'mensuel',    child: Text("Mensuelle")),
                    DropdownMenuItem(value: 'express',    child: Text("Express (1 jour) 🚀")),
                  ],
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
              ),
              const SizedBox(height: 24),

              _section("Heure limite de paiement"),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl("Jour limite du mois"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(16)),
                    child: DropdownButton<int>(
                      value: _deadlineDay,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: List.generate(28, (i) => i + 1).map((d) =>
                        DropdownMenuItem(value: d, child: Text("Le $d du mois"))).toList(),
                      onChanged: (v) => setState(() => _deadlineDay = v!),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _lbl("Heure limite"),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                      decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Icon(Icons.access_time, color: Colors.grey[500], size: 20),
                        const SizedBox(width: 10),
                        Text(_deadlineStr, style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ])),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    "Passé le $_deadlineStr du $_deadlineDay, une amende de 500 F sera appliquée.",
                    style: const TextStyle(color: Colors.orange, fontSize: 12))),
                ]),
              ),
              const SizedBox(height: 24),

              _section("Fond de Caisse"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: field, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _hasCaisseFund ? gold.withValues(alpha: 0.4) : Colors.transparent),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Activer le fond de caisse", style: TextStyle(color: txt, fontWeight: FontWeight.w600)),
                      Text("Requis pour accéder aux prêts", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ]),
                    Switch(
                      value: _hasCaisseFund,
                      activeColor: gold,
                      onChanged: (v) => setState(() => _hasCaisseFund = v),
                    ),
                  ]),
                  if (_hasCaisseFund) ...[
                    const SizedBox(height: 12),
                    _field(_caisseCtrl, "Montant du fond (FCFA)", Icons.account_balance,
                        isNumber: true,
                        validator: (v) => _hasCaisseFund && v!.isEmpty ? "Obligatoire" : null),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        "Chaque membre devra verser ce montant dans la caisse. "
                        "Sans ce fond complet, les prêts ne seront pas accessibles.",
                        style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    "Commission de 2% appliquée pour la maintenance de la plateforme G-Caisse.",
                    style: TextStyle(color: Colors.blue[800], fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _acceptRules ? gold : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  value: _acceptRules,
                  activeColor: gold,
                  checkColor: Colors.white,
                  title: RichText(text: TextSpan(
                    text: "Je confirme être le chef et ",
                    style: TextStyle(color: txt, fontSize: 13),
                    children: [TextSpan(
                      text: "j'accepte le règlement intérieur.",
                      style: TextStyle(color: gold, fontWeight: FontWeight.bold))],
                  )),
                  onChanged: (v) => setState(() => _acceptRules = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: (_acceptRules && !_isLoading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LANCER LA TONTINE",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: TextStyle(color: txt, fontWeight: FontWeight.w600, fontSize: 14)));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: txt, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true, fillColor: field,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: validator,
    );
  }
}
