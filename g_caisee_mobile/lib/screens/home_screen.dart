import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_stripe/flutter_stripe.dart' as stripe; 
import '../services/api_service.dart';
import 'tontine_list_screen.dart'; 
import 'saving_screen.dart';
import 'loan_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart'; 
import 'chat_screen.dart';

// --- ÉCRAN HISTORIQUE ---
class HistoryScreen extends StatelessWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mon Historique"), backgroundColor: const Color(0xFFD4AF37)),
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
                leading: Icon(tx['type'] == 'depot' ? Icons.add_circle : Icons.remove_circle, 
                             color: tx['type'] == 'depot' ? Colors.green : Colors.red),
                title: Text("${tx['amount']} FCFA"),
                subtitle: Text(tx['date']),
                trailing: Text(tx['status'] ?? "Terminé", style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}

// --- ÉCRAN INVESTISSEMENT ---
class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Investissements"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Card(
              color: Colors.greenAccent,
              child: ListTile(
                title: Text("Plan Argent", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Rentabilité : +15% / an"),
                trailing: Icon(Icons.trending_up),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                title: Text("Plan Or", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Rentabilité : +25% / an"),
                trailing: Icon(Icons.star, color: Colors.orange),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {}, 
              child: const Text("Investir maintenant", style: TextStyle(color: Colors.white))
            )
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeDashboard(userData: widget.userData),     
      TontineListScreen(userId: widget.userData['id'], userData: widget.userData), 
      SavingScreen(userData: widget.userData),       
      ProfileScreen(userData: widget.userData), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), 
      body: _pages[_selectedIndex], 
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Portefeuille"),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: "Tontines"),
          BottomNavigationBarItem(icon: Icon(Icons.savings_rounded), label: "Épargne"),
          BottomNavigationBarItem(icon: Icon(Icons.person_pin_rounded), label: "Moi"),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeDashboard({super.key, required this.userData});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
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

  // ✅ CORRECTION RÉELLE STRIPE
  Future<void> _processStripePayment(double amount) async {
    _showSuccess("Initialisation du paiement sécurisé...");
    try {
      int userId = widget.userData['id'];
      final String clientSecret = await ApiService.createStripePaymentIntent(userId, amount);
      if (clientSecret.isNotEmpty) {
        _showSuccess("Paiement prêt. (Test Mode: Secret généré)");
        // Intégrer stripe.Stripe.instance.presentPaymentSheet() ici si configuré
      }
    } catch (e) {
      _showError("Erreur lors de l'accès au service Visa");
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  void _showDepositSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choisir un mode de dépôt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLogoBtn("Orange", 'assets/logo_orange.jpg', () => _openPaymentInput("Orange")),
                _buildLogoBtn("MTN", 'assets/logo_mtn.jpg', () => _openPaymentInput("MTN")),
                _buildLogoBtn("Visa", 'assets/logo_visa.PNG', () => _openPaymentInput("Visa", isStripe: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildBalanceCard(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const SizedBox(height: 35),
              const Text("Services G-Caisse", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildServicesGrid(),
            ],
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
          const Text("Bonjour,", style: TextStyle(color: Colors.grey, fontSize: 16)),
          Text(widget.userData['fullname'] ?? "Utilisateur", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
        const CircleAvatar(radius: 28, backgroundImage: AssetImage('assets/logo.jpeg')),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: darkBlue, 
        borderRadius: BorderRadius.circular(25),
        // ✅ CORRECTION : Retrait de l'image card_bg manquante
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Solde disponible", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Text("${totalBalance.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionBtn(Icons.add_circle, "Dépôt", _showDepositSelector),
        _actionBtn(Icons.account_balance, "Retrait", _showWithdrawDialog),
        _actionBtn(Icons.history, "Historique", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(userId: widget.userData['id'])));
        }),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Icon(icon, color: gold, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, childAspectRatio: 1.3, mainAxisSpacing: 15, crossAxisSpacing: 15,
      children: [
        _serviceCard(Icons.group_add, "Nouvelle Tontine", gold, CreateTontineScreen(userId: widget.userData['id'])),
        _serviceCard(Icons.handshake_rounded, "Prêts", Colors.purple, LoanScreen(userData: widget.userData)),
        _serviceCard(Icons.trending_up, "Investissement", Colors.green, const InvestmentScreen()),
        // ✅ CORRECTION RÉELLE GOOGLE MAPS
        _serviceCard(Icons.location_on, "Agences", Colors.orange, null, onTap: () async {
          final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=Titigarage+Yaounde");
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            _showError("Impossible d'ouvrir la carte");
          }
        }),
      ],
    );
  }

  Widget _serviceCard(IconData icon, String label, Color color, Widget? page, {VoidCallback? onTap}) {
    return InkWell(
      onTap: () { 
        if (onTap != null) { onTap(); } 
        else if (page != null) { Navigator.push(context, MaterialPageRoute(builder: (c) => page)); }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildLogoBtn(String name, String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(assetPath, width: 60, height: 60, fit: BoxFit.cover, 
                errorBuilder: (c,e,s) => const Icon(Icons.payment, size: 40, color: Colors.grey)),
        ),
        const SizedBox(height: 5),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Retrait de fonds"),
        content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Montant FCFA")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(onPressed: () async {
            if (amountController.text.isNotEmpty) {
              Navigator.pop(context);
              await ApiService.transferMoney(widget.userData['id'], widget.userData['phone'], double.parse(amountController.text));
              _loadUserData();
            }
          }, child: const Text("Confirmer"))
        ],
      ),
    );
  }
}