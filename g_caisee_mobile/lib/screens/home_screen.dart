import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/api_service.dart';
import 'tontine_list_screen.dart'; 
import 'saving_screen.dart';
import 'social_screen.dart';
import 'loan_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 

  final List<Widget> _pages = <Widget>[
    const HomeDashboard(),     
    const TontineListScreen(), 
    const SavingScreen(),      
    const ProfileScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _pages[_selectedIndex], 
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Tontines"),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: "Épargne"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Compte"),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);
  double totalBalance = 0.0;
  int trustScore = 0;
  bool isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final balance = await ApiService.getUserBalance(1);
      final score = await ApiService.getTrustScore(1);
      if (mounted) {
        setState(() {
          totalBalance = balance;
          trustScore = score;
        });
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Bonjour, Reine 👋", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("G-Caisse Premium", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const CircleAvatar(backgroundImage: AssetImage('assets/logo.jpeg'), radius: 20),
              ],
            ),
            const SizedBox(height: 20),
            _buildBalanceCard(),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickActionItem(Icons.add, "Recharger", () => _showDepositMethodSelector(context)),
                _quickActionItem(Icons.send, "Envoyer", () => _showSendDialog(context)),
                _quickActionItem(Icons.history, "Historique", () => _showHistoryDialog(context)),
                _quickActionItem(Icons.qr_code_scanner, "Scanner", () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scanner bientôt disponible")));
                }),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Mes Services", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                _serviceCard(context, Icons.add_circle_outline, "Créer Tontine", gold, const CreateTontineScreen()),
                _serviceCard(context, Icons.handshake, "Prêt Islamic", Colors.purple, const LoanScreen()),
                _serviceCard(context, Icons.favorite, "Social", Colors.pink, const SocialScreen()),
                _serviceCard(context, Icons.rocket_launch, "Investir", Colors.orange, const InvestmentScreen()),
                _serviceCard(context, Icons.gavel, "Enchères", Colors.cyan, const AuctionScreen(tontineId: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositMethodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text("Moyen de paiement", style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Choisissez votre mode de recharge", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMaxItCard("Orange", "assets/logo_orange.jpg", () => _showOperatorDialog()),
                _buildMaxItCard("MTN MoMo", "assets/logo_mtn.jpg", () => _showOperatorDialog()),
                _buildIconCard("Carte", Icons.credit_card, () => _showCardDialog()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxItCard(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70, width: 90, 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildIconCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70, width: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Icon(icon, size: 40, color: Colors.blue[900]),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _showOperatorDialog() {
    Navigator.pop(context); 
    final TextEditingController amountController = TextEditingController();
    final TextEditingController phoneController = TextEditingController(text: "694098239"); 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGrey,
        title: Text("Paiement Sécurisé", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController, 
              keyboardType: TextInputType.phone, 
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Numéro de téléphone", hintStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountController, 
              keyboardType: TextInputType.number, 
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: "Montant (Ex: 5000)", hintStyle: const TextStyle(color: Colors.grey), suffixText: "FCFA", suffixStyle: TextStyle(color: gold)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () => _processPayment(phoneController.text, amountController.text),
            child: const Text("PAYER", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showCardDialog() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez choisir Orange ou MTN.")));
  }

  void _processPayment(String phone, String amountText) async {
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0 || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un montant et un numéro valides."), backgroundColor: Colors.red)
      );
      return;
    }
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Génération du lien de paiement..."), backgroundColor: Colors.blue)
    );
    
    try {
      final response = await ApiService.initiatePayment(phone, amount);

      if (response['success'] == true) {
        if (!mounted) return;
        
        final urlString = response['payment_url'];
        final Uri paymentUri = Uri.parse(urlString);

        if (await canLaunchUrl(paymentUri)) {
          await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
          
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              _loadUserData(); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Si le paiement est validé, votre solde est mis à jour."), backgroundColor: Colors.green)
              );
            }
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Impossible d'ouvrir la page de paiement."), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur serveur : ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red)
      );
    }
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gold, const Color(0xFF8B6914)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Solde total", style: TextStyle(color: Colors.white)),
              InkWell(
                onTap: () => setState(() => isBalanceVisible = !isBalanceVisible),
                child: Icon(isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(isBalanceVisible ? "${totalBalance.toStringAsFixed(0)} FCFA" : "•••••••", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 5),
                Text("Score Confiance: $trustScore/100", style: const TextStyle(color: Colors.white, fontSize: 12)),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cardGrey, shape: BoxShape.circle),
          child: Icon(icon, color: gold, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))
      ]),
    );
  }

  Widget _serviceCard(BuildContext context, IconData icon, String label, Color color, Widget? page) {
    return GestureDetector(
      onTap: () { if (page != null) Navigator.push(context, MaterialPageRoute(builder: (c) => page)); },
      child: Container(
        decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(15)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center)
        ]),
      ),
    );
  }

  void _showSendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGrey,
        title: Text("Envoyer de l'argent", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Numéro bénéficiaire", hintStyle: TextStyle(color: Colors.grey))),
            TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Montant", hintStyle: TextStyle(color: Colors.grey))),
          ],
        ),
        actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: gold), onPressed: () => Navigator.pop(context), child: const Text("Envoyer", style: TextStyle(color: Colors.black)))],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardGrey,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: ApiService.getTransactions(1), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snapshot.data ?? [];
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text("Historique des transactions", style: TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: txs.isEmpty 
                    ? const Center(child: Text("Aucune transaction", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: txs.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            leading: Icon(Icons.payment, color: gold),
                            title: Text(txs[i]['description'] ?? "Recharge", style: const TextStyle(color: Colors.white)),
                            subtitle: Text(txs[i]['created_at'].toString().split('T')[0], style: const TextStyle(color: Colors.grey)),
                            trailing: Text("+ ${txs[i]['amount']} FCFA", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Investissements", style: TextStyle(color: Colors.white))),
      body: const Center(child: Text("Bientôt disponible : Financez des projets !", style: TextStyle(color: Colors.white))),
    );
  }
}

class AuctionScreen extends StatelessWidget {
  final int tontineId;
  const AuctionScreen({super.key, required this.tontineId});
  @override
  Widget build(BuildContext context) {
    final Color gold = const Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("ENCHÈRES", style: TextStyle(color: gold)), backgroundColor: Colors.black),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getAuctions(tontineId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("0 Enchère en cours", style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              var auction = snapshot.data![i];
              return Card(
                color: const Color(0xFF1C1C1E),
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Cycle n°${auction['cycle_number']}", style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Mise min : ${auction['minimum_bid']} FCFA", style: const TextStyle(color: Colors.grey)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: gold),
                    onPressed: () {}, 
                    child: const Text("MISER", style: TextStyle(color: Colors.black)),
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