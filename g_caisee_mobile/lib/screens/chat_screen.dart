import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int tontineId;
  final int userId;
  final Map<String, dynamic> userData;

  const ChatScreen({
    super.key,
    required this.tontineId,
    required this.userId,
    required this.userData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── Texte ──────────────────────────────────────────────
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  bool isLoading = true;
  bool isSending = false;

  // ── Enregistrement vocal ───────────────────────────────
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  bool _isRecording = false;
  String? _recordingPath;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // ── Lecture vocale ─────────────────────────────────────
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerReady = false;
  String? _playingUrl;   // URL en cours de lecture
  bool _isPlaying = false;

  static const Color _orange = Color(0xFFFF7900);

  // ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAudio();
    _fetchMessages();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.closeRecorder();
    _player.closePlayer();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    setState(() {
      _recorderReady = true;
      _playerReady = true;
    });
  }

  // ── MESSAGES ───────────────────────────────────────────

  Future<void> _fetchMessages() async {
    try {
      final data = await ApiService.getGroupMessages(widget.tontineId);
      if (mounted) {
        setState(() {
          messages = data;
          isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sendTextMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty || isSending) return;
    setState(() => isSending = true);
    _msgController.clear();
    try {
      await ApiService.sendMessage(widget.tontineId, widget.userId, content);
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur d'envoi"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── ENREGISTREMENT ─────────────────────────────────────

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission micro refusée"), backgroundColor: Colors.red),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(toFile: _recordingPath, codec: Codec.aacADTS);

    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);

    if (_recordingPath == null || _recordSeconds < 1) return;

    setState(() => isSending = true);
    try {
      await ApiService.sendVoiceMessage(
        tontineId: widget.tontineId,
        userId: widget.userId,
        filePath: _recordingPath!,
        durationSec: _recordSeconds,
      );
      // Supprimer le fichier temporaire
      File(_recordingPath!).deleteSync();
      _recordingPath = null;
      await _fetchMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur envoi vocal"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stopRecorder();
    if (_recordingPath != null) {
      try { File(_recordingPath!).deleteSync(); } catch (_) {}
      _recordingPath = null;
    }
    setState(() { _isRecording = false; _recordSeconds = 0; });
  }

  // ── LECTURE ────────────────────────────────────────────

  Future<void> _togglePlay(String url) async {
    if (!_playerReady) return;

    if (_isPlaying && _playingUrl == url) {
      await _player.stopPlayer();
      setState(() { _isPlaying = false; _playingUrl = null; });
      return;
    }

    if (_isPlaying) await _player.stopPlayer();

    setState(() { _isPlaying = true; _playingUrl = url; });

    await _player.startPlayer(
      fromURI: url,
      codec: Codec.aacADTS,
      whenFinished: () {
        if (mounted) setState(() { _isPlaying = false; _playingUrl = null; });
      },
    );
  }

  // ── BUILD ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: _orange))
              : messages.isEmpty
                  ? const Center(
                      child: Text("Aucun message. Soyez le premier !",
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _fetchMessages,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final isMe = msg['user_id'] == widget.userId;
                          final isVoice = msg['message_type'] == 'voice';
                          return isVoice
                              ? _buildVoiceBubble(msg, isMe)
                              : _buildTextBubble(msg, isMe);
                        },
                      ),
                    ),
        ),
        _isRecording ? _buildRecordingBar() : _buildInputBar(),
      ],
    );
  }

  // ── BULLES ─────────────────────────────────────────────

  Widget _buildTextBubble(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? _orange : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg['fullname'] ?? 'Membre',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
            Text(msg['content'] ?? '',
                style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['created_at']),
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(Map msg, bool isMe) {
    final url = msg['voice_url'] as String? ?? '';
    final duration = msg['duration_sec'] as int? ?? 0;
    final isCurrentlyPlaying = _isPlaying && _playingUrl == url;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? _orange : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg['fullname'] ?? 'Membre',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _togglePlay(url),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isMe ? Colors.white24 : _orange.withOpacity(0.15),
                    child: Icon(
                      isCurrentlyPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: isMe ? Colors.white : _orange,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de progression simulée
                    Container(
                      width: 100,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white38 : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: isCurrentlyPlaying
                          ? LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              color: isMe ? Colors.white : _orange,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['created_at']),
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── BARRES D'INPUT ─────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: "Écrire un message...",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
          const SizedBox(width: 6),
          // Bouton vocal — appui long pour enregistrer
          GestureDetector(
            onLongPressStart: (_) => _recorderReady ? _startRecording() : null,
            onLongPressEnd: (_) => _stopAndSendRecording(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: _orange),
            ),
          ),
          const SizedBox(width: 6),
          isSending
              ? const SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _orange))
              : IconButton(
                  icon: const Icon(Icons.send_rounded, color: _orange),
                  onPressed: _sendTextMessage,
                ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          // Annuler
          GestureDetector(
            onTap: _cancelRecording,
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 16),
          // Indicateur d'enregistrement
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Enregistrement... ${_formatDuration(_recordSeconds)}",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          // Envoyer
          GestureDetector(
            onTap: _stopAndSendRecording,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    final str = createdAt.toString();
    return str.length >= 16 ? str.substring(11, 16) : '';
  }
}
