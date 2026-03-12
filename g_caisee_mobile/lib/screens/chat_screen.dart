import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int tontineId;
  final String tontineName;
  final Map<String, dynamic> userData; // RÉEL : Données reçues du membre connecté

  const ChatScreen({
    super.key, 
    required this.tontineId, 
    required this.tontineName, 
    required this.userData
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  
  List<dynamic> messages = [];
  bool isLoading = true;

  // Design System G-Caisse
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);
  final Color bgBlack = const Color(0xFF0F0F0F);

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Rafraîchissement automatique réel
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages(isBackground: true));
  }

  @override
  void dispose() {
    _timer?.cancel(); 
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

    final String content = _msgController.text.trim();
    final int myId = widget.userData['id']; // Utilise ton vrai ID stocké

    _msgController.clear(); 

    try {
      await ApiService.sendMessage(widget.tontineId, myId, content);
      // On rafraîchit immédiatement après l'envoi
      _fetchMessages(isBackground: true); 
      
      // On descend la liste pour voir le nouveau message
      Timer(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de l'envoi du message")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: cardGrey,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tontineName, style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Salon de discussion", style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        iconTheme: IconThemeData(color: gold),
      ),
      body: Column(
        children: [
          // ZONE DES MESSAGES
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: gold))
                : messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Nouveaux messages en bas (standard chat)
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final bool isMe = msg['user_id'] == widget.userData['id'];
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // BARRE DE SAISIE
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: gold.withOpacity(0.1)),
          const SizedBox(height: 15),
          const Text("Aucun message. Lancez la discussion !", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardGrey,
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: "Écrivez ici...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
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
                radius: 24,
                child: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(msg['fullname'] ?? "Membre", 
                  style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? gold : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Text(
              msg['content'] ?? "",
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white, 
                fontSize: 14.5,
                height: 1.3
              ),
            ),
          ),
        ],
      ),
    );
  }
}