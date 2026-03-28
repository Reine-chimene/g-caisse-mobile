import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class BankDepositScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BankDepositScreen({super.key, required this.userData});

  @override
  State<BankDepositScreen> createState() => _BankDepositScreenState();
}

class _BankDepositScreenState extends State<BankDepositScreen> {
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _senderNameController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  Map<String, dynamic> _bankInfo = {};
  List<dynamic> _myDeposits = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  final Color green = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _senderNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      final results = await Future.wait([
        ApiService.getBankInfo(),
        ApiService.getMyBankDeposits(userId),
      ]);
      if (mounted) {
        setState(() {
          _bankInfo = results[0] as Map<String, dynamic>;
          _myDeposits = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitDeposit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 1000) {
      _showMsg("Montant minimum : 1 000 FCFA", Colors.red);
      return;
    }
    if (_bankNameController.text.isEmpty) {
      _showMsg("Indique le nom de ta banque", Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      final res = await ApiService.declareBankDeposit(
        userId: userId,
        amount: amount,
        bankName: _bankNameController.text.trim(),
        senderName: _senderNameController.text.trim(),
      );
      if (mounted) {
        _amountController.clear();
        _bankNameController.clear();
        _senderNameController.clear();
        _showMsg("Déclaration enregistrée ! Réf: ${res['reference']}", Colors.green);
        _loadData();
      }
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceAll('Exception:', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMsg(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showMsg("$label copié !", Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("Dépôt par Virement", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: green,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBankInfoCard(),
                    const SizedBox(height: 25),
                    _buildDepositForm(),
                    const SizedBox(height: 30),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBankInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [green, green.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: green.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text("Compte G-Caisse", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow("Banque", _bankInfo['bank_name'] ?? 'Non configuré'),
          _infoRow("Nom du compte", _bankInfo['account_name'] ?? 'Non configuré'),
          _infoRow("N° de compte", _bankInfo['account_number'] ?? 'Non configuré'),
          if ((_bankInfo['iban'] ?? '').toString().isNotEmpty)
            _infoRow("IBAN", _bankInfo['iban']),
          if ((_bankInfo['swift'] ?? '').toString().isNotEmpty)
            _infoRow("SWIFT", _bankInfo['swift']),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Text(
              "Fais un virement vers ce compte puis déclare-le ci-dessous. Ton solde sera crédité après vérification (max 24h).",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          GestureDetector(
            onTap: () => _copyToClipboard(value, label),
            child: Row(
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 5),
                const Icon(Icons.copy, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Déclarer mon virement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Montant viré (FCFA)",
              prefixIcon: Icon(Icons.money, color: green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: green), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bankNameController,
            decoration: InputDecoration(
              labelText: "Ta banque (ex: UBA, Afriland, etc.)",
              prefixIcon: Icon(Icons.account_balance, color: green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: green), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _senderNameController,
            decoration: InputDecoration(
              labelText: "Nom de l'expéditeur (optionnel)",
              prefixIcon: Icon(Icons.person, color: green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: green), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _isSubmitting ? null : _submitDeposit,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("DÉCLARER LE VIREMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_myDeposits.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Historique des virements", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._myDeposits.map((d) => _depositTile(d)),
      ],
    );
  }

  Widget _depositTile(Map<String, dynamic> d) {
    final status = d['status'] ?? 'pending';
    final amount = double.tryParse(d['amount'].toString()) ?? 0;
    final date = d['created_at']?.toString().substring(0, 10) ?? '';
    final statusColor = {'pending': Colors.orange, 'validated': Colors.green, 'rejected': Colors.red}[status] ?? Colors.grey;
    final statusText = {'pending': 'En attente', 'validated': 'Validé', 'rejected': 'Rejeté'}[status] ?? status;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(status == 'validated' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.hourglass_top, color: statusColor),
        ),
        title: Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${d['bank_name'] ?? ''} — Réf: ${d['reference'] ?? ''}", style: const TextStyle(fontSize: 11)),
            if ((d['admin_note'] ?? '').toString().isNotEmpty)
              Text("Note: ${d['admin_note']}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
