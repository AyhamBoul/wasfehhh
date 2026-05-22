import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class _MedicationEntry {
  final String prescriptionId;
  final String medName;
  final String time;
  final String medication;
  final String dosage;
  final int hour;
  final int minute;
  bool isTaken = false;

  _MedicationEntry({
    required this.prescriptionId,
    required this.medName,
    required this.time,
    required this.medication,
    required this.dosage,
    required this.hour,
    required this.minute,
  });

  String get takenKey => '$prescriptionId:$medName:$hour:$minute';
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

  List<_MedicationEntry> _medications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday % 7;
    _loadMedications()
        .then((_) => _loadTakenState())
        .then((_) => _scheduleNotifications());
  }

  // Maps a frequency string to a list of (hour, minute, displayTime) slots.
  List<(int, int, String)> _parseFrequency(String frequency) {
    final lower = frequency.toLowerCase();
    if (lower.contains('4') ||
        lower.contains('four') ||
        lower.contains('qid')) {
      return [
        (7, 0, '07:00 AM'),
        (12, 0, '12:00 PM'),
        (17, 0, '05:00 PM'),
        (22, 0, '10:00 PM'),
      ];
    }
    if (lower.contains('3') ||
        lower.contains('three') ||
        lower.contains('thrice') ||
        lower.contains('tid')) {
      return [
        (8, 0, '08:00 AM'),
        (14, 0, '02:00 PM'),
        (21, 0, '09:00 PM'),
      ];
    }
    if (lower.contains('2') ||
        lower.contains('two') ||
        lower.contains('twice') ||
        lower.contains('bid')) {
      return [(8, 0, '08:00 AM'), (20, 0, '08:00 PM')];
    }
    if (lower.contains('night') ||
        lower.contains('sleep') ||
        lower.contains('bedtime') ||
        lower.contains('hs')) {
      return [(21, 0, '09:00 PM')];
    }
    return [(8, 0, '08:00 AM')];
  }

  Future<void> _loadMedications() async {
    final id = AuthService().currentUser?.nationalId;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final prescriptions = await AuthService().getPrescriptions(id);
    final entries = <_MedicationEntry>[];
    for (final rx in prescriptions.where((p) => !p.isDispensed)) {
      for (final med in rx.medications) {
        for (final slot in _parseFrequency(med.frequency)) {
          entries.add(_MedicationEntry(
            prescriptionId: rx.id,
            medName: med.name,
            time: slot.$3,
            medication: med.name,
            dosage: '${med.dosage} · ${med.frequency}',
            hour: slot.$1,
            minute: slot.$2,
          ));
        }
      }
    }
    entries.sort((a, b) =>
        a.hour != b.hour ? a.hour.compareTo(b.hour) : a.minute.compareTo(b.minute));
    if (mounted) {
      setState(() {
        _medications = entries;
        _loading = false;
      });
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTakenState() async {
    if (_medications.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final id = AuthService().currentUser?.nationalId ?? 'guest';
    final raw = prefs.getString('qm_taken_${id}_${_todayKey()}');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      // New format: list of takenKey strings.
      final takenKeys = decoded.whereType<String>().toSet();
      for (final m in _medications) {
        m.isTaken = takenKeys.contains(m.takenKey);
      }
    } catch (_) {
      // Ignore stale data from old index-based format.
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveTakenState() async {
    final prefs = await SharedPreferences.getInstance();
    final id = AuthService().currentUser?.nationalId ?? 'guest';
    final takenKeys =
        _medications.where((m) => m.isTaken).map((m) => m.takenKey).toList();
    await prefs.setString(
      'qm_taken_${id}_${_todayKey()}',
      jsonEncode(takenKeys),
    );
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
        minute: med.minute,
      );
    }
    _saveTakenState();
  }

  int get _takenCount => _medications.where((m) => m.isTaken).length;

  // Returns the actual calendar date for week column i (0=Sun … 6=Sat).
  // Uses DateTime overflow arithmetic so month boundaries are handled correctly.
  DateTime _weekDate(int i) {
    final now = DateTime.now();
    final todayIndex = now.weekday % 7; // 1-7 (Mon-Sun) → 0=Sun … 6=Sat
    return DateTime(now.year, now.month, now.day - todayIndex + i);
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(
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
                            onTap: () =>
                                setState(() => _selectedDayIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? kPrimary
                                    : Colors.transparent,
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
                                    '${_weekDate(i).day}',
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
                          Text(
                            '$_takenCount / ${_medications.length} taken',
                            style: const TextStyle(
                                fontSize: 13, color: kTextSecondary),
                          ),
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
                  child: _medications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.medication_outlined,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No active prescriptions.',
                                  style: TextStyle(
                                      color: kTextSecondary, fontSize: 14)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Your schedule will appear here once a\ndoctor issues a prescription.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: kTextSecondary, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: _medications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
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
        color: isTaken ? kSuccess.withValues(alpha: 0.06) : kCardBg,
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
                    decoration:
                        isTaken ? TextDecoration.lineThrough : null,
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
