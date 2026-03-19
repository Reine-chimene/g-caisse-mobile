import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auction_screen.dart';

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

class _TontineDetailsScreenState extends State<TontineDetailsScreen> {
  final Color primaryColor = const Color(0xFFD4AF37); 
  final Color darkCardColor = const Color(0xFF1A1A2E);

  List<dynamic> members = [];
  Map<String, dynamic>? currentWinner; // Pour stocker le bénéficiaire du tour
  bool isLoading = true;
  bool isProcessingPayment = false;
  
  // États pour les fonds
  double userBalance = 0.0;
  double socialFund = 0.0;
  double latePenalty = 500.0; // Exemple : 500 F de amende pour retard

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getTontineMembers(widget.tontine['id']),
        ApiService.getUserBalance(widget.userId),
        ApiService.getSocialFund(),
        ApiService.getCurrentWinner(widget.tontine['id']), // Nouvelle méthode API
      ]);

      if (mounted) {
        setState(() {
          members = results[0] as List<dynamic>; 
          userBalance = (results[1] as num).toDouble();
          socialFund = (results[2] as num).toDouble();
          currentWinner = results[3] as Map<String, dynamic>?;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LOGIQUE DE PAIEMENT ---
  Future<void> _handlePayment({bool isLate = false}) async {
    double baseAmount = double.tryParse(widget.tontine['amount_to_pay']?.toString() ?? "0") ?? 0.0;
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
        tontineId: widget.tontine['id'], 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("G-CAISSE DÉTAILS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildWinnerBanner(), // Le bénéficiaire du tour
              _buildMainCard(),
              _buildPaymentActions(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildMembersSection(),
            ],
          ),
        ),
      ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: darkCardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statTile("COTISATION", "${widget.tontine['amount_to_pay']} F"),
              _statTile("FOND SOCIAL", "$socialFund F"),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Text("GAGNOTTE FINALE", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text("${(double.parse(widget.tontine['amount_to_pay'].toString()) * members.length).toStringAsFixed(0)} FCFA",
            style: TextStyle(color: primaryColor, fontSize: 26, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPaymentActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: isProcessingPayment ? null : () => _confirmAction("Payer ma cotisation ?", () => _handlePayment()),
              child: const Text("PAYER MAINTENANT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _confirmAction("Payer avec amende de retard ($latePenalty F) ?", () => _handlePayment(isLate: true)),
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
            label: const Text("Payer en retard (+ Amende)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionIcon(Icons.gavel, "Enchères", Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AuctionScreen(tontineId: widget.tontine['id'])));
        }),
        _actionIcon(Icons.account_balance_wallet, "Retrait", Colors.blue, _showPayoutMethodDialog),
        _actionIcon(Icons. help_outline, "Règles", Colors.grey, () {}),
      ],
    );
  }

  // --- DIALOGUE : MODE DE RETRAIT ---
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

  Widget _payoutOption(String title, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.check_circle_outline),
      onTap: () {
        Navigator.pop(context);
        _showSnackBar("Mode de retrait mis à jour : $title", Colors.green);
      },
    );
  }

  Widget _buildMembersSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MEMBRES DU GROUPE (${members.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (isLoading) const Center(child: CircularProgressIndicator())
          else ...members.map((m) => ListTile(
            leading: CircleAvatar(backgroundColor: primaryColor.withValues(alpha: 0.1), child: Text(m['fullname']?[0] ?? "")),
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
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(i, color: c)),
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