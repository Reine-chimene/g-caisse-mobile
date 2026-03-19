import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AirtimeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AirtimeScreen({super.key, required this.userData});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  
  String _selectedOperator = "Orange";
  String _rechargeType = "Crédit"; // Crédit ou Data
  String _dataPlan = "Jour"; // Jour, Semaine, Mois
  bool _isLoading = false;

  final List<String> _operators = ["Orange", "MTN", "Camtel"];
  final List<String> _dataPlans = ["Jour", "Semaine", "Mois"];

  void _submitRecharge() async {
    if (_phoneCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Préparation de la description pour le backend
      String description = _rechargeType == "Crédit" 
          ? "Recharge Crédit $_selectedOperator" 
          : "Forfait Data $_selectedOperator ($_dataPlan)";

      final res = await ApiService.buyAirtimeOrData(
        userId: widget.userData['id'],
        phoneNumber: _phoneCtrl.text,
        amount: double.parse(_amountCtrl.text),
        operator: _selectedOperator,
        type: _rechargeType,
        plan: _rechargeType == "Data" ? _dataPlan : null,
      );

      if (mounted) {
        _showSnackBar("Recharge effectuée avec succès !", Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Erreur: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recharge & Data"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choisissez l'opérateur", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _operators.map((op) => _operatorTile(op)).toList(),
            ),
            const SizedBox(height: 30),
            
            const Text("Type de service", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio(
                  value: "Crédit",
                  groupValue: _rechargeType,
                  onChanged: (v) => setState(() => _rechargeType = v.toString()),
                  activeColor: const Color(0xFFFF7900),
                ),
                const Text("Crédit simple"),
                const SizedBox(width: 20),
                Radio(
                  value: "Data",
                  groupValue: _rechargeType,
                  onChanged: (v) => setState(() => _rechargeType = v.toString()),
                  activeColor: const Color(0xFFFF7900),
                ),
                const Text("Forfait Data"),
              ],
            ),

            if (_rechargeType == "Data") ...[
              const SizedBox(height: 10),
              const Text("Validité du forfait", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                value: _dataPlan,
                items: _dataPlans.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _dataPlan = v!),
              ),
            ],

            const SizedBox(height: 20),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Numéro de téléphone",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Montant (FCFA)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7900),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitRecharge,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("VALIDER LA RECHARGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _operatorTile(String name) {
    bool isSelected = _selectedOperator == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedOperator = name),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7900).withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(color: isSelected ? const Color(0xFFFF7900) : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(Icons.signal_cellular_alt, color: isSelected ? const Color(0xFFFF7900) : Colors.grey),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFFF7900) : Colors.black)),
          ],
        ),
      ),
    );
  }
}