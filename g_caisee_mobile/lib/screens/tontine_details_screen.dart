import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/api_service.dart';
import 'chat_screen.dart'; 

class TontineDetailsScreen extends StatefulWidget {
  final Map tontine; 
  final int userId;
  final Map<String, dynamic> userData; // RÉEL : Données nécessaires pour identifier l'auteur dans le chat

  const TontineDetailsScreen({
    super.key, 
    required this.tontine, 
    required this.userId, 
    required this.userData
  });

  @override
  State<TontineDetailsScreen> createState() => _TontineDetailsScreenState();
}

class _TontineDetailsScreenState extends State<TontineDetailsScreen> {
  final Color primaryColor = const Color(0xFFD4AF37);
  final Color backgroundColor = const Color(0xFFF5F6F8);
  final Color textColor = const Color(0xFF1A1A1A);

  List<dynamic> members = [];
  bool isLoading = true;
  double userBalance = 0.0;
  
  double fundBalance = 0.0; 
  double socialBalance = 0.0; 

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final membersData = await ApiService.getTontineMembers(widget.tontine['id']);
      final balance = await ApiService.getUserBalance(widget.userId);
      final sFund = await ApiService.getSocialFund(); 
      
      if (mounted) {
        setState(() {
          members = membersData;
          userBalance = balance;
          socialBalance = sFund;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleCotisation() async {
    double amountToPay = double.tryParse(widget.tontine['amount_to_pay']?.toString() ?? "0") ?? 0.0;

    if (userBalance < amountToPay) {
      _showError("Solde insuffisant. Rechargez votre compte.");
      return;
    }

    try {
      await ApiService.depositMoney(widget.userId, amountToPay); 
      _showSuccess("Cotisation de ${amountToPay.toStringAsFixed(0)} F validée !");
      _refreshData(); 
    } catch (e) {
      _showError("Erreur lors du paiement");
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _showSuccess(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.tontine['name'] ?? "Détails", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (c) => ChatScreen(
            tontineId: widget.tontine['id'], 
            tontineName: widget.tontine['name'] ?? "Discussion",
            userData: widget.userData, // PASSAGE DES DONNÉES RÉELLES
          )
        )),
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text("DISCUSSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildInfoCard(),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, height: 55, 
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: () => _showCotisationConfirm(),
                    icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                    label: const Text("PAYER MA COTISATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              const SizedBox(height: 25),
              _buildQuickActions(),
              const SizedBox(height: 25),
              _buildMembersSection(),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionBtn(Icons.favorite, "Social", Colors.pink, _showSocialDialog),
        _actionBtn(Icons.gavel_rounded, "Enchères", Colors.orange, () {}),
        _actionBtn(Icons.account_balance, "Fond", Colors.blue, _showFondDialog),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MEMBRES (${members.length})", style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.grey)),
              TextButton.icon(
                onPressed: _pickContact, 
                icon: Icon(Icons.add, color: primaryColor),
                label: Text("Inviter", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 10),
          isLoading 
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, i) => _buildMemberTile(members[i]),
              ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(dynamic m) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: primaryColor.withOpacity(0.1),
        child: Text(m['fullname']?[0].toUpperCase() ?? "?", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ),
      title: Text(m['fullname'] ?? "Utilisateur", style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(m['phone'] ?? ""),
      trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
    );
  }

  Widget _buildInfoCard() {
    double amountPerMember = double.tryParse(widget.tontine['amount_to_pay']?.toString() ?? "0") ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoDetail("Cotisation", "${widget.tontine['amount_to_pay']} F"),
              _infoDetail("Fréquence", widget.tontine['frequency'] ?? "N/A"),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cagnotte Totale", style: TextStyle(color: Colors.white70)),
              Text("${(amountPerMember * members.length).toStringAsFixed(0)} FCFA", 
                  style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoDetail(String t, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  void _showCotisationConfirm() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirmer la cotisation"),
        content: Text("Le montant de ${widget.tontine['amount_to_pay']} F sera débité de votre solde G-Caisse."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(c);
              _handleCotisation();
            }, 
            child: const Text("Confirmer le paiement")
          )
        ],
      ),
    );
  }

  void _showSocialDialog() => _showComingSoon("Caisse Sociale");
  void _showFondDialog() => _showComingSoon("Fond de Groupe");
  
  void _showComingSoon(String title) {
    showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: Text(title), 
        content: const Text("Ce module nécessite une validation du bureau."), 
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))]
      )
    );
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
       Contact? contact = await FlutterContacts.openExternalPick();
       if (contact != null && contact.phones.isNotEmpty) {
          _showSuccess("Contact sélectionné : ${contact.displayName}");
       }
    }
  }
}