import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/api_service.dart';
import 'tontine_list_screen.dart'; 
import 'saving_screen.dart';
import 'loan_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart'; 

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
    // ⚠️ SUPPRESSION DES CONST ICI CAR LES DONNÉES SONT DYNAMIQUES
    _pages = [
      HomeDashboard(userData: widget.userData),     
      TontineListScreen(userId: widget.userData['id']), 
      const SavingScreen(), // Celui-ci peut rester const car il n'a pas de paramètres dynamiques     
      ProfileScreen(userData: widget.userData), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      body: _pages[_selectedIndex], 
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: "Groupes"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Épargne"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
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
  double totalBalance = 0.0;
  int trustScore = 100;
  bool isBalanceVisible = true;

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
      
      if (mounted) {
        setState(() {
          totalBalance = balance;
          trustScore = score;
        });
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showDepositMethodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text("Faire un dépôt", style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOperatorBtn("Orange", Colors.orange, () => _showOperatorDialog("Orange")),
                _buildOperatorBtn("MTN MoMo", Colors.yellow.shade700, () => _showOperatorDialog("MTN")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorBtn(String name, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.phone_android, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showOperatorDialog(String op) {
    Navigator.pop(context);
    final TextEditingController amountController = TextEditingController();
    final TextEditingController phoneController = TextEditingController(text: widget.userData['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Dépôt via $op"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Numéro de téléphone")),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Montant (FCFA)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => _processPayment(phoneController.text, amountController.text), child: const Text("Valider")),
        ],
      ),
    );
  }

  void _processPayment(String phone, String amountText) async {
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 500) return;
    Navigator.pop(context);
    try {
      final response = await ApiService.initiatePayment(phone, amount, name: widget.userData['fullname']);
      if (response['success'] == true) {
        final Uri url = Uri.parse(response['payment_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showWithdrawDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Retrait d'argent"),
        content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Montant (Min 500 FCFA)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount >= 500) {
                Navigator.pop(context);
                try {
                  await ApiService.transferMoney(widget.userData['id'], widget.userData['phone'], amount);
                  _loadUserData();
                } catch (e) { debugPrint(e.toString()); }
              }
            }, 
            child: const Text("Retirer")
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(20), child: Text("Historique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: ApiService.getTransactions(widget.userData['id']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final txs = snapshot.data!;
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: txs.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text("${txs[i]['description']}"),
                      subtitle: Text("${txs[i]['created_at']}"),
                      trailing: Text("${txs[i]['amount']} F", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvestmentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("G-Caisse Invest"),
        content: const Text("Le module d'investissement participatif est en cours de validation. Disponibilité : Q3 2026."),
        actions: [
          // APRÈS (CORRIGÉ)
TextButton(onPressed: () => Navigator.pop(context), child: Text("D'ACCORD", style: TextStyle(color: gold)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String firstName = widget.userData['fullname']?.split(' ')[0] ?? "Membre";

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadUserData,
        color: gold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bonjour, $firstName 👋", style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("G-Caisse Premium", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: gold, width: 2),
                    ),
                    child: const CircleAvatar(backgroundImage: AssetImage('assets/logo.jpeg'), radius: 24, backgroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildBalanceCard(),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, spreadRadius: 5)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickActionItem(Icons.download_rounded, "Dépôt", () => _showDepositMethodSelector(context)),
                    _quickActionItem(Icons.upload_rounded, "Retrait", () => _showWithdrawDialog(context)),
                    _quickActionItem(Icons.history_rounded, "Historique", () => _showHistoryDialog(context)),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              const Text("Actions Rapides", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, 
                childAspectRatio: 1.5,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _serviceCard(context, Icons.group_add_rounded, "Créer Tontine", gold, CreateTontineScreen(userId: widget.userData['id'])),
                  _serviceCard(context, Icons.handshake_rounded, "Prêt Islamique", const Color(0xFF4A90E2), const LoanScreen()), 
                  _serviceCard(context, Icons.explore_rounded, "Tontines Publiques", const Color(0xFFE67E22), TontineListScreen(userId: widget.userData['id'])),
                  _serviceCard(context, Icons.trending_up_rounded, "Investissement", const Color(0xFF34C759), null, isDemo: true), 
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gold, const Color(0xFF8B6914)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Solde disponible", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              InkWell(
                onTap: () => setState(() => isBalanceVisible = !isBalanceVisible),
                child: Icon(isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white, size: 20),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(
            isBalanceVisible ? "${totalBalance.toStringAsFixed(0)} FCFA" : "••••••••", 
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1)
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text("Score Confiance : $trustScore/100", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Color(0xFFF5F6F8), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black87, size: 26),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600))
      ]),
    );
  }

  Widget _serviceCard(BuildContext context, IconData icon, String label, Color color, Widget? page, {bool isDemo = false}) {
    return GestureDetector(
      onTap: () { 
        if (isDemo) {
          _showInvestmentInfo(context);
        } else if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (c) => page)); 
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, spreadRadius: 2)],
          border: Border.all(color: Colors.grey.shade100)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}