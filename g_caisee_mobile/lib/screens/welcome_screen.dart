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
    // On attend 3,5 secondes : cela laisse le temps au serveur Render de se réveiller
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
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
              
              // LOGO G-CAISE
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2), 
                      blurRadius: 20, 
                      spreadRadius: 5
                    )
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/logo.jpeg'), 
                    fit: BoxFit.cover
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // TITRE CORRIGÉ
              Text(
                "G-CAISE",
                style: TextStyle(
                  color: primaryColor, 
                  fontSize: 36, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 3
                ),
              ),
              const SizedBox(height: 15),
              
              // SOUS-TITRE
              Text(
                "La tontine moderne, sécurisée et transparente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600], 
                  fontSize: 16, 
                  height: 1.5, 
                  fontWeight: FontWeight.w500
                ),
              ),
              
              const Spacer(),
              
              // INDICATEUR DE CHARGEMENT
              Column(
                children: [
                  Text(
                    "Préparation de votre espace...", 
                    style: TextStyle(
                      color: Colors.grey[500], 
                      fontSize: 14, 
                      fontWeight: FontWeight.w600
                    )
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 200, // Largeur fixe pour la barre
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        minHeight: 6,
                      ),
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