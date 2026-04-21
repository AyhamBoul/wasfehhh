import 'package:flutter/material.dart';

class PatientDashboardPage extends StatelessWidget {
  const PatientDashboardPage({super.key});

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
            Card(
              color: Colors.blue,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(20),
                leading: Icon(Icons.medication, color: Colors.white),
                title: Text(
                  "Upcoming Dose",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                subtitle: Text(
                  'No upcoming doses in your profile yet.',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text("Mark as Taken", style: TextStyle(color: Colors.blue)),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                _PatientOption(
                  icon: Icons.article,
                  label: "My Records",
                  onTap: () {
                    Navigator.pushNamed(context, '/patient-records',
                        arguments: userArgs);
                  },
                ),
                _PatientOption(
                  icon: Icons.calendar_today,
                  label: "Medication Calendar",
                  onTap: () {
                    Navigator.pushNamed(context, '/medication-schedule', arguments: userArgs);
                  },
                ),
              ],
            ),
            Row(
              children: [
                _PatientOption(
                  icon: Icons.location_on,
                  label: "Pharmacy Map",
                  onTap: () {
                    Navigator.pushNamed(context, '/pharmacy', arguments: userArgs);
                  },
                ),
                _PatientOption(
                  icon: Icons.connect_without_contact,
                  label: "Doctor Connect",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Doctor Connect coming soon.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Adjust this based on navigation state
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/medication-schedule', arguments: userArgs);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/pharmacy', arguments: userArgs);
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
}

class _PatientOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PatientOption({
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