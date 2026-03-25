import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditTontineScreen extends StatefulWidget {
  final Map<String, dynamic> tontine;
  const EditTontineScreen({super.key, required this.tontine});

  @override
  State<EditTontineScreen> createState() => _EditTontineScreenState();
}

class _EditTontineScreenState extends State<EditTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String _frequency = 'Mensuelle';
  bool _isLoading = false;

  final List<String> _frequencies = ['Quotidienne', 'Hebdomadaire', 'Mensuelle'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tontine['name'] ?? '');
    _amountController = TextEditingController(text: widget.tontine['amount_to_pay']?.toString() ?? '');
    _frequency = widget.tontine['frequency'] ?? 'Mensuelle';
    if (!_frequencies.contains(_frequency)) {
      _frequency = 'Mensuelle';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final dataToUpdate = {
          'name': _nameController.text,
          'frequency': _frequency,
          'amount_to_pay': double.tryParse(_amountController.text) ?? 0.0,
        };
        final updatedTontine = await ApiService.updateTontine(widget.tontine['id'] as int, dataToUpdate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tontine mise à jour avec succès !"), backgroundColor: Colors.green),
          );
          Navigator.pop(context, updatedTontine); // Renvoie l'objet mis à jour à l'écran précédent
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier la Tontine")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nom du groupe", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Champ requis" : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Montant de la cotisation (FCFA)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => (v!.isEmpty || double.tryParse(v) == null) ? "Montant invalide" : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(labelText: "Fréquence des cotisations", border: OutlineInputBorder()),
              items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENREGISTRER"),
            ),
          ],
        ),
      ),
    );
  }
}