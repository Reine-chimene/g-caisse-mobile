import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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

  final Color primaryOrange = const Color(0xFFFF7900);
  final Color cardGrey = const Color(0xFF1E1E1E);
  final Color bgBlack = const Color(0xFF0F0F0F);

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initRecorder();
    // Rafraîchissement automatique toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages(isBackground: true));
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _recorder!.openRecorder();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    _msgController.dispose();
    _scrollController.dispose();
    _recorder?.closeRecorder(); 
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
      
      // Scroll vers le bas (index 0 car reverse: true)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de l'envoi")));
      }
    }
  }

  // --- LOGIQUE VOCALE ---
  Future<void> _startRecording() async {
    try {
      await _recorder!.startRecorder(toFile: 'vocal_${DateTime.now().millisecondsSinceEpoch}.aac');
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Erreur micro: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _recorder!.stopRecorder();
      setState(() => _isRecording = false);
      if (path != null) {
        _sendMessage(customContent: "[VOICE] Message vocal");
      }
    } catch (e) {
      debugPrint("Erreur arrêt vocal: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: cardGrey,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tontineName, style: TextStyle(color: primaryOrange, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("En ligne", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryOrange))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Les nouveaux messages apparaissent en bas
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final bool isMe = msg['user_id'] == widget.userData['id'];
                      String content = msg['content']?.toString() ?? "";

                      if (content.startsWith("[VOICE]")) return _buildVoiceBubble(msg, isMe);
                      if (content.startsWith("[IMAGE]") || content.startsWith("[PHOTO]")) {
                        return _buildFileBubble(msg, isMe, Icons.camera_alt_rounded, "Image");
                      }
                      if (content.startsWith("[FILE]")) {
                        return _buildFileBubble(msg, isMe, Icons.description_rounded, "Document");
                      }

                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: cardGrey,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: primaryOrange, size: 28),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _msgController,
                  enabled: !_isRecording,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isRecording ? "Enregistrement..." : "Message...",
                    hintStyle: TextStyle(color: _isRecording ? Colors.red : Colors.white24),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isRecording 
              ? const SizedBox.shrink() 
              : GestureDetector(
                  onTap: () => _sendMessage(),
                  child: CircleAvatar(backgroundColor: primaryOrange, child: const Icon(Icons.send, color: Colors.white, size: 20)),
                ),
            const SizedBox(width: 5),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressEnd: (_) => _stopRecordingAndSend(),
              child: CircleAvatar(
                backgroundColor: _isRecording ? Colors.red : Colors.white10,
                child: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Colors.white : primaryOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? primaryOrange : const Color(0xFF2C2C2E),
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(18),
              topEnd: const Radius.circular(18),
              bottomStart: isMe ? const Radius.circular(18) : Radius.zero,
              bottomEnd: isMe ? Radius.zero : const Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) Text(msg['fullname'] ?? "Membre", style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(msg['content'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? primaryOrange.withValues(alpha: 0.2) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(15),
          border: isMe ? Border.all(color: primaryOrange, width: 0.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: isMe ? primaryOrange : Colors.white),
            const SizedBox(width: 8),
            const Text("0:04", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 10),
            Icon(Icons.waves, color: isMe ? primaryOrange : Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildFileBubble(Map msg, bool isMe, IconData icon, String type) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(15),
          border: isMe ? Border.all(color: primaryOrange) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryOrange),
            const SizedBox(width: 10),
            Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardGrey,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _attachIcon(Icons.image, "Galerie", Colors.blue, () async {
              final img = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (img != null) _sendMessage(customContent: "[IMAGE] ${img.name}");
              Navigator.pop(context);
            }),
            _attachIcon(Icons.camera_alt, "Caméra", Colors.pink, () async {
              final img = await ImagePicker().pickImage(source: ImageSource.camera);
              if (img != null) _sendMessage(customContent: "[PHOTO] ${img.name}");
              Navigator.pop(context);
            }),
            _attachIcon(Icons.insert_drive_file, "Fichier", Colors.orange, () async {
              final res = await FilePicker.platform.pickFiles();
              if (res != null) _sendMessage(customContent: "[FILE] ${res.files.single.name}");
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _attachIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(onPressed: onTap, icon: Icon(icon, color: color)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}