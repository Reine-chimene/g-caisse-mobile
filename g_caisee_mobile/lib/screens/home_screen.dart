import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'tontine_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardTab(userData: widget.userData),
      ProfileScreen(userData: widget.userData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Mes Tontines"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const DashboardTab({super.key, this.userData});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final Color primaryColor = const Color(0xFFD4AF37);
  List<dynamic> tontines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTontines();
  }

  Future<void> _fetchTontines() async {
    try {
      // int userId = widget.userData?['id'] ?? 1;
      // TODO: Appeler l'API pour récupérer les tontines de l'utilisateur
      // final data = await ApiService.getUserTontines(userId);
      // tontines = data;
      
      // Simulation pour l'instant
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int userId = widget.userData?['id'] ?? 1;
    String name = widget.userData?['fullname'] ?? "Membre";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bonjour, $name 👋", style: const TextStyle(color: Colors.black, fontSize: 16)),
            const Text("Vos Tontines", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : tontines.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: tontines.length,
                itemBuilder: (context, index) {
                  final tontine = tontines[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.groups, color: primaryColor),
                      ),
                      title: Text(tontine['name'] ?? "Tontine", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${tontine['frequency'] ?? 'Mensuel'} - ${tontine['amount_to_pay'] ?? 0} F"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (c) => TontineDetailsScreen(tontine: tontine, userId: userId))
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () {
           // Navigator.push(context, MaterialPageRoute(builder: (c) => CreateTontineScreen()));
        },
        label: const Text("Créer une tontine", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text("Aucune tontine pour le moment", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}