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
    _pages = <Widget>[
      HomeDashboard(userData: widget.userData),     
      TontineListScreen(userId: widget.userData['id']), 
      const SavingScreen(),      
      ProfileScreen(userData: widget.userData), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fond très clair
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
               // --- EN TÊTE ---
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

              // --- CARTE DE SOLDE ---
              _buildBalanceCard(),
              const SizedBox(height: 25),

              // --- LES 3 BOUTONS PRINCIPAUX ---
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

              // --- ACTIONS RAPIDES (SERVICES) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Actions Rapides", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.more_horiz, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, 
                childAspectRatio: 1.5,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  // ✅ CORRECTION APPLIQUÉE ICI : On passe bien l'ID de l'utilisateur !
                  _serviceCard(context, Icons.group_add_rounded, "Créer Tontine", gold, CreateTontineScreen(userId: widget.userData['id'])),
                  
                  _serviceCard(context, Icons.handshake_rounded, "Prêt Islamique", const Color(0xFF4A90E2), const LoanScreen()), 
                  _serviceCard(context, Icons.group_add_rounded, "Créer Tontine", gold, CreateTontineScreen(userId: widget.userData['id'])),
                  _serviceCard(context, Icons.trending_up_rounded, "Investissement", const Color(0xFF34C759), null), 
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

  Widget _serviceCard(BuildContext context, IconData icon, String label, Color color, Widget? page) {
    return GestureDetector(
      onTap: () { if (page != null) Navigator.push(context, MaterialPageRoute(builder: (c) => page)); },
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

  // --- LOGIQUE DÉPÔT ---
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
            const SizedBox(height: 5),
            const Text("Sécurisé par Notch Pay", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMaxItCard("Orange", "assets/logo_orange.jpg", () => _showOperatorDialog("Dépôt")),
                _buildMaxItCard("MTN MoMo", "assets/logo_mtn.jpg", () => _showOperatorDialog("Dépôt")),
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
              border: Border.all(color: Colors.grey.shade200),
              image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _showOperatorDialog(String type) {
    Navigator.pop(context); 
    final TextEditingController amountController = TextEditingController();
    final TextEditingController phoneController = TextEditingController(text: widget.userData['phone']); 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(type, style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Numéro de téléphone")),
            const SizedBox(height: 15),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Montant (FCFA)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () => _processPayment(phoneController.text, amountController.text),
            child: const Text("VALIDER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processPayment(String phone, String amountText) async {
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0 || phone.isEmpty) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ouverture de Notch Pay..."), backgroundColor: Colors.blue));
    try {
      final response = await ApiService.initiatePayment(phone, amount, name: widget.userData['fullname']);
      if (response['success'] == true) {
        final Uri paymentUri = Uri.parse(response['payment_url']);
        if (await canLaunchUrl(paymentUri)) {
          await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
          Future.delayed(const Duration(seconds: 5), () => _loadUserData());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.red));
    }
  }

  // --- LOGIQUE RETRAIT ---
  void _showWithdrawDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController(text: widget.userData['phone']);
    final TextEditingController amountController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Retrait d'argent", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Saisissez le compte Mobile Money qui recevra l'argent.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 15),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Numéro de réception")),
                const SizedBox(height: 15),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Montant à retirer (FCFA)")),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
              isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                    onPressed: () async {
                      final phone = phoneController.text;
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (phone.isNotEmpty && amount > 0) {
                        setDialogState(() => isLoading = true);
                        try {
                          await ApiService.transferMoney(widget.userData['id'], phone, amount);
                          if (!mounted) return;
                          Navigator.pop(context);
                          _loadUserData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Retrait initié avec succès !"), backgroundColor: Colors.green));
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                        }
                      }
                    }, 
                    child: const Text("Retirer", style: TextStyle(color: Colors.white)),
                  )
            ],
          );
        }
      ),
    );
  }

  // --- LOGIQUE HISTORIQUE AVEC FILTRE ---
  void _showHistoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _HistoryModal(userId: widget.userData['id'], goldColor: gold),
    );
  }
}

// --- WIDGET SÉPARÉ POUR GÉRER LES FILTRES DE L'HISTORIQUE ---
class _HistoryModal extends StatefulWidget {
  final int userId;
  final Color goldColor;

  const _HistoryModal({required this.userId, required this.goldColor});

  @override
  State<_HistoryModal> createState() => _HistoryModalState();
}

class _HistoryModalState extends State<_HistoryModal> {
  String _currentFilter = 'Tous'; 

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85, 
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Historique", style: TextStyle(color: widget.goldColor, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // LES FILTRES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton('Tous'),
                _buildFilterButton('Entrées'),
                _buildFilterButton('Sorties'),
              ],
            ),
            const SizedBox(height: 20),

            // LA LISTE
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: ApiService.getTransactions(widget.userId), 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  List<dynamic> txs = snapshot.data ?? [];

                  // Application du filtre
                  if (_currentFilter == 'Entrées') {
                    txs = txs.where((t) => t['description'] == 'deposit' || t['description'] == 'transfer_in').toList();
                  } else if (_currentFilter == 'Sorties') {
                    txs = txs.where((t) => t['description'] == 'withdrawal' || t['description'] == 'cotisation').toList();
                  }

                  if (txs.isEmpty) return Center(child: Text("Aucune transaction pour ce filtre.", style: TextStyle(color: Colors.grey.shade600)));

                  return ListView.separated(
                    itemCount: txs.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                    itemBuilder: (context, i) {
                      String rawType = txs[i]['description'] ?? "Inconnu";
                      String title = "Transaction";
                      Color amountColor = Colors.green;
                      String sign = "+";
                      IconData icon = Icons.payment;

                      if (rawType == 'withdrawal') { title = "Retrait / Envoi"; amountColor = Colors.redAccent; sign = "-"; icon = Icons.arrow_upward_rounded; }
                      else if (rawType == 'transfer_in') { title = "Argent reçu"; amountColor = Colors.green; sign = "+"; icon = Icons.arrow_downward_rounded; }
                      else if (rawType == 'deposit') { title = "Dépôt (Notch Pay)"; icon = Icons.account_balance_wallet; }
                      else if (rawType == 'cotisation') { title = "Cotisation Tontine"; amountColor = Colors.redAccent; sign = "-"; icon = Icons.pie_chart_rounded; }
                      else { title = rawType; }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFFF5F6F8), shape: BoxShape.circle),
                          child: Icon(icon, color: Colors.black87),
                        ),
                        title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(txs[i]['created_at'].toString().split('T')[0], style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("$sign ${txs[i]['amount']} F", style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text("Succès", style: TextStyle(color: Colors.green, fontSize: 11)), // Statut
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title) {
    bool isSelected = _currentFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? widget.goldColor : Colors.grey.shade300),
        ),
        child: Text(
          title, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }
}