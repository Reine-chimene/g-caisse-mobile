import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // Import pour les fichiers
import '../services/api_service.dart';

class LoanScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const LoanScreen({super.key, this.userData});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final Color primaryColor = const Color(0xFFD4AF37);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color darkCard = const Color(0xFF1A1A2E);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  double maxLoan = 0;
  double fees = 2500;
  bool isLoading = false;
  bool isFetchingScore = true;
  
  // Variable pour stocker le fichier sélectionné
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _fetchMaxLoan();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE FICHIER ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _fetchMaxLoan() async {
    try {
      int userId = widget.userData?['id'] ?? 1;
      int score = await ApiService.getTrustScore(userId);
      if (mounted) {
        setState(() {
          maxLoan = score * 5000.0;
          isFetchingScore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isFetchingScore = false);
    }
  }

  double get _currentAmount => double.tryParse(_amountController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    bool canSubmit = _currentAmount >= 5000 &&
        _currentAmount <= maxLoan &&
        _purposeController.text.trim().length >= 5;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("FINANCEMENT ÉTHIQUE",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isFetchingScore
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCapacityCard(),
                  const SizedBox(height: 35),
                  const Text("Détails de la demande", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildCustomField(
                    label: "Montant souhaité (FCFA)",
                    controller: _amountController,
                    hint: "Ex: 100000",
                    icon: Icons.account_balance_wallet_outlined,
                    isNumber: true,
                  ),
                  if (_currentAmount > maxLoan)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 10),
                      child: Text("Dépasse votre limite de ${maxLoan.toInt()} F",
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 20),
                  _buildCustomField(
                    label: "Motif ou Projet",
                    controller: _purposeController,
                    hint: "Expliquez l'usage des fonds...",
                    icon: Icons.edit_note_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 25),
                  
                  // --- SECTION UPLOAD ---
                  const Text("Justificatif (Optionnel mais recommandé)", 
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  _buildUploadButton(),
                  
                  const SizedBox(height: 30),
                  _buildSummaryTable(),
                  const SizedBox(height: 40),
                  _buildSubmitButton(canSubmit),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _selectedFile != null ? primaryColor : Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(_selectedFile != null ? Icons.file_present : Icons.cloud_upload_outlined, 
                 color: _selectedFile != null ? primaryColor : Colors.grey),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _selectedFile != null ? _selectedFile!.name : "Cliquez pour joindre un PDF ou une image",
                style: TextStyle(color: _selectedFile != null ? Colors.black : Colors.grey.shade600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedFile != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () => setState(() => _selectedFile = null),
              )
          ],
        ),
      ),
    );
  }

  // --- MÉTHODES UI GARDÉES ---

  Widget _buildCapacityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ÉLIGIBILITÉ MAXIMUM",
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text("${maxLoan.toStringAsFixed(0)} FCFA",
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_moon_outlined, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                const Text("Finance Islamique : 0% Riba",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryTable() {
    double total = _currentAmount > 0 ? _currentAmount + fees : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          _summaryRow("Principal", "${_currentAmount.toStringAsFixed(0)} FCFA"),
          const SizedBox(height: 12),
          _summaryRow("Frais de dossier", "${fees.toStringAsFixed(0)} FCFA"),
          const SizedBox(height: 12),
          _summaryRow("Taux de profit", "0%", isGreen: true),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total à rembourser", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text("${total.toStringAsFixed(0)} FCFA",
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: isGreen ? Colors.green : Colors.black, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCustomField({required String label, required TextEditingController controller, required String hint, required IconData icon, bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryColor),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool active) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? primaryColor : Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: active ? 4 : 0,
        ),
        onPressed: (isLoading || !active) ? null : _submitRealRequest,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("SOUMETTRE MON DOSSIER",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  Future<void> _submitRealRequest() async {
    setState(() => isLoading = true);
    try {
      int userId = widget.userData?['id'] ?? 1;
      
      // Ici tu pourrais passer _selectedFile à ton service API si nécessaire
      await ApiService.requestIslamicLoan(
        userId, 
        _currentAmount, 
        _purposeController.text,
        // file: _selectedFile (à ajouter dans ton ApiService)
      );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la soumission"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Demande Enregistrée", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Votre justificatif et votre demande ont été transmis au comité. Réponse sous 24h.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () { Navigator.pop(c); Navigator.pop(context); },
              child: const Text("RETOUR À L'ACCUEIL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}