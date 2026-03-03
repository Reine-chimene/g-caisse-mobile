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
      final balance = await ApiService.getUserBalance(1);
      if (mounted) setState(() => userBalance = balance);
    } catch (e) { debugPrint("Erreur solde: $e"); }
  }

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
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ce contact n'a pas de numéro enregistré."), backgroundColor: Colors.orange)
            );
          }
        }
      } catch (e) {
        debugPrint("Erreur lors de la sélection du contact: $e");
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission d'accéder aux contacts refusée."), backgroundColor: Colors.red)
      );
    }
  }

  void _payerCotisation() {
    double amountToPay = double.tryParse(widget.tontine['amount']?.toString() ?? widget.tontine['amount_to_pay']?.toString() ?? "0") ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGrey,
        title: Text("Payer ma cotisation", style: TextStyle(color: gold)),
        content: Text(
          "Montant : ${amountToPay.toStringAsFixed(0)} FCFA\nVotre solde G-Caisse : ${userBalance.toStringAsFixed(0)} FCFA",
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
                  const SnackBar(content: Text("❌ Solde insuffisant. Rechargez votre compte."), backgroundColor: Colors.red)
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
        title: Text(widget.tontine['name'] ?? "Détails Tontine", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Règlement intérieur",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const RulesScreen()));
            },
          )
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green, 
        onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ouverture du Chat...")));
        },
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
                label: const Text("COTISER MAINTENANT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("MEMBRES", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                TextButton.icon(
                  onPressed: _pickContact, 
                  icon: Icon(Icons.person_add, color: gold, size: 18),
                  label: Text("Ajouter", style: TextStyle(color: gold)),
                )
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: gold))
                : members.isEmpty
                    ? const Center(child: Text("Aucun membre pour l'instant", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: members.length,
                        itemBuilder: (context, i) {
                          final member = members[i];
                          bool hasPaid = i % 2 == 0; 

                          return Card(
                            color: cardGrey,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade800,
                                child: Text(member['fullname']?[0].toUpperCase() ?? "?", style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(member['fullname'] ?? "Inconnu", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(member['phone'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasPaid ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2), 
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: hasPaid ? Colors.green : Colors.red),
                                ),
                                child: Text(
                                  hasPaid ? "À JOUR" : "IMPAYÉ",
                                  style: TextStyle(color: hasPaid ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    String amountDisplay = widget.tontine['amount']?.toString() ?? widget.tontine['amount_to_pay']?.toString() ?? "0";

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gold, const Color(0xFF8B6914)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.2), blurRadius: 10)], 
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem("Montant/Pers", "$amountDisplay XAF"),
              Container(height: 30, width: 1, color: Colors.white30), 
              _infoItem("Fréquence", widget.tontine['frequency'] ?? "Mensuel"),
            ],
          ),
          const Divider(color: Colors.white24, height: 30), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cagnotte du tour :", style: TextStyle(color: Colors.white70)),
              Text("${(double.tryParse(amountDisplay)! * (members.isEmpty ? 1 : members.length)).toStringAsFixed(0)} XAF", 
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 5), 
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        title: Text("Inviter un contact", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Nom du membre",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
            const SizedBox(height: 10), 
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Numéro de téléphone",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Invitation envoyée à ${nameController.text.isNotEmpty ? nameController.text : phoneController.text} !"))
              );
            },
            child: const Text("Envoyer l'invitation", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}