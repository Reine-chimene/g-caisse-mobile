import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class RadarMapScreen extends StatefulWidget {
  final int tontineId;
  final String tontineName;
  final int userId; // Ajouté pour savoir qui envoie sa position

  const RadarMapScreen({
    super.key, 
    required this.tontineId, 
    required this.tontineName,
    required this.userId,
  });

  @override
  State<RadarMapScreen> createState() => _RadarMapScreenState();
}

class _RadarMapScreenState extends State<RadarMapScreen> {
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _statusMessage = "Initialisation du Radar...";
  Timer? _timer;

  // Liste des marqueurs des VRAIS membres
  List<Marker> _memberMarkers = [];

  final Color primaryOrange = const Color(0xFFFF7900);

  @override
  void initState() {
    super.initState();
    _startRadar();
    // Rafraîchir les positions toutes le 10 secondes
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => _updateRadarData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Première initialisation
  Future<void> _startRadar() async {
    await _determinePosition();
    await _updateRadarData();
  }

  // Logique pour obtenir et envoyer sa propre position
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = "Activez votre GPS.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = "Permission GPS refusée.");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        // On informe le serveur de notre position
        await ApiService.updateUserLocation(widget.userId, position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Erreur GPS : $e");
    }
  }

  // Récupérer les autres membres depuis le backend
  Future<void> _updateRadarData() async {
    try {
      final membersData = await ApiService.getTontineMembersLocations(widget.tontineId);
      
      List<Marker> markers = [];
      for (var m in membersData) {
        // On n'affiche pas son propre marqueur dans la liste des autres
        if (m['id'] == widget.userId) continue;

        markers.add(
          Marker(
            point: LatLng(double.parse(m['latitude'].toString()), double.parse(m['longitude'].toString())),
            width: 60,
            height: 60,
            child: Column(
              children: [
                const Icon(Icons.person_pin_circle, color: Colors.red, size: 35),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(5)),
                  child: Text(
                    m['fullname'] ?? "Membre",
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _memberMarkers = markers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur Radar : $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Radar : ${widget.tontineName}", style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
        foregroundColor: primaryOrange,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _startRadar),
        ],
      ),
      body: _isLoading || _currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryOrange),
                  const SizedBox(height: 15),
                  Text(_statusMessage, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gcaisse.app',
                ),
                MarkerLayer(
                  markers: [
                    // MON MARQUEUR (Bleu)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 35),
                    ),
                    // LES AUTRES MEMBRES (Rouge)
                    ..._memberMarkers,
                  ],
                ),
              ],
            ),
    );
  }
}