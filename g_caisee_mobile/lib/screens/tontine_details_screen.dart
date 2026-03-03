import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/api_service.dart';
import 'chat_screen.dart'; 
import 'rules_screen.dart'; 

class TontineDetailsScreen extends StatefulWidget {
  final Map tontine; 
  const TontineDetailsScreen({super.key, required this.tontine});

  @override
  State<TontineDetailsScreen> createState() => _TontineDetailsScreenState();
}

class _TontineDetailsScreenState extends State<TontineDetailsScreen> {
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);
  List<dynamic> members = [];
  bool isLoading = true;
  double userBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _fetchBalance();
  }

  Future<void> _fetchMembers() async {
    try {
      final data = await ApiService.getTontineMembers(widget.tontine['id']);
      if (mounted) setState(() { members = data; isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchBalance() async {
    try {
      final balance = await ApiService.getUserBalance(1); // ID 1 pour test
      if (mounted) setState(() => userBalance = balance);
    } catch (e) { debugPrint("Erreur solde: $e"); }
  }

  // --- CORRECTION : AJOUT DE LA FONCTION _pickContact MANQUANTE ---
  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      try {
        Contact? contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          Contact? fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null && fullContact.phones.isNotEmpty) {
            String phoneNumber = fullContact.phones.first.number;
            String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
            if (!mounted) return;
            _showAddMemberDialog(context, initialPhone: cleanNumber, initialName: fullContact.displayName);
          }
        }
      } catch (e) { debugPrint("Erreur contacts: $e"); }
    }
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Quitter la tontine ?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          "Êtes-vous sûr de vouloir quitter ce groupe ? Vos cotisations actuelles seront traitées selon le règlement.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Vous avez quitté le groupe."), backgroundColor: Colors.orange)
              );
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _payerCotisation() {
    double amountToPay = double.tryParse(widget.tontine['amount_to_pay']?.toString() ?? "0") ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGrey,
        title: Text("Payer ma cotisation", style: TextStyle(color: gold)),
        content: Text(
          "Montant : ${amountToPay.toStringAsFixed(0)} FCFA\nVotre solde : ${userBalance.toStringAsFixed(0)} FCFA",
          style: const TextStyle(color: Colors.white, height: 1.5), 
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () async {
              Navigator.pop(context); 
              if (userBalance >= amountToPay) {
                setState(() => userBalance -= amountToPay);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Cotisation validée !"), backgroundColor: Colors.green)
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Solde insuffisant."), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.tontine['name'] ?? "Détails", style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RulesScreen())),
          )
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green, 
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (c) => ChatScreen(
            tontineId: widget.tontine['id'],
            tontineName: widget.tontine['name'] ?? "Discussion", // CORRECTION : Argument manquant ajouté
          )
        )),
        child: const Icon(Icons.chat, color: Colors.white),
      ),

      body: Column(
        children: [
          _buildInfoCard(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: _payerCotisation,
                icon: const Icon(Icons.payment, color: Colors.black),
                label: const Text("COTISER MAINTENANT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MEMBRES DU GROUPE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      TextButton.icon(
                        onPressed: _pickContact, 
                        icon: Icon(Icons.person_add, color: gold, size: 18),
                        label: Text("Inviter", style: TextStyle(color: gold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: isLoading
                      ? Center(child: CircularProgressIndicator(color: gold))
                      : ListView(
                          children: [
                            ...members.map((member) => _buildMemberItem(member)).toList(),
                            const SizedBox(height: 40),
                            TextButton.icon(
                              onPressed: _showLeaveConfirmation,
                              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                              label: const Text("QUITTER LA TONTINE", 
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                            const SizedBox(height: 40),
                          ],
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

  Widget _buildMemberItem(dynamic member) {
    return Card(
      color: cardGrey,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: gold.withValues(alpha: 0.1),
          child: Text(member['fullname']?[0].toUpperCase() ?? "?", style: TextStyle(color: gold)),
        ),
        title: Text(member['fullname'] ?? "Inconnu", style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(member['phone'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 11)),
        trailing: Icon(Icons.check_circle, color: Colors.green.withValues(alpha: 0.5), size: 18),
      ),
    );
  }

  Widget _buildInfoCard() {
    String amountDisplay = widget.tontine['amount_to_pay']?.toString() ?? "0";
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gold, const Color(0xFF8B6914)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.2), blurRadius: 15)], 
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem("Cotisation", "$amountDisplay F"),
              _infoItem("Fréquence", widget.tontine['frequency'] ?? "Mensuel"),
              _infoItem("Membres", "${members.length}"),
            ],
          ),
          const Divider(color: Colors.white24, height: 35), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cagnotte estimée :", style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text("${(double.tryParse(amountDisplay)! * (members.isEmpty ? 1 : members.length)).toStringAsFixed(0)} FCFA", 
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 5), 
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  void _showAddMemberDialog(BuildContext context, {String? initialPhone, String? initialName}) {
    final phoneController = TextEditingController(text: initialPhone);
    final nameController = TextEditingController(text: initialName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGrey,
        title: Text("Inviter un membre", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Nom")),
            TextField(controller: phoneController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Téléphone")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invitation envoyée !")));
            },
            child: const Text("Inviter", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}