import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final Color primaryColor = const Color(0xFFD4AF37);
  final Color backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Le chronomètre : on attend 3,5 secondes puis on bascule sur la connexion
    Timer(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // LOGO
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)],
                  image: const DecorationImage(image: AssetImage('assets/logo.jpeg'), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 40),
              
              // TITRE
              Text(
                "G-CAISSE",
                style: TextStyle(color: primaryColor, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 15),
              
              // SOUS-TITRE
              Text(
                "La tontine moderne, sécurisée et transparente.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
              ),
              
              const Spacer(),
              
              // BARRE DE CHARGEMENT
              Column(
                children: [
                  Text("Chargement...", style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}