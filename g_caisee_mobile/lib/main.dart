import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g_caisee_mobile/screens/splash_screen.dart';
import 'package:g_caisee_mobile/screens/home_screen.dart';
import 'package:g_caisee_mobile/screens/tontine_list_screen.dart';
import 'package:g_caisee_mobile/screens/saving_screen.dart';
import 'package:g_caisee_mobile/screens/profile_screen.dart';
import 'services/offline_service.dart';
import 'theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<String?> paymentResultNotifier = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le cache hors-ligne
  await OfflineService.init();

  // Charger le thème sauvegardé
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
  ));

  _initDeepLinkListener();
  runApp(const MyApp());
}

void _initDeepLinkListener() {
  // Écouter les deep links entrants (gcaisse://payment?status=success)
  const channel = MethodChannel('flutter/navigation');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'pushRoute') {
      final url = call.arguments as String?;
      if (url != null && url.startsWith('gcaisse://payment')) {
        final uri = Uri.parse(url);
        paymentResultNotifier.value = uri.queryParameters['status'];
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'G-CAISE',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(), 
        );
      }
    );
  }
}

// ==========================================================
// LE WRAPPER : Gère la navigation par onglets après Login
// ==========================================================
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
    // Initialisation sécurisée des données utilisateur
    currentUser = widget.userData ?? {
      "id": 1,
      "fullname": "Client G-CAISE",
      "phone": "600000000",
    };
  }

  @override
  Widget build(BuildContext context) {
    // Liste des pages synchronisée avec tes fichiers screens/
    final List<Widget> pages = [
      HomeScreen(userData: currentUser), 
      TontineListScreen(userId: currentUser['id'], userData: currentUser),
      SavingScreen(userData: currentUser),
      ProfileScreen(userData: currentUser),
    ];

    // On utilise ValueListenableBuilder pour que la barre de navigation 
    // change de couleur dès que le thème change dans les paramètres.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          // IndexedStack permet de ne pas recharger les pages à chaque clic
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
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              selectedItemColor: const Color(0xFFFF7900),
              unselectedItemColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded), 
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_rounded), 
                  label: 'Tontines',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_rounded), 
                  label: 'Épargne',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded), 
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}