import 'package:flutter/material.dart';
import 'package:g_caisee_mobile/screens/splash_screen.dart';
import 'package:g_caisee_mobile/screens/home_screen.dart'; 
import 'package:g_caisee_mobile/screens/tontine_list_screen.dart';
import 'package:g_caisee_mobile/screens/saving_screen.dart';
import 'package:g_caisee_mobile/screens/profile_screen.dart';

// 💡 GLOBAL : Contrôleur pour changer le thème
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'G-CAISE',
          
          theme: ThemeData(
            brightness: Brightness.light, 
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFFF5F6F8),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white, 
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
          
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFD4AF37),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E), 
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          
          themeMode: currentMode,
          home: const SplashScreen(), 
        );
      }
    );
  }
}

// Le Wrapper qui gère la navigation par onglets après connexion
class MainWrapper extends StatefulWidget {
  final Map<String, dynamic>? userData; 
  const MainWrapper({super.key, this.userData});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  late Map<String, dynamic> currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.userData ?? {
      "id": 1,
      "fullname": "Client G-CAISE",
      "phone": "600000000",
    };
  }

  @override
  Widget build(BuildContext context) {
    // Liste des pages synchronisée avec les classes corrigées
    final List<Widget> pages = [
      HomeScreen(userData: currentUser), 
      TontineListScreen(userId: currentUser['id'], userData: currentUser),
      SavingScreen(userData: currentUser),
      ProfileScreen(userData: currentUser),
    ];

    bool isDark = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10,
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