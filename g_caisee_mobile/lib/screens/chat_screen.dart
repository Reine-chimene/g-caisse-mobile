import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart'; // NOUVEAU
import 'package:image_picker/image_picker.dart'; // NOUVEAU
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

  // Design System G-Caisse (Orange Max It)
  final Color primaryOrange = const Color(0xFFFF7900);
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
      _sendMessage(customContent: "[VOICE] Message vocal");
    } catch (e) {
      debugPrint("Erreur arrêt enregistrement : $e");
    }
  }

  // --- NOUVEAU : ENVOI DE PIÈCE JOINTE ---
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardGrey,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Galerie Photo', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _sendMessage(customContent: "[IMAGE] ${image.name}");
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.pink),
                title: const Text('Prendre une photo', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    _sendMessage(customContent: "[PHOTO] ${photo.name}");
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
                title: const Text('Document (PDF, Word...)', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    _sendMessage(customContent: "[FILE] ${result.files.single.name}");
                  }
                },
              ),
            ],
          ),
        );
      }
    );
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
            Text(widget.tontineName, style: TextStyle(color: primaryOrange, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Salon de discussion", style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        iconTheme: IconThemeData(color: primaryOrange),
        // ✅ NOUVEAU : BOUTONS APPEL ET CARTE EN HAUT
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Démarrage de l'appel de groupe...")));
              // Ici, nous mettrons le lien vers ZegoCloud plus tard
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ouverture du Radar des membres...")));
              // Ici, nous mettrons le lien vers l'écran Google Maps plus tard
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(
        children: [
          // ZONE DES MESSAGES
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryOrange))
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
                          
                          // Détection des messages spéciaux
                          String msgContent = msg['content']?.toString() ?? "";
                          if (msgContent.startsWith("[VOICE]")) return _buildVoiceBubble(msg, isMe);
                          if (msgContent.startsWith("[IMAGE]") || msgContent.startsWith("[PHOTO]")) return _buildFileBubble(msg, isMe, Icons.image, "Photo envoyée");
                          if (msgContent.startsWith("[FILE]")) return _buildFileBubble(msg, isMe, Icons.insert_drive_file, "Fichier joint");
                          
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
          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: primaryOrange.withValues(alpha: 0.1)),
          const SizedBox(height: 15),
          const Text("Aucun message. Lancez la discussion !", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: cardGrey,
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ✅ NOUVEAU : BOUTON TROMBONE (PIÈCE JOINTE)
            IconButton(
              icon: Icon(Icons.attach_file, color: primaryOrange),
              onPressed: _showAttachmentOptions,
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _isRecording ? Colors.red.withValues(alpha: 0.5) : Colors.white10),
                ),
                child: TextField(
                  controller: _msgController,
                  enabled: !_isRecording, 
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: _isRecording ? "Enregistrement..." : "Écrivez ici...",
                    hintStyle: TextStyle(color: _isRecording ? Colors.red : Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),

            // BOUTON MICROPHONE (Mode Voice)
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressEnd: (details) => _stopRecordingAndSend(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_isRecording ? 10 : 8),
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none, 
                  color: _isRecording ? Colors.white : primaryOrange, 
                  size: _isRecording ? 28 : 24
                ),
              ),
            ),

            // BOUTON ENVOYER TEXTE
            GestureDetector(
              onTap: () => _sendMessage(),
              child: CircleAvatar(
                backgroundColor: primaryOrange,
                radius: 20,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
              child: Text(msg['fullname'] ?? "Membre", style: TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? primaryOrange : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Text(
              msg['content'] ?? "",
              style: TextStyle(color: isMe ? Colors.white : Colors.white, fontSize: 14.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // BULLE VOCALE
  Widget _buildVoiceBubble(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? primaryOrange : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill, color: Colors.white, size: 35),
            const SizedBox(width: 10),
            Container(
              width: 100, height: 3,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5)),
              child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.3, child: Container(color: Colors.white)),
            ),
            const SizedBox(width: 15),
            const Icon(Icons.mic, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVELLE BULLE FICHIER (Photos/Documents)
  Widget _buildFileBubble(Map msg, bool isMe, IconData icon, String label) {
    String filename = msg['content'].toString().split("] ").last; // Récupère le nom du fichier
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? primaryOrange.withValues(alpha: 0.2) : const Color(0xFF2C2C2E),
          border: Border.all(color: isMe ? primaryOrange : Colors.transparent),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isMe ? primaryOrange : Colors.grey.shade700, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                SizedBox(
                  width: 120,
                  child: Text(filename, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}