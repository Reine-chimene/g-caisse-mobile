import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import 'saving_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart';
import 'om_momo_screen.dart';
import 'airtime_screen.dart';
import 'history_screen.dart';
import 'tontine_details_screen.dart';
import 'bill_payment_screen.dart';

// =========================================================
// 1. WRAPPER PRINCIPAL
// =========================================================
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  // Utilisation d'une fonction pour reconstruire les pages avec les données à jour
  List<Widget> _getPages() {
    return [
      HomeDashboard(userData: widget.userData),
      TontinesListScreen(userData: widget.userData),
      SavingScreen(userData: widget.userData),
      ProfileScreen(userData: widget.userData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _getPages()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF7900),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Tontines"),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: "Épargne"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

// =========================================================
// 3. ECRAN LISTE TONTINES (NOUVEAU)
// =========================================================
class TontinesListScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TontinesListScreen({super.key, required this.userData});

  @override
  State<TontinesListScreen> createState() => _TontinesListScreenState();
}

class _TontinesListScreenState extends State<TontinesListScreen> {
  List<dynamic> tontines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final myId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      final data = await ApiService.getTontines(myId);
      if (mounted) {
        setState(() {
          tontines = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Tontines"), automaticallyImplyLeading: false, centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7900))) 
          : tontines.isEmpty 
            ? ListView(children: const [SizedBox(height: 200), Center(child: Text("Aucune tontine trouvée"))])
            : ListView.builder(
                itemCount: tontines.length,
                itemBuilder: (c, i) => ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFF7900), child: Icon(Icons.groups, color: Colors.white)),
                  title: Text(tontines[i]['name'] ?? "Groupe"),
                  subtitle: Text("${tontines[i]['amount']} FCFA - ${tontines[i]['frequency'] ?? ''}"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => TontineDetailsScreen(
                      tontine: tontines[i], 
                      userData: widget.userData,
                      userId: int.tryParse(widget.userData['id'].toString()) ?? 0,
                    )));
                  },
                ),
              ),
      ),
    );
  }
}

// =========================================================
// 2. DASHBOARD
// =========================================================
class HomeDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeDashboard({super.key, required this.userData});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final Color orangeColor = const Color(0xFFFF7900);
  bool _isBalanceVisible = true;
  double totalBalance = 0.0;
  List<dynamic> mesTontines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // Sécurisation de l'ID pour le Backend
      final myId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      
      final results = await Future.wait([
        ApiService.getUserBalance(myId),
        ApiService.getTontines(myId),
      ]);

      if (mounted) {
        setState(() {
          totalBalance = results[0] as double;
          mesTontines = results[1] as List<dynamic>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Erreur chargement données: $e");
    }
  }

  // --- LOGIQUE TRANSACTION (DÉPÔT & RETRAIT) ---
  void _openTransactionDialog(bool isDeposit, String operator) {
    Navigator.pop(context);
    // Pré-remplit avec le numéro du profil, mais modifiable
    final TextEditingController phoneCtrl = TextEditingController(text: widget.userData['phone']);
    final TextEditingController amountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("${isDeposit ? 'Dépôt' : 'Retrait'} $operator"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. On demande d'abord le numéro
            TextField(
              controller: phoneCtrl, 
              keyboardType: TextInputType.phone, 
              decoration: const InputDecoration(labelText: "Numéro de téléphone", hintText: "6XXXXXXXX", prefixIcon: Icon(Icons.phone))
            ),
            const SizedBox(height: 15),
            // 2. Ensuite le montant
            TextField(
              controller: amountCtrl, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: "Montant FCFA", hintText: "Ex: 1000", prefixIcon: Icon(Icons.money))
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orangeColor),
            onPressed: () async {
              if (phoneCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
              Navigator.pop(c);
              _processTransaction(isDeposit, phoneCtrl.text.trim(), double.tryParse(amountCtrl.text) ?? 0);
            },
            child: const Text("Valider", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _processTransaction(bool isDeposit, String phone, double amount) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isDeposit ? "Initialisation du dépôt..." : "Traitement du retrait...")));
      
      final myId = int.tryParse(widget.userData['id'].toString()) ?? 0;

      if (isDeposit) {
        final res = await ApiService.initiatePayment(myId, phone, amount, name: widget.userData['fullname']);
        if (res['success'] == true && res['payment_url'] != null) {
          final Uri url = Uri.parse(res['payment_url']);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception("Lien impossible à ouvrir");
          }
        } else {
          throw Exception(res['message'] ?? "Erreur d'initialisation");
        }
      } else {
        // Logique de Retrait
        await ApiService.processPayout(userId: myId, amount: amount, phone: phone, name: widget.userData['fullname']);
        if (mounted) _showSuccessDialog("Retrait initié avec succès sur le $phone");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            _buildBalanceCard(),
            _buildQuickActions(),
            const SizedBox(height: 30),
            _buildTontineSection(),
            _buildServicesGrid(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE L'INTERFACE ---
  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Solde Principal", style: TextStyle(color: Colors.white70)),
              IconButton(
                icon: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white, size: 20),
                onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
              )
            ],
          ),
          Text(
            _isBalanceVisible ? "${totalBalance.toStringAsFixed(0)} FCFA" : "•••••• FCFA",
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionItem(Icons.add_circle, "Dépôt", () => _showOperatorSelector(true)),
        _actionItem(Icons.remove_circle, "Retrait", () => _showOperatorSelector(false)), 
        _actionItem(Icons.history, "Historique", () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryScreen(userId: int.tryParse(widget.userData['id'].toString()) ?? 0)));
        }),
      ],
    );
  }

  void _showOperatorSelector(bool isDeposit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Mode de ${isDeposit ? 'dépôt' : 'retrait'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _logoBtn("Orange", 'assets/logo_orange.jpg', () => _openTransactionDialog(isDeposit, "Orange")),
                _logoBtn("MTN", 'assets/logo_mtn.jpg', () => _openTransactionDialog(isDeposit, "MTN")),
                if (isDeposit) // La carte n'est souvent dispo que pour le dépôt
                  _logoBtn("Carte", '', () => Navigator.pop(context), icon: Icons.credit_card),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTontineSection() {
    if (isLoading) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("MES TONTINES", style: TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        mesTontines.isEmpty 
          ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Aucune tontine trouvée", style: TextStyle(color: Colors.grey)))
          : SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                itemCount: mesTontines.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => TontineDetailsScreen(
                      tontine: mesTontines[i],
                      userData: widget.userData,
                      userId: int.tryParse(widget.userData['id'].toString()) ?? 0,
                    )));
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                    child: Center(child: Text(mesTontines[i]['name'] ?? "Groupe", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500))),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildServicesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _serviceCard(Icons.phone_android, "Recharge", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AirtimeScreen(userData: widget.userData)))),
        _serviceCard(Icons.compare_arrows, "OM/MoMo", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => OmMomoScreen(userData: widget.userData)))),
        _serviceCard(Icons.savings, "Épargne", Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (c) => SavingScreen(userData: widget.userData)))),
        _serviceCard(Icons.add_business, "Créer Tontine", Colors.purple, () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (c) => CreateTontineScreen(userId: int.tryParse(widget.userData['id'].toString()) ?? 0))
          ).then((_) => _loadData()); // Rafraîchit après création
        }),
        _serviceCard(Icons.lightbulb_outline, "Factures", Colors.yellow.shade800, () => Navigator.push(context, MaterialPageRoute(builder: (c) => BillPaymentScreen(userData: widget.userData)))),
      ],
    );
  }

  // --- FONCTIONS AUXILIAIRES ---
  Widget _actionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: orangeColor.withOpacity(0.1), child: Icon(icon, color: orangeColor)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _serviceCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _logoBtn(String name, String path, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        icon != null ? Icon(icon, size: 50, color: Colors.blueGrey) : (path.isNotEmpty ? Image.asset(path, width: 50, height: 50, errorBuilder: (c, e, s) => const Icon(Icons.payment, size: 50)) : const Icon(Icons.payment, size: 50)),
        Text(name, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  void _showSuccessDialog(String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Text(msg, textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))
        ],
      )
    );
  }
}