import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter_stripe/flutter_stripe.dart'; // Nouvel import pour Stripe
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
    _pages = [
      HomeDashboard(userData: widget.userData),     
      TontineListScreen(userId: widget.userData['id']), 
      const SavingScreen(),      
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

  // --- FONCTION STRIPE (CARTE BANCAIRE) ---
  Future<void> _processCardPayment() async {
    try {
      // Pour la démo, on utilise un clientSecret fictif. 
      // En production, ton backend Render générera ce secret via sk_test...
      String clientSecret = "pi_3P..._secret_..."; 

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'G-Caisse Pro',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFFD4AF37)),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paiement par carte validé ! ✅"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Annulé ou Erreur: ${e.error.localizedMessage}")),
        );
      }
    }
  }

  // --- FONCTIONS ACTIONS ---

  void _openGoogleMaps() async {
    final Uri url = Uri.parse("http://maps.google.com/?q=Yaounde");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _openVoiceSupport() async {
    final Uri whatsappUrl = Uri.parse("https://wa.me/237600000000"); 
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  }

  void _showDepositMethodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: 350, // Augmenté un peu pour laisser de la place au 3ème bouton
        child: Column(
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Choisir le mode de paiement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOperatorBtn("Orange", Colors.orange, Icons.phone_android, () {
                  // Ici ta logique réelle Notch Pay existante reste inchangée
                  Navigator.pop(context);
                }),
                _buildOperatorBtn("MTN MoMo", Colors.yellow.shade800, Icons.account_balance_wallet, () {
                  // Ici ta logique réelle Notch Pay existante reste inchangée
                  Navigator.pop(context);
                }),
                // AJOUT DU BOUTON CARTE BANCAIRE (Indépendant)
                _buildOperatorBtn("Carte", Colors.black, Icons.credit_card, () {
                  Navigator.pop(context);
                  _processCardPayment();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorBtn(String name, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 35),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showInvestmentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("G-Caisse Invest"),
        content: const Text("Module en cours de validation. Disponible en 2026."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: TextStyle(color: gold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tableau de bord", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const CircleAvatar(radius: 25, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 25),
              _buildBalanceCard(),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickActionItem(Icons.add_circle_outline, "Dépôt", () => _showDepositMethodSelector(context)),
                    _quickActionItem(Icons.remove_circle_outline, "Retrait", () {}),
                    _quickActionItem(Icons.history, "Historique", () {}),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const Text("Nos Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _serviceCard(context, Icons.group_add, "Créer Tontine", gold, CreateTontineScreen(userId: widget.userData['id'])),
                  _serviceCard(context, Icons.location_on, "Points Relais", Colors.redAccent, null, onCustomTap: _openGoogleMaps),
                  _serviceCard(context, Icons.mic, "Support Vocal", Colors.teal, null, onCustomTap: _openVoiceSupport),
                  _serviceCard(context, Icons.trending_up, "Investissement", Colors.green, null, isDemo: true),
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
        gradient: LinearGradient(colors: [gold, const Color(0xFF8B6914)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Solde total", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text("${totalBalance.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [Icon(icon, color: gold), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12))]),
    );
  }

  Widget _serviceCard(BuildContext context, IconData icon, String label, Color color, Widget? page, {bool isDemo = false, VoidCallback? onCustomTap}) {
    return GestureDetector(
      onTap: () {
        if (onCustomTap != null) onCustomTap();
        else if (isDemo) _showInvestmentInfo(context);
        else if (page != null) Navigator.push(context, MaterialPageRoute(builder: (c) => page));
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}