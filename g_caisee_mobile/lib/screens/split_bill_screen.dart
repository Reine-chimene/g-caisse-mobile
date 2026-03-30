import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SplitBillScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SplitBillScreen({super.key, required this.userData});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = false;
  List<dynamic> _myBills = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    try {
      final bills = await ApiService.getMySplitBills();
      if (mounted) setState(() => _myBills = bills);
    } catch (_) {}
  }

  void _addParticipant() {
    if (_phoneCtrl.text.isEmpty) return;
    setState(() {
      _participants.add({"phone": _phoneCtrl.text.trim()});
      _phoneCtrl.clear();
    });
  }

  Future<void> _createBill() async {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty || _participants.isEmpty) {
      _showMsg("Remplis tous les champs et ajoute au moins 1 participant", AppTheme.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.createSplitBill(
        title: _titleCtrl.text,
        totalAmount: double.parse(_amountCtrl.text),
        participants: _participants,
      );
      _titleCtrl.clear(); _amountCtrl.clear(); _participants.clear();
      _loadBills();
      _showMsg("Partage créé !", AppTheme.success);
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception: ', ''), AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payBill(int billId) async {
    try {
      await ApiService.paySplitBill(billId);
      _loadBills();
      _showMsg("Paiement effectué !", AppTheme.success);
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception: ', ''), AppTheme.error);
    }
  }

  void _showMsg(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: const Text("Partage de dépenses", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.dark,
        foregroundColor: AppTheme.textLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateForm(),
            const SizedBox(height: 28),
            const Text("Mes partages", style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ..._myBills.map(_buildBillCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final totalPeople = _participants.length + 1;
    final perPerson = totalPeople > 1 ? (amount / totalPeople).toStringAsFixed(0) : amount.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 28),
            SizedBox(width: 12),
            Text("Nouveau partage", style: TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          _field(_titleCtrl, "Titre (ex: Restaurant)", Icons.title_rounded),
          const SizedBox(height: 12),
          _field(_amountCtrl, "Montant total (FCFA)", Icons.monetization_on_rounded, TextInputType.number),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field(_phoneCtrl, "Numéro ami", Icons.phone_rounded, TextInputType.phone)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addParticipant,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded, color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
          if (_participants.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _participants.asMap().entries.map((e) => Chip(
                label: Text(e.value['phone'], style: const TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.darkSurface,
                deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.error),
                onDeleted: () => setState(() => _participants.removeAt(e.key)),
              )).toList(),
            ),
          ],
          if (amount > 0 && totalPeople > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_rounded, color: Color(0xFF6366F1), size: 18),
                  const SizedBox(width: 8),
                  Text("$totalPeople personnes · $perPerson FCFA chacun", style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _isLoading ? null : _createBill,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("CRÉER LE PARTAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(dynamic bill) {
    final totalAmount = double.tryParse(bill['total_amount'].toString()) ?? 0;
    final participants = bill['participants'] as List? ?? [];
    final isCreator = bill['creator_id'].toString() == widget.userData['id'].toString();
    final myShare = participants.cast<Map>().firstWhere(
      (p) => p['user_id'].toString() == widget.userData['id'].toString(),
      orElse: () => {'status': 'paid', 'amount_owed': '0'},
    );
    final myStatus = myShare['status'] ?? 'paid';
    final myAmount = double.tryParse(myShare['amount_owed'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(bill['title'] ?? '', style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (myStatus == 'paid' ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(myStatus == 'paid' ? 'Payé' : 'À payer', style: TextStyle(color: myStatus == 'paid' ? AppTheme.success : AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Total: ${totalAmount.toStringAsFixed(0)} FCFA · ${participants.length} participants", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          if (myStatus != 'paid' && !isCreator) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => _payBill(bill['id']),
                child: Text("PAYER ${myAmount.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: ctrl, keyboardType: type,
      style: const TextStyle(color: AppTheme.textLight),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        filled: true, fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
