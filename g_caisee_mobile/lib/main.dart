import 'package:flutter/material.dart';
import 'package:g_caisee_mobile/screens/welcome_screen.dart';
import 'package:g_caisee_mobile/screens/home_screen.dart'; 
import 'package:g_caisee_mobile/screens/tontine_list_screen.dart';
import 'package:g_caisee_mobile/screens/saving_screen.dart';
import 'package:g_caisee_mobile/screens/profile_screen.dart';

// 💡 GLOBAL : On crée un contrôleur pour changer le thème n'importe où
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 On utilise ValueListenableBuilder pour écouter le changement de thème
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'G-Caisse',
          
          // Thème Clair
          theme: ThemeData(
            brightness: Brightness.light, 
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFFF5F6F8),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
          ),
          
          // Thème Sombre
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white),
          ),
          
          themeMode: currentMode, // Applique le mode actuel (light ou dark)
          home: const WelcomeScreen(),
        );
      }
    );
  }
}

class MainWrapper extends StatefulWidget {
  final Map<String, dynamic>? userData; // On permet de recevoir les infos de connexion
  const MainWrapper({super.key, this.userData});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Données utilisateur centralisées
  late Map<String, dynamic> currentUser;

  @override
  void initState() {
    super.initState();
    // On initialise avec les données reçues ou un dummy si vide
    currentUser = widget.userData ?? {
      "id": 1,
      "fullname": "Client G-Caisse",
      "phone": "600000000",
    };
  }

  @override
  Widget build(BuildContext context) {
    // On définit les pages ici pour qu'elles se mettent à jour si currentUser change
    final List<Widget> _pages = [
      HomeScreen(userData: currentUser), 
      TontineListScreen(userId: currentUser['id']),
      const SavingScreen(),
      ProfileScreen(userData: currentUser),
    ];

    bool isDark = themeNotifier.value == ThemeMode.dark;

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
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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