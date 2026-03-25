import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    // Pour l'instant, c'est une maquette.
    // Il faudra la connecter à un service comme Firebase pour un chat en temps réel.
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text("Chat pour la tontine #${widget.tontineId}"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(child: TextField(decoration: InputDecoration(hintText: "Écrire un message..."))),
              IconButton(icon: const Icon(Icons.send), onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }
}