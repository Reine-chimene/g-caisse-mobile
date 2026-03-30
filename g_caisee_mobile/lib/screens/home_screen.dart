import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notchpay_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import 'saving_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart';
import 'om_momo_screen.dart';
import 'airtime_screen.dart';
import 'history_screen.dart';
import 'tontine_details_screen.dart';
import 'bill_payment_screen.dart';
import 'bank_deposit_screen.dart';
import 'referral_screen.dart';
import 'features/qr_code_screen.dart';
import 'features/financial_dashboard_screen.dart';
import 'features/gamification_screen.dart';
import 'request_money_screen.dart';
import 'split_bill_screen.dart';
import 'round_up_settings_screen.dart';
import 'notifications_screen.dart';
import 'scheduled_payments_screen.dart';
import 'school_fee_screen.dart';

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
      backgroundColor: AppTheme.dark,
      body: IndexedStack(index: _selectedIndex, children: _getPages()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          border: Border(top: BorderSide(color: AppTheme.darkSurface, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Accueil"),
            BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: "Tontines"),
            BottomNavigationBarItem(icon: Icon(Icons.savings_rounded), label: "Épargne"),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
          ],
        ),
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
    final myId = int.tryParse(widget.userData['id'].toString()) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Tontines"), automaticallyImplyLeading: false, centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateTontineScreen(userId: myId)),
        ).then((_) => _fetchData()),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("CRÉER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
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
                  subtitle: Text("${tontines[i]['amount_to_pay'] ?? tontines[i]['amount'] ?? ''} FCFA - ${tontines[i]['frequency'] ?? ''}"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TontineDetailsScreen(
                    tontine: tontines[i], 
                    userData: widget.userData,
                    userId: myId,
                  ))).then((_) => _fetchData()),
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

class _HomeDashboardState extends State<HomeDashboard> with WidgetsBindingObserver {
  final Color orangeColor = const Color(0xFFFF7900);
  bool _isBalanceVisible = true;
  double totalBalance = 0.0;
  List<dynamic> mesTontines = [];
  bool isLoading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final myId = int.tryParse(widget.userData['id'].toString()) ?? 0;
      final results = await Future.wait([
        ApiService.getUserBalance(myId),
        ApiService.getTontines(myId),
        ApiService.getNotifications(),
      ]);
      if (mounted) {
        setState(() {
          totalBalance = results[0] as double;
          mesTontines  = results[1] as List<dynamic>;
          _unreadNotifications = (results[2] as Map)['unread_count'] ?? 0;
          isLoading    = false;
        });
        // Sauvegarder en cache hors-ligne
        await OfflineService.saveBalance(totalBalance);
        await OfflineService.saveTontines(mesTontines);
      }
    } catch (e) {
      // Mode hors-ligne : charger depuis le cache
      if (mounted) {
        setState(() {
          totalBalance = OfflineService.getBalance();
          mesTontines  = OfflineService.getTontines();
          isLoading    = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Mode hors-ligne — données en cache'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
      debugPrint('Erreur chargement données: $e');
    }
  }

  // --- LOGIQUE TRANSACTION (DÉPÔT & RETRAIT) ---
  void _openTransactionDialog(bool isDeposit, String operator, String notchChannel) {
    Navigator.pop(context);
    final TextEditingController phoneCtrl = TextEditingController(text: widget.userData['phone']);
    final TextEditingController amountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("${isDeposit ? 'Dépôt' : 'Retrait'} $operator"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl, 
              keyboardType: TextInputType.phone, 
              decoration: const InputDecoration(labelText: "Numéro de téléphone", hintText: "6XXXXXXXX", prefixIcon: Icon(Icons.phone))
            ),
            const SizedBox(height: 15),
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
              // On passe le channel Notch Pay correct (cm.orange ou cm.mtn)
              _processTransaction(isDeposit, phoneCtrl.text.trim(), double.tryParse(amountCtrl.text) ?? 0, notchChannel);
            },
            child: const Text("Valider", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _processTransaction(bool isDeposit, String phone, double amount, String notchChannel) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isDeposit ? "Initialisation du dépôt..." : "Traitement du retrait...")));
      
      final myId = int.tryParse(widget.userData['id'].toString()) ?? 0;

      if (isDeposit) {
        // Ouvre la page Notch Pay dans le navigateur
        final reference = await NotchPayService.deposit(
          context: context,
          userId: myId,
          amount: amount,
          phone: phone,
          name: widget.userData['fullname'] ?? 'Membre G-Caisse',
        );
        if (mounted && reference.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paie dans le navigateur, puis reviens ici...'), backgroundColor: Colors.blue, duration: Duration(seconds: 3)),
          );
          // Vérifier le statut du dépôt après retour (polling)
          await _pollDepositStatus(reference, amount);
        }
      } else {
        final result = await ApiService.processPayout(
          userId: myId,
          amount: amount,
          phone: phone,
          name: widget.userData['fullname'],
          channel: notchChannel,
        );
        if (mounted) {
          final status = result['transfer_status'] ?? 'sent';
          final statusMsg = {
            'complete': 'Retrait effectué avec succès ✅',
            'sent':     'Retrait envoyé, en attente de confirmation ⏳',
            'processing': 'Retrait en cours de traitement ⏳',
            'failed':   'Retrait échoué, votre solde a été restitué ❌',
          }[status] ?? 'Retrait initié sur $phone';
          _showSuccessDialog(statusMsg);
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red));
    }
  }

  Future<void> _pollDepositStatus(String reference, double amount) async {
    // Vérifie le statut du dépôt 6 fois (30 secondes max)
    for (int i = 0; i < 6; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      try {
        final status = await ApiService.checkDepositStatus(reference);
        if (status['status'] == 'complete') {
          _loadData(); // Rafraîchir le solde
          if (mounted) {
            _showSuccessDialog('Dépôt de ${amount.toStringAsFixed(0)} FCFA effectué avec succès ✅');
          }
          return;
        }
      } catch (_) {}
    }
    // Si toujours pas confirmé après 30s, rafraîchir quand même
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dépôt en cours de traitement. Ton solde sera mis à jour sous peu.'), backgroundColor: Colors.orange, duration: Duration(seconds: 4)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 28),
            _buildTontineSection(),
            const SizedBox(height: 28),
            _buildServicesGrid(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = widget.userData['fullname']?.toString().split(' ').first ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Salut, $name 👋',
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w700)),
                const Text('Bienvenue sur G-Caisse',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(userData: widget.userData))).then((_) => _loadData()),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: AppTheme.textLight, size: 22),
                  if (_unreadNotifications > 0)
                    Positioned(right: 0, top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$_unreadNotifications', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7900), Color(0xFFFF5500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('Solde Principal', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(_isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _isBalanceVisible ? '${totalBalance.toStringAsFixed(0)} FCFA' : '•••••• FCFA',
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _cardBtn(Icons.arrow_downward_rounded, 'Dépôt', () => _showOperatorSelector(true)),
              const SizedBox(width: 12),
              _cardBtn(Icons.arrow_upward_rounded, 'Retrait', () => _showOperatorSelector(false)),
              const SizedBox(width: 12),
              _cardBtn(Icons.history_rounded, 'Historique', () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => HistoryScreen(userId: int.tryParse(widget.userData['id'].toString()) ?? 0)));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final items = [
      {'icon': Icons.send_rounded, 'label': 'Envoyer', 'color': const Color(0xFF6366F1), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => OmMomoScreen(userData: widget.userData)))},
      {'icon': Icons.request_page_rounded, 'label': 'Demander', 'color': const Color(0xFFEC4899), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestMoneyScreen(userData: widget.userData)))},
      {'icon': Icons.phone_android_rounded, 'label': 'Recharge', 'color': const Color(0xFF22C55E), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => AirtimeScreen(userData: widget.userData)))},
      {'icon': Icons.receipt_long_rounded, 'label': 'Partager', 'color': const Color(0xFFF59E0B), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => SplitBillScreen(userData: widget.userData)))},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) {
          final color = item['color'] as Color;
          return GestureDetector(
            onTap: item['onTap'] as VoidCallback,
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
                    child: Icon(item['icon'] as IconData, color: color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(item['label'] as String, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showOperatorSelector(bool isDeposit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Text('Mode de ${isDeposit ? 'dépôt' : 'retrait'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textLight)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _operatorBtn('Orange', 'assets/logo_orange.jpg', const Color(0xFFFF7900), () => _openTransactionDialog(isDeposit, 'Orange', 'cm.orange')),
                _operatorBtn('MTN', 'assets/logo_mtn.jpg', const Color(0xFFFFCC00), () => _openTransactionDialog(isDeposit, 'MTN', 'cm.mtn')),
                if (isDeposit)
                  _operatorBtn('Virement', '', Colors.blueGrey, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (c) => BankDepositScreen(userData: widget.userData)));
                  }, icon: Icons.account_balance_rounded),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _operatorBtn(String name, String path, Color color, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: icon != null
                ? Icon(icon, size: 30, color: color)
                : (path.isNotEmpty
                    ? Image.asset(path, width: 36, height: 36, errorBuilder: (_, __, ___) => Icon(Icons.payment, size: 30, color: color))
                    : Icon(Icons.payment, size: 30, color: color)),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  Widget _buildTontineSection() {
    if (isLoading) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    if (mesTontines.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mes Tontines', style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CreateTontineScreen(userId: int.tryParse(widget.userData['id'].toString()) ?? 0),
                  )).then((_) => _loadData());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [Icon(Icons.add_rounded, color: AppTheme.primary, size: 16), SizedBox(width: 4), Text('Créer', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700))]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: mesTontines.length,
            itemBuilder: (context, i) {
              final t = mesTontines[i];
              final colors = [const Color(0xFF6366F1), const Color(0xFF22C55E), const Color(0xFFF59E0B), const Color(0xFFEC4899), const Color(0xFF3B82F6)];
              final color = colors[i % colors.length];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TontineDetailsScreen(
                  tontine: t, userData: widget.userData, userId: int.tryParse(widget.userData['id'].toString()) ?? 0,
                ))).then((_) => _loadData()),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.groups_rounded, color: color, size: 20),
                      ),
                      const SizedBox(height: 10),
                      Text(t['name'] ?? 'Groupe', style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${t['amount_to_pay'] ?? ''} F · ${t['frequency'] ?? ''}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {'icon': Icons.savings_rounded, 'label': 'Épargne', 'color': const Color(0xFF22C55E), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavingScreen(userData: widget.userData)))},
      {'icon': Icons.groups_3_rounded, 'label': 'Tontine', 'color': const Color(0xFF8B5CF6), 'onTap': () { Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTontineScreen(userId: int.tryParse(widget.userData['id'].toString()) ?? 0))).then((_) => _loadData()); }},
      {'icon': Icons.receipt_long_rounded, 'label': 'Factures', 'color': const Color(0xFFF59E0B), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => BillPaymentScreen(userData: widget.userData)))},
      {'icon': Icons.auto_awesome_rounded, 'label': 'Round-Up', 'color': const Color(0xFF22D3EE), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoundUpSettingsScreen(userData: widget.userData)))},
      {'icon': Icons.schedule_rounded, 'label': 'Programmés', 'color': const Color(0xFFF97316), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduledPaymentsScreen(userData: widget.userData)))},
      {'icon': Icons.school_rounded, 'label': 'Scolarité', 'color': const Color(0xFF6366F1), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => SchoolFeeScreen(userData: widget.userData)))},
      {'icon': Icons.bar_chart_rounded, 'label': 'Finances', 'color': const Color(0xFF3B82F6), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => FinancialDashboardScreen(userData: widget.userData)))},
      {'icon': Icons.qr_code_scanner_rounded, 'label': 'QR Pay', 'color': const Color(0xFF14B8A6), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => QrCodeScreen(userData: widget.userData)))},
      {'icon': Icons.emoji_events_rounded, 'label': 'Badges', 'color': const Color(0xFFFFD700), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => GamificationScreen(userData: widget.userData)))},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Parrainage', 'color': const Color(0xFFEC4899), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReferralScreen(userData: widget.userData)))},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Services', style: TextStyle(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1),
            itemCount: services.length,
            itemBuilder: (context, i) {
              final s = services[i];
              final color = s['color'] as Color;
              return GestureDetector(
                onTap: s['onTap'] as VoidCallback,
                child: Container(
                  decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                        child: Icon(s['icon'] as IconData, color: color, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(s['label'] as String, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 60),
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textLight)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => Navigator.pop(c),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}