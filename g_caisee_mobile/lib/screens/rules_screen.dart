import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color gold = const Color(0xFFD4AF37);
    final Color cardGrey = const Color(0xFF1E1E1E);

    // Liste des règles (Tu pourras les charger depuis l'API plus tard si tu veux)
    final List<Map<String, dynamic>> rules = [
      {
        "title": "Article 1 : Ponctualité",
        "desc": "Les cotisations doivent être versées avant la date limite fixée par l'administrateur. Tout retard perturbe le cycle.",
        "icon": Icons.access_time_filled
      },
      {
        "title": "Article 2 : Commission G-Caisse",
        "desc": "Une commission de fonctionnement de 2% est prélevée automatiquement sur chaque tour de tontine pour la maintenance du service.",
        "icon": Icons.percent
      },
      {
        "title": "Article 3 : Pénalités de Retard",
        "desc": "En cas de retard non justifié de plus de 24h, une amende forfaitaire de 1000 FCFA sera débitée du compte de l'utilisateur.",
        "icon": Icons.warning_amber_rounded
      },
      {
        "title": "Article 4 : Respect & Courtoisie",
        "desc": "Les échanges dans le chat du groupe doivent rester courtois. Tout propos injurieux peut entraîner l'exclusion.",
        "icon": Icons.handshake
      },
      {
        "title": "Article 5 : Validation des Dépôts",
        "desc": "Les dépôts par Mobile Money sont validés instantanément. Les virements peuvent prendre 24 à 48h.",
        "icon": Icons.verified_user
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("RÈGLEMENT INTÉRIEUR", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            color: cardGrey,
            width: double.infinity,
            child: Column(
              children: [
                const Icon(Icons.gavel, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                const Text(
                  "Charte de bonne conduite",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "En utilisant G-Caisse, vous acceptez les conditions suivantes :",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Liste des articles
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: cardGrey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: gold.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(rule['icon'], color: gold, size: 20),
                      ),
                      title: Text(rule['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      collapsedIconColor: Colors.grey,
                      iconColor: gold,
                      children: [
                        Text(
                          rule['desc'],
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Pied de page
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                   // Action pour contacter le support
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support contacté")));
                },
                icon: const Icon(Icons.support_agent),
                label: const Text("Une question sur le règlement ?"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: BorderSide(color: gold),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}