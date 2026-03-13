import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int tontineId;
  final String tontineName;
  final Map<String, dynamic> userData;

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

  // --- AUDIO VARIABLES ---
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  // Design System G-Caisse
  final Color gold = const Color(0xFFD4AF37);
  final Color cardGrey = const Color(0xFF1E1E1E);
  final Color bgBlack = const Color(0xFF0F0F0F);

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initRecorder(); // Initialise le micro
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages(isBackground: true));
  }

  // Demande la permission et prépare le micro
  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint("Permission micro refusée");
      return;
    }
    await _recorder!.openRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    _msgController.dispose();
    _scrollController.dispose();
    _recorder?.closeRecorder(); // Ferme proprement le micro
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

  Future<void> _sendMessage({String? customContent}) async {
    final String content = customContent ?? _msgController.text.trim();
    if (content.isEmpty) return;

    final int myId = widget.userData['id'];

    if (customContent == null) _msgController.clear(); 

    try {
      await ApiService.sendMessage(widget.tontineId, myId, content);
      _fetchMessages(isBackground: true); 
      
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

  // --- LOGIQUE D'ENREGISTREMENT VOCAL ---
  Future<void> _startRecording() async {
    try {
      await _recorder!.startRecorder(toFile: 'temp_audio.aac');
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Erreur d'enregistrement : $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      await _recorder!.stopRecorder();
      setState(() => _isRecording = false);
      
      // On envoie un marqueur spécial pour le backend
      // Le client verra l'UI d'un message vocal
      _sendMessage(customContent: "[VOICE] Message vocal");
    } catch (e) {
      debugPrint("Erreur arrêt enregistrement : $e");
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
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final bool isMe = msg['user_id'] == widget.userData['id'];
                          
                          // Détection du mode vocal
                          if (msg['content'] != null && msg['content'].toString().startsWith("[VOICE]")) {
                            return _buildVoiceBubble(msg, isMe);
                          }
                          
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
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // BOUTON MICROPHONE (Mode Voice)
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressEnd: (details) => _stopRecordingAndSend(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_isRecording ? 12 : 8),
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none, 
                  color: _isRecording ? Colors.white : gold, 
                  size: _isRecording ? 28 : 24
                ),
              ),
            ),
            const SizedBox(width: 5),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _isRecording ? Colors.red.withOpacity(0.5) : Colors.white10),
                ),
                child: TextField(
                  controller: _msgController,
                  enabled: !_isRecording, // Désactive l'écriture pendant l'enregistrement vocal
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: _isRecording ? "Enregistrement en cours..." : "Écrivez ici...",
                    hintStyle: TextStyle(color: _isRecording ? Colors.red : Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _sendMessage(),
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

  // BULLE TEXTE CLASSIQUE
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

  // NOUVELLE BULLE : MODE VOICE
  Widget _buildVoiceBubble(Map msg, bool isMe) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? gold : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, color: isMe ? Colors.black87 : Colors.white, size: 35),
                const SizedBox(width: 10),
                // Ligne de progression (UI)
                Container(
                  width: 100, height: 3,
                  decoration: BoxDecoration(color: isMe ? Colors.black26 : Colors.white24, borderRadius: BorderRadius.circular(5)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.3, // Fausse progression
                    child: Container(color: isMe ? Colors.black : gold),
                  ),
                ),
                const SizedBox(width: 15),
                Icon(Icons.mic, color: isMe ? Colors.black54 : Colors.white54, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}