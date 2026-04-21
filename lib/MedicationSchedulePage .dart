import 'package:flutter/material.dart';
import 'notification_service.dart';

class _MedicationEntry {
  final String time;
  final String medication;
  final String dosage;
  final int hour;
  final int minute;
  bool isTaken = false;

  _MedicationEntry({
    required this.time,
    required this.medication,
    required this.dosage,
    required this.hour,
    required this.minute,
  });
}

class MedicationSchedulePage extends StatefulWidget {
  const MedicationSchedulePage({super.key});

  @override
  State<MedicationSchedulePage> createState() => _MedicationSchedulePageState();
}

class _MedicationSchedulePageState extends State<MedicationSchedulePage> {
  int _selectedDayIndex = 0;
  final List<String> _days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  final List<_MedicationEntry> _medications = [
    _MedicationEntry(
        time: '08:00 AM',
        medication: 'Amoxicillin',
        dosage: '1 capsule • Post-meal',
        hour: 8,
        minute: 0),
    _MedicationEntry(
        time: '02:00 PM',
        medication: 'Amoxicillin',
        dosage: '1 capsule • Post-meal',
        hour: 14,
        minute: 0),
    _MedicationEntry(
        time: '09:00 PM',
        medication: 'Melatonin',
        dosage: '1 capsule • Post-meal',
        hour: 21,
        minute: 0),
    _MedicationEntry(
        time: '10:00 PM',
        medication: 'Amoxicillin',
        dosage: '1 capsule • Post-meal',
        hour: 22,
        minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    await NotificationService().cancelAll();
    for (int i = 0; i < _medications.length; i++) {
      final med = _medications[i];
      if (!med.isTaken) {
        await NotificationService().scheduleMedicationReminder(
          id: i,
          medicationName: med.medication,
          hour: med.hour,
          minute: med.minute,
        );
      }
    }
  }

  void _toggleTaken(int index) {
    setState(() {
      _medications[index].isTaken = !_medications[index].isTaken;
    });

    if (_medications[index].isTaken) {
      NotificationService().cancelById(index);
    } else {
      final med = _medications[index];
      NotificationService().scheduleMedicationReminder(
        id: index,
        medicationName: med.medication,
        hour: med.hour,
        minute: med.minute,
      );
    }
  }

  int get _takenCount => _medications.where((m) => m.isTaken).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'December 2025',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_days.length, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedDayIndex == i
                          ? Colors.blue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Center(
                      child: Text(
                        _days[i],
                        style: TextStyle(
                          color: _selectedDayIndex == i
                              ? Colors.white
                              : Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              "Today's Routine $_takenCount of ${_medications.length} taken",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _medications.length,
                itemBuilder: (context, index) {
                  final med = _medications[index];
                  return _MedicationItem(
                    time: med.time,
                    medication: med.medication,
                    dosage: med.dosage,
                    isTaken: med.isTaken,
                    onToggle: () => _toggleTaken(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/patient-dashboard');
            case 2:
              Navigator.pushReplacementNamed(context, '/pharmacy');
            case 3:
              Navigator.pushReplacementNamed(context, '/signin');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_pharmacy), label: 'Pharmacy'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MedicationItem extends StatelessWidget {
  final String time;
  final String medication;
  final String dosage;
  final bool isTaken;
  final VoidCallback onToggle;

  const _MedicationItem({
    required this.time,
    required this.medication,
    required this.dosage,
    required this.isTaken,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time.split(' ')[0],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              time.split(' ').length > 1 ? time.split(' ')[1] : '',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        title: Text(
          medication,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isTaken ? TextDecoration.lineThrough : null,
            color: isTaken ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(dosage),
        trailing: GestureDetector(
          onTap: onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(isTaken),
              color: isTaken ? Colors.green : Colors.blue,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
