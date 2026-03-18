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

  // ✅ APPEL RÉEL CORRIGÉ
  void _processDirectTransfer() async {
    if (_amountController.text.isEmpty || _receiverPhoneController.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // On convertit le nom lisible en identifiant pour l'API (orange ou mtn)
      String opForApi = _senderOperator.contains('Orange') ? 'orange' : 'mtn';

      final result = await ApiService.processDirectTransfer(
        senderId: widget.userData?['id'] ?? 0,
        receiverPhone: _receiverPhoneController.text,
        amount: double.parse(_amountController.text),
        operator: opForApi, // ✅ Paramètre corrigé ici
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor, 
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
      appBar: AppBar(
        title: const Text("Transfert OM ↔ MoMo"), 
        backgroundColor: primaryColor, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
                if (_senderOperator == _receiverOperator) {
                  _receiverOperator = (_senderOperator == 'Orange Money') ? 'MTN MoMo' : 'Orange Money';
                }
              });
            }),

            // ✅ LE BOUTON SWAP
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: IconButton(
                icon: Icon(Icons.swap_vert_circle, size: 55, color: primaryColor),
                onPressed: _switchOperators,
              ),
            ),

            // SECTION ARRIVÉE
            _buildOperatorCard("VERS", _receiverOperator, _receiverPhoneController, (val) {
              setState(() {
                _receiverOperator = val!;
                if (_receiverOperator == _senderOperator) {
                  _senderOperator = (_receiverOperator == 'Orange Money') ? 'MTN MoMo' : 'Orange Money';
                }
              });
            }),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _processDirectTransfer,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("VALIDER LE TRANSFERT", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        labelStyle: const TextStyle(fontSize: 16),
        suffixText: "FCFA",
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildOperatorCard(String label, String op, TextEditingController ctrl, Function(String?) onCh) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                    fontWeight: FontWeight.bold
                  ))
                )).toList(),
                onChanged: onCh,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: ctrl, 
                  keyboardType: TextInputType.phone, 
                  decoration: const InputDecoration(
                    hintText: "6XX XXX XXX", 
                    border: InputBorder.none,
                    icon: Icon(Icons.phone_android, size: 20),
                  )
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}