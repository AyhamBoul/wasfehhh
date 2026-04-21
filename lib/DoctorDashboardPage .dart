import 'package:flutter/material.dart';
import 'doctor_pharmacist_chat.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

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
            Text(
              "Hello, $firstName",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "How can we help your patients today?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.blue,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(20),
                leading: Icon(Icons.add, color: Colors.white),
                title: Text(
                  "New Prescription",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                subtitle: Text(
                  "Issue a secure digital prescription with AI safety checks.",
                  style: TextStyle(color: Colors.white),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/new-prescription', arguments: userArgs);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text("Create Now", style: TextStyle(color: Colors.blue)),
                ),
              ),
            ),
            Row(
              children: [
                _DashboardOption(
                  icon: Icons.history,
                  label: "Patient History",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Patient history coming soon.')),
                    );
                  },
                ),
                _DashboardOption(
                  icon: Icons.chat_bubble,
                  label: "Pharmacists",
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => DoctorPharmacistChat(
                        firstName: firstName,
                        userRole: 'doctor',
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Recent Issues",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            const Expanded(
              child: Center(
                child: Text('No recent issues yet.'),
              ),
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
              Navigator.pushReplacementNamed(context, '/new-prescription', arguments: userArgs);
              break;
            case 2:
              // Open chat as bottom sheet instead of navigating
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => DoctorPharmacistChat(
                  firstName: firstName,
                  userRole: 'doctor',
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
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
        ],
      ),
    );
  }
}

class _DashboardOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardOption({required this.icon, required this.label, required this.onTap});

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

