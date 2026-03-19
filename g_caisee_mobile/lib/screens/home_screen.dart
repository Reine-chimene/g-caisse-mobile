import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import '../services/pdf_receipt_service.dart';
import 'saving_screen.dart';
import 'loan_screen.dart';
import 'create_tontine_screen.dart';
import 'profile_screen.dart';
import 'om_momo_screen.dart';
import 'airtime_screen.dart';
import 'bill_payment_screen.dart';

// --- ÉCRAN : SAISIE CARTE BANCAIRE ---
class CardPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CardPaymentScreen({super.key, required this.userData});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _cardNumberCtrl = TextEditingController();
  final TextEditingController _expiryCtrl = TextEditingController();
  final TextEditingController _cvvCtrl = TextEditingController();

  void _processCardPayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final res = await ApiService.initiatePayment(
            widget.userData['phone'], double.parse(_amountCtrl.text));
        if (res['success'] == true) {
          await launchUrl(Uri.parse(res['payment_url']),
              mode: LaunchMode.externalApplication);
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Erreur de traitement")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Paiement par Carte"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Icon(Icons.credit_card, size: 80, color: Color(0xFFFF7900)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Montant (FCFA)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Entrez un montant" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _cardNumberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Numéro de Carte",
                    hintText: "XXXX XXXX XXXX XXXX",
                    border: OutlineInputBorder()),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16)
                ],
                validator: (v) => v!.length < 16 ? "Numéro invalide" : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "MM/AA", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Expire ?" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: "CVV", border: OutlineInputBorder()),
                      validator: (v) => v!.length < 3 ? "Invalide" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7900),
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: _processCardPayment,
                child: const Text("PAYER MAINTENANT",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
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
        title: const Text("Mon Historique",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getUserTransactions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7900)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune transaction trouvée"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final tx = snapshot.data![index];
              final isDepot = tx['type'] == 'deposit';
              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  onTap: () async {
                    try {
                      final fullData =
                          await ApiService.getTransactionReceipt(tx['id']);
                      await PdfReceiptService.generateAndPrintReceipt(fullData);
                    } catch (e) {
                      debugPrint("Erreur reçu: $e");
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor: isDepot
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                        isDepot
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isDepot ? Colors.green : Colors.red),
                  ),
                  title: Text("${tx['amount']} FCFA",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(tx['description'] ?? "Transaction",
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                  trailing: const Icon(Icons.picture_as_pdf,
                      color: Colors.blue, size: 20),
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
  final LocalAuthentication auth = LocalAuthentication();

  bool _isBalanceVisible = true;
  double totalBalance = 0.0;
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
      final tontines = await ApiService.getTontines(myId);
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

  Future<bool> _authenticate() async {
    try {
      
      return await auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour valider le retrait',
        
      );
    } catch (e) {
      debugPrint("Erreur auth: $e");
      return false;
    }
  }
  void _contactSupport() async {
    final url = Uri.parse("https://wa.me/237675577715");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showWithdrawDialog() {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Retrait de fonds"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Montant FCFA")),
            const SizedBox(height: 10),
            const Text("NB: Frais de service de 2% inclus.",
                style: TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("Annuler")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: blackColor),
              onPressed: () async {
                if (ctrl.text.isNotEmpty) {
                  bool authenticated = await _authenticate();
                  if (!authenticated) return;

                  String amountStr = ctrl.text;
                  if (!mounted) return;
                  Navigator.pop(c);

                  try {
                    await ApiService.transferMoney(widget.userData['id'],
                        widget.userData['phone'], double.parse(amountStr));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Retrait réussi !"),
                        backgroundColor: Colors.green));
                    _loadUserData();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text("Valider", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("G-CAISE",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (c) =>
                            ProfileScreen(userData: widget.userData)));
              }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _contactSupport,
        backgroundColor: const Color(0xFF25D366),
        child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
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
              _buildRecentTontines(),
              const SizedBox(height: 20),
              _buildServicesGrid(),
              const SizedBox(height: 100),
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
      decoration: BoxDecoration(
          color: blackColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Solde Principal",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              GestureDetector(
                onTap: () =>
                    setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(
                    _isBalanceVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                    size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isBalanceVisible
                  ? "${totalBalance.toStringAsFixed(0)} FCFA"
                  : "•••••• FCFA",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionIcon(
              Icons.add_to_photos, "Dépôt", () => _showDepositSelector()),
          _actionIcon(
              Icons.file_upload, "Retrait", () => _showWithdrawDialog()),
          _actionIcon(Icons.history, "Historique", () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) =>
                        HistoryScreen(userId: widget.userData['id'])));
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: orangeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: orangeColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRecentTontines() {
    if (isLoadingTontines) {
      return const Center(child: CircularProgressIndicator());
    }
    if (mesTontines.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("MES TONTINES",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 130,
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
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups, color: orangeColor, size: 28),
                    const Spacer(),
                    Text(t['name'] ?? 'Groupe',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1),
                    Text("${t['amount_to_pay']} FCFA",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SERVICES G-CAISE (HUB)",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1.1,
            children: [
              _coloredServiceItem(
                  Icons.phone_android,
                  "Recharge Crédit",
                  [Colors.orange.shade800, Colors.orange.shade400],
                  AirtimeScreen(userData: widget.userData)),
              _coloredServiceItem(
                  Icons.lightbulb,
                  "Facture ENEO",
                  [Colors.yellow.shade900, Colors.yellow.shade600],
                  BillPaymentScreen(userData: widget.userData)),
              _coloredServiceItem(
                  Icons.swap_horiz,
                  "OM ↔ MoMo",
                  [Colors.blueGrey.shade700, Colors.blueGrey.shade400],
                  OmMomoScreen(userData: widget.userData)),
              _coloredServiceItem(
                  Icons.savings,
                  "Mon Épargne",
                  [Colors.green.shade700, Colors.green.shade400],
                  SavingScreen(userData: widget.userData)),
              _coloredServiceItem(
                  Icons.handshake,
                  "Prêts Urgents",
                  [Colors.purple.shade700, Colors.purple.shade400],
                  LoanScreen(userData: widget.userData)),
              _coloredServiceItem(
                  Icons.add_business,
                  "Nouvelle Tontine",
                  [Colors.black, Colors.grey.shade800],
                  CreateTontineScreen(userId: widget.userData['id'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coloredServiceItem(
      IconData icon, String label, List<Color> gradientColors, Widget page) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showDepositSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mode de dépôt",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _logoBtn("Orange", 'assets/logo_orange.jpg',
                    () => _openPaymentInput("Orange")),
                _logoBtn("MTN", 'assets/logo_mtn.jpg',
                    () => _openPaymentInput("MTN")),
                _logoBtn("Carte", '', () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) =>
                              CardPaymentScreen(userData: widget.userData)));
                }, icon: Icons.credit_card),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openPaymentInput(String op) {
    Navigator.pop(context);
    final TextEditingController ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: Text("Dépôt $op"),
              content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Montant FCFA")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text("Annuler")),
                ElevatedButton(
                    onPressed: () async {
                      if (ctrl.text.isEmpty) return;
                      String amountStr = ctrl.text;
                      Navigator.pop(c);
                      try {
                        final res = await ApiService.initiatePayment(
                            widget.userData['phone'], double.parse(amountStr));
                        if (res['success'] == true) {
                          await launchUrl(Uri.parse(res['payment_url']),
                              mode: LaunchMode.externalApplication);
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Échec du paiement")));
                      }
                    },
                    child: const Text("Confirmer"))
              ],
            ));
  }

  Widget _logoBtn(String name, String path, VoidCallback onTap,
      {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        icon != null
            ? Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200, shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: Colors.blue.shade900))
            : Image.asset(path,
                width: 60,
                height: 60,
                errorBuilder: (c, e, s) => const Icon(Icons.payment, size: 60)),
        const SizedBox(height: 5),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}