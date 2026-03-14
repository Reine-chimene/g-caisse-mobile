import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'tontine_list_screen.dart';
import 'saving_screen.dart';
import 'loan_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart';
import 'om_momo_screen.dart'; // ✅ AJOUT DE L'IMPORTATION ICI

// --- ÉCRAN INVESTISSEMENT (De retour !) ---
class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Investissements"), backgroundColor: const Color(0xFFFF7900), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Card(
              color: Color(0xFFFFF3E0),
              child: ListTile(
                title: Text("Plan Argent", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Rentabilité : +15% / an"),
                trailing: Icon(Icons.trending_up, color: Color(0xFFFF7900)),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              color: Color(0xFFFFF3E0),
              child: ListTile(
                title: Text("Plan Or", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Rentabilité : +25% / an"),
                trailing: Icon(Icons.star, color: Colors.orange),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7900), minimumSize: const Size(double.infinity, 50)),
              onPressed: () {}, 
              child: const Text("Investir maintenant", style: TextStyle(color: Colors.white))
            )
          ],
        ),
      ),
    );
  }
}

// --- ÉCRAN HISTORIQUE ---
class HistoryScreen extends StatelessWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mon Historique", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getUserTransactions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7900)));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Aucune transaction trouvée"));
          
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
                    child: Icon(isDepot ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isDepot ? Colors.green : Colors.red),
                  ),
                  title: Text("${tx['amount']} FCFA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(tx['created_at'] ?? "Récemment", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
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

// --- ÉCRAN DASHBOARD PRINCIPAL ---
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeScreen> {
  final Color orangeColor = const Color(0xFFFF7900);
  final Color blackColor = Colors.black;
  bool _isBalanceVisible = true;
  double totalBalance = 0.0;
  
  // Nouvelles variables pour les tontines récentes
  List<dynamic> mesTontines = [];
  bool isLoadingTontines = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      int myId = widget.userData['id'];
      final balance = await ApiService.getUserBalance(myId);
      final tontines = await ApiService.getTontines(myId); // Charge les tontines pour le carrousel
      if (mounted) {
        setState(() {
          totalBalance = balance;
          mesTontines = tontines;
          isLoadingTontines = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingTontines = false);
    }
  }

  // --- LOGIQUE DES PAIEMENTS (Inchangée) ---
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
      final response = await ApiService.initiatePayment(widget.userData['phone'], amount, name: widget.userData['fullname']);
      if (response['success'] == true) await launchUrl(Uri.parse(response['payment_url']), mode: LaunchMode.externalApplication);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec du paiement"))); }
  }

  Future<void> _processStripePayment(double amount) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Initialisation Visa...")));
    try {
      final res = await ApiService.createStripePaymentIntent(widget.userData['id'], amount);
      if (res.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paiement prêt")));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur service Visa"))); }
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
                } catch(e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solde insuffisant"), backgroundColor: Colors.red)); }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceSection(),
              _buildQuickActions(),
              const SizedBox(height: 25),
              
              // NOUVEAU : Carrousel des tontines
              _buildRecentTontines(),
              
              const SizedBox(height: 20),
              _buildServicesGrid(),
              const SizedBox(height: 40), // Espace pour la bottom nav bar
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
      decoration: BoxDecoration(color: blackColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Solde G-CAISE", style: TextStyle(color: Colors.white70, fontSize: 14)),
              GestureDetector(
                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(_isBalanceVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white, size: 20),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Mieux espacé
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
            padding: const EdgeInsets.all(14), // Un peu plus grand
            decoration: BoxDecoration(color: orangeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: orangeColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // NOUVEAU : Aperçu des Tontines
  Widget _buildRecentTontines() {
    if (isLoadingTontines) return const Center(child: CircularProgressIndicator());
    if (mesTontines.isEmpty) return const SizedBox(); // Cache la section si aucune tontine

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("MES GROUPES DE TONTINE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 130, // Hauteur du carrousel
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: mesTontines.length,
            itemBuilder: (context, i) {
              var t = mesTontines[i];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Gris très sombre, élégant
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups, color: orangeColor, size: 28),
                    const Spacer(),
                    Text(t['name'] ?? 'Groupe', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("${t['amount_to_pay']} FCFA", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // NOUVEAU DESIGN : De vrais boutons colorés
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
            childAspectRatio: 1.1, // Ajustement de la taille des tuiles
            children: [
              // ✅ NOUVEAU : Le bouton OM <-> MoMo !
              _coloredServiceItem(Icons.swap_horiz_rounded, "OM ↔ MoMo", [Colors.blueGrey.shade700, Colors.blueGrey.shade400], OmMomoScreen(userData: widget.userData)),
              
              _coloredServiceItem(Icons.trending_up, "Investir", [Colors.blue.shade700, Colors.blue.shade400], const InvestmentScreen()),
              _coloredServiceItem(Icons.savings, "Épargne", [Colors.green.shade700, Colors.green.shade400], SavingScreen(userData: widget.userData)),
              _coloredServiceItem(Icons.handshake, "Prêts", [Colors.purple.shade700, Colors.purple.shade400], LoanScreen(userData: widget.userData)),
              _coloredServiceItem(Icons.add_business_rounded, "Créer Tontine", [Colors.orange.shade800, orangeColor], CreateTontineScreen(userId: widget.userData['id'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coloredServiceItem(IconData icon, String label, List<Color> gradientColors, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          ],
        ),
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
            child: Image.asset(path, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.payment, size: 40)),
          ),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}