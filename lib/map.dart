import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyPage extends StatefulWidget {
  const PharmacyPage({super.key});

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 13,
  );

  static final Set<Marker> _pharmacyMarkers = {
    Marker(
      markerId: MarkerId('cvs'),
      position: LatLng(37.7804, -122.4212),
      infoWindow: InfoWindow(title: 'CVS Pharmacy'),
    ),
    Marker(
      markerId: MarkerId('walgreens'),
      position: LatLng(37.7840, -122.4089),
      infoWindow: InfoWindow(title: 'Walgreens Pharmacy'),
    ),
    Marker(
      markerId: MarkerId('cbhs'),
      position: LatLng(37.7736, -122.4244),
      infoWindow: InfoWindow(title: 'CBHS Pharmacy'),
    ),
  };

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar for pharmacy
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for a pharmacy...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: _initialCamera,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  markers: _pharmacyMarkers,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _launchMapForQuery(_searchController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Open in Google Maps"),
            ),
            const SizedBox(height: 20),
            // AI Recommendations
            const Text(
              "AI Assistant Recommendations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Here are 3 highly rated pharmacies within 5km of your location:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            ...[
              ('CBHS Pharmacy',
                  '1380 Howard St, San Francisco, CA 94103 — Rating: 5 ⭐ · 1.4 km'),
              ('Gates Opioids Pharmacy',
                  '2101 Sutter St, San Francisco, CA 94115 — Rating: 4.5 ⭐ · 3.3 km'),
              ('CVS Pharmacy',
                  '701 Van Ness Ave, San Francisco, CA 94102 — Rating: 4.2 ⭐ · 2.0 km'),
            ].map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${entry.$1}  ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    TextSpan(
                      text: entry.$2,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Nearby Pharmacies
            const Text(
              "Nearby Pharmacies",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _NearbyPharmacy(
              name: "CVS Pharmacy",
              url: "https://maps.google.com/?cid=1379669075810392204",
            ),
            _NearbyPharmacy(
              name: "Walgreens Pharmacy",
              url: "https://maps.google.com/?cid=1379669075810392205",
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Adjust this based on navigation state
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/patient-dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/medication-schedule');
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/signin');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy), label: "Pharmacy"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
        ],
      ),
    );
  }

  Future<void> _launchMapForQuery(String query) async {
    final String sanitized = query.isEmpty ? 'nearby pharmacies' : query;
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(sanitized)}',
    );

    final bool launched = await launchUrl(
      mapsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }
}

class _NearbyPharmacy extends StatelessWidget {
  final String name;
  final String url;

  const _NearbyPharmacy({
    required this.name,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(name),
        trailing: ElevatedButton(
          onPressed: () {
            _launchURL(url);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Navigate"),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}