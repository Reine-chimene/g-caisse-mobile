import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'tontine_list_screen.dart';
import 'saving_screen.dart';
import 'loan_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart';

// --- ÉCRAN HISTORIQUE (Défini ici pour corriger l'erreur) ---
class HistoryScreen extends StatelessWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Historique"),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getUserTransactions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Aucune transaction trouvée"));
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final tx = snapshot.data![index];
              return ListTile(
                leading: Icon(
                  tx['type'] == 'depot' ? Icons.add_circle : Icons.remove_circle, 
                  color: tx['type'] == 'depot' ? Colors.green : Colors.red
                ),
                title: Text("${tx['amount']} FCFA"),
                subtitle: Text(tx['created_at'] ?? ""),
                trailing: Text(tx['status'] ?? "Terminé", style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}

// --- ÉCRAN DASHBOARD PRINCIPAL ---
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color darkBlue = const Color(0xFF1A1A2E);
  double totalBalance = 0.0;
  int trustScore = 100;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      int myId = widget.userData['id'];
      final balance = await ApiService.getUserBalance(myId);
      final score = await ApiService.getTrustScore(myId);
      if (mounted) setState(() { totalBalance = balance; trustScore = score; });
    } catch (e) { debugPrint(e.toString()); }
  }

  // --- LOGIQUE DES PAIEMENTS (CORRECTIF DES MÉTHODES MANQUANTES) ---

  void _openPaymentInput(String operatorName, {bool isStripe = false}) {
    Navigator.pop(context); 
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Dépôt via $operatorName", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Montant (FCFA)",
            prefixIcon: Icon(Icons.payments_outlined, color: gold),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () async {
              double amt = double.tryParse(amountController.text) ?? 0;
              if (amt < 500) return;
              Navigator.pop(context);
              if (isStripe) { _processStripePayment(amt); } else { _processMobilePayment(amt); }
            }, 
            child: const Text("Confirmer", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Future<void> _processMobilePayment(double amount) async {
    try {
      final response = await ApiService.initiatePayment(
        widget.userData['phone'], amount, name: widget.userData['fullname']
      );
      if (response['success'] == true) {
        await launchUrl(Uri.parse(response['payment_url']), mode: LaunchMode.externalApplication);
      }
    } catch (e) { _showError("Échec du paiement"); }
  }

  Future<void> _processStripePayment(double amount) async {
    _showSuccess("Initialisation Visa...");
    try {
      int userId = widget.userData['id'];
      final res = await ApiService.createStripePaymentIntent(userId, amount);
      if (res.isNotEmpty) _showSuccess("Paiement prêt");
    } catch (e) { _showError("Erreur service Visa"); }
  }

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Retrait de fonds"),
        content: TextField(
          controller: amountController, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(labelText: "Montant FCFA")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ApiService.transferMoney(widget.userData['id'], widget.userData['phone'], double.parse(amountController.text));
                  _showSuccess("Retrait initié !");
                  _loadUserData();
                } catch(e) { _showError("Solde insuffisant"); }
              }
            }, 
            child: const Text("Confirmer")
          )
        ],
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  void _showDepositSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mode de dépôt", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _logoOption("Orange", 'assets/logo_orange.jpg', () => _openPaymentInput("Orange")),
                _logoOption("MTN", 'assets/logo_mtn.jpg', () => _openPaymentInput("MTN")),
                _logoOption("Visa", 'assets/logo_visa.png', () => _openPaymentInput("Visa", isStripe: true)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _logoOption(String name, String path, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(path, width: 65, height: 65, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.payment, size: 40)),
            ),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: gold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildPremiumBalanceCard(),
                const SizedBox(height: 30),
                _buildActionGrid(),
                const SizedBox(height: 35),
                const Text("Services G-CAISE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 15),
                _buildServicesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Content de vous revoir,", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(widget.userData['fullname'] ?? "Membre", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ]),
        const CircleAvatar(radius: 26, backgroundImage: AssetImage('assets/logo.jpeg')),
      ],
    );
  }

  Widget _buildPremiumBalanceCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: [darkBlue, const Color(0xFF16213E)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Solde G-CAISE", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Text("${totalBalance.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickAction(Icons.add_circle_outline, "Dépôt", Colors.blue, _showDepositSelector),
        _quickAction(Icons.outbox_rounded, "Retrait", Colors.orange, _showWithdrawDialog),
        _quickAction(Icons.history_toggle_off_rounded, "Historique", Colors.grey, () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryScreen(userId: widget.userData['id'])));
        }),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Container(
          height: 60, width: 60,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildServicesList() {
    return Column(children: [
      _serviceRow(Icons.groups_3_outlined, "Tontines Actives", Colors.amber, TontineListScreen(userId: widget.userData['id'], userData: widget.userData)),
      _serviceRow(Icons.savings_outlined, "Mon Épargne", Colors.green, SavingScreen(userData: widget.userData)),
      _serviceRow(Icons.handshake_outlined, "Demander un Prêt", Colors.purple, LoanScreen(userData: widget.userData)),
      _serviceRow(Icons.add_business_outlined, "Créer une Tontine", Colors.blue, CreateTontineScreen(userId: widget.userData['id'])),
    ]);
  }

  Widget _serviceRow(IconData icon, String title, Color color, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}