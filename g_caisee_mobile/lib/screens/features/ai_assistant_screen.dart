import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AiAssistantScreen({super.key, required this.userData});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _msgCtrl      = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;

  // Données utilisateur chargées
  double _balance      = 0;
  int    _trustScore   = 100;
  List<dynamic> _txs  = [];
  List<dynamic> _tontines = [];

  @override
  void initState() {
    super.initState();
    _loadContext();
    _addBot('Bonjour ${widget.userData['fullname']?.toString().split(' ').first ?? ''} ! 👋\n\nJe suis votre assistant G-Caisse. Je peux vous aider avec :\n• Votre solde et transactions\n• Vos tontines\n• Des conseils financiers\n• Des calculs de prêt\n\nQue puis-je faire pour vous ?');
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final id = widget.userData['id'] as int;
      final results = await Future.wait([
        ApiService.getUserBalance(id),
        ApiService.getTrustScore(id),
        ApiService.getUserTransactions(id),
        ApiService.getTontines(id),
      ]);
      _balance    = results[0] as double;
      _trustScore = results[1] as int;
      _txs        = results[2] as List<dynamic>;
      _tontines   = results[3] as List<dynamic>;
    } catch (_) {}
  }

  void _addBot(String text) {
    setState(() => _messages.add(_Message(text: text, isUser: false)));
    _scrollToBottom();
  }

  void _addUser(String text) {
    setState(() => _messages.add(_Message(text: text, isUser: true)));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    _addUser(text);

    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isTyping = false);
      _addBot(_generateResponse(text.toLowerCase()));
    }
  }

  String _generateResponse(String input) {
    // Solde
    if (input.contains('solde') || input.contains('argent') || input.contains('combien')) {
      return 'Votre solde actuel est de **${_balance.toStringAsFixed(0)} FCFA**.\n\n${_balance < 5000 ? '⚠️ Votre solde est bas. Pensez à effectuer un dépôt.' : '✅ Votre solde est en bonne santé.'}';
    }

    // Tontines
    if (input.contains('tontine') || input.contains('groupe')) {
      if (_tontines.isEmpty) return 'Vous n\'avez pas encore de tontine. Créez-en une depuis l\'onglet Tontines !';
      final names = _tontines.map((t) => '• ${t['name']}').join('\n');
      return 'Vous participez à **${_tontines.length} tontine(s)** :\n$names\n\nVoulez-vous des détails sur l\'une d\'elles ?';
    }

    // Transactions
    if (input.contains('transaction') || input.contains('historique') || input.contains('dépense')) {
      if (_txs.isEmpty) return 'Vous n\'avez pas encore de transactions enregistrées.';
      final recent = _txs.take(3).map((t) => '• ${t['type']} : ${t['amount']} F').join('\n');
      return 'Vos 3 dernières transactions :\n$recent\n\nConsultez l\'historique complet dans la section dédiée.';
    }

    // Prêt
    if (input.contains('prêt') || input.contains('emprunt') || input.contains('loan')) {
      final maxLoan = _trustScore * 5000;
      return 'Basé sur votre score de crédibilité (**$_trustScore/100**), vous êtes éligible à un prêt islamique de jusqu\'à **${maxLoan.toStringAsFixed(0)} FCFA** à 0% de taux.\n\nAccédez à la section Prêts pour soumettre une demande.';
    }

    // Score
    if (input.contains('score') || input.contains('crédibilité') || input.contains('confiance')) {
      return 'Votre score de crédibilité est de **$_trustScore/100**.\n\n${_trustScore >= 80 ? '🏆 Excellent ! Vous êtes un membre très fiable.' : _trustScore >= 60 ? '👍 Bon score. Continuez à payer vos cotisations à temps.' : '⚠️ Score moyen. Payez vos cotisations à temps pour l\'améliorer.'}';
    }

    // Conseil financier
    if (input.contains('conseil') || input.contains('économi') || input.contains('épargn')) {
      return '💡 **Conseils financiers personnalisés :**\n\n1. Épargnez au moins 10% de chaque dépôt\n2. Payez vos cotisations tontine à temps pour améliorer votre score\n3. Évitez les retraits fréquents de petits montants\n4. Utilisez le prêt islamique (0% intérêt) plutôt que les crédits classiques\n5. Diversifiez vos tontines pour maximiser vos gains';
    }

    // Transfert
    if (input.contains('transfert') || input.contains('envoyer') || input.contains('envoie')) {
      return 'Pour envoyer de l\'argent :\n\n1. Allez dans **OM/MoMo** sur l\'accueil\n2. Ou scannez le **QR Code** du destinataire\n3. Ou utilisez le bouton **Retrait** pour envoyer vers Mobile Money\n\nLes frais sont de 2% par transaction.';
    }

    // Recharge
    if (input.contains('recharge') || input.contains('crédit') || input.contains('data') || input.contains('forfait')) {
      return 'Pour recharger un numéro :\n\n1. Allez dans **Recharge & Data** sur l\'accueil\n2. Choisissez MTN ou Orange\n3. Entrez le numéro et le montant\n4. Validez avec votre PIN Mobile Money\n\nLes recharges sont disponibles 24h/24.';
    }

    // Salutation
    if (input.contains('bonjour') || input.contains('salut') || input.contains('bonsoir')) {
      return 'Bonjour ! Comment puis-je vous aider aujourd\'hui ? 😊';
    }

    // Merci
    if (input.contains('merci') || input.contains('thanks')) {
      return 'Avec plaisir ! N\'hésitez pas si vous avez d\'autres questions. 🙏';
    }

    // Réponse par défaut
    return 'Je n\'ai pas bien compris votre question. Voici ce que je peux faire :\n\n• **"Mon solde"** — voir votre solde\n• **"Mes tontines"** — liste de vos groupes\n• **"Mon score"** — score de crédibilité\n• **"Prêt"** — capacité d\'emprunt\n• **"Conseils"** — conseils financiers\n• **"Transfert"** — comment envoyer de l\'argent';
  }

  // Suggestions rapides
  static const List<String> _suggestions = [
    'Mon solde 💰',
    'Mes tontines 👥',
    'Mon score 🏆',
    'Conseils financiers 💡',
    'Capacité de prêt 🏦',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant G-Caisse',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('En ligne', style: TextStyle(color: AppTheme.success, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) return _buildTypingIndicator();
                return _buildBubble(_messages[i]);
              },
            ),
          ),

          // Suggestions rapides
          if (_messages.length <= 2)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    _msgCtrl.text = _suggestions[i];
                    _send();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(_suggestions[i],
                        style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Barre de saisie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Posez votre question...',
                      hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: AppTheme.darkSurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Message msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primary : AppTheme.darkCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : AppTheme.textLight,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16),
            bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => AnimatedContainer(
            duration: Duration(milliseconds: 400 + i * 100),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6, height: 6,
            decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle),
          )),
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}
