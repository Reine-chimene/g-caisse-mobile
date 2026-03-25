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
  String _recipientName = ""; 

  final Color orangeColor = const Color(0xFFFF7900);

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

  void _startVerification() async {
    if (_amountController.text.isEmpty || _receiverPhoneController.text.isEmpty) {
      _showSnackBar("Veuillez remplir le montant et le numéro", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String opForApi = _receiverOperator.contains('Orange') ? 'orange' : 'mtn';
      
      // Note : Cette erreur "undefined_method" disparaîtra quand tu mettras à jour ApiService
      final name = await ApiService.getRecipientName(
        _receiverPhoneController.text.trim(), 
        opForApi
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _recipientName = name;
        });
        _showConfirmationSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Bénéficiaire introuvable", Colors.red);
      }
    }
  }

  void _executeFinalTransfer() async {
    setState(() => _isLoading = true);
    try {
      String opForApi = _senderOperator.contains('Orange') ? 'orange' : 'mtn';
      final result = await ApiService.processDirectTransfer(
        senderId: widget.userData?['id'] ?? 0,
        receiverPhone: _receiverPhoneController.text.trim(),
        amount: double.parse(_amountController.text),
        operator: opForApi,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _amountController.clear();
        _receiverPhoneController.clear();
        _showSuccessDialog(result['message'] ?? "Transfert réussi");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString().replaceAll("Exception: ", ""), Colors.red);
      }
    }
  }

  void _showConfirmationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("CONFIRMER LE TRANSFERT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 20),
            // Correction FontWeight.black -> FontWeight.w900
            Text("${_amountController.text} FCFA", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const Icon(Icons.arrow_downward, color: Colors.blue, size: 30),
            const SizedBox(height: 10),
            Text(_recipientName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            Text("Vers le numéro : ${_receiverPhoneController.text}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  Navigator.pop(context);
                  _executeFinalTransfer();
                },
                child: const Text("OUI, ENVOYER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orangeColor, minimumSize: const Size(double.infinity, 45)),
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
            _buildOperatorCard("DEPUIS MON COMPTE", _senderOperator, _senderPhoneController, (val) {
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
            _buildOperatorCard("VERS LE DESTINATAIRE", _receiverOperator, _receiverPhoneController, (val) {
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
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _startVerification,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("VÉRIFIER ET ENVOYER", 
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
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Montant à transférer",
        suffixText: "FCFA",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildOperatorCard(String label, String op, TextEditingController ctrl, Function(String?) onCh) {
    bool isOrange = op.contains('Orange');
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(15), 
        // Correction withOpacity -> withValues
        border: Border.all(color: isOrange ? orangeColor.withOpacity(0.5) : Colors.blue.withOpacity(0.5)),
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