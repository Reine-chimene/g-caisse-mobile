import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class OmMomoScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const OmMomoScreen({super.key, this.userData});

  @override
  State<OmMomoScreen> createState() => _OmMomoScreenState();
}

class _OmMomoScreenState extends State<OmMomoScreen> {
  final _amountController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _receiverPhoneController = TextEditingController();

  String _senderOperator = 'Orange Money';
  String _receiverOperator = 'MTN MoMo';
  bool _isLoading = false;

  final Color orangeColor = const Color(0xFFFF7900);

  @override
  void dispose() {
    _amountController.dispose();
    _senderPhoneController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  String _opToNotchCode(String op) => op.contains('Orange') ? 'cm.orange' : 'cm.mtn';

  void _switchOperators() {
    setState(() {
      final tempOp = _senderOperator;
      _senderOperator = _receiverOperator;
      _receiverOperator = tempOp;

      final tempPhone = _senderPhoneController.text;
      _senderPhoneController.text = _receiverPhoneController.text;
      _receiverPhoneController.text = tempPhone;
    });
  }

  Future<void> _sendMoney() async {
    final senderPhone = _senderPhoneController.text.trim();
    final receiverPhone = _receiverPhoneController.text.trim();
    final amountText = _amountController.text.trim();

    if (senderPhone.isEmpty || receiverPhone.isEmpty || amountText.isEmpty) {
      _showSnackBar("Remplis tous les champs", Colors.red);
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 100) {
      _showSnackBar("Montant minimum : 100 FCFA", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = int.tryParse(widget.userData?['id']?.toString() ?? '0') ?? 0;
      final result = await ApiService.initiateDirectTransfer(
        senderId: userId,
        senderPhone: senderPhone,
        senderOperator: _opToNotchCode(_senderOperator),
        receiverPhone: receiverPhone,
        receiverOperator: _opToNotchCode(_receiverOperator),
        amount: amount,
      );

      final paymentUrl = result['payment_url'];
      if (paymentUrl != null) {
        final uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // Vérifier le statut après paiement
          if (mounted) _showWaitingDialog(result['reference']);
        } else {
          _showSnackBar("Impossible d'ouvrir la page de paiement", Colors.red);
        }
      } else {
        _showSnackBar("URL de paiement non reçue", Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString().replaceAll('Exception:', '').trim(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWaitingDialog(String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF7900)),
            const SizedBox(height: 20),
            const Text("En attente du paiement...", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Réf: $reference", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 15),
            const Text("Paie via Orange Money ou MTN MoMo dans le navigateur, puis reviens ici.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("FERMER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orangeColor),
            onPressed: () async {
              try {
                final status = await ApiService.getDirectTransferStatus(reference);
                if (status['status'] == 'completed') {
                  Navigator.pop(ctx);
                  _showSuccessDialog("Transfert effectué avec succès !");
                } else if (status['status'] == 'failed') {
                  Navigator.pop(ctx);
                  _showSnackBar("Le transfert a échoué", Colors.red);
                } else {
                  _showSnackBar("Paiement en attente. Termine le paiement d'abord.", Colors.orange);
                }
              } catch (e) {
                _showSnackBar("Erreur de vérification", Colors.red);
              }
            },
            child: const Text("J'AI PAYÉ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orangeColor, minimumSize: const Size(double.infinity, 45)),
            onPressed: () {
              Navigator.pop(ctx);
              _amountController.clear();
              _receiverPhoneController.clear();
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Transfert OM ↔ MoMo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: orangeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAmountField(),
            const SizedBox(height: 30),
            _buildOperatorCard("DEPUIS", _senderOperator, _senderPhoneController, (val) {
              setState(() {
                _senderOperator = val!;
                if (_senderOperator == _receiverOperator) {
                  _receiverOperator = (_senderOperator == 'Orange Money') ? 'MTN MoMo' : 'Orange Money';
                }
              });
            }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: IconButton(
                icon: Icon(Icons.swap_vert_circle, size: 60, color: orangeColor),
                onPressed: _switchOperators,
              ),
            ),
            _buildOperatorCard("VERS", _receiverOperator, _receiverPhoneController, (val) {
              setState(() {
                _receiverOperator = val!;
                if (_receiverOperator == _senderOperator) {
                  _senderOperator = (_receiverOperator == 'Orange Money') ? 'MTN MoMo' : 'Orange Money';
                }
              });
            }),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    "Tu seras redirigé vers Orange Money ou MTN MoMo pour payer. L'argent sera envoyé directement au destinataire.",
                    style: TextStyle(fontSize: 12, color: Colors.blue))),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _sendMoney,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ENVOYER",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Montant à envoyer",
        suffixText: "FCFA",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildOperatorCard(String label, String op, TextEditingController ctrl, Function(String?) onChanged) {
    bool isOrange = op.contains('Orange');
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isOrange ? orangeColor.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          Row(
            children: [
              DropdownButton<String>(
                value: op,
                underline: const SizedBox(),
                items: ['Orange Money', 'MTN MoMo'].map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(
                    color: e.contains('Orange') ? Colors.orange.shade800 : Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  )),
                )).toList(),
                onChanged: onChanged,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "6XX XXX XXX",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
