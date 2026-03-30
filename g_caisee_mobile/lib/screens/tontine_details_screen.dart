import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'auction_screen.dart';
import 'chat_screen.dart';
import 'call_screen.dart';
import 'radar_map_screen.dart';
import 'edit_tontine_screen.dart';

class TontineDetailsScreen extends StatefulWidget {
  final Map tontine;
  final int userId;
  final Map<String, dynamic> userData;

  const TontineDetailsScreen({
    super.key,
    required this.tontine,
    required this.userId,
    required this.userData,
  });

  @override
  State<TontineDetailsScreen> createState() => _TontineDetailsScreenState();
}

class _TontineDetailsScreenState extends State<TontineDetailsScreen> with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFD4AF37); 
  final Color darkCardColor = const Color(0xFF1A1A2E);

  late Map<String, dynamic> _currentTontine;
  List<dynamic> members = [];
  List<dynamic> schedule = [];
  Map<String, dynamic>? currentWinner;
  Map<String, dynamic> memberStatus = {};
  Map<String, dynamic> cagnotte = {};
  bool isLoading = true;
  bool isProcessingPayment = false;

  late TabController _tabController;

  double userBalance = 0.0;
  double socialFund  = 0.0;
  double get latePenalty => 500.0;

  bool get _isAdmin => widget.userId == (_currentTontine['admin_id'] as int? ?? -1);

  @override
  void initState() {
    super.initState();
    _currentTontine = Map<String, dynamic>.from(widget.tontine);
    _tabController = TabController(length: 4, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getTontineMembers(_currentTontine['id'] as int),
        ApiService.getUserBalance(widget.userId),
        ApiService.getSocialFund(),
        ApiService.getCurrentWinner(_currentTontine['id'] as int),
        ApiService.getMemberStatus(_currentTontine['id'] as int, widget.userId),
        ApiService.getTontinesCagnotte(_currentTontine['id'] as int),
        ApiService.getTontineSchedule(_currentTontine['id'] as int),
      ]);

      if (mounted) {
        setState(() {
          members       = results[0] as List<dynamic>;
          userBalance   = (results[1] as num).toDouble();
          socialFund    = (results[2] as num).toDouble();
          currentWinner = results[3] as Map<String, dynamic>?;
          memberStatus  = results[4] as Map<String, dynamic>;
          cagnotte      = results[5] as Map<String, dynamic>;
          schedule      = results[6] as List<dynamic>;
          isLoading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LOGIQUE DE PAIEMENT ---
  Future<void> _handlePayment({bool isLate = false}) async {
    double baseAmount = double.tryParse(_currentTontine['amount_to_pay']?.toString() ?? "0") ?? 0.0;
    double totalToPay = isLate ? (baseAmount + latePenalty) : baseAmount;

    if (userBalance < totalToPay) {
      _showSnackBar("Solde insuffisant ($userBalance F).", Colors.red);
      return;
    }

    setState(() => isProcessingPayment = true);
    try {
      // ✅ Correction de l'erreur "undefined_method" en attendant la MAJ de ApiService
      await ApiService.processTontinePayment(
        userId: widget.userId, 
        tontineId: _currentTontine['id'] as int, 
        amount: totalToPay,
        isLate: isLate // On signale si c'est un retard pour le fond social
      );
      
      _showSnackBar(isLate ? "Cotisation + Amende payées !" : "Cotisation validée !", Colors.green);
      _refreshData();
    } catch (e) {
      _showSnackBar("Erreur : $e", Colors.red);
    } finally {
      if (mounted) setState(() => isProcessingPayment = false);
    }
  }

  // --- LOGIQUE AJOUT MEMBRE ---
  Future<void> _addMemberFromContacts() async {
    _showSnackBar("Bientôt : Ajout depuis le répertoire.", Colors.blue);
    // --- Implementation future ---
    // try {
    //   if (await Permission.contacts.request().isGranted) {
    //     final Contact? contact = await ContactsService.openDeviceContactPicker();
    //     if (contact != null && contact.phones!.isNotEmpty) {
    //       // Logique pour inviter/ajouter le contact à la tontine via API
    //       _showSnackBar("Invitation envoyée à ${contact.displayName}", Colors.green);
    //     }
    //   } else {
    //     _showSnackBar("Permission aux contacts refusée.", Colors.red);
    //   }
    // } catch (e) {
    //   _showSnackBar("Erreur: $e", Colors.red);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(_currentTontine['name'] ?? "Détails", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (widget.userId == (_currentTontine['admin_id'] as int))
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: "Modifier la tontine",
              onPressed: () async {
                final updatedTontine = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => EditTontineScreen(tontine: _currentTontine)),
                );

                if (updatedTontine != null && updatedTontine is Map<String, dynamic>) {
                  setState(() {
                    _currentTontine = updatedTontine;
                  });
                  _refreshData();
                }
              },
            ),
          IconButton(icon: const Icon(Icons.call), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CallScreen(
            callID: _currentTontine['id'].toString(),
            userID: widget.userId.toString(),
            userName: widget.userData['fullname'] ?? 'Utilisateur',
          )))),
          IconButton(icon: const Icon(Icons.map_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RadarMapScreen(
            tontineId: _currentTontine['id'] as int,
            tontineName: _currentTontine['name'] ?? 'Tontine',
            userId: widget.userId,
          )))),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: "Détails"),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: "Chat"),
            Tab(icon: Icon(Icons.people_outline), text: "Social"),
            Tab(icon: Icon(Icons.folder_outlined), text: "Docs"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Onglet Détails
          RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildWinnerBanner(),
                  _buildMainCard(),
                  _buildCagnotteCard(),
                  _buildPaymentActions(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  _buildScheduleSection(),
                  const SizedBox(height: 20),
                  _buildMembersSection(),
                ],
              ),
            ),
          ),
          // 2. Onglet Chat
          ChatScreen(
            tontineId: _currentTontine['id'],
            userId: widget.userId,
            userData: widget.userData,
          ),
          // 3. Onglet Social
          SocialScreen(tontineId: _currentTontine['id'], userId: widget.userId),
          // 4. Onglet Documents
          _buildDocumentsTab(),
        ],
      ),
    );
  }

  // --- WIDGET : DOCUMENTS ---
  Widget _buildDocumentsTab() {
    final docs = [
      {'name': 'Règlement intérieur', 'icon': Icons.description_rounded, 'type': 'PDF'},
      {'name': 'Liste des membres', 'icon': Icons.people_rounded, 'type': 'PDF'},
      {'name': 'Historique des paiements', 'icon': Icons.receipt_long_rounded, 'type': 'PDF'},
      {'name': 'Calendrier des tours', 'icon': Icons.calendar_month_rounded, 'type': 'PDF'},
      {'name': 'Attestation de participation', 'icon': Icons.verified_user_rounded, 'type': 'PDF'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Documents", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text("Télécharge les documents liés à cette tontine", style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 20),
        ...docs.map((doc) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: darkCardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(doc['icon'] as IconData, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              Text("${doc['type']} · Disponible", style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ])),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Génération de ${doc['name']}..."),
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        )),
      ]),
    );
  }

  // --- WIDGET : LE BÉNÉFICIAIRE DU TOUR ---
  Widget _buildWinnerBanner() {
    if (currentWinner == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, const Color(0xFFB8860B)]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.stars, color: Colors.orange)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("BÉNÉFICIAIRE DU TOUR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(currentWinner!['fullname'] ?? "En attente...", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text("Mode de retrait : ${currentWinner!['payout_method'] ?? 'Compte G-Caisse'}", 
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    final hasCaisse = _currentTontine['has_caisse_fund'] == true;
    final caissePaid = double.tryParse(memberStatus['caisse_fund_paid']?.toString() ?? '0') ?? 0;
    final caisseRequired = double.tryParse(memberStatus['caisse_fund_required']?.toString() ?? '0') ?? 0;
    final isRegular = memberStatus['is_regular'] == true;
    final deadlineTime = _currentTontine['deadline_time'] ?? '23:59';
    final deadlineDay = _currentTontine['deadline_day'] ?? 28;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: darkCardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _statTile("COTISATION", "${_currentTontine['amount_to_pay']} F"),
            _statTile("FOND SOCIAL", "$socialFund F"),
            _statTile("MEMBRES", "${members.length}"),
          ]),
          const Divider(color: Colors.white10, height: 24),

          // Heure limite
          Row(children: [
            const Icon(Icons.access_time, color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text("Limite : le $deadlineDay du mois à $deadlineTime",
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
          const SizedBox(height: 8),

          // Statut membre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isRegular ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(isRegular ? Icons.verified : Icons.warning_amber_rounded,
                color: isRegular ? Colors.greenAccent : Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Text(isRegular ? "Membre régulier — Prêts autorisés" : "Membre irrégulier — Prêts bloqués",
                style: TextStyle(
                  color: isRegular ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),

          // Fond de caisse
          if (hasCaisse) ...[
            const SizedBox(height: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("FOND DE CAISSE", style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                Text("${caissePaid.toStringAsFixed(0)} / ${caisseRequired.toStringAsFixed(0)} F",
                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: caisseRequired > 0 ? (caissePaid / caisseRequired).clamp(0.0, 1.0) : 0,
                  backgroundColor: Colors.white10,
                  color: caissePaid >= caisseRequired ? Colors.greenAccent : primaryColor,
                  minHeight: 5,
                ),
              ),
            ]),
          ],

          const Divider(color: Colors.white10, height: 24),
          Text("GAGNOTTE FINALE", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text(
            "${(double.tryParse(_currentTontine['amount_to_pay']?.toString() ?? '0') ?? 0 * members.length).toStringAsFixed(0)} FCFA",
            style: TextStyle(color: primaryColor, fontSize: 26, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPaymentActions() {
    final hasCaisse = _currentTontine['has_caisse_fund'] == true;
    final caissePaid = double.tryParse(memberStatus['caisse_fund_paid']?.toString() ?? '0') ?? 0;
    final caisseRequired = double.tryParse(memberStatus['caisse_fund_required']?.toString() ?? '0') ?? 0;
    final caisseComplete = caissePaid >= caisseRequired;
    final isAdmin = widget.userId == (_currentTontine['admin_id'] as int? ?? -1);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Payer cotisation
        SizedBox(
          width: double.infinity, height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: isProcessingPayment ? null
                : () => _confirmAction("Payer ma cotisation ?", () => _handlePayment()),
            child: const Text("PAYER MA COTISATION",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 10),

        // Payer en retard
        TextButton.icon(
          onPressed: () => _confirmAction(
            "Payer avec amende de retard ($latePenalty F) ?",
            () => _handlePayment(isLate: true)),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
          label: const Text("Payer en retard (+ Amende 500 F)",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),

        // Fond de caisse
        if (hasCaisse && !caisseComplete) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _showCaisseFundDialog(),
              icon: const Icon(Icons.account_balance, size: 18),
              label: Text(
                "Payer fond de caisse (${(caisseRequired - caissePaid).toStringAsFixed(0)} F restants)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],

        // Bouton auto-débit (admin seulement)
        if (isAdmin) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _confirmAction(
                "Déclencher le débit automatique pour tous les membres en retard ?",
                _triggerAutoDebit),
              icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
              label: const Text("DÉBIT AUTOMATIQUE (ADMIN)",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ]),
    );
  }

  void _showCaisseFundDialog() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Payer le Fond de Caisse",
            style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Montant (FCFA)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () async {
                final amount = double.tryParse(ctrl.text) ?? 0;
                if (amount <= 0) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.payCaisseFund(
                    userId: widget.userId,
                    tontineId: _currentTontine['id'] as int,
                    amount: amount);
                  _showSnackBar("Fond de caisse payé !", Colors.green);
                  _refreshData();
                } catch (e) {
                  _showSnackBar(e.toString().replaceAll('Exception:', ''), Colors.red);
                }
              },
              child: const Text("CONFIRMER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Future<void> _triggerAutoDebit() async {
    try {
      final result = await ApiService.autoDebit(_currentTontine['id'] as int);
      final debited = (result['debited'] as List?)?.join(', ') ?? 'Aucun';
      final failed  = (result['failed']  as List?)?.join(', ') ?? 'Aucun';
      if (mounted) {
        showDialog(context: context, builder: (c) => AlertDialog(
          title: const Text("Résultat du débit automatique"),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Débités (${result['total_debited']}) : $debited",
              style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 8),
            Text("Échecs (${result['total_failed']}) : $failed",
              style: const TextStyle(color: Colors.red)),
          ]),
          actions: [TextButton(onPressed: () { Navigator.pop(c); _refreshData(); }, child: const Text("OK"))],
        ));
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception:', ''), Colors.red);
    }
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionIcon(Icons.gavel, "Enchères", Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AuctionScreen(tontineId: _currentTontine['id'])));
        }),
        _actionIcon(Icons.account_balance_wallet, "Retrait", Colors.blue, _showPayoutMethodDialog),
        _actionIcon(Icons.help_outline, "Règles", Colors.grey, () {}),
      ],
    );
  }

  void _showPayoutMethodDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("MODE DE RÉCEPTION DES FONDS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            _payoutOption("Portefeuille G-Caisse", Icons.account_balance_wallet, Colors.blue),
            _payoutOption("Orange Money", Icons.phone_android, Colors.orange),
            _payoutOption("MTN MoMo", Icons.vibration, Colors.yellow.shade700),
          ],
        ),
      ),
    );
  }

  Widget _payoutOption(String title, IconData icon, Color color, {bool selected = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Icon(selected ? Icons.check_circle : Icons.check_circle_outline, color: selected ? color : Colors.grey),
      onTap: onTap ?? () {
        Navigator.pop(context);
        _showSnackBar("Mode de retrait mis à jour : $title", Colors.green);
      },
    );
  }

  // ── CAGNOTTE DU CYCLE ──────────────────────────────────
  Widget _buildCagnotteCard() {
    final total = double.tryParse(cagnotte['total_collected']?.toString() ?? '0') ?? 0;
    final payers = int.tryParse(cagnotte['payers_count']?.toString() ?? '0') ?? 0;
    final totalMembers = int.tryParse(cagnotte['total_members']?.toString() ?? '0') ?? 0;
    final amountPer = double.tryParse(cagnotte['amount_per_member']?.toString() ?? '0') ?? 0;
    final expected = amountPer * totalMembers;
    final progress = expected > 0 ? (total / expected).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, const Color(0xFFB8860B)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("CAGNOTTE DU MOIS", style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
            Text("$payers / $totalMembers payé(s)", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Text("${total.toStringAsFixed(0)} FCFA",
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("sur ${expected.toStringAsFixed(0)} FCFA attendus",
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Bouton envoyer cagnotte (admin seulement)
          if (_isAdmin && total > 0 && currentWinner != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showSendCagnotteDialog(total),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  "ENVOYER À ${currentWinner!['fullname']?.toString().split(' ').first ?? 'BÉNÉFICIAIRE'}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void _showSendCagnotteDialog(double total) {
    String method = 'wallet';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Envoyer la Cagnotte", style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Bénéficiaire : ${currentWinner!['fullname']}",
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
            Text("Montant : ${total.toStringAsFixed(0)} FCFA",
              style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            const Text("Mode de paiement", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _payoutOption("Portefeuille G-Caisse", Icons.account_balance_wallet, Colors.blue,
              selected: method == 'wallet', onTap: () => setS(() => method = 'wallet')),
            _payoutOption("Orange Money", Icons.phone_android, Colors.orange,
              selected: method == 'orange', onTap: () => setS(() => method = 'orange')),
            _payoutOption("MTN MoMo", Icons.vibration, Colors.yellow.shade700,
              selected: method == 'mtn', onTap: () => setS(() => method = 'mtn')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiService.sendCagnotte(
                      tontineId: _currentTontine['id'] as int,
                      beneficiaryId: currentWinner!['id'] as int,
                      payoutMethod: method,
                    );
                    _showSnackBar("Cagnotte envoyée à ${currentWinner!['fullname']} !", Colors.green);
                    _refreshData();
                  } catch (e) {
                    _showSnackBar(e.toString().replaceAll('Exception:', ''), Colors.red);
                  }
                },
                child: const Text("CONFIRMER L'ENVOI",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── CLASSEMENT DES MEMBRES ──────────────────────────────
  Widget _buildScheduleSection() {
    final months = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("CLASSEMENT DES TOURS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Row(children: [
              if (_isAdmin) ...[
                // Bouton rappel WhatsApp
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 20),
                  tooltip: "Envoyer rappels WhatsApp",
                  onPressed: _sendWhatsAppReminders,
                ),
                // Générer classement
                if (schedule.isEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await ApiService.generateSchedule(_currentTontine['id'] as int);
                        _refreshData();
                      } catch (e) {
                        _showSnackBar(e.toString().replaceAll('Exception:', ''), Colors.red);
                      }
                    },
                    icon: const Icon(Icons.shuffle, size: 16),
                    label: const Text("Générer", style: TextStyle(fontSize: 12)),
                  ),
              ],
            ]),
          ]),
          const SizedBox(height: 12),
          if (schedule.isEmpty)
            Center(child: Text(
              _isAdmin ? "Appuyez sur 'Générer' pour créer le classement" : "Classement non encore défini",
              style: const TextStyle(color: Colors.grey, fontSize: 13)))
          else
            ...schedule.map((s) {
              final hasReceived = s['has_received'] == true;
              final isCurrentWinner = currentWinner != null && s['user_id'] == currentWinner!['id'];
              final monthName = s['scheduled_month'] != null
                  ? months[(s['scheduled_month'] as int) - 1] : '?';
              final year = s['scheduled_year']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: hasReceived
                      ? Colors.green.withValues(alpha: 0.06)
                      : isCurrentWinner
                          ? primaryColor.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasReceived
                        ? Colors.green.withValues(alpha: 0.3)
                        : isCurrentWinner
                            ? primaryColor.withValues(alpha: 0.4)
                            : Colors.transparent,
                  ),
                ),
                child: Row(children: [
                  // Numéro de cycle
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: hasReceived ? Colors.green : isCurrentWinner ? primaryColor : Colors.grey.shade300,
                      shape: BoxShape.circle),
                    child: Center(child: hasReceived
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text("${s['cycle_number']}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['fullname'] ?? 'Membre',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasReceived ? Colors.green.shade700 : Colors.black87,
                        decoration: hasReceived ? TextDecoration.lineThrough : null)),
                    Text("$monthName $year",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ])),
                  if (isCurrentWinner && !hasReceived)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text("CE MOIS", style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (hasReceived)
                    Text("${double.tryParse(s['payout_amount']?.toString() ?? '0')?.toStringAsFixed(0)} F",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppReminders() async {
    try {
      final result = await ApiService.getWhatsAppReminders(_currentTontine['id'] as int);
      final reminders = result['reminders'] as List? ?? [];

      if (reminders.isEmpty) {
        _showSnackBar("Tous les membres ont déjà payé ce mois !", Colors.green);
        return;
      }

      // Afficher la liste et permettre d'ouvrir WhatsApp pour chacun
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, ctrl) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Rappels WhatsApp (${reminders.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () async {
                    // Envoyer à tous
                    for (final r in reminders) {
                      final uri = Uri.parse(r['whatsapp_url']);
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      await Future.delayed(const Duration(milliseconds: 500));
                    }
                  },
                  child: const Text("Envoyer à tous", style: TextStyle(color: Color(0xFF25D366))),
                ),
              ]),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: reminders.length,
                  itemBuilder: (_, i) {
                    final r = reminders[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF25D366),
                        child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 16)),
                      title: Text(r['fullname'] ?? ''),
                      subtitle: Text(r['phone'] ?? ''),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () async {
                          final uri = Uri.parse(r['whatsapp_url']);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text("Envoyer", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      );
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception:', ''), Colors.red);
    }
  }

  Widget _buildMembersSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MEMBRES DU GROUPE (${members.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(onPressed: _addMemberFromContacts, icon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFFFF7900)), tooltip: "Ajouter un membre"),
            ],
          ),
          const SizedBox(height: 15),
          if (isLoading) const Center(child: CircularProgressIndicator())
          else ...members.map((m) => ListTile(
            leading: CircleAvatar(backgroundColor: primaryColor.withOpacity(0.1), child: Text(m['fullname']?[0] ?? "")),
            title: Text(m['fullname'] ?? "Anonyme"),
            subtitle: Text(m['phone'] ?? ""),
            trailing: const Icon(Icons.chevron_right, size: 16),
          )),
        ],
      ),
    );
  }

  Widget _statTile(String t, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _actionIcon(IconData i, String l, Color c, VoidCallback t) {
    return InkWell(
      onTap: t,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, color: c)),
          const SizedBox(height: 5),
          Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmAction(String m, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text(m),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("NON")),
          ElevatedButton(onPressed: () { Navigator.pop(c); onConfirm(); }, child: const Text("OUI")),
        ],
      ),
    );
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));
}

class SocialScreen extends StatefulWidget {
  final int tontineId;
  final int userId;
  const SocialScreen({super.key, required this.tontineId, required this.userId});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color dark = const Color(0xFF1A1A2E);

  List<dynamic> events = [];
  bool isLoading = true;

  // Types d'événements avec icône, couleur et label
  static const List<Map<String, dynamic>> eventTypes = [
    {'key': 'death',     'label': 'Deuil',       'icon': Icons.sentiment_very_dissatisfied, 'color': Color(0xFFEF5350)},
    {'key': 'birth',     'label': 'Naissance',   'icon': Icons.child_friendly,              'color': Color(0xFFAB47BC)},
    {'key': 'wedding',   'label': 'Mariage',     'icon': Icons.favorite,                    'color': Color(0xFFEC407A)},
    {'key': 'illness',   'label': 'Maladie',     'icon': Icons.local_hospital,              'color': Color(0xFFFF7043)},
    {'key': 'school',    'label': 'Scolarité',   'icon': Icons.school,                      'color': Color(0xFF42A5F5)},
    {'key': 'other',     'label': 'Autre',       'icon': Icons.volunteer_activism,          'color': Color(0xFF66BB6A)},
  ];

  static Map<String, dynamic> _typeInfo(String key) =>
      eventTypes.firstWhere((e) => e['key'] == key, orElse: () => eventTypes.last);

  String _fmt(double v) => v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getTontineSocialEvents(widget.tontineId);
      if (mounted) setState(() { events = data; isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        onPressed: _showCreateEventSheet,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("CRÉER UNE AIDE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: gold))
          : RefreshIndicator(
              onRefresh: _load,
              color: gold,
              child: events.isEmpty ? _buildEmpty() : _buildList(),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.volunteer_activism_outlined, size: 70, color: Colors.white12),
              const SizedBox(height: 16),
              const Text("Aucune aide en cours", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Créez une collecte pour soutenir un membre", style: TextStyle(color: Colors.white30, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: events.length,
      itemBuilder: (_, i) => _buildCard(events[i]),
    );
  }

  Widget _buildCard(Map event) {
    final info = _typeInfo(event['event_type'] ?? 'other');
    final Color color = info['color'] as Color;
    final double target = double.tryParse(event['target_amount']?.toString() ?? '0') ?? 0;
    final double collected = double.tryParse(event['collected']?.toString() ?? '0') ?? 0;
    final double progress = target > 0 ? (collected / target).clamp(0.0, 1.0) : 0.0;
    final bool done = collected >= target && target > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête coloré
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(info['icon'] as IconData, color: color, size: 20),
                const SizedBox(width: 10),
                Text(info['label'] as String,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                const Spacer(),
                if (done)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text("OBJECTIF ATTEINT", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bénéficiaire
                if ((event['beneficiary_name'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Text(event['beneficiary_name'], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                // Description
                Text(event['description'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                // Montants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("COLLECTÉ", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                      Text("${_fmt(collected)} F", style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text("OBJECTIF", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                      Text("${_fmt(target)} F", style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
                const SizedBox(height: 10),
                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    color: done ? Colors.greenAccent : color,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text("${(progress * 100).toStringAsFixed(0)}% atteint",
                    style: const TextStyle(color: Colors.white30, fontSize: 11)),
                const SizedBox(height: 16),
                // Bouton don
                if (!done)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.15),
                        foregroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: color.withValues(alpha: 0.4))),
                        elevation: 0,
                      ),
                      onPressed: () => _showDonateSheet(event),
                      icon: const Icon(Icons.favorite_border, size: 18),
                      label: const Text("CONTRIBUER", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SHEET : CRÉER UN ÉVÉNEMENT ──────────────────────────
  void _showCreateEventSheet() {
    final descCtrl = TextEditingController();
    final benefCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedType = 'death';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text("Nouvelle Aide Solidaire", style: TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Type d'événement
                const Text("Type d'événement", style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: eventTypes.map((t) {
                    final sel = selectedType == t['key'];
                    final c = t['color'] as Color;
                    return GestureDetector(
                      onTap: () => setS(() => selectedType = t['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? c.withValues(alpha: 0.2) : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? c : Colors.transparent),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t['icon'] as IconData, color: sel ? c : Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Text(t['label'] as String, style: TextStyle(color: sel ? c : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Bénéficiaire
                _field(benefCtrl, "Nom du bénéficiaire", Icons.person_outline, "Ex: Famille Mbarga"),
                const SizedBox(height: 12),

                // Description
                _field(descCtrl, "Description de la situation", Icons.edit_note, "Ex: Décès du père de Jean...", maxLines: 2),
                const SizedBox(height: 12),

                // Montant cible
                _field(amountCtrl, "Montant cible (FCFA)", Icons.monetization_on_outlined, "Ex: 50000", isNumber: true),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isLoading ? null : () async {
                      if (descCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                      setS(() => isLoading = true);
                      try {
                        await ApiService.createSocialEvent(
                          tontineId: widget.tontineId,
                          createdBy: widget.userId,
                          eventType: selectedType,
                          description: descCtrl.text.trim(),
                          targetAmount: double.tryParse(amountCtrl.text) ?? 0,
                          beneficiaryName: benefCtrl.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Aide créée avec succès"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                          );
                        }
                      } catch (e) {
                        setS(() => isLoading = false);
                        if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception:', '')), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text("LANCER LA COLLECTE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SHEET : FAIRE UN DON ────────────────────────────────
  void _showDonateSheet(Map event) {
    final amountCtrl = TextEditingController();
    bool isLoading = false;
    final info = _typeInfo(event['event_type'] ?? 'other');
    final Color color = info['color'] as Color;

    // Montants rapides suggérés
    const quickAmounts = [500, 1000, 2000, 5000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Icon(info['icon'] as IconData, color: color, size: 32),
              const SizedBox(height: 8),
              Text("Contribuer à cette aide", style: TextStyle(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(event['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 20),

              // Montants rapides
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: quickAmounts.map((a) => GestureDetector(
                  onTap: () => amountCtrl.text = a.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
                    child: Text("$a F", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),

              // Champ montant
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Montant (FCFA)",
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color.withValues(alpha: 0.4))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color, width: 2)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isLoading ? null : () async {
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (amount <= 0) return;
                    setS(() => isLoading = true);
                    try {
                      await ApiService.makeDonation(int.parse(event['id'].toString()), amount, widget.userId);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Don enregistré, merci ❤️"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (e) {
                      setS(() => isLoading = false);
                      if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception:', '')), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  child: isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("CONFIRMER LE DON", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: gold.withValues(alpha: 0.5))),
      ),
    );
  }
}