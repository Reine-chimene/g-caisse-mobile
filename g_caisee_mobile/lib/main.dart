import 'package:flutter/material.dart';

import 'package:g_caisee_mobile/screens/welcome_screen.dart';
import 'package:g_caisee_mobile/screens/home_screen.dart'; 
import 'package:g_caisee_mobile/screens/tontine_list_screen.dart';
import 'package:g_caisee_mobile/screens/saving_screen.dart';
import 'package:g_caisee_mobile/screens/profile_screen.dart';

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
      home: const WelcomeScreen(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final int userId = 1; 

  // 💡 ON AJOUTE ÇA : Un profil par défaut pour que HomeScreen ne râle plus
  final Map<String, dynamic> dummyUser = {
    "fullname": "Client G-Caisse",
    "phone": "600000000",
    "balance": 0
  };

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // ✅ CORRECTION : On passe userData à HomeScreen
      HomeScreen(userData: dummyUser), 
      TontineListScreen(userId: userId),
      const SavingScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: Colors.grey.shade400,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Tontines'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Épargne'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}