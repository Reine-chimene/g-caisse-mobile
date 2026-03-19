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
  String _selectedType = 'CREDIT'; 
  bool _isLoading = false;
  final double _feeRate = 0.02;

  // Données factices pour les forfaits Orange Cameroun
  final List<Map<String, dynamic>> _orangeBundles = [
    {'name': 'Maxi Jour', 'data': '1.2 Go', 'price': 500, 'duration': '24H'},
    {'name': 'Giga Data', 'data': '2.5 Go', 'price': 1000, 'duration': '24H'},
    {'name': 'Semaine Zen', 'data': '5 Go', 'price': 2500, 'duration': '7 Jours'},
    {'name': 'Mois Illimité', 'data': '20 Go', 'price': 10000, 'duration': '30 Jours'},
  ];

  Map<String, dynamic>? _selectedBundle;

  double get _amount => _selectedType == 'DATA' && _selectedBundle != null 
      ? _selectedBundle!['price'].toDouble() 
      : (double.tryParse(_amountController.text) ?? 0.0);
  
  double get _fees => _amount * _feeRate;
  double get _total => _amount + _fees;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePurchase() async {
    // 1. Validation
    if (_phoneController.text.length < 9 || _amount < 100) {
      _showSnackBar("Numéro ou montant invalide", Colors.red);
      return;
    }

    // 2. Vérification solde
    double currentBalance = double.tryParse(widget.userData['balance'].toString()) ?? 0;
    if (_total > currentBalance) {
      _showSnackBar("Solde G-CAISE insuffisant", Colors.red);
      return;
    }

    // 3. TODO: Appeler _authenticate() ici pour la sécurité biométrique

    setState(() => _isLoading = true);
    try {
      await ApiService.buyAirtime(
        userId: widget.userData['id'],
        phone: _phoneController.text,
        amount: _amount,
        operator: _selectedOperator,
      );

      if (!mounted) return;
      _showSuccessDialog("Transaction réussie", 
        "Recharge de ${_amount.toInt()} F effectuée avec succès vers ${_phoneController.text}.");
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst("Exception: ", ""), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Recharge & Forfaits", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _getOperatorColor(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("1. Choisir l'opérateur"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _opItem("MTN", Colors.yellow.shade700),
                      _opItem("ORANGE", Colors.orange.shade800),
                      _opItem("CAMTEL", Colors.blue.shade800),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _sectionTitle("2. Type de service"),
                  Row(
                    children: [
                      _typeChip("CREDIT", Icons.phone_android),
                      const SizedBox(width: 10),
                      _typeChip("DATA", Icons.language),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  // Section dynamique pour les Forfaits Orange
                  if (_selectedType == 'DATA' && _selectedOperator == 'ORANGE') ...[
                    _sectionTitle("3. Sélectionner un forfait Orange"),
                    const SizedBox(height: 10),
                    _buildBundleList(),
                    const SizedBox(height: 25),
                  ],

                  _sectionTitle(_selectedType == 'DATA' && _selectedOperator == 'ORANGE' ? "4. Infos bénéficiaire" : "3. Infos recharge"),
                  const SizedBox(height: 10),
                  _buildInputs(),
                  const SizedBox(height: 25),
                  _buildSummary(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: _getOperatorColor(),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text("Solde disponible", style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text("${widget.userData['balance'] ?? 0} FCFA", 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBundleList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _orangeBundles.length,
        itemBuilder: (context, index) {
          final b = _orangeBundles[index];
          bool isSelected = _selectedBundle == b;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedBundle = b;
              _amountController.text = b['price'].toString();
            }),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(b['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(b['data'], style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                  Text("${b['price']} F", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.contact_phone),
            labelText: "Numéro de téléphone",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        if (!(_selectedType == 'DATA' && _selectedOperator == 'ORANGE')) ...[
          const SizedBox(height: 15),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.account_balance_wallet),
              labelText: "Montant",
              suffixText: "FCFA",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _summaryRow("Service", "$_selectedOperator $_selectedType"),
          _summaryRow("Montant net", "${_amount.toInt()} F"),
          _summaryRow("Frais G-CAISE (2%)", "+ ${_fees.toInt()} F", color: Colors.orange),
          const Divider(),
          _summaryRow("Total à débiter", "${_total.toInt()} F", bold: true),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
          : const Text("CONFIRMER L'ACHAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- Helpers UI ---
  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));

  Color _getOperatorColor() {
    if (_selectedOperator == 'MTN') return Colors.yellow.shade800;
    if (_selectedOperator == 'ORANGE') return Colors.orange.shade900;
    return Colors.blue.shade800;
  }

  Widget _opItem(String name, Color color) {
    bool isSelected = _selectedOperator == name;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedOperator = name;
        _selectedBundle = null; // Reset bundle si on change d'opérateur
      }),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(name, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _typeChip(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      selectedColor: _getOperatorColor(),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      onSelected: (v) => setState(() {
        _selectedType = type;
        if (type == 'CREDIT') _selectedBundle = null;
      }),
    );
  }

  Widget _summaryRow(String label, String value, {Color color = Colors.black, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  void _showSuccessDialog(String title, String content) {
    showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
      content: Text(content, textAlign: TextAlign.center),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("RETOUR"),
          ),
        )
      ],
    ));
  }
}