import 'package:flutter/material.dart';
import 'doctor_pharmacist_chat.dart';
import 'prescription_scanner_page.dart';

class PharmacistPortalPage extends StatelessWidget {
  const PharmacistPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    const String authFirstName = 'User';
    final String routedFirstName = (args?['firstName'] as String? ?? '').trim();
    final String firstName = routedFirstName.isNotEmpty ? routedFirstName : authFirstName;
    final Map<String, String> userArgs = {'firstName': firstName};

    return Scaffold(
      appBar: AppBar(
        title: Text("Wasfeh"),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Hello, $firstName",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Quickly verify and dispense medications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // QR Code Scanner and National ID Lookup
            Card(
              color: Colors.blue.shade900,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(20),
                leading: Icon(Icons.qr_code, color: Colors.white),
                title: Text(
                  "Scan QR Code",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                subtitle: Text(
                  "Instant prescription verification",
                  style: TextStyle(color: Colors.white),
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrescriptionScannerPage(),
                      ),
                    );
                    if (result != null && result['dispensed'] == true) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Medication dispensed for patient ${result['patientId']}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('Open Scanner',
                      style: TextStyle(color: Colors.blue)),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Manual ID Lookup
            TextField(
              decoration: InputDecoration(
                labelText: "Manual ID Lookup",
                hintText: "National ID...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),
            // Doctor Chat and Recent Activity
            Row(
              children: [
                _PortalOption(
                  icon: Icons.chat,
                  label: "Doctor Chat",
                  onTap: () {
                    Navigator.pushNamed(context, '/doctor-dashboard', arguments: userArgs);
                  },
                ),
                _PortalOption(
                  icon: Icons.refresh,
                  label: "Recent Activity",
                  onTap: () {
                    Navigator.pushNamed(context, '/patient-dashboard', arguments: userArgs);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            // Pending Refill Requests
            Text(
              "Pending Refill Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Expanded(
              child: Center(
                child: Text('No pending refill requests right now.'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Adjust this based on navigation state
        onTap: (index) async {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/pharmacist-portal');
              break;
            case 1:
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrescriptionScannerPage()),
              );
              if (result != null &&
                  result['dispensed'] == true &&
                  context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Medication dispensed for patient ${result['patientId']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              break;
            case 2:
              // Open chat as bottom sheet instead of navigating
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => DoctorPharmacistChat(
                  firstName: firstName,
                  userRole: 'pharmacist',
                ),
              );
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/signin');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
        ],
      ),
    );
  }
}

class _PortalOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PortalOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: Colors.white,
          margin: EdgeInsets.all(10),
          elevation: 5,
          child: ListTile(
            leading: Icon(icon, color: Colors.blue),
            title: Text(label, style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

