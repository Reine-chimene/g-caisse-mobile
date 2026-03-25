import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class RadarMapScreen extends StatefulWidget {
  final int tontineId;
  final String tontineName;
  final int userId;

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
  final MapController _mapController = MapController(); // Pour manipuler la vue
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _statusMessage = "Localisation en cours...";
  Timer? _timer;
  List<Marker> _memberMarkers = [];

  final Color primaryOrange = const Color(0xFFFF7900);

  @override
  void initState() {
    super.initState();
    _initRadar();
    // Rafraîchissement toutes les 15 secondes (plus économe en batterie)
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) => _updateRadarData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initRadar() async {
    await _determinePosition();
    await _updateRadarData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    try {
      // Utilisation d'une précision équilibrée pour économiser la batterie
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        // Envoi au serveur (PostgreSQL)
        await ApiService.updateUserLocation(widget.userId, position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Erreur GPS : $e");
    }
  }

  Future<void> _updateRadarData() async {
    try {
      final membersData = await ApiService.getTontineMembersLocations(widget.tontineId);
      
      List<Marker> markers = [];
      for (var m in membersData) {
      // Le champ retourné par la route /locations est 'id' (pas 'user_id')
      if (m['id'] == widget.userId) continue;

        final lat = double.tryParse(m['latitude'].toString()) ?? 0.0;
        final lon = double.tryParse(m['longitude'].toString()) ?? 0.0;

        if (lat == 0 || lon == 0) continue;

        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 80,
            height: 80,
            child: _buildMemberMarker(m['fullname'] ?? "Membre"),
          ),
        );
      }

      if (mounted) {
        setState(() => _memberMarkers = markers);
      }
    } catch (e) {
      debugPrint("Erreur Sync Radar : $e");
    }
  }

  // Design du marqueur membre
  Widget _buildMemberMarker(String name) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryOrange, width: 1),
          ),
          child: Text(
            name.split(' ')[0], // Affiche juste le prénom pour plus de clarté
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.location_on, color: primaryOrange, size: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("RADAR TONTINE", style: TextStyle(color: primaryOrange, fontSize: 14, fontWeight: FontWeight.bold)),
            Text("${widget.tontineName} • ${_memberMarkers.length} en ligne", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location), 
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(_currentPosition!, 15.0);
              }
            }
          ),
        ],
      ),
      body: _isLoading || _currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryOrange, strokeWidth: 2),
                  const SizedBox(height: 20),
                  Text(_statusMessage, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', // Carte Sombre (CartoDB)
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(
                  markers: [
                    // MOI
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.circle, color: Colors.blue, size: 20),
                          Icon(Icons.person, color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                    // LES AUTRES
                    ..._memberMarkers,
                  ],
                ),
              ],
            ),
    );
  }
}