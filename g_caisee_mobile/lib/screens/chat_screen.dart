import 'dart:async'; // Pour le rafraîchissement automatique
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int tontineId;
  final String tontineName;
  const ChatScreen({super.key, required this.tontineId, required this.tontineName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  
  List<dynamic> messages = [];
  bool isLoading = true;
  final int currentUserId = 1; // ID simulé de l'utilisateur connecté

  // Couleurs
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);
  final Color bgBlack = const Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Rafraîchir les messages toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages(isBackground: true));
  }

  @override
  void dispose() {
    _timer?.cancel(); // Arrêter le timer quand on quitte l'écran
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    try {
      final data = await ApiService.getGroupMessages(widget.tontineId);
      if (mounted) {
        setState(() {
          messages = data;
          if (!isBackground) isLoading = false;
        });
      }
    } catch (e) {
      if (!isBackground && mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final content = _msgController.text;
    _msgController.clear(); // Vider le champ tout de suite

    try {
      // Envoi optimiste : on pourrait l'ajouter localement tout de suite, 
      // mais ici on attend le serveur pour être sûr.
      await ApiService.sendMessage(widget.tontineId, currentUserId, content);
      _fetchMessages(); // Recharger la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur d'envoi")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tontineName, style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("En ligne", style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
        backgroundColor: bgBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ZONE DES MESSAGES
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: gold))
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade800),
                            const SizedBox(height: 10),
                            const Text("Début de la discussion", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Le plus récent en bas (standard chat)
                        padding: const EdgeInsets.all(15),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          // Les messages arrivent souvent du plus récent au plus vieux via l'API, 
                          // mais reverse: true inverse l'affichage.
                          // Adapte selon le tri de ton API (ici on suppose que l'API renvoie du plus récent au plus vieux)
                          var msg = messages[i];
                          bool isMe = msg['user_id'] == currentUserId;
                          
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // ZONE DE SAISIE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: cardGrey,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add, color: Colors.grey), onPressed: () {}),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Message...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: gold,
                    child: const Icon(Icons.send, color: Colors.black, size: 20),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET : BULLE DE MESSAGE ---
  Widget _buildMessageBubble(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? gold : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg['fullname'] ?? "Membre", style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
            
            if (!isMe) const SizedBox(height: 3),
            
            Text(
              msg['content'],
              style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 15),
            ),
            
            const SizedBox(height: 3),
            
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                // Si tu as une date, formate-la ici, sinon texte vide
                "12:30", 
                style: TextStyle(color: isMe ? Colors.black54 : Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}