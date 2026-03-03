import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';

class MembersMapScreen extends StatefulWidget {
  const MembersMapScreen({super.key});

  @override
  State<MembersMapScreen> createState() => _MembersMapScreenState();
}

class _MembersMapScreenState extends State<MembersMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  
  final Color gold = const Color(0xFFD4AF37);
  final LatLng _centerYaounde = const LatLng(3.848, 11.502); // Point de départ par défaut

  @override
  void initState() {
    super.initState();
    _loadMembersLocations();
  }

  Future<void> _loadMembersLocations() async {
    try {
      var locations = await ApiService.getMembersLocations();
      
      Set<Marker> newMarkers = locations.map((loc) {
        // Conversion sécurisée (parfois les API renvoient des strings)
        double lat = double.parse(loc['latitude'].toString());
        double lng = double.parse(loc['longitude'].toString());

        return Marker(
          markerId: MarkerId(loc['id'].toString()),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: loc['fullname'],
            snippet: "Membre G-Caisse",
          ),
          // On met un marqueur Orange (le plus proche du doré disponible par défaut)
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        );
      }).toSet();

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });
        
        // Si on a des marqueurs, on essaie de zoomer pour tous les voir
        if (_markers.isNotEmpty) {
          _zoomToFit(_markers);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Erreur Map: $e");
    }
  }

  // Fonction pour cadrer la caméra sur tous les membres
  void _zoomToFit(Set<Marker> markers) {
    if (_mapController == null) return;

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (var m in markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50, // Padding
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("POSITIONS DES MEMBRES", style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMembersLocations();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(target: _centerYaounde, zoom: 12),
            markers: _markers,
            myLocationEnabled: true, // Affiche le point bleu de ma position
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false, // On retire les boutons +/- moches par défaut
          ),
          
          // Indicateur de chargement stylé
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(color: gold),
              ),
            ),
            
          // Bouton flottant pour recentrer manuellement si besoin (Design Perso)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              child: Icon(Icons.center_focus_strong, color: gold),
              onPressed: () {
                 if (_markers.isNotEmpty) _zoomToFit(_markers);
                 else _mapController?.animateCamera(CameraUpdate.newLatLng(_centerYaounde));
              },
            ),
          )
        ],
      ),
    );
  }
}