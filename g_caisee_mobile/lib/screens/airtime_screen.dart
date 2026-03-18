import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AirtimeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AirtimeScreen({super.key, required this.userData});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  String _selectedOperator = 'MTN';
  String _selectedType = 'CREDIT'; // 'CREDIT' ou 'DATA'
  bool _isLoading = false;
  double _feeRate = 0.02; // Commission de 2%

  // Calcul dynamique des frais
  double get _amount => double.tryParse(_amountController.text) ?? 0.0;
  double get _fees => _amount * _feeRate;
  double get _total => _amount + _fees;

  void _handlePurchase() async {
    if (_phoneController.text.length < 9 || _amount < 100) {
      _showSnackBar("Numéro ou montant (min 100F) invalide", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.buyAirtime(
        userId: widget.userData['id'],
        phone: _phoneController.text,
        amount: _amount,
        operator: _selectedOperator,
      );

      _showSuccessDialog("Succès !", "La recharge de ${_amount.toInt()} F vers ${_phoneController.text} est confirmée.");
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst("Exception: ", ""), Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Recharge Crédit & Data", style: TextStyle(color: Colors.white)),
        backgroundColor: _getOperatorColor(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header avec Solde
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getOperatorColor(),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Text("Votre solde G-CAISE", style: TextStyle(color: Colors.white70)),
                  Text("${widget.userData['balance'] ?? 0} FCFA", 
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Choisir l'opérateur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _opItem("MTN", "assets/mtn_logo.png", Colors.yellow.shade700),
                      _opItem("ORANGE", "assets/orange_logo.png", Colors.orange),
                      _opItem("CAMTEL", "assets/camtel_logo.png", Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text("2. Type de recharge", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      _typeChip("CREDIT", Icons.confirmation_number_outlined),
                      const SizedBox(width: 10),
                      _typeChip("DATA / INTERNET", Icons.wifi),
                    ],
                  ),

                  const SizedBox(height: 30),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone),
                      hintText: "6XX XXX XXX",
                      labelText: "Numéro du bénéficiaire",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.money),
                      hintText: "Ex: 500",
                      labelText: "Montant à envoyer",
                      suffixText: "FCFA",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),

                  const SizedBox(height: 25),
                  // RÉCAPITULATIF DES FRAIS (L'effet Wouaou de transparence)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _summaryRow("Montant recharge", "${_amount.toInt()} F"),
                        _summaryRow("Frais G-CAISE (2%)", "+ ${_fees.toInt()} F", color: Colors.orange),
                        const Divider(),
                        _summaryRow("TOTAL À PAYER", "${_total.toInt()} F", bold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getOperatorColor(),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isLoading ? null : _handlePurchase,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("RECHARGER MAINTENANT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE SUPPORT ---

  Color _getOperatorColor() {
    if (_selectedOperator == 'MTN') return Colors.yellow.shade800;
    if (_selectedOperator == 'ORANGE') return Colors.orange.shade900;
    return Colors.blue.shade800;
  }

  Widget _opItem(String name, String asset, Color color) {
    bool isSelected = _selectedOperator == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedOperator = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : [],
        ),
        child: Text(name, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _typeChip(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (v) => setState(() => _selectedType = type),
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
    );
  }

  Widget _summaryRow(String label, String value, {Color color = Colors.black, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  void _showSuccessDialog(String title, String content) {
    showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(children: [const Icon(Icons.check_circle, color: Colors.green, size: 60), const SizedBox(height: 10), Text(title)]),
      content: Text(content, textAlign: TextAlign.center),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Générer mon Reçu PDF"))],
    ));
  }
}