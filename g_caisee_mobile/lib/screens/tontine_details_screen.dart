import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/api_service.dart';
import 'chat_screen.dart'; 
import 'rules_screen.dart'; 

class TontineDetailsScreen extends StatefulWidget {
  final Map tontine; 
  final int userId;

  const TontineDetailsScreen({super.key, required this.tontine, required this.userId});

  @override
  State<TontineDetailsScreen> createState() => _TontineDetailsScreenState();
}

class _TontineDetailsScreenState extends State<TontineDetailsScreen> {
  // Couleurs "Mode Jour"
  final Color primaryColor = const Color(0xFFD4AF37); // Doré
  final Color backgroundColor = const Color(0xFFF5F6F8); // Gris très clair
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF1A1A1A);
  final Color fieldColor = const Color(0xFFF5F6F8); 

  List<dynamic> members = [];
  bool isLoading = true;
  double userBalance = 0.0;
  
  double fundBalance = 0.0; 
  double socialBalance = 0.0; 

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
      final balance = await ApiService.getUserBalance(widget.userId); 
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
          }
        }
      } catch (e) { debugPrint("Erreur contacts: $e"); }
    }
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Quitter la tontine ?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          "Êtes-vous sûr de vouloir quitter ce groupe ? Vos cotisations actuelles seront traitées selon le règlement.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async { 
              try {
                await ApiService.leaveTontine(widget.tontine['id'], widget.userId);
                
                if (mounted) {
                  Navigator.pop(context); 
                  Navigator.pop(context, true); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vous avez quitté le groupe."), backgroundColor: Colors.orange)
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la sortie."), backgroundColor: Colors.red));
                }
              }
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Payer ma cotisation", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Text(
          "Montant à payer : ${amountToPay.toStringAsFixed(0)} FCFA\n\nVotre solde G-Caisse : ${userBalance.toStringAsFixed(0)} FCFA",
          style: TextStyle(color: textColor, height: 1.5, fontSize: 15), 
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context); 
              if (userBalance >= amountToPay) {
                setState(() => userBalance -= amountToPay);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Cotisation validée !"), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Solde insuffisant. Veuillez recharger."), backgroundColor: Colors.red));
              }
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRetardDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Pénalité de retard", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("L'argent payé pour les retards sera directement reversé dans le Fond de la cotisation.", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Montant de la pénalité (FCFA)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              double amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                setState(() => fundBalance += amount); 
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Pénalité payée. Le fond a augmenté de $amount FCFA"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Payer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFondDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Fond de la cotisation", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  const Text("Montant disponible", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 5),
                  Text("${fundBalance.toStringAsFixed(0)} FCFA", style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text("Ce fond accumule les pénalités et les bénéfices. Il sert à accorder des prêts aux membres du groupe.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demande de prêt envoyée au bureau."), backgroundColor: Colors.blue));
            },
            child: const Text("Demander un prêt", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSocialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Caisse Sociale", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  const Text("Caisse de solidarité", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 5),
                  Text("${socialBalance.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.pink, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text("Utilisée pour les événements (mariages, deuils, naissances) des membres de cette tontine.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assistance sociale demandée."), backgroundColor: Colors.pink));
            },
            child: const Text("Demander aide", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.tontine['name'] ?? "Détails", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: textColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RulesScreen())),
          )
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366), 
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (c) => ChatScreen(tontineId: widget.tontine['id'], tontineName: widget.tontine['name'] ?? "Discussion")
        )),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),

      body: Column(
        children: [
          _buildInfoCard(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity, 
              height: 55, 
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                onPressed: _payerCotisation,
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text("COTISER MAINTENANT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(Icons.favorite, "Social", Colors.pink, _showSocialDialog),
                _actionButton(Icons.timer_off, "Retards", Colors.orange, _showRetardDialog),
                _actionButton(Icons.account_balance, "Fond", Colors.blue, _showFondDialog),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("MEMBRES DU GROUPE", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        onPressed: _pickContact, 
                        icon: Icon(Icons.person_add, color: primaryColor, size: 18),
                        label: Text("Inviter", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: isLoading
                      ? Center(child: CircularProgressIndicator(color: primaryColor))
                      : ListView(
                          children: [
                            ...members.map((member) => _buildMemberItem(member)).toList(),
                            const SizedBox(height: 30),
                            TextButton.icon(
                              onPressed: _showLeaveConfirmation,
                              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                              label: const Text("QUITTER LA TONTINE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 80), 
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

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMemberItem(dynamic member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.2),
          child: Text(member['fullname']?[0].toUpperCase() ?? "?", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(member['fullname'] ?? "Inconnu", style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(member['phone'] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20), 
      ),
    );
  }

  Widget _buildInfoCard() {
    String amountDisplay = widget.tontine['amount_to_pay']?.toString() ?? "0";
    double amountPerMember = double.tryParse(amountDisplay) ?? 0.0;
    
    double cagnotte = amountPerMember * members.length; 

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, const Color(0xFF8B6914)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))], 
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
          const Divider(color: Colors.white30, height: 35), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cagnotte du tour :", style: TextStyle(color: Colors.white, fontSize: 14)),
              Text("${cagnotte.toStringAsFixed(0)} FCFA", 
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Inviter un membre", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nom", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Téléphone", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Invitation envoyée !"), backgroundColor: Colors.green));
            },
            child: const Text("Inviter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}