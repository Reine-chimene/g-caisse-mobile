import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFD4AF37); // Ton Or
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _timer; // On stocke le timer pour pouvoir l'annuler

  @override
  void initState() {
    super.initState();
    
    // Configuration de l'animation de fondu
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Navigation après 3.5s
    _timer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder( // Animation de transition douce vers le Login
            pageBuilder: (context, anim, secondaryAnim) => const LoginScreen(),
            transitionsBuilder: (context, anim, secondaryAnim, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Sécurité : on annule le timer
    _controller.dispose(); // On libère la mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition( // Tout l'écran apparaît en fondu
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // LOGO avec ombre portée plus douce
                Hero( // Hero pour une transition fluide si le logo est sur le login
                  tag: 'logo',
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15), 
                          blurRadius: 30, 
                          spreadRadius: 10
                        )
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.jpeg'), 
                        fit: BoxFit.cover
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Text(
                  "G-CAISE",
                  style: TextStyle(
                    color: primaryColor, 
                    fontSize: 40, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 4
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  "La tontine moderne,\nsécurisée et transparente.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600], 
                    fontSize: 16, 
                    height: 1.4, 
                    fontWeight: FontWeight.w400
                  ),
                ),
                
                const Spacer(),
                
                // Barre de chargement plus stylisée
                Column(
                  children: [
                    Text(
                      "Initialisation sécurisée...", 
                      style: TextStyle(
                        color: Colors.grey[400], 
                        fontSize: 13, 
                        fontStyle: FontStyle.italic
                      )
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 180,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}