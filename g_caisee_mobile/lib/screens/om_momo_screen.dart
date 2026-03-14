import 'package:flutter/material.dart';

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

  final Color primaryColor = const Color(0xFFFF7900); // Orange Max It

  void _processDirectTransfer() async {
    if (_amountController.text.isEmpty || _senderPhoneController.text.isEmpty || _receiverPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    // Simulation du temps de traitement API (Notch Pay Collection -> Payout)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: Text(
            "Transfert de ${_amountController.text} FCFA initié avec succès depuis $_senderOperator vers $_receiverOperator.",
            textAlign: TextAlign.center,
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Transfert Direct OM ↔ MoMo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau d'explication
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Icon(Icons.autorenew, color: primaryColor, size: 30),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Text("Transférez directement de l'argent d'un opérateur à un autre sans passer par le solde G-CAISE.", style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // SECTION MONTANT
            const Text("Montant (Franc CFA)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Saisissez le montant à envoyer",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 25),

            // SECTION EXPÉDITEUR
            const Text("Expéditeur (Celui qui paie)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _senderOperator,
                          isExpanded: true,
                          items: ['Orange Money', 'MTN MoMo'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: value == 'Orange Money' ? Colors.orange.shade800 : Colors.yellow.shade800, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _senderOperator = val!),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _senderPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: "6xx xx xx xx", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 15)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            Center(child: Icon(Icons.arrow_downward, color: Colors.grey.shade400, size: 30)),
            const SizedBox(height: 25),

            // SECTION BÉNÉFICIAIRE
            const Text("Bénéficiaire (Celui qui reçoit)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _receiverOperator,
                          isExpanded: true,
                          items: ['Orange Money', 'MTN MoMo'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: value == 'Orange Money' ? Colors.orange.shade800 : Colors.yellow.shade800, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _receiverOperator = val!),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _receiverPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: "6xx xx xx xx", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 15)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),

            // BOUTON SUIVANT
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _processDirectTransfer,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Suivant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}