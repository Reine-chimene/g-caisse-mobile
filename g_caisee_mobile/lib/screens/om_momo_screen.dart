import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OmMomoScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const OmMomoScreen({super.key, this.userData});

  @override
  State<OmMomoScreen> createState() => _OmMomoScreenState();
}

class _OmMomoScreenState extends State<OmMomoScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  
  String _senderOperator = 'Orange Money';
  String _receiverOperator = 'MTN MoMo';
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFFFF7900);

  // ✅ LOGIQUE D'INVERSION DES OPÉRATEURS
  void _switchOperators() {
    setState(() {
      String tempOp = _senderOperator;
      _senderOperator = _receiverOperator;
      _receiverOperator = tempOp;

      String tempPhone = _senderPhoneController.text;
      _senderPhoneController.text = _receiverPhoneController.text;
      _receiverPhoneController.text = tempPhone;
    });
  }

  // ✅ APPEL RÉEL À NOTCH PAY VIA TON BACKEND
  void _processDirectTransfer() async {
    if (_amountController.text.isEmpty || _senderPhoneController.text.isEmpty || _receiverPhoneController.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.processDirectTransfer(
        senderId: widget.userData?['id'] ?? 0,
        receiverPhone: _receiverPhoneController.text,
        amount: double.parse(_amountController.text),
        senderOperator: _senderOperator,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog(result['message'] ?? "Transfert réussi");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString().replaceAll("Exception: ", ""), Colors.red);
      }
    }
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 45)),
            onPressed: () => Navigator.pop(context),
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
      appBar: AppBar(title: const Text("Transfert OM ↔ MoMo"), backgroundColor: primaryColor, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAmountField(),
            const SizedBox(height: 25),
            
            // SECTION DÉPART
            _buildOperatorCard("DEPUIS", _senderOperator, _senderPhoneController, (val) {
              setState(() {
                _senderOperator = val!;
                if (_senderOperator == _receiverOperator) _receiverOperator = (_senderOperator == 'Orange Money') ? 'MTN MoMo' : 'Orange Money';
              });
            }),

            // ✅ LE BOUTON SWAP POUR CHANGER DE SENS
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: IconButton(
                icon: const Icon(Icons.swap_vert_circle, size: 50, color: Color(0xFFFF7900)),
                onPressed: _switchOperators,
              ),
            ),

            // SECTION ARRIVÉE
            _buildOperatorCard("VERS", _receiverOperator, _receiverPhoneController, (val) {
              setState(() {
                _receiverOperator = val!;
                if (_receiverOperator == _senderOperator) _senderOperator = (_receiverOperator == 'Orange Money') ? 'MTN MoMo' : 'Orange Money';
              });
            }),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : _processDirectTransfer,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("VALIDER LE TRANSFERT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Montant à transférer",
        suffixText: "FCFA",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildOperatorCard(String label, String op, TextEditingController ctrl, Function(String?) onCh) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          Row(
            children: [
              DropdownButton<String>(
                value: op,
                items: ['Orange Money', 'MTN MoMo'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: e.contains('Orange') ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold)))).toList(),
                onChanged: onCh,
              ),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: ctrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: "N° Téléphone", border: InputBorder.none))),
            ],
          )
        ],
      ),
    );
  }
}