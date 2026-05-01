import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
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

  Future<void> _openMaps(String query) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: const BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Browsing as guest',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13)),
                            const Text('Nearby Pharmacies',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/signin'),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.login, size: 16),
                          label: const Text('Sign In',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sign in to manage prescriptions, set reminders, and more.',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(
                                    context, '/create-account'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.only(left: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Register',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Map ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 240,
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
                                  userAgentPackageName:
                                      'com.example.wasfehhh',
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
                                              color: kPrimary.withValues(
                                                  alpha: 0.4),
                                              blurRadius: 10,
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
                                  child: CircularProgressIndicator(
                                      color: kPrimary)),
                            ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: FloatingActionButton.small(
                              heroTag: 'locate_guest',
                              backgroundColor: kCardBg,
                              foregroundColor: kPrimary,
                              elevation: 3,
                              onPressed: () =>
                                  _mapController.move(_center, 15),
                              child: const Icon(Icons.my_location, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Find a Pharmacy',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary)),
                    const SizedBox(height: 12),

                    _GuestPharmCard(
                      icon: Icons.local_pharmacy,
                      title: 'Nearest Pharmacy',
                      subtitle: 'Closest to your location',
                      color: kPrimary,
                      onTap: () => _openMaps('pharmacy near me'),
                    ),
                    const SizedBox(height: 10),
                    _GuestPharmCard(
                      icon: Icons.nightlight_outlined,
                      title: '24-Hour Pharmacy',
                      subtitle: 'Open around the clock',
                      color: const Color(0xFF7C3AED),
                      onTap: () =>
                          _openMaps('24 hour pharmacy near me'),
                    ),
                    const SizedBox(height: 10),
                    _GuestPharmCard(
                      icon: Icons.local_hospital_outlined,
                      title: 'Hospital Pharmacy',
                      subtitle: 'Hospital-affiliated',
                      color: kDanger,
                      onTap: () =>
                          _openMaps('hospital pharmacy near me'),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openMaps('pharmacies near me'),
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Search All Nearby Pharmacies'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CTA card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.health_and_safety_rounded,
                              color: Colors.white, size: 28),
                          const SizedBox(height: 10),
                          const Text('Get the full experience',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            'Create an account to manage prescriptions, track medications, and receive reminders.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/create-account'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: kPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Create Account',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/signin'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Colors.white),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Sign In',
                                      style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushReplacementNamed(context, '/signin');
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.local_pharmacy_outlined),
              activeIcon: Icon(Icons.local_pharmacy),
              label: 'Pharmacies'),
          BottomNavigationBarItem(
              icon: Icon(Icons.login), label: 'Sign In'),
        ],
      ),
    );
  }
}

class _GuestPharmCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GuestPharmCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecondary)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.directions, color: color, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
