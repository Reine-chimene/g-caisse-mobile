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

  // --- NOUVELLES FONCTIONS DEMANDÉES ---

  void _openGoogleMaps() async {
    // Lien vers une position (ex: Agence Yaoundé)
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=Yaoundé+Cameroon");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir Maps");
    }
  }

  void _openVoiceSupport() async {
    // Ouvre WhatsApp pour envoyer un Voice ou un message au support
    final Uri whatsappUrl = Uri.parse("https://wa.me/237600000000"); // REMPLACE PAR TON NUMÉRO
    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossible d'ouvrir WhatsApp");
    }
  }

  // --- DIALOGUES EXISTANTS ---

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
                _buildOperatorBtn("Orange Money", Colors.orange),
                _buildOperatorBtn("MTN MoMo", Colors.yellow.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorBtn(String name, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.phone_android, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showInvestmentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("G-Caisse Invest"),
        content: const Text("Le module d'investissement participatif (Immobilier & Agriculture) est en cours de validation. Disponibilité : Q3 2026."),
        actions: [
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
                  const CircleAvatar(backgroundImage: AssetImage('assets/logo.jpeg'), radius: 24, backgroundColor: Colors.white),
                ],
              ),
              const SizedBox(height: 30),
              _buildBalanceCard(),
              const SizedBox(height: 25),

              // ACTIONS PRINCIPALES
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
                    _quickActionItem(Icons.upload_rounded, "Retrait", () {}),
                    _quickActionItem(Icons.history_rounded, "Historique", () {}),
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
                  // 1. Tontine
                  _serviceCard(context, Icons.group_add_rounded, "Créer Tontine", gold, CreateTontineScreen(userId: widget.userData['id'])),
                  
                  // 2. NOUVEAU : Google Maps
                  _serviceCard(context, Icons.map_rounded, "Points Relais", Colors.redAccent, null, onCustomTap: _openGoogleMaps), 
                  
                  // 3. NOUVEAU : Voice/Support
                  _serviceCard(context, Icons.record_voice_over_rounded, "Support Vocal", Colors.teal, null, onCustomTap: _openVoiceSupport),
                  
                  // 4. Investissement
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

  Widget _serviceCard(BuildContext context, IconData icon, String label, Color color, Widget? page, {bool isDemo = false, VoidCallback? onCustomTap}) {
    return GestureDetector(
      onTap: () { 
        if (onCustomTap != null) {
          onCustomTap();
        } else if (isDemo) {
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