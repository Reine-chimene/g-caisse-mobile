import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'tontine_list_screen.dart';
import 'saving_screen.dart';
import 'loan_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart';

// --- 1. ÉCRAN HISTORIQUE (Il est bien là !) ---
class HistoryScreen extends StatelessWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mon Historique", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black, // Assorti au style Max It
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getUserTransactions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7900)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune transaction trouvée"));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final tx = snapshot.data![index];
              final isDepot = tx['type'] == 'depot';
              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDepot ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                      isDepot ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                      color: isDepot ? Colors.green : Colors.red
                    ),
                  ),
                  title: Text("${tx['amount']} FCFA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(tx['created_at'] ?? "Récemment", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Text(tx['status'] ?? "Terminé", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 2. ÉCRAN DASHBOARD PRINCIPAL (STYLE MAX IT) ---
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeScreen> {
  final Color orangeColor = const Color(0xFFFF7900); // Orange Orange
  final Color blackColor = Colors.black;
  bool _isBalanceVisible = true; // Pour masquer/afficher le solde
  double totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      int myId = widget.userData['id'];
      final balance = await ApiService.getUserBalance(myId);
      if (mounted) setState(() { totalBalance = balance; });
    } catch (e) { debugPrint(e.toString()); }
  }

  // --- LOGIQUE DES PAIEMENTS (Dépôt/Retrait connectés à l'API) ---
  
  void _openPaymentInput(String operatorName, {bool isStripe = false}) {
    Navigator.pop(context); 
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Dépôt via $operatorName", style: TextStyle(color: blackColor, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Montant (FCFA)",
            prefixIcon: Icon(Icons.payments_outlined, color: orangeColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: blackColor),
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
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec du paiement")));
    }
  }

  Future<void> _processStripePayment(double amount) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Initialisation Visa...")));
    try {
      int userId = widget.userData['id'];
      final res = await ApiService.createStripePaymentIntent(userId, amount);
      if (res.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paiement prêt")));
      }
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur service Visa")));
    }
  }

  void _showWithdrawDialog() {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Retrait de fonds"),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Montant FCFA")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: blackColor),
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ApiService.transferMoney(widget.userData['id'], widget.userData['phone'], double.parse(ctrl.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Retrait initié !")));
                  _loadUserData();
                } catch(e) { 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solde insuffisant"), backgroundColor: Colors.red));
                }
              }
            }, 
            child: const Text("Valider", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/logo.jpeg', height: 40),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: orangeColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBalanceSection(),
              _buildQuickActions(),
              const Divider(thickness: 1, height: 40),
              _buildServicesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: blackColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Solde G-CAISE", style: TextStyle(color: Colors.white70, fontSize: 14)),
              GestureDetector(
                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(
                  _isBalanceVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white, size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isBalanceVisible ? "${totalBalance.toStringAsFixed(0)} FCFA" : "•••••• FCFA",
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionIcon(Icons.add_to_photos, "Dépôt", () => _showDepositSelector()),
          _actionIcon(Icons.file_upload, "Retrait", () => _showWithdrawDialog()),
          _actionIcon(Icons.history, "Historique", () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryScreen(userId: widget.userData['id'])));
          }),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: orangeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: orangeColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showDepositSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mode de dépôt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _logoBtn("Orange", 'assets/logo_orange.jpg', () => _openPaymentInput("Orange")),
                _logoBtn("MTN", 'assets/logo_mtn.jpg', () => _openPaymentInput("MTN")),
                _logoBtn("Visa", 'assets/logo_visa.png', () => _openPaymentInput("Visa", isStripe: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoBtn(String name, String path, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(path, width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.payment, size: 40)),
          ),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MES SERVICES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1.2,
            children: [
              _serviceItem(Icons.groups, "Tontines", Colors.blue, TontineListScreen(userId: widget.userData['id'], userData: widget.userData)),
              _serviceItem(Icons.savings, "Épargne", Colors.green, SavingScreen(userData: widget.userData)),
              _serviceItem(Icons.handshake, "Prêts", Colors.purple, LoanScreen(userData: widget.userData)),
              _serviceItem(Icons.person, "Profil", Colors.grey, ProfileScreen(userData: widget.userData)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceItem(IconData icon, String label, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}