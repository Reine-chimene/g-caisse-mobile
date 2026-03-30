import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RequestMoneyScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const RequestMoneyScreen({super.key, required this.userData});

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _incoming = [];
  List<dynamic> _outgoing = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tab.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      final results = await Future.wait([
        ApiService.getIncomingMoneyRequests(),
        ApiService.getOutgoingMoneyRequests(),
      ]);
      if (mounted) setState(() { _incoming = results[0]; _outgoing = results[1]; });
    } catch (_) {}
  }

  Future<void> _sendRequest() async {
    if (_phoneCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.requestMoney(
        receiverPhone: _phoneCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        message: _msgCtrl.text,
      );
      _phoneCtrl.clear(); _amountCtrl.clear(); _msgCtrl.clear();
      _loadRequests();
      _tab.animateTo(1);
      _showMsg("Demande envoyée !", AppTheme.success);
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception: ', ''), AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(int id) async {
    try {
      await ApiService.acceptMoneyRequest(id);
      _loadRequests();
      _showMsg("Argent transféré !", AppTheme.success);
    } catch (e) {
      _showMsg(e.toString().replaceAll('Exception: ', ''), AppTheme.error);
    }
  }

  Future<void> _declineRequest(int id) async {
    await ApiService.declineMoneyRequest(id);
    _loadRequests();
  }

  void _showMsg(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: const Text("Demande d'argent", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.dark,
        foregroundColor: AppTheme.textLight,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: "Demander"),
            Tab(text: "Reçues"),
            Tab(text: "Envoyées"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildRequestForm(), _buildIncomingList(), _buildOutgoingList()],
      ),
    );
  }

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const Row(children: [
                  Icon(Icons.request_page_rounded, color: AppTheme.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Demande d'argent", style: TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text("Demande de l'argent à un ami", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ])),
                ]),
                const SizedBox(height: 24),
                _field(_phoneCtrl, "Numéro du destinataire", Icons.phone_rounded, TextInputType.phone),
                const SizedBox(height: 16),
                _field(_amountCtrl, "Montant (FCFA)", Icons.monetization_on_rounded, TextInputType.number),
                const SizedBox(height: 16),
                _field(_msgCtrl, "Message (optionnel)", Icons.message_rounded, TextInputType.text),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _isLoading ? null : _sendRequest,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("ENVOYER LA DEMANDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingList() {
    if (_incoming.isEmpty) return const Center(child: Text("Aucune demande reçue", style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _incoming.length,
      itemBuilder: (context, i) {
        final r = _incoming[i];
        final amount = double.tryParse(r['amount'].toString()) ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppTheme.primary)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['sender_name'] ?? '', style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700)),
                  Text("${amount.toStringAsFixed(0)} FCFA — ${r['message'] ?? ''}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success), onPressed: () => _acceptRequest(r['id'])),
              IconButton(icon: const Icon(Icons.cancel_rounded, color: AppTheme.error), onPressed: () => _declineRequest(r['id'])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutgoingList() {
    if (_outgoing.isEmpty) return const Center(child: Text("Aucune demande envoyée", style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _outgoing.length,
      itemBuilder: (context, i) {
        final r = _outgoing[i];
        final amount = double.tryParse(r['amount'].toString()) ?? 0;
        final status = r['status'] ?? 'pending';
        final statusColor = {'pending': AppTheme.warning, 'accepted': AppTheme.success, 'declined': AppTheme.error}[status] ?? AppTheme.textMuted;
        final statusLabel = {'pending': 'En attente', 'accepted': 'Acceptée', 'declined': 'Refusée'}[status] ?? status;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: statusColor.withValues(alpha: 0.15), child: Icon(Icons.person_rounded, color: statusColor)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['receiver_name'] ?? '', style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700)),
                  Text("${amount.toStringAsFixed(0)} FCFA", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl, keyboardType: type,
      style: const TextStyle(color: AppTheme.textLight),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        filled: true, fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
