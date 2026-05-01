import 'package:flutter/material.dart';
import 'app_theme.dart';
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
  State<MedicationSchedulePage> createState() =>
      _MedicationSchedulePageState();
}

class _MedicationSchedulePageState extends State<MedicationSchedulePage> {
  late int _selectedDayIndex;
  final List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _daysFull = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  final List<_MedicationEntry> _medications = [
    _MedicationEntry(
        time: '08:00 AM',
        medication: 'Amoxicillin',
        dosage: '500mg · 1 capsule · Post-meal',
        hour: 8,
        minute: 0),
    _MedicationEntry(
        time: '02:00 PM',
        medication: 'Amoxicillin',
        dosage: '500mg · 1 capsule · Post-meal',
        hour: 14,
        minute: 0),
    _MedicationEntry(
        time: '09:00 PM',
        medication: 'Melatonin',
        dosage: '5mg · 1 capsule · Before sleep',
        hour: 21,
        minute: 0),
    _MedicationEntry(
        time: '10:00 PM',
        medication: 'Amoxicillin',
        dosage: '500mg · 1 capsule · Post-meal',
        hour: 22,
        minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday % 7;
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
    setState(() => _medications[index].isTaken = !_medications[index].isTaken);
    if (_medications[index].isTaken) {
      NotificationService().cancelById(index);
    } else {
      final med = _medications[index];
      NotificationService().scheduleMedicationReminder(
          id: index,
          medicationName: med.medication,
          hour: med.hour,
          minute: med.minute);
    }
  }

  int get _takenCount => _medications.where((m) => m.isTaken).length;

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName = args?['firstName'] as String? ?? 'User';
    final Map<String, String> userArgs = {'firstName': firstName};

    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel = '${months[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Calendar strip ──
          Container(
            color: kCardBg,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monthLabel,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final isToday = i == DateTime.now().weekday % 7;
                    final isSelected = i == _selectedDayIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday && !isSelected
                                ? kPrimary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_days[i],
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : kTextSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              '${(now.day - (DateTime.now().weekday % 7) + i).clamp(1, 31)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : kTextPrimary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Progress bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_daysFull[_selectedDayIndex]}\'s Routine',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary),
                    ),
                    Text('$_takenCount / ${_medications.length} taken',
                        style: const TextStyle(
                            fontSize: 13, color: kTextSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _medications.isEmpty
                        ? 0
                        : _takenCount / _medications.length,
                    backgroundColor: kBorder,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(kSuccess),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: _medications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final med = _medications[i];
                return _MedicationItem(
                  time: med.time,
                  medication: med.medication,
                  dosage: med.dosage,
                  isTaken: med.isTaken,
                  onToggle: () => _toggleTaken(i),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/patient-dashboard',
                  arguments: userArgs);
            case 2:
              Navigator.pushReplacementNamed(context, '/pharmacy',
                  arguments: userArgs);
            case 3:
              Navigator.pushReplacementNamed(context, '/signin');
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTaken
            ? kSuccess.withValues(alpha: 0.06)
            : kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTaken ? kSuccess.withValues(alpha: 0.3) : kBorder,
        ),
      ),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  time.split(' ')[0],
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isTaken ? kTextSecondary : kPrimary),
                ),
                Text(
                  time.split(' ').length > 1 ? time.split(' ')[1] : '',
                  style: const TextStyle(
                      fontSize: 10, color: kTextSecondary),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: kBorder,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isTaken ? kTextSecondary : kTextPrimary,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                    decorationColor: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(dosage,
                    style: const TextStyle(
                        fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ),
          // Toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isTaken
                  ? Container(
                      key: const ValueKey('taken'),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kSuccess,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 18),
                    )
                  : Container(
                      key: const ValueKey('pending'),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kBorder, width: 1.5),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
