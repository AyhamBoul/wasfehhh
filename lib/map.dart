import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class PharmacyPage extends StatefulWidget {
  const PharmacyPage({super.key});

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(31.9522, 35.9330);
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _locateUser();
  }

  Future<void> _locateUser() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() {
          _center = LatLng(pos.latitude, pos.longitude);
          _locating = false;
        });
        _mapController.move(_center, 15);
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _launchMaps(String query) async {
    final q = query.isEmpty ? 'pharmacies near me' : query;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName = args?['firstName'] as String? ?? 'User';
    final Map<String, String> userArgs = {'firstName': firstName};

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Pharmacy Map'),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Map ──
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wasfehhh',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _center,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimary.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.my_location,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_locating)
                  const Positioned.fill(
                    child: Center(
                        child: CircularProgressIndicator(color: kPrimary)),
                  ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'locate_map',
                    backgroundColor: kCardBg,
                    foregroundColor: kPrimary,
                    elevation: 3,
                    onPressed: () => _mapController.move(_center, 15),
                    child: const Icon(Icons.my_location, size: 18),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a pharmacy...',
                      prefixIcon: const Icon(Icons.search,
                          color: kTextSecondary, size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            _launchMaps(_searchController.text.trim()),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Nearby Pharmacies',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary)),
                  const SizedBox(height: 4),
                  const Text(
                      'Tap Navigate to open directions in Google Maps.',
                      style:
                          TextStyle(fontSize: 12, color: kTextSecondary)),
                  const SizedBox(height: 14),

                  _PharmacyCard(
                    name: 'Nearest Pharmacy',
                    query: 'pharmacy near me',
                    icon: Icons.local_pharmacy,
                    color: kPrimary,
                    onTap: _launchMaps,
                  ),
                  const SizedBox(height: 10),
                  _PharmacyCard(
                    name: '24-Hour Pharmacy',
                    query: '24 hour pharmacy near me',
                    icon: Icons.nightlight_outlined,
                    color: const Color(0xFF7C3AED),
                    onTap: _launchMaps,
                  ),
                  const SizedBox(height: 10),
                  _PharmacyCard(
                    name: 'Hospital Pharmacy',
                    query: 'hospital pharmacy near me',
                    icon: Icons.local_hospital_outlined,
                    color: kDanger,
                    onTap: _launchMaps,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchMaps('pharmacies near me'),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Search All Nearby Pharmacies'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/patient-dashboard',
                  arguments: userArgs);
            case 1:
              Navigator.pushReplacementNamed(context, '/medication-schedule',
                  arguments: userArgs);
            case 3:
              Navigator.pushReplacementNamed(context, '/profile',
                  arguments: userArgs);
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_pharmacy_outlined),
              activeIcon: Icon(Icons.local_pharmacy),
              label: 'Pharmacy'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final String name;
  final String query;
  final IconData icon;
  final Color color;
  final Future<void> Function(String) onTap;

  const _PharmacyCard({
    required this.name,
    required this.query,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                    fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => onTap(query),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Navigate'),
          ),
        ],
      ),
    );
  }
}
