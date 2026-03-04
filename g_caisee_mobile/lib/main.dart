import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart'; // 👈 On importe l'écran de bienvenue

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'G-Caisse',
      theme: ThemeData(
        brightness: Brightness.light, 
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(), // 👈 ICI on démarre sur WelcomeScreen !
    );
  }
}