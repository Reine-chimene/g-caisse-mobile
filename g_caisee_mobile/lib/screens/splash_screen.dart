import 'package:flutter/material.dart';
import 'dart:async';
import 'welcome_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _timer; // ✅ Variable pour le timer

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2)
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Redirection automatique après 3 secondes
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ On annule le timer pour éviter les fuites de mémoire
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo circulaire avec ombre légère
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      // ✅ Utilisation de withValues pour être à jour
                      color: Colors.black.withValues(alpha: 0.05), 
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/logo.jpeg'), 
                    fit: BoxFit.cover
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              const Text(
                "G-CAISE",
                style: TextStyle(
                  color: Color(0xFFD4AF37), // Doré G-CAISE
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 10),
              
              Text(
                "La Tontine Digitale Éthique", 
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                )
              ),
              const SizedBox(height: 60),
              
              const CircularProgressIndicator(
                color: Color(0xFFD4AF37), 
                strokeWidth: 3
              ),
            ],
          ),
        ),
      ),
    );
  }
}