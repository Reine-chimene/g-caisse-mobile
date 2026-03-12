import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int tontineId;
  final String tontineName;
  final Map<String, dynamic> userData; // RÉEL : On récupère les vraies infos du membre

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

  // Couleurs Premium
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);
  final Color bgBlack = const Color(0xFF0F0F0F);

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // RÉEL : Rafraîchissement automatique toutes les 3 secondes
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

    final content = _msgController.text;
    final int myId = widget.userData['id']; // RÉEL : Ton vrai ID

    _msgController.clear(); 

    try {
      await ApiService.sendMessage(widget.tontineId, myId, content);
      _fetchMessages(isBackground: true); 
      // Petit délai pour laisser le message apparaître avant de scroller
      Timer(const Duration(milliseconds: 300), () => _scrollToBottom());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de l'envoi")));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
            const Text("Groupe de Tontine", style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        iconTheme: IconThemeData(color: gold),
        actions: [
          IconButton(icon: Icon(Icons.info_outline, color: gold), onPressed: () {}),
        ],
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
                        reverse: true, // Nouveaux messages en bas
                        padding: const EdgeInsets.all(20),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          var msg = messages[i];
                          bool isMe = msg['user_id'] == widget.userData['id'];
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // ZONE DE SAISIE PROFESSIONNELLE
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
          Icon(Icons.forum_outlined, size: 80, color: gold.withOpacity(0.1)),
          const SizedBox(height: 15),
          const Text("Bienvenue dans le salon tontine", style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardGrey,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Écrivez un message...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                backgroundColor: gold,
                radius: 24,
                child: const Icon(Icons.send_rounded, color: Colors.black),
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
              padding: const EdgeInsets.only(left: 10, bottom: 4),
              child: Text(msg['fullname'] ?? "Membre", 
                  style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
              msg['content'],
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white, 
                fontSize: 15,
                height: 1.3
              ),
            ),
          ),
        ],
      ),
    );
  }
}